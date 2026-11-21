-- Olist | Order-level dataset for MySQL 8.0
-- One row per orders.order_id. Run against the validated olist schema.
-- Preserve missing item and payment amounts as NULL. Zero is a recorded amount.
-- Use raw item rows for category and seller analysis and raw review rows
-- for KPIs defined at review-record grain.

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
)
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
LEFT JOIN latest_review AS lr ON lr.order_id = o.order_id;
