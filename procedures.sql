USE calorie_reco;
DELIMITER $$

-- Drop existing procedures (safe)
DROP PROCEDURE IF EXISTS sp_log_dish$$
DROP PROCEDURE IF EXISTS sp_daily_summary$$
DROP PROCEDURE IF EXISTS sp_adjust_goal$$
DROP PROCEDURE IF EXISTS sp_recommend_lower_calorie$$
DROP PROCEDURE IF EXISTS sp_get_or_generate_recommendations$$
DROP PROCEDURE IF EXISTS sp_daily_meal_summary_inferred$$
DROP PROCEDURE IF EXISTS sp_generate_meal_insights$$

-- ✅ Log a dish for a user (modular calorie calc)
CREATE PROCEDURE sp_log_dish(
  IN p_user_id BIGINT UNSIGNED,
  IN p_dish_id BIGINT UNSIGNED,
  IN p_r_id    BIGINT UNSIGNED,
  IN p_log_date DATE,
  IN p_quantity DECIMAL(6,2)
)
BEGIN
  INSERT INTO user_log (user_id, dish_id, r_id, log_date, quantity, total_calories)
  VALUES (
    p_user_id,
    p_dish_id,
    p_r_id,
    p_log_date,
    p_quantity,
    fn_calc_total_calories(p_dish_id, p_quantity)
  );
END$$

-- ✅ Daily summary vs user's calorie_target
CREATE PROCEDURE sp_daily_summary(
  IN p_user_id BIGINT UNSIGNED,
  IN p_date DATE
)
BEGIN
  DECLARE target INT;

  SELECT calorie_target INTO target
  FROM users WHERE user_id = p_user_id;

  SELECT
    u.user_id,
    u.name,
    p_date AS log_date,
    COALESCE(SUM(l.total_calories),0) AS total_calories,
    COALESCE(SUM(d.protein_g * l.quantity),0) AS total_protein,
    COALESCE(SUM(d.carbs_g * l.quantity),0) AS total_carbs,
    COALESCE(SUM(d.fats_g * l.quantity),0) AS total_fats,
    target AS calorie_target,
    CASE
      WHEN COALESCE(SUM(l.total_calories),0) > target THEN 'EXCEEDED'
      ELSE 'OK'
    END AS status
  FROM users u
  LEFT JOIN user_log l ON u.user_id = l.user_id AND l.log_date = p_date
  LEFT JOIN dishes d ON d.dish_id = l.dish_id
  WHERE u.user_id = p_user_id
  GROUP BY u.user_id, u.name, p_date, target;
END$$

-- ✅ Goal adjustment: 10% toward recent average intake
CREATE PROCEDURE sp_adjust_goal(
  IN p_user_id BIGINT UNSIGNED,
  IN p_days INT
)
BEGIN
  DECLARE avg_intake INT;
  DECLARE current_target INT;
  DECLARE new_target INT;

  SELECT calorie_target INTO current_target FROM users WHERE user_id = p_user_id;

  SELECT COALESCE(AVG(daily.total),0)
    INTO avg_intake
  FROM (
    SELECT log_date, SUM(total_calories) AS total
    FROM user_log
    WHERE user_id = p_user_id
      AND log_date >= CURDATE() - INTERVAL p_days DAY
    GROUP BY log_date
  ) daily;

  SET new_target = current_target + ROUND((avg_intake - current_target) * 0.1);

  UPDATE users SET calorie_target = new_target WHERE user_id = p_user_id;

  SELECT current_target AS old_target,
         avg_intake AS recent_avg,
         new_target AS updated_target;
END$$

