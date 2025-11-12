USE calories;
DROP TRIGGER IF EXISTS tr_show_remaining_calories;
DELIMITER $$

CREATE TRIGGER tr_show_remaining_calories
AFTER INSERT ON user_log
FOR EACH ROW
BEGIN
  DECLARE v_target INT;
  DECLARE v_consumed FLOAT;
  DECLARE v_remaining FLOAT;

  -- Get user's daily calorie target
  SELECT calorie_target INTO v_target
  FROM users
  WHERE user_id = NEW.user_id;

  -- Sum calories logged for that user on that date
  SELECT SUM(total_calories) INTO v_consumed
  FROM user_log
  WHERE user_id = NEW.user_id AND log_date = NEW.log_date;

  -- Calculate remaining
  SET v_remaining = v_target - v_consumed;

  -- Show result
  SELECT CONCAT('Remaining calories for ', NEW.log_date, ': ', ROUND(v_remaining, 2)) AS remaining_calories;
END$$

DELIMITER ;
