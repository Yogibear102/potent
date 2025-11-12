USE CALORIES;
INSERT INTO platforms VALUES
(1, 'Swiggy', 'https://www.swiggy.com', 'https://example.com/logos/swiggy.png'),
(2, 'Zomato', 'https://www.zomato.com', 'https://www.zomato.com/images/logo.png');

INSERT INTO restaurant_platforms  VALUES
-- Chinese Wok
(1, 1, 'https://www.swiggy.com/restaurants/chinese-wok', 29, TRUE),
(1, 2, 'https://www.zomato.com/bangalore/chinese-wok', 25, TRUE),

-- Pizza Hut
(2, 1, 'https://www.swiggy.com/restaurants/pizza-hut', 35, TRUE),
(2, 2, 'https://www.zomato.com/bangalore/pizza-hut', 30, TRUE),

-- KFC
(3, 1, 'https://www.swiggy.com/restaurants/kfc', 39, TRUE),
(3, 2, 'https://www.zomato.com/bangalore/kfc', 34, TRUE),

-- Burger King
(4, 1, 'https://www.swiggy.com/restaurants/burger-king', 33, TRUE),
(4, 2, 'https://www.zomato.com/bangalore/burger-king', 28, TRUE),

-- Wendys
(5, 1, 'https://www.swiggy.com/restaurants/wendys', 31, TRUE),
(5, 2, 'https://www.zomato.com/bangalore/wendys', 27, TRUE),

-- Dominos
(6, 1, 'https://www.swiggy.com/restaurants/dominos', 36, TRUE),
(6, 2, 'https://www.zomato.com/bangalore/dominos', 32, TRUE),

-- McDonalds
(7, 1, 'https://www.swiggy.com/restaurants/mcdonalds', 34, TRUE),
(7, 2, 'https://www.zomato.com/bangalore/mcdonalds', 29, TRUE),

-- Theobroma
(8, 1, 'https://www.swiggy.com/restaurants/theobroma', 28, TRUE),
(8, 2, 'https://www.zomato.com/bangalore/theobroma', 24, TRUE),

-- Subway
(9, 1, 'https://www.swiggy.com/restaurants/subway', 27, TRUE),
(9, 2, 'https://www.zomato.com/bangalore/subway', 23, TRUE),

-- Starbucks
(10, 1, 'https://www.swiggy.com/restaurants/starbucks', 32, TRUE),
(10, 2, 'https://www.zomato.com/bangalore/starbucks', 26, TRUE),

-- Third Wave Coffee
(11, 1, 'https://www.swiggy.com/restaurants/third-wave-coffee', 30, TRUE),
(11, 2, 'https://www.zomato.com/bangalore/third-wave-coffee', 25, TRUE),

-- Taco Bell
(12, 1, 'https://www.swiggy.com/restaurants/taco-bell', 35, TRUE),
(12, 2, 'https://www.zomato.com/bangalore/taco-bell', 31, TRUE);