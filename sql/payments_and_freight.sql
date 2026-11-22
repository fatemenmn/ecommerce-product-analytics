-- ============================================================
-- payments_and_freight.sql — read-only analysis (no DDL, no writes)
--
-- Definitions follow docs/03_product_metrics.md:
--   * 6.1 Item-Level Freight-to-Price Ratio
--   * 6.2 Order-Level Freight-to-Price Ratio
--   * 6.3 Payment Method Distribution
--   * 6.4 Average Installments (positive installment records only)
--   * 6.5 AOV by Installment Group
--   * 9.3 Aggregation before joining
--
-- Merchandise GMV comes from order_items.price and excludes freight.
-- Recorded payment value comes from order_payments.payment_value. The two are
-- reported side by side and never merged into one measure.
--
-- Installment classification (6.5), applied per order over valid payment rows
-- (rows with payment_installments > 0):
--   single_installment     all valid payment rows have exactly 1 installment
--   multi_installment      at least one valid payment row has more than 1
--   no_payment             the order has no payment row at all
--   no_valid_installments  payment rows exist but none has a positive count
--
-- Run:  mysql -u root --database=olist --table < sql/payments_and_freight.sql
-- ============================================================

USE olist;

-- ------------------------------------------------------------
-- Result 1 — Payment methods
-- Record share uses all payment rows as the denominator; value share uses
-- total recorded payment value. `distinct_orders` overcounts across methods
-- because one order can carry several payment types, so those counts must
-- not be added together.
-- ------------------------------------------------------------
SELECT
    payment_type,
    COUNT(*)                                                        AS payment_rows,
    ROUND(SUM(payment_value), 2)                                    AS recorded_payment_value_brl,
    ROUND(100.0 * SUM(payment_value) / SUM(SUM(payment_value)) OVER (), 2)
                                                                    AS value_share_pct,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)               AS record_share_pct,
    COUNT(DISTINCT order_id)                                        AS distinct_orders
FROM olist.order_payments
GROUP BY payment_type
ORDER BY SUM(payment_value) DESC, payment_type;

-- ------------------------------------------------------------
-- Result 2 — Installments and AOV
-- Payment rows are aggregated to one row per order before joining to item
-- totals, so item rows and payment rows cannot multiply each other.
-- Population: delivered orders that have at least one item row.
-- ------------------------------------------------------------
WITH item_totals AS (
    SELECT order_id,
           COUNT(*)            AS item_count,
           SUM(price)          AS merchandise_value,
           SUM(freight_value)  AS freight_value
    FROM olist.order_items
    GROUP BY order_id
),
payment_totals AS (
    SELECT order_id,
           COUNT(*)                                                AS payment_rows,
           SUM(payment_value)                                      AS recorded_payment_value,
           SUM(payment_installments > 0)                           AS valid_installment_rows,
           MAX(CASE WHEN payment_installments > 0
                    THEN payment_installments END)                 AS max_valid_installments
    FROM olist.order_payments
    GROUP BY order_id
),
delivered_with_items AS (
    SELECT o.order_id,
           i.item_count,
           i.merchandise_value,
           i.freight_value,
           p.payment_rows,
           p.recorded_payment_value,
           p.valid_installment_rows,
           p.max_valid_installments
    FROM olist.orders AS o
    JOIN item_totals AS i ON i.order_id = o.order_id
    LEFT JOIN payment_totals AS p ON p.order_id = o.order_id
    WHERE o.order_status = 'delivered'
),
classified AS (
    SELECT d.*,
           CASE
               WHEN d.payment_rows IS NULL         THEN 'no_payment'
               WHEN d.valid_installment_rows = 0   THEN 'no_valid_installments'
               WHEN d.max_valid_installments > 1   THEN 'multi_installment'
               ELSE 'single_installment'
           END AS installment_group
    FROM delivered_with_items AS d
)
SELECT
    installment_group,
    COUNT(*)                                                AS orders,
    ROUND(SUM(merchandise_value), 2)                        AS delivered_merchandise_gmv_brl,
    ROUND(SUM(merchandise_value) / COUNT(*), 2)             AS aov_brl,
    ROUND(SUM(merchandise_value) / SUM(item_count), 2)      AS item_value_per_item_brl,
    ROUND(SUM(freight_value), 2)                            AS freight_brl,
    ROUND(SUM(recorded_payment_value), 2)                   AS recorded_payment_value_brl
FROM classified
GROUP BY installment_group
ORDER BY FIELD(installment_group,
               'single_installment', 'multi_installment',
               'no_payment', 'no_valid_installments');

