-- Olist Brazilian E-Commerce | Data validation and exploration
-- Run on the MySQL connection containing the olist schema.
-- Statements return metadata or aggregate results and make no database changes.
-- Run in order. Compare the row counts with the source CSVs to validate import completeness.

-- 01. Identify the active database and list tables in the project schema.
SELECT DATABASE() AS current_database;
SHOW TABLES FROM olist;

-- 02. Inspect imported column types and declared nullability.
SELECT table_name,
       ordinal_position AS column_position,
       column_name,
       column_type,
       is_nullable,
       column_key
FROM information_schema.columns
WHERE table_schema = 'olist'
ORDER BY table_name, ordinal_position;

-- Discover declared primary, unique and foreign keys, including composite key order.
-- Observed relationships are checked separately below.
SELECT tc.table_name,
       tc.constraint_name,
       tc.constraint_type,
       kcu.ordinal_position AS key_position,
       kcu.column_name,
       kcu.referenced_table_name,
       kcu.referenced_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON kcu.constraint_schema = tc.constraint_schema
    AND kcu.table_schema = tc.table_schema
    AND kcu.table_name = tc.table_name
    AND kcu.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'olist'
    AND tc.constraint_type IN ('PRIMARY KEY', 'UNIQUE', 'FOREIGN KEY')
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name, kcu.ordinal_position;

-- 03. Count imported rows by table.
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM olist.customers
UNION ALL
SELECT 'geolocation' AS table_name, COUNT(*) AS row_count FROM olist.geolocation
UNION ALL
SELECT 'order_items' AS table_name, COUNT(*) AS row_count FROM olist.order_items
UNION ALL
SELECT 'order_payments' AS table_name, COUNT(*) AS row_count FROM olist.order_payments
UNION ALL
SELECT 'order_reviews' AS table_name, COUNT(*) AS row_count FROM olist.order_reviews
UNION ALL
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM olist.orders
UNION ALL
SELECT 'product_category_name_translation' AS table_name, COUNT(*) AS row_count FROM olist.product_category_name_translation
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM olist.products
UNION ALL
SELECT 'sellers' AS table_name, COUNT(*) AS row_count FROM olist.sellers
ORDER BY table_name;

