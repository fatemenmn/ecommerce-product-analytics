-- ============================================================
-- customer_repeat_purchase.sql — read-only analysis (no DDL, no writes)
--
-- Definitions follow docs/03_product_metrics.md:
--   * 4.2 Lifetime Repeat Purchase Rate
--   * 4.3 30-Day Repeat Purchase Rate (generalised here to 90 days)
--   * 4.4 Time to Second Purchase
--   * 9.1 Customer Identity: join on customer_id, identify buyers with
--         customer_unique_id
--
-- Population: delivered orders with a purchase timestamp, joined to the
-- customer record that owns them.
--
-- Ordering: each buyer's delivered orders are sequenced by
-- order_purchase_timestamp, then order_id to break timestamp ties.
--
-- Exclusions: delivered orders missing a purchase timestamp or with no
-- matching customer row cannot enter the buyer history; they are counted in
-- the QA block rather than dropped silently.
--
-- Run:  mysql -u root --database=olist --table < sql/customer_repeat_purchase.sql
-- ============================================================

USE olist;

-- ------------------------------------------------------------
-- Result 1 — Observed history across the whole dataset
-- ------------------------------------------------------------
WITH delivered_orders AS (
    SELECT o.order_id,
           c.customer_unique_id,
           o.order_purchase_timestamp
    FROM olist.orders AS o
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
),
sequenced AS (
    SELECT order_id,
           customer_unique_id,
           order_purchase_timestamp,
           ROW_NUMBER() OVER (
               PARTITION BY customer_unique_id
               ORDER BY order_purchase_timestamp, order_id
           ) AS order_seq
    FROM delivered_orders
),
buyer_history AS (
    SELECT customer_unique_id,
           MIN(order_purchase_timestamp) AS first_purchase_ts,
           MAX(order_purchase_timestamp) AS last_purchase_ts,
           COUNT(*) AS delivered_orders,
           MAX(CASE WHEN order_seq = 2 THEN order_purchase_timestamp END)
               AS second_purchase_ts
    FROM sequenced
    GROUP BY customer_unique_id
),
elapsed AS (
    SELECT DATEDIFF(second_purchase_ts, first_purchase_ts) AS days_to_second
    FROM buyer_history
    WHERE delivered_orders >= 2
),
ordered_elapsed AS (
    SELECT days_to_second,
           ROW_NUMBER() OVER (ORDER BY days_to_second) AS rn,
           COUNT(*) OVER () AS n
    FROM elapsed
)
SELECT
    COUNT(*)                                                  AS unique_buyers,
    SUM(delivered_orders >= 2)                                AS repeat_buyers,
    ROUND(100.0 * SUM(delivered_orders >= 2) / COUNT(*), 2)   AS repeat_buyer_rate_pct,
    ROUND(AVG(delivered_orders), 3)                           AS avg_delivered_orders_per_buyer,
    SUM(delivered_orders)                                     AS total_delivered_orders,
    MAX(delivered_orders)                                     AS max_delivered_orders_one_buyer,
    (SELECT COUNT(*) FROM elapsed)                            AS buyers_with_two_or_more,
    (SELECT ROUND(AVG(days_to_second), 1) FROM ordered_elapsed
      WHERE rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2)))    AS median_days_first_to_second,
    (SELECT ROUND(AVG(days_to_second), 1) FROM elapsed)        AS mean_days_first_to_second
FROM buyer_history;

-- ------------------------------------------------------------
-- Result 2 — 90-day repeat purchase by first-purchase month
--
-- Reporting period: first purchase in 2017-01 through 2018-08.
-- Observation cutoff: end of 2018-08-31 (23:59:59).
-- A buyer's first purchase is their first delivered purchase in the whole
-- dataset, so cohort assignment uses all earlier observed history.
-- Only buyers whose full 90-day window fits before the cutoff are counted,
-- which means first purchase on or before 2018-06-02 23:59:59.
-- ------------------------------------------------------------
WITH delivered_orders AS (
    SELECT o.order_id,
           c.customer_unique_id,
           o.order_purchase_timestamp
    FROM olist.orders AS o
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
),
sequenced AS (
    SELECT order_id,
           customer_unique_id,
           order_purchase_timestamp,
           ROW_NUMBER() OVER (
               PARTITION BY customer_unique_id
               ORDER BY order_purchase_timestamp, order_id
           ) AS order_seq
    FROM delivered_orders
),
buyer_history AS (
    SELECT customer_unique_id,
           MIN(order_purchase_timestamp) AS first_purchase_ts,
           COUNT(*) AS delivered_orders,
           MAX(CASE WHEN order_seq = 2 THEN order_purchase_timestamp END)
               AS second_purchase_ts
    FROM sequenced
    GROUP BY customer_unique_id
),
cohorts AS (
    SELECT customer_unique_id,
           first_purchase_ts,
           DATE_FORMAT(first_purchase_ts, '%Y-%m') AS first_purchase_month,
           second_purchase_ts,
           -- Inclusive, exact deadline: the second purchase counts when it is
           -- no later than the same clock time 90 days after the first.
           CASE WHEN second_purchase_ts IS NOT NULL
                     AND second_purchase_ts <= TIMESTAMPADD(DAY, 90, first_purchase_ts)
                THEN 1 ELSE 0 END AS returned_within_90d
    FROM buyer_history
),
eligible_cohorts AS (
    SELECT *
    FROM cohorts
    WHERE first_purchase_month BETWEEN '2017-01' AND '2018-08'
      AND first_purchase_ts <= TIMESTAMPADD(DAY, -90, '2018-08-31 23:59:59')
)
SELECT
    first_purchase_month,
    COUNT(*)                                                  AS cohort_size,
    SUM(returned_within_90d)                                  AS second_purchase_within_90d,
    ROUND(100.0 * SUM(returned_within_90d) / COUNT(*), 2)     AS repeat_rate_90d_pct,
    SUM(returned_within_90d) <= COUNT(*)                      AS repeat_within_cohort
