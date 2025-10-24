CREATE DATABASE IF NOT EXISTS calorie_reco CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE calorie_reco;

-- USERS (calorie_target moved here)
CREATE TABLE users (
  user_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  latitude DECIMAL(9,6) NOT NULL,
  longitude DECIMAL(9,6) NOT NULL,
  age INT,

  height_cm DECIMAL(5,2),
  weight_kg DECIMAL(6,2),
  calorie_target INT NOT NULL,  -- daily target
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE restaurants (
  r_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(200) NOT NULL,
  latitude DECIMAL(9,6) NOT NULL,
  longitude DECIMAL(9,6) NOT NULL,
  contact VARCHAR(120),
  rating DECIMAL(3,2),
  cuisine_type VARCHAR(120),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


DROP TABLE IF EXISTS dishes;

CREATE TABLE dishes (
  dish_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  r_id BIGINT UNSIGNED NOT NULL,
  dish_name VARCHAR(200) NOT NULL,
  calories INT NOT NULL,
  protein_g DECIMAL(6,2) NOT NULL,
  carbs_g DECIMAL(6,2) NOT NULL,
  fats_g DECIMAL(6,2) NOT NULL,
  price DECIMAL(10,2) NOT NULL,

  -- Taste vector fields for recommendation logic
  savoury FLOAT DEFAULT 0,
  salty FLOAT DEFAULT 0,
  sweet FLOAT DEFAULT 0,
  crunchy FLOAT DEFAULT 0,
  nutty FLOAT DEFAULT 0,
  chocolatey FLOAT DEFAULT 0,
  fried FLOAT DEFAULT 0,
  crispy FLOAT DEFAULT 0,
  hot FLOAT DEFAULT 0,
  cold FLOAT DEFAULT 0,
  buttery FLOAT DEFAULT 0,
  rich FLOAT DEFAULT 0,
  creamy FLOAT DEFAULT 0,
  spicy FLOAT DEFAULT 0,
  meaty FLOAT DEFAULT 0,
  juicy FLOAT DEFAULT 0,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_dishes_rid (r_id),
  INDEX idx_dishes_name (dish_name),
  FULLTEXT INDEX ft_dish_name (dish_name),
  CONSTRAINT fk_dishes_restaurant FOREIGN KEY (r_id) REFERENCES restaurants (r_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;


-- USER LOG (daily diary)
CREATE TABLE user_log (
  log_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  dish_id BIGINT UNSIGNED NOT NULL,
  r_id BIGINT UNSIGNED NOT NULL,
  log_date DATE NOT NULL,
  quantity DECIMAL(6,2) NOT NULL DEFAULT 1.0,
  total_calories INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_log_user_date (user_id, log_date),
  INDEX idx_log_dish (dish_id),
  INDEX idx_log_rest (r_id),
  CONSTRAINT fk_log_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_log_dish FOREIGN KEY (dish_id) REFERENCES dishes(dish_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_log_rest FOREIGN KEY (r_id) REFERENCES restaurants(r_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE recommendation (
  rec_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,

  -- Source and target dishes
  dish_name_original BIGINT UNSIGNED NOT NULL,
  dish_name_alt BIGINT UNSIGNED NOT NULL,

  -- Optional personalization
  user_id BIGINT UNSIGNED DEFAULT NULL,

  -- Why this dish was recommended
  reason VARCHAR(255),
  taste_score FLOAT DEFAULT NULL,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  -- Indexes for fast lookup
  INDEX idx_reco_original (dish_name_original),
  INDEX idx_reco_alt (dish_name_alt),
  INDEX idx_reco_user (user_id),

  -- Foreign keys
  CONSTRAINT fk_reco_orig FOREIGN KEY (dish_name_original) REFERENCES dishes(dish_name)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_reco_alt FOREIGN KEY (dish_name_alt) REFERENCES dishes(dish_name)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_reco_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ORDERS (internal orders removed; we use platform orders instead)
-- EXTERNAL ORDERING PLATFORMS
CREATE TABLE ordering_platforms (
  platform_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  website_url VARCHAR(255) NOT NULL,
  contact VARCHAR(120)
) ENGINE=InnoDB;

-- PLATFORM OFFERS (dish price per platform)
CREATE TABLE platform_offers (
  offer_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  dish_id BIGINT UNSIGNED NOT NULL,
  platform_id BIGINT UNSIGNED NOT NULL,
  listed_price DECIMAL(10,2) NOT NULL,
  last_checked TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_offer_dish (dish_id),
  INDEX idx_offer_platform (platform_id),
  CONSTRAINT fk_offer_dish FOREIGN KEY (dish_id) REFERENCES dishes(dish_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_offer_platform FOREIGN KEY (platform_id) REFERENCES ordering_platforms(platform_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- PLATFORM ORDERS (intent to order via external platform)
CREATE TABLE platform_orders (
  platform_order_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  dish_id BIGINT UNSIGNED NOT NULL,
  platform_id BIGINT UNSIGNED NOT NULL,
  order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status ENUM('PLACED','CANCELLED') DEFAULT 'PLACED',
  INDEX idx_platform_order_user (user_id),
  INDEX idx_platform_order_dish (dish_id),
  INDEX idx_platform_order_platform (platform_id),
  CONSTRAINT fk_platform_order_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_platform_order_dish FOREIGN KEY (dish_id) REFERENCES dishes(dish_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_platform_order_platform FOREIGN KEY (platform_id) REFERENCES ordering_platforms(platform_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- GOAL ALERTS (exceeded daily intake warnings)
CREATE TABLE goal_alerts (
  alert_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  log_date DATE NOT NULL,
  total_intake INT NOT NULL,
  calorie_target INT NOT NULL,
  message VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_alert_user_date (user_id, log_date),
  CONSTRAINT fk_alert_user FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE meal_insights (
  insight_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT,
  log_date DATE,
  meal_label VARCHAR(20),
  actual_calories INT,
  expected_calories INT,
  deviation INT,
  message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