-- ------------------------------------------------------------
-- Result 3 — Freight on delivered orders with eligible data
-- Two different ratios are reported and must not be confused:
--   median order freight ratio = median of per-order (freight / item value),
--     an unweighted median across orders
--   aggregate freight ratio = total freight / total item value,
--     a value-weighted ratio across the same orders
-- Excluded: orders with zero or invalid total item value (division by zero)
-- and orders with a missing freight value. Zero freight is kept, because a
-- zero is a recorded shipping charge.
-- ------------------------------------------------------------
WITH item_totals AS (
    SELECT order_id,
           SUM(price)          AS merchandise_value,
           SUM(freight_value)  AS freight_value
    FROM olist.order_items
    GROUP BY order_id
),
eligible AS (
    SELECT o.order_id,
           i.merchandise_value,
           i.freight_value,
           i.freight_value / i.merchandise_value AS freight_ratio
    FROM olist.orders AS o
    JOIN item_totals AS i ON i.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND i.merchandise_value > 0
      AND i.freight_value IS NOT NULL
),
ranked AS (
    SELECT freight_ratio,
           ROW_NUMBER() OVER (ORDER BY freight_ratio) AS rn,
           COUNT(*) OVER () AS n
    FROM eligible
)
SELECT
    (SELECT COUNT(*) FROM eligible)                             AS eligible_orders,
    (SELECT ROUND(SUM(freight_value), 2) FROM eligible)         AS total_freight_brl,
    (SELECT ROUND(SUM(merchandise_value), 2) FROM eligible)     AS total_merchandise_value_brl,
    (SELECT ROUND(AVG(freight_ratio), 4) FROM ranked
      WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2)))      AS median_order_freight_ratio,
    (SELECT ROUND(100.0 * AVG(freight_ratio), 2) FROM ranked
      WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2)))      AS median_order_freight_pct,
    (SELECT ROUND(SUM(freight_value) / SUM(merchandise_value), 4) FROM eligible)
                                                                AS aggregate_freight_ratio,
    (SELECT ROUND(100.0 * SUM(freight_value) / SUM(merchandise_value), 2) FROM eligible)
                                                                AS aggregate_freight_pct;

-- ------------------------------------------------------------
-- Result 4 — QA and reconciliation
-- Payment totals reconcile on ALL payment rows: the independent total must
-- equal the sum of the per-method totals. The delivered-with-items subset is
-- a smaller population (delivered orders only, one payment value per order)
-- and is therefore reported separately rather than expected to match.
-- ------------------------------------------------------------
WITH item_totals AS (
    SELECT order_id,
           COUNT(*)            AS item_count,
           SUM(price)          AS merchandise_value,
           SUM(freight_value)  AS freight_value
    FROM olist.order_items
    GROUP BY order_id
),
payment_totals AS (
    SELECT order_id,
           COUNT(*)                                     AS payment_rows,
           SUM(payment_value)                           AS recorded_payment_value,
           SUM(payment_installments > 0)                AS valid_installment_rows,
           MAX(CASE WHEN payment_installments > 0
                    THEN payment_installments END)      AS max_valid_installments
    FROM olist.order_payments
    GROUP BY order_id
),
delivered_with_items AS (
    SELECT o.order_id,
           i.item_count,
           i.merchandise_value,
           i.freight_value,
           p.payment_rows,
           p.recorded_payment_value,
           p.valid_installment_rows,
           p.max_valid_installments
    FROM olist.orders AS o
    JOIN item_totals AS i ON i.order_id = o.order_id
    LEFT JOIN payment_totals AS p ON p.order_id = o.order_id
    WHERE o.order_status = 'delivered'
),
classified AS (
    SELECT d.*,
           CASE
               WHEN d.payment_rows IS NULL         THEN 'no_payment'
               WHEN d.valid_installment_rows = 0   THEN 'no_valid_installments'
               WHEN d.max_valid_installments > 1   THEN 'multi_installment'
               ELSE 'single_installment'
           END AS installment_group
    FROM delivered_with_items AS d
)
SELECT
    (SELECT ROUND(SUM(payment_value), 2) FROM olist.order_payments)
        AS independent_payment_total,
    (SELECT ROUND(SUM(type_total), 2)
       FROM (SELECT SUM(payment_value) AS type_total
               FROM olist.order_payments
              GROUP BY payment_type) AS by_type)
        AS payment_total_by_type,
    (SELECT ROUND(SUM(recorded_payment_value), 2) FROM classified)
        AS payment_value_delivered_subset,
    (SELECT ROUND(SUM(merchandise_value), 2) FROM classified)
        AS merchandise_across_installment_groups,
    (SELECT ROUND(SUM(oi.price), 2)
       FROM olist.order_items AS oi
       JOIN olist.orders AS o ON o.order_id = oi.order_id
      WHERE o.order_status = 'delivered')
        AS independent_delivered_gmv,
    (SELECT ROUND(SUM(oi.freight_value), 2)
       FROM olist.order_items AS oi
       JOIN olist.orders AS o ON o.order_id = oi.order_id
      WHERE o.order_status = 'delivered')
        AS independent_freight_total,
    (SELECT ROUND(SUM(freight_value), 2) FROM delivered_with_items)
        AS freight_total_delivered_with_items,
    (SELECT COUNT(*) FROM classified)                AS installment_rows,
    (SELECT COUNT(DISTINCT order_id) FROM classified) AS installment_distinct_orders,
    (SELECT COUNT(*) FROM classified
      WHERE installment_group = 'no_payment')        AS orders_no_payment,
    (SELECT COUNT(*) FROM classified
      WHERE installment_group = 'no_valid_installments') AS orders_no_valid_installments,
    (SELECT COUNT(*) FROM delivered_with_items
      WHERE merchandise_value <= 0)                  AS orders_zero_item_value,
    (SELECT COUNT(*) FROM delivered_with_items
      WHERE freight_value IS NULL)                   AS orders_missing_freight,
    (SELECT COUNT(DISTINCT order_id)
       FROM olist.order_payments)                    AS orders_with_payment_source,
    (SELECT COUNT(*) FROM classified
      WHERE installment_group LIKE '%_installment'
        AND payment_rows IS NULL)                    AS grouped_orders_without_payment;
