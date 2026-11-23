-- ============================================================
-- delivery_by_state.sql — read-only analysis (no DDL, no writes)
--
-- Definitions follow docs/03_product_metrics.md:
--   * 5.1 Median Delivery Lead Time
--   * 5.2 Delivery Delay Rate  (late = actual delivery AFTER the estimate)
--   * 9.3 aggregation and geography join rules
--   * 9.6 straight-line distance is not route distance
--   * Q8 Geographic Logistics: delivery lead time by state pair
--
-- Eligibility (same rule as sql/delivery_vs_reviews.sql):
--   order_status = 'delivered'
--   AND order_purchase_timestamp IS NOT NULL
--   AND order_delivered_customer_date IS NOT NULL
--   AND order_delivered_customer_date >= order_purchase_timestamp
--   AND order_estimated_delivery_date IS NOT NULL
-- This gives 96,470 timing-eligible orders out of 96,478 delivered.
--
-- Late classification (5.2): a delivery exactly on the estimated calendar
-- date is ON TIME; only an actual delivery strictly after the estimate is late.
--
-- State values: customer_state and seller_state are used as recorded. Any
-- missing value falls into an '(unknown)' bucket instead of being dropped.
--
-- This analysis stays at state level. It does not use coordinates or
-- distance, so no straight-line approximation is involved.
--
-- Run:  mysql -u root --database=olist --table < sql/delivery_by_state.sql
-- ============================================================

USE olist;

-- ------------------------------------------------------------
-- Result 1 — Buyer state, one row per delivered order
-- delivered_orders  : all delivered orders attributed to the buyer's state
-- eligible_orders   : delivered orders with usable timing dates (denominator
--                     for both the median and the late rate)
-- median_delivery_days : median purchase-to-delivery days over eligible orders
-- late_rate_pct     : late orders / eligible orders
-- ------------------------------------------------------------
WITH delivered_orders AS (
    SELECT o.order_id,
           COALESCE(c.customer_state, '(unknown)') AS buyer_state,
           CASE WHEN o.order_purchase_timestamp IS NOT NULL
                     AND o.order_delivered_customer_date IS NOT NULL
                     AND o.order_delivered_customer_date >= o.order_purchase_timestamp
                     AND o.order_estimated_delivery_date IS NOT NULL
                THEN 1 ELSE 0 END AS is_eligible,
           DATEDIFF(o.order_delivered_customer_date,
                    o.order_purchase_timestamp) AS delivery_days,
           -- Calendar-date rule (5.2): delivery on the estimated date is on time.
           CASE WHEN DATEDIFF(o.order_delivered_customer_date,
                               o.order_estimated_delivery_date) > 0
                THEN 1 ELSE 0 END AS is_late
    FROM olist.orders AS o
    LEFT JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
state_ranked AS (
    SELECT buyer_state,
           delivery_days,
           ROW_NUMBER() OVER (PARTITION BY buyer_state ORDER BY delivery_days) AS rn,
           COUNT(*) OVER (PARTITION BY buyer_state) AS n
    FROM delivered_orders
    WHERE is_eligible = 1
),
state_medians AS (
    SELECT buyer_state,
           ROUND(AVG(delivery_days), 1) AS median_delivery_days
    FROM state_ranked
    WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2))
    GROUP BY buyer_state
)
SELECT
    d.buyer_state,
    COUNT(*)                                    AS delivered_orders,
    SUM(d.is_eligible)                          AS eligible_orders,
    m.median_delivery_days,
    SUM(d.is_eligible = 1 AND d.is_late = 1)    AS late_orders,
    ROUND(100.0 * SUM(d.is_eligible = 1 AND d.is_late = 1)
          / NULLIF(SUM(d.is_eligible), 0), 2)   AS late_rate_pct
FROM delivered_orders AS d
LEFT JOIN state_medians AS m ON m.buyer_state = d.buyer_state
GROUP BY d.buyer_state, m.median_delivery_days
ORDER BY SUM(d.is_eligible) DESC, d.buyer_state;

