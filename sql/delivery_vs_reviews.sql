-- ============================================================
-- delivery_vs_reviews.sql — read-only analysis (no DDL, no writes)
--
-- Question: do late deliveries associate with lower customer review scores?
--
-- Grain: one row per delivered order. The order-level grain is the same one
-- defined in sql/order_level_dataset.sql and is reproduced here as the
-- `order_level` CTE, so this script runs standalone without creating objects.
--
-- Eligibility (delivered orders with valid dates only):
--   * order_status = 'delivered'                       (via is_delivery_duration_eligible)
--   * order_purchase_timestamp IS NOT NULL
--   * order_delivered_customer_date IS NOT NULL
--   * order_delivered_customer_date >= order_purchase_timestamp
--   * order_estimated_delivery_date IS NOT NULL
--
-- Delivery delay definition (docs/03_product_metrics.md, section 5.2):
--   delay_days = DATEDIFF(actual delivery, estimated delivery date)
--   late    => delay_days > 0   (actual arrived after the estimate)
--   on_time => delay_days <= 0  (early, or exactly on the estimated date)
--
-- Same-day deliveries:
--   * Delivered exactly on the estimated date (delay_days = 0) counts as
--     ON TIME, because section 5.2 defines a late order strictly as
--     actual > estimated.
--   * Delivered on the same calendar day as the purchase (delivery_days = 0)
--     is NOT auto-classified; it is judged by the estimate like any other
--     order, so it is on time if it did not arrive after the estimate.
--
-- Exclusions:
--   * The 8 delivered orders with no customer delivery timestamp are excluded
--     rather than counted as on time, as required by the 5.2 note.
--   * Review score uses the latest valid answered score rule
--     (docs/03_product_metrics.md, section 9.7). Orders without a qualifying
--     review keep a missing score and are reported separately, not as zeros.
--
-- Run:  mysql -u root --database=olist --table < sql/delivery_vs_reviews.sql
-- ============================================================

USE olist;

WITH item_totals AS (
    SELECT order_id,
           COUNT(*) AS item_count,
           SUM(price) AS merchandise_value,
           SUM(freight_value) AS freight_value
    FROM olist.order_items
    GROUP BY order_id
),
payment_totals AS (
    SELECT order_id,
           COUNT(*) AS payment_count,
           SUM(payment_value) AS recorded_payment_value,
           MAX(CASE WHEN payment_installments > 0
                    THEN payment_installments END) AS max_valid_installments,
           COUNT(CASE WHEN payment_installments IS NULL
                           OR payment_installments <= 0 THEN 1 END)
               AS invalid_installment_record_count
    FROM olist.order_payments
    GROUP BY order_id
),
review_coverage AS (
    SELECT order_id,
           COUNT(*) AS review_count,
           MAX(CASE WHEN review_score BETWEEN 1 AND 5
                    THEN review_answer_timestamp END) AS latest_valid_answer_timestamp
    FROM olist.order_reviews
    GROUP BY order_id
),
latest_review AS (
    SELECT r.order_id,
           COUNT(DISTINCT r.review_score) AS latest_distinct_scores,
           CASE WHEN COUNT(DISTINCT r.review_score) = 1
                THEN MAX(r.review_score) END AS latest_review_score
    FROM olist.order_reviews AS r
    INNER JOIN review_coverage AS rc
        ON rc.order_id = r.order_id
       AND rc.latest_valid_answer_timestamp = r.review_answer_timestamp
    WHERE r.review_score BETWEEN 1 AND 5
    GROUP BY r.order_id
),
order_level AS (
    SELECT o.order_id,
           o.customer_id,
           c.customer_unique_id,
           c.customer_state,
           o.order_status,
           o.order_purchase_timestamp,
           o.order_approved_at,
           o.order_delivered_carrier_date,
           o.order_delivered_customer_date,
           o.order_estimated_delivery_date,
           CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END AS is_delivered,
           CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END AS is_canceled,
           CASE WHEN o.order_status = 'delivered'
                      AND o.order_delivered_customer_date >= o.order_purchase_timestamp
                THEN 1 ELSE 0 END AS is_delivery_duration_eligible,
           COALESCE(i.item_count, 0) AS item_count,
           i.merchandise_value,
           i.freight_value,
           CASE WHEN o.order_status = 'delivered' THEN i.merchandise_value END
               AS delivered_merchandise_value,
           COALESCE(p.payment_count, 0) AS payment_count,
           p.recorded_payment_value,
           COALESCE(p.invalid_installment_record_count, 0) AS invalid_installment_record_count,
           CASE
               WHEN p.payment_count IS NULL THEN 'no_payment'
               WHEN p.max_valid_installments IS NULL THEN 'no_valid_installments'
               WHEN p.max_valid_installments > 1 THEN 'multi_installment'
               ELSE 'single_installment'
           END AS installment_group,
           COALESCE(rc.review_count, 0) AS review_count,
           rc.latest_valid_answer_timestamp,
           lr.latest_review_score,
           CASE
               WHEN rc.review_count IS NULL THEN 'no_review'
               WHEN rc.latest_valid_answer_timestamp IS NULL THEN 'no_valid_answered_review'
               WHEN lr.latest_distinct_scores > 1 THEN 'conflicting_latest_scores'
               ELSE 'scored'
           END AS order_review_status
    FROM olist.orders AS o
    LEFT JOIN olist.customers AS c ON c.customer_id = o.customer_id
    LEFT JOIN item_totals AS i ON i.order_id = o.order_id
    LEFT JOIN payment_totals AS p ON p.order_id = o.order_id
    LEFT JOIN review_coverage AS rc ON rc.order_id = o.order_id
    LEFT JOIN latest_review AS lr ON lr.order_id = o.order_id
),
eligible AS (
    SELECT ol.order_id,
           ol.order_purchase_timestamp,
           ol.order_delivered_customer_date,
           ol.order_estimated_delivery_date,
           ol.latest_review_score,
           DATEDIFF(ol.order_delivered_customer_date,
                    ol.order_estimated_delivery_date) AS delay_days,
           DATEDIFF(ol.order_delivered_customer_date,
                    ol.order_purchase_timestamp) AS delivery_days
    FROM order_level AS ol
    WHERE ol.is_delivery_duration_eligible = 1
      AND ol.order_estimated_delivery_date IS NOT NULL
),
classified AS (
    SELECT e.*,
           CASE WHEN e.delay_days > 0 THEN 'late' ELSE 'on_time' END AS delivery_timing
    FROM eligible AS e
),
by_timing AS (
    SELECT
        delivery_timing,
        COUNT(*)                                                          AS eligible_orders,
        SUM(latest_review_score IS NOT NULL)                              AS reviewed_orders,
        ROUND(100.0 * SUM(latest_review_score IS NOT NULL) / COUNT(*), 2) AS review_coverage_pct,
        ROUND(AVG(latest_review_score), 2)                                AS avg_review_score,
        ROUND(
            100.0 * SUM(latest_review_score <= 2)
            / NULLIF(SUM(latest_review_score IS NOT NULL), 0), 2
        )                                                                 AS low_score_pct,
        SUM(delivery_days = 0)                                            AS delivered_same_day_as_purchase,
        SUM(delay_days = 0)                                               AS delivered_on_estimated_date
    FROM classified
    GROUP BY delivery_timing
)
SELECT
    delivery_timing,
    eligible_orders,
    reviewed_orders,
    review_coverage_pct,
    avg_review_score,
    low_score_pct,
    ROUND(MAX(low_score_pct) OVER () - MIN(low_score_pct) OVER (), 2)
        AS low_score_gap_pp,
    delivered_same_day_as_purchase,
    delivered_on_estimated_date