-- ✅ Recommend lower-calorie alternatives (live search or stored recos)
CREATE PROCEDURE sp_recommend_lower_calorie(
  IN p_craving VARCHAR(200),
  IN p_user_id BIGINT UNSIGNED,
  IN p_original_dish_id BIGINT UNSIGNED,
  IN p_max_calories INT,
  IN p_max_distance_km FLOAT
)
BEGIN
  DECLARE orig_cals INT;
  DECLARE u_lat DECIMAL(9,6);
  DECLARE u_lon DECIMAL(9,6);

  -- Get user location
  SELECT latitude, longitude INTO u_lat, u_lon
  FROM users WHERE user_id = p_user_id;

  -- Get original dish calories if provided
  IF p_original_dish_id IS NOT NULL THEN
    SELECT calories INTO orig_cals FROM dishes WHERE dish_id = p_original_dish_id;
  ELSE
    SET orig_cals = NULL;
  END IF;

  -- Use stored recommendations if available
  IF p_original_dish_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM recommendation WHERE dish_id_original = p_original_dish_id
  ) THEN
    SELECT
      d.dish_id,
      d.dish_name,
      r.r_id,
      r.name AS restaurant_name,
      r.latitude,
      r.longitude,
      r.rating,
      d.calories,
      d.protein_g,
      d.carbs_g,
      d.fats_g,
      d.price,
      (orig_cals - d.calories) AS calorie_savings,
      fn_calc_total_calories(d.dish_id, 1.0) AS expected_intake,
      ro.taste_score
    FROM recommendation ro
    JOIN dishes d ON d.dish_id = ro.dish_id_alt
    JOIN restaurants r ON r.r_id = d.r_id
    WHERE ro.dish_id_original = p_original_dish_id
      AND d.dish_name LIKE CONCAT('%', p_craving, '%')
      AND d.calories < orig_cals
      AND (p_max_distance_km IS NULL OR fn_distance_km(u_lat, u_lon, r.latitude, r.longitude) <= p_max_distance_km)
    ORDER BY ro.taste_score DESC, d.calories ASC, r.rating DESC, d.price ASC
    LIMIT 50;
  ELSE
    -- Live search fallback
    SELECT
      d.dish_id,
      d.dish_name,
      r.r_id,
      r.name AS restaurant_name,
      r.latitude,
      r.longitude,
      r.rating,
      d.calories,
      d.protein_g,
      d.carbs_g,
      d.fats_g,
      d.price,
      CASE
        WHEN orig_cals IS NOT NULL THEN (orig_cals - d.calories)
        WHEN p_max_calories IS NOT NULL THEN (p_max_calories - d.calories)
        ELSE NULL
      END AS calorie_savings,
      fn_calc_total_calories(d.dish_id, 1.0) AS expected_intake,
      fn_cosine_similarity_user_dish(p_original_dish_id, d.dish_id) AS taste_score
    FROM dishes d
    JOIN restaurants r ON r.r_id = d.r_id
    WHERE d.dish_name LIKE CONCAT('%', p_craving, '%')
      AND (
        (orig_cals IS NOT NULL AND d.calories < orig_cals)
        OR (orig_cals IS NULL AND (p_max_calories IS NULL OR d.calories <= p_max_calories))
      )
      AND (p_max_distance_km IS NULL OR fn_distance_km(u_lat, u_lon, r.latitude, r.longitude) <= p_max_distance_km)
    ORDER BY taste_score DESC, d.calories ASC, r.rating DESC, d.price ASC
    LIMIT 50;
  END IF;
END$$

-- ✅ Get or generate recommendations (inserts up to 5 auto suggestions)
CREATE PROCEDURE sp_get_or_generate_recommendations(
  IN p_dish_name VARCHAR(200),
  IN p_user_id BIGINT UNSIGNED,
  IN p_max_distance_km FLOAT
)
BEGIN
  DECLARE u_lat DECIMAL(9,6);
  DECLARE u_lon DECIMAL(9,6);

  -- Get user location
  SELECT latitude, longitude INTO u_lat, u_lon
  FROM users WHERE user_id = p_user_id;

  -- Generate recommendations if they don't exist
  IF NOT EXISTS (
    SELECT 1 FROM recommendation WHERE dish_name_original = p_dish_name
  ) THEN
    INSERT INTO recommendation (dish_name_original, dish_name_alt, reason, taste_score)
    SELECT 
      p_dish_name,
      d2.dish_name,
      CONCAT('Auto-suggested: ', d2.dish_name),
      fn_cosine_similarity_dishes(d1.dish_name, d2.dish_name)
    FROM dishes d2
    JOIN dishes d1 ON d1.dish_name = p_dish_name
    JOIN restaurants r ON r.r_id = d2.r_id
    WHERE d2.dish_name <> p_dish_name
      AND d2.calories < d1.calories
      AND (p_max_distance_km IS NULL OR fn_distance_km(u_lat, u_lon, r.latitude, r.longitude) <= p_max_distance_km)
    ORDER BY d2.calories ASC
    LIMIT 5;
  END IF;

  -- Return recommendations
  SELECT
    ro.rec_id,
    da.dish_name,
    da.calories,
    r.name AS restaurant_name,
    r.latitude,
    r.longitude,
    (do.calories - da.calories) AS calorie_savings,
    ro.taste_score,
    fn_distance_km(u_lat, u_lon, r.latitude, r.longitude) AS distance_km
  FROM recommendation ro
  JOIN dishes do ON do.dish_name = ro.dish_name_original
  JOIN dishes da ON da.dish_name = ro.dish_name_alt
  JOIN restaurants r ON r.r_id = da.r_id
  WHERE ro.dish_name_original = p_dish_name
    AND (p_max_distance_km IS NULL OR fn_distance_km(u_lat, u_lon, r.latitude, r.longitude) <= p_max_distance_km)
  ORDER BY ro.taste_score DESC, calorie_savings DESC;