-- 04. Count SQL NULL values by column.
SELECT 'customers' AS table_name, 'customer_id' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(customer_id) AS null_count
FROM olist.customers
UNION ALL
SELECT 'customers' AS table_name, 'customer_unique_id' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(customer_unique_id) AS null_count
FROM olist.customers
UNION ALL
SELECT 'customers' AS table_name, 'customer_zip_code_prefix' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(customer_zip_code_prefix) AS null_count
FROM olist.customers
UNION ALL
SELECT 'customers' AS table_name, 'customer_city' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(customer_city) AS null_count
FROM olist.customers
UNION ALL
SELECT 'customers' AS table_name, 'customer_state' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(customer_state) AS null_count
FROM olist.customers
UNION ALL
SELECT 'geolocation' AS table_name, 'geolocation_zip_code_prefix' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(geolocation_zip_code_prefix) AS null_count
FROM olist.geolocation
UNION ALL
SELECT 'geolocation' AS table_name, 'geolocation_lat' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(geolocation_lat) AS null_count
FROM olist.geolocation
UNION ALL
SELECT 'geolocation' AS table_name, 'geolocation_lng' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(geolocation_lng) AS null_count
FROM olist.geolocation
UNION ALL
SELECT 'geolocation' AS table_name, 'geolocation_city' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(geolocation_city) AS null_count
FROM olist.geolocation
UNION ALL
SELECT 'geolocation' AS table_name, 'geolocation_state' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(geolocation_state) AS null_count
FROM olist.geolocation
UNION ALL
SELECT 'order_items' AS table_name, 'order_id' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(order_id) AS null_count
FROM olist.order_items
UNION ALL
SELECT 'order_items' AS table_name, 'order_item_id' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(order_item_id) AS null_count
FROM olist.order_items
UNION ALL
SELECT 'order_items' AS table_name, 'product_id' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(product_id) AS null_count
FROM olist.order_items
UNION ALL
SELECT 'order_items' AS table_name, 'seller_id' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(seller_id) AS null_count
FROM olist.order_items
UNION ALL
SELECT 'order_items' AS table_name, 'shipping_limit_date' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(shipping_limit_date) AS null_count
FROM olist.order_items
UNION ALL
SELECT 'order_items' AS table_name, 'price' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(price) AS null_count
FROM olist.order_items
UNION ALL
SELECT 'order_items' AS table_name, 'freight_value' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(freight_value) AS null_count
FROM olist.order_items
UNION ALL
SELECT 'order_payments' AS table_name, 'order_id' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(order_id) AS null_count
FROM olist.order_payments
UNION ALL
SELECT 'order_payments' AS table_name, 'payment_sequential' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(payment_sequential) AS null_count
FROM olist.order_payments
UNION ALL
SELECT 'order_payments' AS table_name, 'payment_type' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(payment_type) AS null_count
FROM olist.order_payments
UNION ALL
SELECT 'order_payments' AS table_name, 'payment_installments' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(payment_installments) AS null_count
FROM olist.order_payments
UNION ALL
SELECT 'order_payments' AS table_name, 'payment_value' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(payment_value) AS null_count
FROM olist.order_payments
UNION ALL
SELECT 'order_reviews' AS table_name, 'review_id' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(review_id) AS null_count
FROM olist.order_reviews
UNION ALL
SELECT 'order_reviews' AS table_name, 'order_id' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(order_id) AS null_count
FROM olist.order_reviews
UNION ALL
SELECT 'order_reviews' AS table_name, 'review_score' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(review_score) AS null_count
FROM olist.order_reviews
UNION ALL
SELECT 'order_reviews' AS table_name, 'review_comment_title' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(review_comment_title) AS null_count
FROM olist.order_reviews
UNION ALL
SELECT 'order_reviews' AS table_name, 'review_comment_message' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(review_comment_message) AS null_count
FROM olist.order_reviews
UNION ALL
SELECT 'order_reviews' AS table_name, 'review_creation_date' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(review_creation_date) AS null_count
FROM olist.order_reviews
UNION ALL
SELECT 'order_reviews' AS table_name, 'review_answer_timestamp' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(review_answer_timestamp) AS null_count
FROM olist.order_reviews
UNION ALL
SELECT 'orders' AS table_name, 'order_id' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(order_id) AS null_count
FROM olist.orders
UNION ALL
SELECT 'orders' AS table_name, 'customer_id' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(customer_id) AS null_count
FROM olist.orders
UNION ALL
SELECT 'orders' AS table_name, 'order_status' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(order_status) AS null_count
FROM olist.orders
UNION ALL
SELECT 'orders' AS table_name, 'order_purchase_timestamp' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(order_purchase_timestamp) AS null_count
FROM olist.orders
UNION ALL
SELECT 'orders' AS table_name, 'order_approved_at' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(order_approved_at) AS null_count
FROM olist.orders
UNION ALL
SELECT 'orders' AS table_name, 'order_delivered_carrier_date' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(order_delivered_carrier_date) AS null_count
FROM olist.orders
UNION ALL
SELECT 'orders' AS table_name, 'order_delivered_customer_date' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(order_delivered_customer_date) AS null_count
FROM olist.orders
UNION ALL
SELECT 'orders' AS table_name, 'order_estimated_delivery_date' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(order_estimated_delivery_date) AS null_count
FROM olist.orders
UNION ALL
SELECT 'product_category_name_translation' AS table_name, 'product_category_name' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(product_category_name) AS null_count
FROM olist.product_category_name_translation
UNION ALL
SELECT 'product_category_name_translation' AS table_name, 'product_category_name_english' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(product_category_name_english) AS null_count
FROM olist.product_category_name_translation
UNION ALL
SELECT 'products' AS table_name, 'product_id' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(product_id) AS null_count
FROM olist.products
UNION ALL
SELECT 'products' AS table_name, 'product_category_name' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(product_category_name) AS null_count
FROM olist.products
UNION ALL
SELECT 'products' AS table_name, 'product_name_lenght' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(product_name_lenght) AS null_count
FROM olist.products
UNION ALL
SELECT 'products' AS table_name, 'product_description_lenght' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(product_description_lenght) AS null_count
FROM olist.products
UNION ALL
SELECT 'products' AS table_name, 'product_photos_qty' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(product_photos_qty) AS null_count
FROM olist.products
UNION ALL
SELECT 'products' AS table_name, 'product_weight_g' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(product_weight_g) AS null_count
FROM olist.products
UNION ALL
SELECT 'products' AS table_name, 'product_length_cm' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(product_length_cm) AS null_count
FROM olist.products
UNION ALL
SELECT 'products' AS table_name, 'product_height_cm' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(product_height_cm) AS null_count
FROM olist.products
UNION ALL
SELECT 'products' AS table_name, 'product_width_cm' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(product_width_cm) AS null_count
FROM olist.products
UNION ALL
SELECT 'sellers' AS table_name, 'seller_id' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(seller_id) AS null_count
FROM olist.sellers
UNION ALL
SELECT 'sellers' AS table_name, 'seller_zip_code_prefix' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(seller_zip_code_prefix) AS null_count
FROM olist.sellers
UNION ALL
SELECT 'sellers' AS table_name, 'seller_city' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(seller_city) AS null_count
FROM olist.sellers
UNION ALL
SELECT 'sellers' AS table_name, 'seller_state' AS column_name,
       COUNT(*) AS rows_checked, COUNT(*) - COUNT(seller_state) AS null_count
