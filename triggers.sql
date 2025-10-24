USE calorie_reco;
DELIMITER $$

-- ✅ Trigger: Generate recommendations after logging a dish
DROP TRIGGER IF EXISTS tr_generate_recommendation_on_log$$
CREATE TRIGGER tr_generate_recommendation_on_log
AFTER INSERT ON user_log
FOR EACH ROW
BEGIN
  DECLARE has_reco INT DEFAULT 0;
  DECLARE u_lat DECIMAL(9,6);
  DECLARE u_lon DECIMAL(9,6);

  SELECT COUNT(*) INTO has_reco
  FROM recommendation
  WHERE dish_id_original = NEW.dish_id;

  SELECT latitude, longitude INTO u_lat, u_lon
  FROM users WHERE user_id = NEW.user_id;

  IF has_reco = 0 THEN
    INSERT INTO recommendation (dish_id_original, dish_id_alt, reason, taste_score)
    SELECT
      NEW.dish_id,
      d2.dish_id,
      CONCAT('Auto-suggested: ', d2.dish_name),
      fn_cosine_similarity_user_dish(
        d1.taste_savoury, d1.taste_salty, d1.taste_sweet, d1.taste_crunchy,
        d1.taste_nutty, d1.taste_chocolatey, d1.taste_fried, d1.taste_crispy,
        d1.taste_hot, d1.taste_cold, d1.taste_buttery, d1.taste_rich,
        d1.taste_creamy, d1.taste_spicy, d1.taste_meaty, d1.taste_juicy,
        d2.dish_id
      )
    FROM dishes d1
    JOIN dishes d2 ON d1.dish_id <> d2.dish_id
    JOIN restaurants r ON r.r_id = d2.r_id
    WHERE d1.dish_id = NEW.dish_id
      AND d2.calories < d1.calories
      AND fn_distance_km(u_lat, u_lon, r.latitude, r.longitude) <= 5.0
    ORDER BY d2.calories ASC
    LIMIT 5;
  END IF;
END$$

-- ✅ Trigger: Alert if user exceeds daily calorie target
DROP TRIGGER IF EXISTS trg_user_log_ai$$
CREATE TRIGGER trg_user_log_ai
AFTER INSERT ON user_log
FOR EACH ROW
BEGIN
  DECLARE daily_total INT;
  DECLARE target INT;

  SELECT COALESCE(SUM(total_calories),0)
    INTO daily_total
    FROM user_log
   WHERE user_id = NEW.user_id
     AND log_date = NEW.log_date;

  SELECT calorie_target INTO target FROM users WHERE user_id = NEW.user_id;

  IF target IS NOT NULL AND daily_total > target THEN
    INSERT INTO goal_alerts (user_id, log_date, total_intake, calorie_target, message)
    VALUES (NEW.user_id, NEW.log_date, daily_total, target,
            CONCAT('Daily intake ', daily_total, ' exceeds target ', target));
  END IF;
END$$

-- ✅ Trigger: Auto-log dish from platform order
DROP TRIGGER IF EXISTS trg_platform_order_ai$$
CREATE TRIGGER trg_platform_order_ai
AFTER INSERT ON platform_orders
FOR EACH ROW
BEGIN
  DECLARE rid BIGINT UNSIGNED;
  SELECT r_id INTO rid FROM dishes WHERE dish_id = NEW.dish_id;
  INSERT INTO user_log (user_id, dish_id, r_id, log_date, quantity, total_calories)
  VALUES (NEW.user_id, NEW.dish_id, rid, CURDATE(), 1.0, 0);
END$$

-- ✅ Trigger: Check log count and trigger summary
DROP TRIGGER IF EXISTS trg_user_log_ai_check_count$$
CREATE TRIGGER trg_user_log_ai_check_count
AFTER INSERT ON user_log
FOR EACH ROW
BEGIN
  CALL sp_check_meal_log_count(NEW.user_id, NEW.log_date);
END$$

DELIMITER ;
