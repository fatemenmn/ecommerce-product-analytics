-- ============================================================
-- 00 — Olist schema definition (MySQL 8.0+)
--
-- This is the source of truth for `python/load_mysql.py --create`: the loader
-- reads this file, skips the CREATE DATABASE / USE statements, and executes the
-- remaining statements against the database given by --database (default:
-- olist). Each table uses IF NOT EXISTS, so re-running is safe.
--
-- The DDL mirrors the validated local tables (captured with SHOW CREATE TABLE
-- from the imported schema): table names, column names, data types, primary
-- keys, indexes and engine are identical, and the order matches the loader's
-- load order in python/load_mysql.py (TABLES).
--
-- Two source quirks are preserved deliberately:
--   * product_name_lenght / product_description_lenght keep the vendor's
--     spelling so CSV columns map 1:1 to table columns.
--   * Zip prefixes are CHAR(5), not INT, so leading zeros survive.
--
-- Foreign keys are not declared: the raw dataset has a few orphan rows and the
-- analytical loads are validated with plain indexes instead.
-- ============================================================

CREATE DATABASE IF NOT EXISTS olist
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;

USE olist;

-- 1. customers — one row per order-level customer key
CREATE TABLE IF NOT EXISTS `customers` (
  `customer_id` char(32) NOT NULL,
  `customer_unique_id` char(32) NOT NULL,
  `customer_zip_code_prefix` char(5) DEFAULT NULL,
  `customer_city` varchar(64) DEFAULT NULL,
  `customer_state` char(2) DEFAULT NULL,
  PRIMARY KEY (`customer_id`),
  KEY `idx_customers_unique_id` (`customer_unique_id`),
  KEY `idx_customers_state` (`customer_state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2. orders — order lifecycle timestamps
CREATE TABLE IF NOT EXISTS `orders` (
  `order_id` char(32) NOT NULL,
  `customer_id` char(32) NOT NULL,
  `order_status` varchar(20) DEFAULT NULL,
  `order_purchase_timestamp` datetime DEFAULT NULL,
  `order_approved_at` datetime DEFAULT NULL,
  `order_delivered_carrier_date` datetime DEFAULT NULL,
  `order_delivered_customer_date` datetime DEFAULT NULL,
  `order_estimated_delivery_date` datetime DEFAULT NULL,
  PRIMARY KEY (`order_id`),
  KEY `idx_orders_customer` (`customer_id`),
  KEY `idx_orders_status` (`order_status`),
  KEY `idx_orders_purchase` (`order_purchase_timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 3. order_items — one row per item line in an order
CREATE TABLE IF NOT EXISTS `order_items` (
  `order_id` char(32) NOT NULL,
  `order_item_id` int NOT NULL,
  `product_id` char(32) DEFAULT NULL,
  `seller_id` char(32) DEFAULT NULL,
  `shipping_limit_date` datetime DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `freight_value` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`order_id`,`order_item_id`),
  KEY `idx_items_product` (`product_id`),
  KEY `idx_items_seller` (`seller_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 4. order_payments — one row per payment method/sequence
CREATE TABLE IF NOT EXISTS `order_payments` (
  `order_id` char(32) NOT NULL,
  `payment_sequential` int NOT NULL,
  `payment_type` varchar(20) DEFAULT NULL,
  `payment_installments` int DEFAULT NULL,
  `payment_value` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`order_id`,`payment_sequential`),
  KEY `idx_payments_type` (`payment_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 5. order_reviews — review rows; review_id is NOT unique in the source data,
--    so no primary key is declared
CREATE TABLE IF NOT EXISTS `order_reviews` (
  `review_id` char(32) NOT NULL,
  `order_id` char(32) NOT NULL,
  `review_score` tinyint DEFAULT NULL,
  `review_comment_title` varchar(255) DEFAULT NULL,
  `review_comment_message` text,
  `review_creation_date` datetime DEFAULT NULL,
  `review_answer_timestamp` datetime DEFAULT NULL,
  KEY `idx_reviews_review` (`review_id`),
  KEY `idx_reviews_order` (`order_id`),
  KEY `idx_reviews_score` (`review_score`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 6. products — product attributes and source category name
CREATE TABLE IF NOT EXISTS `products` (
  `product_id` char(32) NOT NULL,
  `product_category_name` varchar(64) DEFAULT NULL,
  `product_name_lenght` int DEFAULT NULL,
  `product_description_lenght` int DEFAULT NULL,
  `product_photos_qty` int DEFAULT NULL,
  `product_weight_g` int DEFAULT NULL,
  `product_length_cm` int DEFAULT NULL,
  `product_height_cm` int DEFAULT NULL,
  `product_width_cm` int DEFAULT NULL,
  PRIMARY KEY (`product_id`),
  KEY `idx_products_category` (`product_category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 7. sellers — seller location
CREATE TABLE IF NOT EXISTS `sellers` (
  `seller_id` char(32) NOT NULL,
  `seller_zip_code_prefix` char(5) DEFAULT NULL,
  `seller_city` varchar(64) DEFAULT NULL,
  `seller_state` char(2) DEFAULT NULL,
  PRIMARY KEY (`seller_id`),
  KEY `idx_sellers_state` (`seller_state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 8. geolocation — postal prefix coordinates (~1M rows, no natural key)
CREATE TABLE IF NOT EXISTS `geolocation` (
  `geolocation_zip_code_prefix` char(5) DEFAULT NULL,
  `geolocation_lat` double DEFAULT NULL,
  `geolocation_lng` double DEFAULT NULL,
  `geolocation_city` varchar(64) DEFAULT NULL,
  `geolocation_state` char(2) DEFAULT NULL,
  KEY `idx_geo_zip` (`geolocation_zip_code_prefix`),
  KEY `idx_geo_state` (`geolocation_state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 9. product_category_name_translation — Portuguese to English category names
CREATE TABLE IF NOT EXISTS `product_category_name_translation` (
  `product_category_name` varchar(64) NOT NULL,
  `product_category_name_english` varchar(64) NOT NULL,
  PRIMARY KEY (`product_category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