END$$

-- ✅ Daily meal summary with inferred meal buckets
CREATE PROCEDURE sp_daily_meal_summary_inferred (
  IN p_user_id BIGINT,
  IN p_date DATE
)
BEGIN
  SELECT
    CASE
      WHEN HOUR(log_time) BETWEEN 5 AND 10 THEN 'breakfast'
      WHEN HOUR(log_time) BETWEEN 11 AND 14 THEN 'lunch'
      WHEN HOUR(log_time) BETWEEN 15 AND 17 THEN 'snack'
      WHEN HOUR(log_time) BETWEEN 18 AND 21 THEN 'dinner'
      ELSE 'late'
    END AS inferred_meal,
    COUNT(*) AS dishes,
    SUM(total_calories) AS calories,
    SUM(d.protein_g * l.quantity) AS protein,
    SUM(d.carbs_g * l.quantity) AS carbs,
    SUM(d.fats_g * l.quantity) AS fats
  FROM user_log l
  JOIN dishes d ON d.dish_id = l.dish_id
  WHERE l.user_id = p_user_id AND l.log_date = p_date
  GROUP BY inferred_meal
  ORDER BY FIELD(inferred_meal, 'breakfast','lunch','snack','dinner','late');
END$$

-- ✅ Meal insights vs expected distribution
CREATE PROCEDURE sp_generate_meal_insights (
  IN p_user_id BIGINT,
  IN p_date DATE
)
BEGIN
  DECLARE target INT;

  SELECT calorie_target INTO target FROM users WHERE user_id = p_user_id;

  DELETE FROM meal_insights WHERE user_id = p_user_id AND log_date = p_date;

  INSERT INTO meal_insights (user_id, log_date, meal_label, actual_calories, expected_calories, deviation, message)
  SELECT
    p_user_id,
    p_date,
    inferred_meal,
    SUM(total_calories),
    ROUND(fn_expected_meal_ratio(inferred_meal) * target),
    SUM(total_calories) - ROUND(fn_expected_meal_ratio(inferred_meal) * target),
    CASE
      WHEN SUM(total_calories) > ROUND(fn_expected_meal_ratio(inferred_meal) * target)
        THEN CONCAT(UCASE(inferred_meal), ' exceeded by ', SUM(total_calories) - ROUND(fn_expected_meal_ratio(inferred_meal) * target), ' kcal')
      WHEN SUM(total_calories) < ROUND(fn_expected_meal_ratio(inferred_meal) * target)
        THEN CONCAT(UCASE(inferred_meal), ' under target by ', ROUND(fn_expected_meal_ratio(inferred_meal) * target) - SUM(total_calories), ' kcal')
      ELSE CONCAT(UCASE(inferred_meal), ' met target exactly')
    END
  FROM (
    SELECT
      CASE
        WHEN HOUR(log_time) BETWEEN 5 AND 10 THEN 'breakfast'
        WHEN HOUR(log_time) BETWEEN 11 AND 14 THEN 'lunch'
        WHEN HOUR(log_time) BETWEEN 15 AND 17 THEN 'snack'
        WHEN HOUR(log_time) BETWEEN 18 AND 21 THEN 'dinner'
        ELSE 'late'
      END AS inferred_meal,
      total_calories
    FROM user_log
    WHERE user_id = p_user_id AND log_date = p_date
  ) meal_data
  GROUP BY inferred_meal;
END$$

DELIMITER ;