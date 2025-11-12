
use calories;
DROP FUNCTION IF EXISTS fn_distance_km;
DROP FUNCTION IF EXISTS fn_cosine_similarity_user_dish;
DROP FUNCTION IF EXISTS fn_calc_total_calories;


DELIMITER $$

CREATE FUNCTION fn_distance_km(
  lat1 DECIMAL(9,6),
  lon1 DECIMAL(9,6),
  lat2 DECIMAL(9,6),
  lon2 DECIMAL(9,6)
) RETURNS FLOAT
DETERMINISTIC
BEGIN
  DECLARE R INT DEFAULT 6371;
  DECLARE dlat FLOAT;
  DECLARE dlon FLOAT;
  DECLARE a FLOAT;
  DECLARE c FLOAT;

  SET dlat = RADIANS(lat2 - lat1);
  SET dlon = RADIANS(lon2 - lon1);

  SET a = SIN(dlat/2) * SIN(dlat/2) +
          COS(RADIANS(lat1)) * COS(RADIANS(lat2)) *
          SIN(dlon/2) * SIN(dlon/2);

  SET c = 2 * ATAN2(SQRT(a), SQRT(1 - a));

  RETURN ROUND(R * c, 2);
END$$

DELIMITER $$

CREATE FUNCTION fn_calc_total_calories(
  p_dish_id BIGINT,
  p_quantity FLOAT
) RETURNS FLOAT
DETERMINISTIC
BEGIN
  DECLARE base_cals FLOAT;

  SELECT calories INTO base_cals
  FROM dishes
  WHERE dish_id = p_dish_id;

  RETURN ROUND(base_cals * p_quantity, 2);
END$$

DELIMITER $$

CREATE FUNCTION fn_cosine_similarity_user_dish (
  d_id_source BIGINT,
  d_id_target BIGINT
) RETURNS FLOAT
DETERMINISTIC
BEGIN
  DECLARE score FLOAT;

  SELECT
    (
      (src.savory * tgt.savory) + (src.salty * tgt.salty) + (src.sweet * tgt.sweet) +
      (src.crunchy * tgt.crunchy) + (src.nutty * tgt.nutty) + (src.chocolatey * tgt.chocolatey) +
      (src.fried * tgt.fried) + (src.crispy * tgt.crispy) + (src.hot * tgt.hot) +
      (src.cold * tgt.cold) + (src.buttery * tgt.buttery) + (src.rich * tgt.rich) +
      (src.creamy * tgt.creamy) + (src.spicy * tgt.spicy) + (src.meaty * tgt.meaty) +
      (src.juicy * tgt.juicy)
    )
    /
    (
      SQRT(
        POW(src.savory,2) + POW(src.salty,2) + POW(src.sweet,2) + POW(src.crunchy,2) +
        POW(src.nutty,2) + POW(src.chocolatey,2) + POW(src.fried,2) + POW(src.crispy,2) +
        POW(src.hot,2) + POW(src.cold,2) + POW(src.buttery,2) + POW(src.rich,2) +
        POW(src.creamy,2) + POW(src.spicy,2) + POW(src.meaty,2) + POW(src.juicy,2)
      )
      *
      SQRT(
        POW(tgt.savory,2) + POW(tgt.salty,2) + POW(tgt.sweet,2) + POW(tgt.crunchy,2) +
        POW(tgt.nutty,2) + POW(tgt.chocolatey,2) + POW(tgt.fried,2) + POW(tgt.crispy,2) +
        POW(tgt.hot,2) + POW(tgt.cold,2) + POW(tgt.buttery,2) + POW(tgt.rich,2) +
        POW(tgt.creamy,2) + POW(tgt.spicy,2) + POW(tgt.meaty,2) + POW(tgt.juicy,2)
      )
    )
  INTO score
  FROM
    (SELECT * FROM dishes WHERE dish_id = d_id_source) AS src,
    (SELECT * FROM dishes WHERE dish_id = d_id_target) AS tgt;

  RETURN ROUND(score, 4);
END$$
DELIMITER ;