FROM by_timing
ORDER BY CASE WHEN delivery_timing = 'on_time' THEN 0 ELSE 1 END;

-- Reconciliation check: eligible orders must equal on-time plus late, and
-- reviewed orders must equal eligible minus orders without a usable score.
WITH item_totals AS (
    SELECT order_id, COUNT(*) AS item_count
    FROM olist.order_items
    GROUP BY order_id
),
review_coverage AS (
    SELECT order_id,
           COUNT(*) AS review_count,
           MAX(CASE WHEN review_score BETWEEN 1 AND 5
                    THEN review_answer_timestamp END) AS latest_valid_answer_timestamp
    FROM olist.order_reviews
    GROUP BY order_id
),
latest_review AS (
    SELECT r.order_id,
           CASE WHEN COUNT(DISTINCT r.review_score) = 1
                THEN MAX(r.review_score) END AS latest_review_score
    FROM olist.order_reviews AS r
    INNER JOIN review_coverage AS rc
        ON rc.order_id = r.order_id
       AND rc.latest_valid_answer_timestamp = r.review_answer_timestamp
    WHERE r.review_score BETWEEN 1 AND 5
    GROUP BY r.order_id
),
eligible AS (
    SELECT o.order_id,
           DATEDIFF(o.order_delivered_customer_date,
                    o.order_estimated_delivery_date) AS delay_days,
           lr.latest_review_score
    FROM olist.orders AS o
    LEFT JOIN latest_review AS lr ON lr.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_delivered_customer_date >= o.order_purchase_timestamp
      AND o.order_estimated_delivery_date IS NOT NULL
)
SELECT
    COUNT(*)                                                        AS eligible_orders,
    SUM(delay_days > 0)                                             AS late_orders,
    SUM(delay_days <= 0)                                            AS on_time_orders,
    SUM(latest_review_score IS NOT NULL)                            AS reviewed_orders,
    SUM(latest_review_score IS NULL)                                AS unreviewed_orders,
    SUM(delay_days > 0) + SUM(delay_days <= 0) = COUNT(*)           AS timing_reconciles,
    SUM(latest_review_score IS NOT NULL)
        + SUM(latest_review_score IS NULL) = COUNT(*)               AS review_reconciles
FROM eligible;
