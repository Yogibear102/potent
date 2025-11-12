USE calories;
DROP TABLE IF EXISTS user_log;
DROP TABLE IF EXISTS recommendation;
DROP TABLE IF EXISTS dishes;
DROP TABLE IF EXISTS restaurant_platforms;
DROP TABLE IF EXISTS platforms;
DROP TABLE IF EXISTS restaurants;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
  user_id BIGINT PRIMARY KEY,
  name VARCHAR(100),
  email VARCHAR(100),
  calorie_target INT,
  latitude DECIMAL(9,6),
  longitude DECIMAL(9,6)
);


CREATE TABLE restaurants (
  r_id BIGINT PRIMARY KEY,
  name VARCHAR(100),
  latitude DECIMAL(9,6),
  longitude DECIMAL(9,6),
  rating FLOAT
);


CREATE TABLE platforms (
  platform_id BIGINT PRIMARY KEY,
  name VARCHAR(100),
  url VARCHAR(255),
  logo_url VARCHAR(255)
);


CREATE TABLE restaurant_platforms (
  r_id BIGINT,
  platform_id BIGINT,
  platform_url VARCHAR(255),     -- optional: deep link to restaurant on platform
  delivery_fee INT,              -- optional: platform-specific delivery fee
  availability BOOLEAN DEFAULT TRUE, -- optional: is restaurant currently listed
  PRIMARY KEY (r_id, platform_id),
  FOREIGN KEY (r_id) REFERENCES restaurants(r_id),
  FOREIGN KEY (platform_id) REFERENCES platforms(platform_id)
);

CREATE TABLE dishes (
  dish_id BIGINT PRIMARY KEY,
  dish_name VARCHAR(100),
  calories INT,
  protein_g FLOAT,
  carbs_g FLOAT,
  fats_g FLOAT,
  price INT,
  r_id BIGINT,
  savory FLOAT, salty FLOAT, sweet FLOAT, crunchy FLOAT, nutty FLOAT,
  chocolatey FLOAT, fried FLOAT, crispy FLOAT, hot FLOAT, cold FLOAT,
  buttery FLOAT, rich FLOAT, creamy FLOAT, spicy FLOAT, meaty FLOAT, juicy FLOAT,
  FOREIGN KEY (r_id) REFERENCES restaurants(r_id)
);

CREATE TABLE recommendation (
  rec_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  dish_id_original BIGINT,
  r_id_original BIGINT,
  dish_id_alt BIGINT,
  r_id_alt BIGINT,
  taste_score FLOAT,
  alt_price INT,
  alt_calories INT,
  calorie_diff INT,
  FOREIGN KEY (dish_id_original) REFERENCES dishes(dish_id),
  FOREIGN KEY (dish_id_alt) REFERENCES dishes(dish_id),
  FOREIGN KEY (r_id_original) REFERENCES restaurants(r_id),
  FOREIGN KEY (r_id_alt) REFERENCES restaurants(r_id)
);

CREATE TABLE user_log (
  log_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT,
  dish_id BIGINT,
  r_id BIGINT,
  log_date DATE,
  quantity FLOAT,
  total_calories FLOAT,
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  FOREIGN KEY (dish_id) REFERENCES dishes(dish_id),
  FOREIGN KEY (r_id) REFERENCES restaurants(r_id)
);