FROM olist.sellers
ORDER BY table_name, column_name;

-- Check delivery-date completeness independently for each order status.
SELECT order_status,
       COUNT(*) AS rows_checked,
       COUNT(*) - COUNT(order_delivered_customer_date) AS missing_delivery_dates,
       COUNT(order_delivered_customer_date) AS present_delivery_dates
FROM olist.orders
GROUP BY order_status
ORDER BY order_status;

-- 05. Profile repeated review IDs and orders with multiple review rows.
-- Review ID repetition is a group count and is insufficient to identify exact duplicates.
SELECT 'review_ids_with_multiple_rows' AS check_name,
       COUNT(*) AS group_count
FROM (
    SELECT review_id
    FROM olist.order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
) AS repeated_review_ids
UNION ALL
SELECT 'order_ids_with_multiple_review_rows', COUNT(*)
FROM (
    SELECT order_id
    FROM olist.order_reviews
    WHERE order_id IS NOT NULL
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS orders_with_multiple_review_rows
UNION ALL
SELECT 'order_ids_with_different_review_scores', COUNT(*)
FROM (
    SELECT order_id
    FROM olist.order_reviews
    WHERE order_id IS NOT NULL
    GROUP BY order_id
    HAVING COUNT(DISTINCT review_score) > 1
) AS orders_with_different_review_scores;

-- A customer ID identifies a customer row. Use customer_unique_id for buyer identity.
SELECT COUNT(*) AS customer_rows,
       COUNT(DISTINCT customer_unique_id) AS distinct_buyers
FROM olist.customers;

-- 06. Check date coverage and delivery before purchase.
SELECT MIN(order_purchase_timestamp) AS first_purchase,
       MAX(order_purchase_timestamp) AS last_purchase,
       MIN(order_delivered_customer_date) AS first_delivery,
       MAX(order_delivered_customer_date) AS last_delivery,
       COUNT(CASE WHEN order_delivered_customer_date < order_purchase_timestamp
                  THEN 1 END) AS delivered_before_purchase
FROM olist.orders;

-- 07. Check numeric coverage and count values outside the stated bounds.
-- Zero installments are included in the range and counted separately below.
SELECT 'order_items.price' AS field_name,
       MIN(price) AS min_value, MAX(price) AS max_value,
       COUNT(*) - COUNT(price) AS null_count,
       COUNT(CASE WHEN price < 0 THEN 1 END) AS out_of_range_count
FROM olist.order_items
UNION ALL
SELECT 'order_items.freight_value' AS field_name,
       MIN(freight_value) AS min_value, MAX(freight_value) AS max_value,
       COUNT(*) - COUNT(freight_value) AS null_count,
       COUNT(CASE WHEN freight_value < 0 THEN 1 END) AS out_of_range_count
FROM olist.order_items
UNION ALL
SELECT 'order_payments.payment_value' AS field_name,
       MIN(payment_value) AS min_value, MAX(payment_value) AS max_value,
       COUNT(*) - COUNT(payment_value) AS null_count,
       COUNT(CASE WHEN payment_value < 0 THEN 1 END) AS out_of_range_count
FROM olist.order_payments
UNION ALL
SELECT 'order_payments.payment_installments' AS field_name,
       MIN(payment_installments) AS min_value, MAX(payment_installments) AS max_value,
       COUNT(*) - COUNT(payment_installments) AS null_count,
       COUNT(CASE WHEN payment_installments < 0 THEN 1 END) AS out_of_range_count
FROM olist.order_payments
UNION ALL
SELECT 'order_reviews.review_score' AS field_name,
       MIN(review_score) AS min_value, MAX(review_score) AS max_value,
       COUNT(*) - COUNT(review_score) AS null_count,
       COUNT(CASE WHEN review_score NOT BETWEEN 1 AND 5 THEN 1 END) AS out_of_range_count
FROM olist.order_reviews
UNION ALL
SELECT 'geolocation.geolocation_lat' AS field_name,
       MIN(geolocation_lat) AS min_value, MAX(geolocation_lat) AS max_value,
       COUNT(*) - COUNT(geolocation_lat) AS null_count,
       COUNT(CASE WHEN geolocation_lat NOT BETWEEN -90 AND 90 THEN 1 END) AS out_of_range_count
FROM olist.geolocation
UNION ALL
SELECT 'geolocation.geolocation_lng' AS field_name,
       MIN(geolocation_lng) AS min_value, MAX(geolocation_lng) AS max_value,
       COUNT(*) - COUNT(geolocation_lng) AS null_count,
       COUNT(CASE WHEN geolocation_lng NOT BETWEEN -180 AND 180 THEN 1 END) AS out_of_range_count
FROM olist.geolocation;

SELECT payment_type,
       COUNT(*) AS rows_with_zero_installments
FROM olist.order_payments
WHERE payment_installments = 0
GROUP BY payment_type
ORDER BY payment_type;

-- 08. Check link coverage from source rows to unique destination keys.
-- A null key and a populated key without a match are counted separately.
SELECT 'orders -> customers' AS relationship_name,
       COUNT(*) AS rows_checked,
       COUNT(*) - COUNT(child.customer_id) AS null_key_count,
       COUNT(child.customer_id) - COUNT(parent.customer_id) AS unmatched_count
FROM olist.orders AS child
LEFT JOIN olist.customers AS parent ON parent.customer_id = child.customer_id
UNION ALL
SELECT 'order_items -> orders' AS relationship_name,
       COUNT(*) AS rows_checked,
       COUNT(*) - COUNT(child.order_id) AS null_key_count,
       COUNT(child.order_id) - COUNT(parent.order_id) AS unmatched_count
FROM olist.order_items AS child
LEFT JOIN olist.orders AS parent ON parent.order_id = child.order_id
UNION ALL
SELECT 'order_items -> products' AS relationship_name,
       COUNT(*) AS rows_checked,
       COUNT(*) - COUNT(child.product_id) AS null_key_count,
       COUNT(child.product_id) - COUNT(parent.product_id) AS unmatched_count
FROM olist.order_items AS child
LEFT JOIN olist.products AS parent ON parent.product_id = child.product_id
UNION ALL
SELECT 'order_items -> sellers' AS relationship_name,
       COUNT(*) AS rows_checked,
       COUNT(*) - COUNT(child.seller_id) AS null_key_count,
       COUNT(child.seller_id) - COUNT(parent.seller_id) AS unmatched_count
FROM olist.order_items AS child
LEFT JOIN olist.sellers AS parent ON parent.seller_id = child.seller_id
UNION ALL
SELECT 'order_payments -> orders' AS relationship_name,
       COUNT(*) AS rows_checked,
       COUNT(*) - COUNT(child.order_id) AS null_key_count,
       COUNT(child.order_id) - COUNT(parent.order_id) AS unmatched_count
FROM olist.order_payments AS child
LEFT JOIN olist.orders AS parent ON parent.order_id = child.order_id
UNION ALL
SELECT 'order_reviews -> orders' AS relationship_name,
       COUNT(*) AS rows_checked,
       COUNT(*) - COUNT(child.order_id) AS null_key_count,
       COUNT(child.order_id) - COUNT(parent.order_id) AS unmatched_count
FROM olist.order_reviews AS child
LEFT JOIN olist.orders AS parent ON parent.order_id = child.order_id
UNION ALL
SELECT 'products -> product_category_name_translation' AS relationship_name,
       COUNT(*) AS rows_checked,
       COUNT(*) - COUNT(child.product_category_name) AS null_key_count,
       COUNT(child.product_category_name) - COUNT(parent.product_category_name) AS unmatched_count
FROM olist.products AS child
LEFT JOIN olist.product_category_name_translation AS parent ON parent.product_category_name = child.product_category_name;

-- 09. Observe relationship cardinality from the parent side.
-- Aggregate child rows before joining to avoid multiplying parent rows.
SELECT 'orders -> order_items' AS relationship_name,
       COUNT(*) AS parent_rows,
       COUNT(*) - COUNT(child.join_key) AS parents_with_no_match,
       COUNT(CASE WHEN child.row_count = 1 THEN 1 END) AS parents_with_one_match,
       COUNT(CASE WHEN child.row_count > 1 THEN 1 END) AS parents_with_multiple_matches,
       MAX(COALESCE(child.row_count, 0)) AS max_rows_per_parent
FROM olist.orders AS parent
LEFT JOIN (
    SELECT order_id AS join_key, COUNT(*) AS row_count
    FROM olist.order_items
    GROUP BY order_id
) AS child ON child.join_key = parent.order_id
UNION ALL
SELECT 'orders -> order_payments' AS relationship_name,
       COUNT(*) AS parent_rows,
       COUNT(*) - COUNT(child.join_key) AS parents_with_no_match,
       COUNT(CASE WHEN child.row_count = 1 THEN 1 END) AS parents_with_one_match,
       COUNT(CASE WHEN child.row_count > 1 THEN 1 END) AS parents_with_multiple_matches,
       MAX(COALESCE(child.row_count, 0)) AS max_rows_per_parent
FROM olist.orders AS parent
LEFT JOIN (
    SELECT order_id AS join_key, COUNT(*) AS row_count
    FROM olist.order_payments
    GROUP BY order_id
) AS child ON child.join_key = parent.order_id
UNION ALL
SELECT 'orders -> order_reviews' AS relationship_name,
       COUNT(*) AS parent_rows,
       COUNT(*) - COUNT(child.join_key) AS parents_with_no_match,
       COUNT(CASE WHEN child.row_count = 1 THEN 1 END) AS parents_with_one_match,
       COUNT(CASE WHEN child.row_count > 1 THEN 1 END) AS parents_with_multiple_matches,
       MAX(COALESCE(child.row_count, 0)) AS max_rows_per_parent
FROM olist.orders AS parent
LEFT JOIN (
    SELECT order_id AS join_key, COUNT(*) AS row_count
    FROM olist.order_reviews
    GROUP BY order_id
) AS child ON child.join_key = parent.order_id
UNION ALL
SELECT 'customers -> orders' AS relationship_name,
       COUNT(*) AS parent_rows,
       COUNT(*) - COUNT(child.join_key) AS parents_with_no_match,
       COUNT(CASE WHEN child.row_count = 1 THEN 1 END) AS parents_with_one_match,
       COUNT(CASE WHEN child.row_count > 1 THEN 1 END) AS parents_with_multiple_matches,
       MAX(COALESCE(child.row_count, 0)) AS max_rows_per_parent
FROM olist.customers AS parent
LEFT JOIN (
    SELECT customer_id AS join_key, COUNT(*) AS row_count
    FROM olist.orders
    GROUP BY customer_id
) AS child ON child.join_key = parent.customer_id;

-- 10. Check postal prefix repetition and matching without multiplying source rows.
-- A postal prefix can have multiple geographic records. It is an approximate location.
SELECT COUNT(*) AS distinct_non_null_prefixes,
       COUNT(CASE WHEN row_count > 1 THEN 1 END) AS prefixes_with_multiple_rows,
       MAX(row_count) AS max_rows_per_prefix
FROM (
    SELECT geolocation_zip_code_prefix, COUNT(*) AS row_count
    FROM olist.geolocation
    WHERE geolocation_zip_code_prefix IS NOT NULL
    GROUP BY geolocation_zip_code_prefix
) AS prefix_counts;

SELECT 'customers' AS source_table,
       COUNT(*) AS rows_checked,
       COUNT(*) - COUNT(src.customer_zip_code_prefix) AS null_prefix_count,
       COUNT(CASE WHEN src.customer_zip_code_prefix IS NOT NULL AND NOT EXISTS (
           SELECT 1
           FROM olist.geolocation AS g
           WHERE g.geolocation_zip_code_prefix = src.customer_zip_code_prefix
       ) THEN 1 END) AS unmatched_prefix_count
FROM olist.customers AS src
UNION ALL
SELECT 'sellers' AS source_table,
       COUNT(*) AS rows_checked,
       COUNT(*) - COUNT(src.seller_zip_code_prefix) AS null_prefix_count,
       COUNT(CASE WHEN src.seller_zip_code_prefix IS NOT NULL AND NOT EXISTS (
           SELECT 1
           FROM olist.geolocation AS g
           WHERE g.geolocation_zip_code_prefix = src.seller_zip_code_prefix
       ) THEN 1 END) AS unmatched_prefix_count
FROM olist.sellers AS src;
