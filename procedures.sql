USE calories;
DROP PROCEDURE IF EXISTS sp_get_or_generate_recommendations;
DROP PROCEDURE IF EXISTS sp_log_dish;
DROP PROCEDURE IF EXISTS sp_get_cheapest_delivery;
DROP PROCEDURE IF EXISTS sp_get_dish_id_by_name;
DROP PROCEDURE IF EXISTS sp_get_user_id_by_email;
DROP PROCEDURE IF EXISTS sp_get_daily_macros;
DELIMITER $$

CREATE PROCEDURE sp_get_or_generate_recommendations(
  IN p_dish_id BIGINT,
  IN p_user_id BIGINT,
  IN p_max_distance_km FLOAT,
  OUT p_alt_dish_name VARCHAR(100),
  OUT p_alt_restaurant VARCHAR(100),
  OUT p_alt_calories INT,
  OUT p_calorie_diff INT
)
BEGIN
  DECLARE u_lat DECIMAL(9,6);
  DECLARE u_lon DECIMAL(9,6);
  DECLARE d_cals INT;
  DECLARE d_r_id BIGINT;

  -- Get user location
  SELECT latitude, longitude INTO u_lat, u_lon
  FROM users WHERE user_id = p_user_id;

  -- Get dish calories and restaurant
  SELECT calories, r_id INTO d_cals, d_r_id
  FROM dishes WHERE dish_id = p_dish_id;

  -- Check if recommendations exist
  IF NOT EXISTS (
    SELECT 1 FROM recommendation WHERE dish_id_original = p_dish_id
  ) THEN
    -- Generate recommendations
    INSERT INTO recommendation (
      dish_id_original, r_id_original, dish_id_alt, r_id_alt,
      taste_score, alt_price, alt_calories, calorie_diff
    )
    SELECT
      p_dish_id,
      d_r_id,
      d2.dish_id,
      d2.r_id,
      fn_cosine_similarity_user_dish(p_dish_id, d2.dish_id),
      d2.price,
      d2.calories,
      d_cals - d2.calories
    FROM dishes d2
    JOIN restaurants r ON r.r_id = d2.r_id
    WHERE d2.dish_id <> p_dish_id
      AND d2.calories < d_cals
      AND fn_distance_km(u_lat, u_lon, r.latitude, r.longitude) <= p_max_distance_km
      AND fn_cosine_similarity_user_dish(p_dish_id, d2.dish_id) >= 0.90
    ORDER BY d2.calories ASC
    LIMIT 5;
  END IF;

  -- Return best match directly into OUT parameters
  SELECT 
    da.dish_name,
    r.name,
    ro.alt_calories,
    ro.calorie_diff
  INTO 
    p_alt_dish_name,
    p_alt_restaurant,
    p_alt_calories,
    p_calorie_diff
  FROM recommendation ro
  JOIN dishes da ON da.dish_id = ro.dish_id_alt
  JOIN restaurants r ON r.r_id = ro.r_id_alt
  WHERE ro.dish_id_original = p_dish_id
  ORDER BY ro.calorie_diff ASC, ro.taste_score DESC, ro.alt_price ASC
  LIMIT 1;
END$$

DELIMITER $$

CREATE PROCEDURE sp_log_dish (
  IN p_user_id BIGINT,
  IN p_dish_id BIGINT,
  IN p_quantity FLOAT,
  IN p_log_date DATE
)
BEGIN
  DECLARE v_r_id BIGINT;
  DECLARE v_total_calories FLOAT;

  -- Get restaurant ID for the dish
  SELECT r_id INTO v_r_id
  FROM dishes
  WHERE dish_id = p_dish_id;

  -- Calculate total calories
  SET v_total_calories = fn_calc_total_calories(p_dish_id, p_quantity);

  -- Insert into user_log
  INSERT INTO user_log (
    user_id, dish_id, r_id, log_date, quantity, total_calories
  ) VALUES (
    p_user_id, p_dish_id, v_r_id, p_log_date, p_quantity, v_total_calories
  );
END$$

DELIMITER $$


CREATE PROCEDURE sp_get_cheapest_delivery (
  IN p_dish_id BIGINT
)
BEGIN
  DECLARE v_r_id BIGINT;

  -- Get the restaurant ID for the given dish
  SELECT r_id INTO v_r_id
  FROM dishes
  WHERE dish_id = p_dish_id
  LIMIT 1;

  -- If no restaurant found, return an empty result
  IF v_r_id IS NULL THEN
    SELECT 
      NULL AS platform_id,
      NULL AS platform_name,
      NULL AS delivery_fee,
      NULL AS platform_url;
  ELSE
    -- Return the cheapest delivery option for that restaurant
    SELECT
      rp.platform_id,
      p.name AS platform_name,
      rp.delivery_fee,
      rp.platform_url
    FROM restaurant_platforms rp
    JOIN platforms p ON rp.platform_id = p.platform_id
    WHERE rp.r_id = v_r_id
      AND rp.availability = TRUE
    ORDER BY rp.delivery_fee ASC
    LIMIT 1;
  END IF;
END$$

DELIMITER $$

CREATE PROCEDURE sp_get_dish_id_by_name(
  IN p_dish_name VARCHAR(100),
  OUT p_dish_id BIGINT
)
BEGIN
  SELECT dish_id
  INTO p_dish_id
  FROM dishes
  WHERE LOWER(TRIM(dish_name)) = LOWER(TRIM(p_dish_name))
  LIMIT 1;
END$$

DELIMITER $$
CREATE PROCEDURE sp_get_user_id_by_email(
  IN p_email VARCHAR(255),
  OUT p_user_id BIGINT
)
BEGIN
  SELECT user_id
  INTO p_user_id
  FROM users
  WHERE LOWER(TRIM(email)) = LOWER(TRIM(p_email))
  LIMIT 1;
END$$

DELIMITER $$


CREATE PROCEDURE sp_get_daily_macros (
    IN p_user_id BIGINT,
    IN p_date DATE,
    OUT o_total_calories FLOAT,
    OUT o_total_protein FLOAT,
    OUT o_total_carbs FLOAT,
    OUT o_total_fats FLOAT
)
BEGIN
    -- Compute totals
    SELECT 
        IFNULL(SUM(d.calories * ul.quantity), 0),
        IFNULL(SUM(d.protein_g * ul.quantity), 0),
        IFNULL(SUM(d.carbs_g * ul.quantity), 0),
        IFNULL(SUM(d.fats_g * ul.quantity), 0)
    INTO 
        o_total_calories,
        o_total_protein,
        o_total_carbs,
        o_total_fats
    FROM user_log ul
    JOIN dishes d ON ul.dish_id = d.dish_id
    WHERE ul.user_id = p_user_id
      AND ul.log_date = p_date;
END$$



DELIMITER ;
