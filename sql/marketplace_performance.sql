WITH item_value AS (
    SELECT order_id, SUM(price) AS merchandise_value
    FROM olist.order_items
    GROUP BY order_id
),
monthly AS (
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
        COUNT(*) AS placed_orders,
        COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END)
            AS delivered_orders,
        COUNT(CASE WHEN o.order_status = 'delivered'
                    AND i.order_id IS NOT NULL THEN 1 END)
            AS delivered_orders_with_items,
        COUNT(CASE WHEN o.order_status = 'canceled' THEN 1 END)
            AS canceled_orders,
        SUM(CASE WHEN o.order_status = 'delivered'
                 THEN COALESCE(i.merchandise_value, 0) ELSE 0 END)
            AS delivered_gmv_brl
    FROM olist.orders AS o
    LEFT JOIN item_value AS i ON i.order_id = o.order_id
    GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
)
SELECT
    purchase_month,
    placed_orders,
    delivered_orders,
    delivered_orders_with_items,
    canceled_orders,
    delivered_gmv_brl,
    ROUND(delivered_gmv_brl / NULLIF(delivered_orders_with_items, 0), 2)
        AS aov_brl,
    ROUND(100.0 * canceled_orders / NULLIF(placed_orders, 0), 2)
        AS cancellation_rate_pct
FROM monthly
ORDER BY purchase_month;
