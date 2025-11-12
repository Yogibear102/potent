
use calories;
DROP VIEW IF EXISTS v_daily_user_summary;
CREATE OR REPLACE VIEW v_daily_user_summary AS
SELECT
  ul.user_id,
  u.name,
  ul.log_date,
  u.calorie_target,
  SUM(ul.total_calories) AS calories_consumed,
  SUM(d.price * ul.quantity) AS total_price,
  SUM(d.protein_g * ul.quantity) AS total_protein_g,
  SUM(d.carbs_g * ul.quantity) AS total_carbs_g,
  SUM(d.fats_g * ul.quantity) AS total_fats_g,
  u.calorie_target - SUM(ul.total_calories) AS calories_remaining
FROM user_log ul
JOIN users u ON ul.user_id = u.user_id
JOIN dishes d ON ul.dish_id = d.dish_id
GROUP BY ul.user_id, ul.log_date;