-- ------------------------------------------------------------
-- Result 2 — Seller state to buyer state
-- Order/state pairs are derived from order items joined to seller state.
-- COUNT(DISTINCT order_id) counts each order once inside a pair, but an
-- order that bought from sellers in several states appears in several pairs,
-- so pair-level counts overlap and cannot be summed.
-- The timing figures are the order's purchase-to-delivery timing associated
-- with that state pair; they are not the shipping time of an individual item.
-- ------------------------------------------------------------
WITH order_seller_states AS (
    SELECT DISTINCT oi.order_id,
           COALESCE(s.seller_state, '(unknown)') AS seller_state
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    LEFT JOIN olist.sellers AS s ON s.seller_id = oi.seller_id
    WHERE o.order_status = 'delivered'
),
pairs AS (
    SELECT DISTINCT oss.order_id,
           oss.seller_state,
           COALESCE(c.customer_state, '(unknown)') AS buyer_state
    FROM order_seller_states AS oss
    JOIN olist.orders AS o ON o.order_id = oss.order_id
    LEFT JOIN olist.customers AS c ON c.customer_id = o.customer_id
),
pair_base AS (
    SELECT p.seller_state,
           p.buyer_state,
           p.order_id,
           DATEDIFF(o.order_delivered_customer_date,
                    o.order_purchase_timestamp) AS delivery_days,
           CASE WHEN DATEDIFF(o.order_delivered_customer_date,
                               o.order_estimated_delivery_date) > 0
                THEN 1 ELSE 0 END AS is_late
    FROM pairs AS p
    JOIN olist.orders AS o ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_delivered_customer_date >= o.order_purchase_timestamp
      AND o.order_estimated_delivery_date IS NOT NULL
),
pair_ranked AS (
    SELECT seller_state,
           buyer_state,
           delivery_days,
           ROW_NUMBER() OVER (PARTITION BY seller_state, buyer_state
                              ORDER BY delivery_days) AS rn,
           COUNT(*) OVER (PARTITION BY seller_state, buyer_state) AS n
    FROM pair_base
),
pair_medians AS (
    SELECT seller_state,
           buyer_state,
           ROUND(AVG(delivery_days), 1) AS median_delivery_days
    FROM pair_ranked
    WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2))
    GROUP BY seller_state, buyer_state
)
SELECT
    b.seller_state,
    b.buyer_state,
    COUNT(*)                            AS eligible_orders,
    m.median_delivery_days,
    SUM(b.is_late)                      AS late_orders,
    ROUND(100.0 * SUM(b.is_late) / COUNT(*), 2) AS late_rate_pct
FROM pair_base AS b
LEFT JOIN pair_medians AS m
       ON m.seller_state = b.seller_state
      AND m.buyer_state = b.buyer_state
GROUP BY b.seller_state, b.buyer_state, m.median_delivery_days
ORDER BY COUNT(*) DESC, b.seller_state, b.buyer_state;

-- ------------------------------------------------------------
-- Result 3 — QA and reconciliation
-- ------------------------------------------------------------
WITH delivered_orders AS (
    SELECT o.order_id,
           o.customer_id,
           c.customer_state,
           CASE WHEN o.order_purchase_timestamp IS NOT NULL
                     AND o.order_delivered_customer_date IS NOT NULL
                     AND o.order_delivered_customer_date >= o.order_purchase_timestamp
                     AND o.order_estimated_delivery_date IS NOT NULL
                THEN 1 ELSE 0 END AS is_eligible,
           CASE WHEN DATEDIFF(o.order_delivered_customer_date,
                               o.order_estimated_delivery_date) > 0
                THEN 1 ELSE 0 END AS is_late
    FROM olist.orders AS o
    LEFT JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
order_seller_states AS (
    SELECT DISTINCT oi.order_id,
           COALESCE(s.seller_state, '(unknown)') AS seller_state
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    LEFT JOIN olist.sellers AS s ON s.seller_id = oi.seller_id
    WHERE o.order_status = 'delivered'
),
pairs AS (
    SELECT DISTINCT oss.order_id,
           oss.seller_state,
           COALESCE(c.customer_state, '(unknown)') AS buyer_state
    FROM order_seller_states AS oss
    JOIN olist.orders AS o ON o.order_id = oss.order_id
    LEFT JOIN olist.customers AS c ON c.customer_id = o.customer_id
)
SELECT
    (SELECT COUNT(*) FROM olist.orders WHERE order_status = 'delivered')
        AS delivered_source,
    (SELECT COUNT(*) FROM delivered_orders)                        AS delivered_buyer_state_rows,
    (SELECT SUM(is_eligible) FROM delivered_orders)                AS eligible_buyer_state_total,
    (SELECT SUM(is_eligible = 1 AND is_late = 1) FROM delivered_orders)
                                                                   AS late_buyer_state_total,
    (SELECT COUNT(*) FROM delivered_orders
      WHERE customer_state IS NULL)                                AS delivered_missing_buyer_state,
    (SELECT COUNT(DISTINCT oi.seller_id)
       FROM olist.order_items AS oi
       JOIN olist.orders AS o ON o.order_id = oi.order_id
      WHERE o.order_status = 'delivered'
        AND oi.seller_id IS NULL)                                  AS items_missing_seller_id,
    (SELECT COUNT(*) FROM olist.sellers WHERE seller_state IS NULL) AS sellers_missing_state,
    (SELECT COUNT(*) FROM pairs)                                   AS order_state_pair_rows,
    (SELECT COUNT(*) FROM (
        SELECT DISTINCT order_id, seller_state, buyer_state FROM pairs
     ) AS distinct_pairs)                                          AS distinct_order_state_pairs,
    (SELECT COUNT(*) FROM (
        SELECT order_id FROM pairs
        GROUP BY order_id HAVING COUNT(DISTINCT seller_state) > 1
     ) AS multi)                                                    AS multi_seller_state_orders,
    (SELECT COUNT(DISTINCT order_id) FROM pairs)                   AS distinct_orders_in_pairs,
    (SELECT COUNT(*) FROM delivered_orders
      WHERE is_eligible = 1
        AND NOT EXISTS (SELECT 1 FROM pairs AS p
                         WHERE p.order_id = delivered_orders.order_id))
                                                                   AS eligible_orders_missing_from_pairs;