FROM eligible_cohorts
GROUP BY first_purchase_month
ORDER BY first_purchase_month;

-- ------------------------------------------------------------
-- Result 3 — QA and reconciliation
-- ------------------------------------------------------------
WITH delivered_orders AS (
    SELECT o.order_id,
           c.customer_unique_id,
           o.order_purchase_timestamp
    FROM olist.orders AS o
    JOIN olist.customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp IS NOT NULL
),
sequenced AS (
    SELECT order_id,
           customer_unique_id,
           order_purchase_timestamp,
           ROW_NUMBER() OVER (
               PARTITION BY customer_unique_id
               ORDER BY order_purchase_timestamp, order_id
           ) AS order_seq
    FROM delivered_orders
),
buyer_history AS (
    SELECT customer_unique_id,
           MIN(order_purchase_timestamp) AS first_purchase_ts,
           COUNT(*) AS delivered_orders,
           MAX(CASE WHEN order_seq = 2 THEN order_purchase_timestamp END)
               AS second_purchase_ts
    FROM sequenced
    GROUP BY customer_unique_id
),
cohorts AS (
    SELECT customer_unique_id,
           first_purchase_ts,
           DATE_FORMAT(first_purchase_ts, '%Y-%m') AS first_purchase_month,
           second_purchase_ts,
           CASE WHEN second_purchase_ts IS NOT NULL
                     AND second_purchase_ts <= TIMESTAMPADD(DAY, 90, first_purchase_ts)
                THEN 1 ELSE 0 END AS returned_within_90d
    FROM buyer_history
),
eligible_cohorts AS (
    SELECT *
    FROM cohorts
    WHERE first_purchase_month BETWEEN '2017-01' AND '2018-08'
      AND first_purchase_ts <= TIMESTAMPADD(DAY, -90, '2018-08-31 23:59:59')
)
SELECT
    (SELECT COUNT(*) FROM olist.orders
      WHERE order_status = 'delivered')                        AS delivered_orders_source,
    (SELECT COUNT(*) FROM delivered_orders)                    AS delivered_orders_used,
    (SELECT COUNT(*) FROM olist.orders
      WHERE order_status = 'delivered'
        AND order_purchase_timestamp IS NULL)                  AS delivered_excluded_no_purchase_ts,
    (SELECT COUNT(*) FROM olist.orders AS o
      WHERE o.order_status = 'delivered'
        AND NOT EXISTS (SELECT 1 FROM olist.customers AS c
                         WHERE c.customer_id = o.customer_id)) AS delivered_excluded_no_customer,
    (SELECT COUNT(DISTINCT c.customer_unique_id)
       FROM olist.orders AS o
       JOIN olist.customers AS c ON c.customer_id = o.customer_id
      WHERE o.order_status = 'delivered'
        AND o.order_purchase_timestamp IS NOT NULL)            AS distinct_buyers_independent,
    (SELECT COUNT(*) FROM buyer_history)                       AS distinct_buyers_cte,
    (SELECT COUNT(*) FROM buyer_history
      WHERE delivered_orders >= 2)                             AS repeat_buyers_cte,
    (SELECT SUM(delivered_orders) FROM buyer_history)          AS orders_accounted_for,
    -- 90-day cohort figures, recomputed here to confirm the cohort query.
    (SELECT COUNT(*) FROM eligible_cohorts)                    AS cohort_eligible_buyers,
    (SELECT SUM(returned_within_90d) FROM eligible_cohorts)    AS cohort_second_within_90d,
    (SELECT ROUND(100.0 * SUM(returned_within_90d) / COUNT(*), 2)
       FROM eligible_cohorts)                                  AS cohort_rate_90d_pct,
    -- Impact of the exact timestamp deadline versus a calendar-day difference:
    -- buyers on day 90 whose second purchase fell later in the clock than the
    -- first purchase are excluded by the exact rule but counted by DATEDIFF.
    (SELECT COUNT(*) FROM eligible_cohorts
      WHERE second_purchase_ts IS NOT NULL
        AND DATEDIFF(second_purchase_ts, first_purchase_ts) <= 90) AS calendar_day_rule_second_90d,
    (SELECT COUNT(*) FROM eligible_cohorts
      WHERE returned_within_90d = 0
        AND second_purchase_ts IS NOT NULL
        AND DATEDIFF(second_purchase_ts, first_purchase_ts) = 90)   AS excluded_by_exact_deadline;

-- ------------------------------------------------------------
-- Result 4 — Boundary check for the inclusive 90-day deadline
-- The deadline is first_purchase + 90 days. A purchase exactly at the
-- deadline must count; one second later must not.
-- ------------------------------------------------------------
SELECT 'exact deadline (included)' AS boundary_case,
       TIMESTAMP('2018-01-03 10:00:00')
           <= TIMESTAMPADD(DAY, 90, TIMESTAMP('2017-10-05 10:00:00')) AS counted_within_90d
UNION ALL
SELECT 'one second later (excluded)',
       TIMESTAMPADD(SECOND, 1, TIMESTAMP('2018-01-03 10:00:00'))
           <= TIMESTAMPADD(DAY, 90, TIMESTAMP('2017-10-05 10:00:00'));
