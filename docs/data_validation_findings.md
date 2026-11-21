# Olist data validation findings

The November 21, 2026 MySQL export contains 16 successful statements and 16 result sets from [data_exploration.sql](../sql/data_exploration.sql). The exported statements match the script. The checks cover the local `olist` schema. The supplied customer CSV was also checked against MySQL. Source-file reconciliation for the other eight tables is pending.

## Imported tables

| Table | MySQL rows | Declared primary key |
| --- | ---: | --- |
| `customers` | 99,441 | `customer_id` |
| `geolocation` | 1,000,163 | None reported |
| `order_items` | 112,650 | `(order_id, order_item_id)` |
| `order_payments` | 103,886 | `(order_id, payment_sequential)` |
| `order_reviews` | 99,224 | None reported |
| `orders` | 99,441 | `order_id` |
| `product_category_name_translation` | 71 | `product_category_name` |
| `products` | 32,951 | `product_id` |
| `sellers` | 3,095 | `seller_id` |

The schema inspection returned 52 columns. Order timestamps use `DATETIME`, monetary fields use `DECIMAL(10,2)`, and postal prefixes use `CHAR(5)`. MySQL reported no declared foreign keys. Six tested links had zero missing or unmatched source keys: orders to customers, items to orders/products/sellers, payments to orders, and reviews to orders.

## Findings and implications

| Area | Observed result | Implication for analysis |
| --- | --- | --- |
| Delivery timing | Of 96,478 orders marked delivered, 8 lack a customer delivery timestamp. Six canceled orders have one. No recorded customer delivery timestamp precedes its purchase timestamp. | Use delivered orders with both timestamps for purchase-to-delivery duration. That yields 96,470 eligible orders for this duration check. Keep the six canceled orders under their recorded status and flag the inconsistency. |
| Buyer identity | 99,441 customer records represent 96,096 distinct `customer_unique_id` values. Each `customer_id` maps to exactly one order in this snapshot. The customer CSV agrees on the row count and both distinct ID counts. | Join orders on `customer_id`, then group by `customer_unique_id` to measure repeat purchasing. The difference between counts does not give the number of repeat buyers. |
| Reviews | 789 review IDs occur in multiple rows. Of 547 orders with multiple review rows, 202 have different scores. All scores are present and range from 1 to 5. Review messages are missing in 58,247 rows. | Validate the order-level review selection rule before modeling scores. Check timestamp ties and document how conflicting scores are resolved. Report review-text coverage separately. |
| Product categories | 610 of 32,951 products (1.85%) have no category. Another 13 product records have a category with no English translation match. | Preserve these order items in category reporting. Label missing categories separately and use the original label where a translation is unavailable. |
| Prices and payments | Item prices range from 0.85 to 6,735.00, freight from 0.00 to 409.68, and payments from 0.00 to 13,664.08. The script detected no negative values in these fields. Two credit-card payment rows report zero installments. | Keep zero installments visible as a data exception and confirm how to treat them before comparing installment groups. |
| Geolocation | 17,972 of 19,015 postal prefixes have multiple geolocation rows (94.5%), with up to 1,146 rows per prefix. Prefixes for 278 customer records and 7 seller records have no match. Coordinate extremes pass global bounds but include values inconsistent with a Brazil-only analysis. | Validate coordinates before deriving one location per prefix. Preserve unmatched customer and seller records in the underlying model. Use state fields for state-level analysis. |

Purchase timestamps span September 4, 2016 through October 17, 2018. The first and last months in this observed range have partial coverage. Flag the boundary months when comparing monthly volumes or interpreting the available follow-up time for repeat purchases.

## Order-level joins

| Related table | Orders with zero rows | Orders with one row | Orders with multiple rows | Maximum rows per order |
| --- | ---: | ---: | ---: | ---: |
| `order_items` | 775 | 88,863 | 9,803 | 21 |
| `order_payments` | 1 | 96,479 | 2,961 | 29 |
| `order_reviews` | 768 | 98,126 | 547 | 3 |

Use `orders` as the base for order-level metrics. Summarize each related table to one row per order before joining. Check that the model preserves order counts and reconciles monetary totals with their source tables. Retain item-level detail for category and seller metrics. An order without a related row should stay visible in the order model so each KPI can apply its own eligibility criteria.

## Next checks

All three checks are resolved against the live `olist` schema. Each is read-only and runs against the same connection as [data_exploration.sql](../sql/data_exploration.sql). The SQL is retained so every result can be reproduced.

### 1. Status of the 775 orders without items

```sql
SELECT o.order_status, COUNT(*) AS orders
FROM olist.orders AS o
LEFT JOIN olist.order_items AS i ON i.order_id = o.order_id
WHERE i.order_id IS NULL
GROUP BY o.order_status
ORDER BY orders DESC;
```

**Result (confirmed).**

| `order_status` | Orders |
| --- | ---: |
| `unavailable` | 603 |
| `canceled` | 164 |
| `created` | 5 |
| `invoiced` | 2 |
| `shipped` | 1 |
| **Total** | **775** |

No `delivered` order lacks items, so there is no capture defect among fulfilled orders. The 767 `unavailable` and `canceled` orders account for 99.0% of the group. Excluding these orders from item-based revenue is defensible, and only the single `shipped` order could still produce items later. All 775 stay in order-count KPIs so order totals continue to reconcile.

### 2. The single order without a payment

```sql
SELECT o.order_id, o.order_status, o.order_purchase_timestamp,
       oi.items, oi.item_value
FROM olist.orders AS o
LEFT JOIN olist.order_payments AS p ON p.order_id = o.order_id
LEFT JOIN (
    SELECT order_id, COUNT(*) AS items, SUM(price) AS item_value
    FROM olist.order_items
    GROUP BY order_id
) AS oi ON oi.order_id = o.order_id
WHERE p.order_id IS NULL;
```

**Result (confirmed).**

| `order_id` | `order_status` | `order_purchase_timestamp` | `items` | `item_value` |
| --- | --- | --- | ---: | ---: |
| `bfbd0f9bdef84302105ad712db648a6c` | `delivered` | 2016-09-15 12:16:38 | 3 | 134.97 |

The order carries merchandise value with no payment row at all, so it is the item-value-without-payment case. It is excluded from payment-based measures and recorded as an exclusion, while remaining in delivered-order and item-revenue counts. It also accounts for the entire delivered revenue of 2016-09, which is why that month shows a single order worth R$ 134.97.

### 3. How to handle conflicting review scores

```sql
SELECT r.order_id, COUNT(*) AS review_rows,
       COUNT(DISTINCT r.review_score) AS distinct_scores,
       GROUP_CONCAT(r.review_score
                    ORDER BY r.review_creation_date, r.review_answer_timestamp) AS scores,
       MIN(r.review_creation_date) AS first_created,
       MAX(r.review_answer_timestamp) AS last_answered
FROM olist.order_reviews AS r
GROUP BY r.order_id
HAVING COUNT(DISTINCT r.review_score) > 1
ORDER BY distinct_scores DESC, review_rows DESC;
```

**Result (confirmed).** The counts behind the rule come from this aggregate query:

```sql
WITH conflicting AS (
    SELECT order_id
    FROM olist.order_reviews
    GROUP BY order_id
    HAVING COUNT(DISTINCT review_score) > 1
),
latest AS (
    SELECT r.order_id, MAX(r.review_answer_timestamp) AS last_ts
    FROM olist.order_reviews AS r
    JOIN conflicting AS c ON c.order_id = r.order_id
    GROUP BY r.order_id
),
tied_latest AS (
    SELECT r.order_id
    FROM olist.order_reviews AS r
    JOIN latest AS l ON l.order_id = r.order_id
                    AND r.review_answer_timestamp = l.last_ts
    GROUP BY r.order_id
    HAVING COUNT(DISTINCT r.review_score) > 1
),
no_answer AS (
    SELECT DISTINCT r.order_id
    FROM olist.order_reviews AS r
    JOIN conflicting AS c ON c.order_id = r.order_id
    WHERE r.review_answer_timestamp IS NULL
)
SELECT
    (SELECT COUNT(*) FROM conflicting) AS conflicting_orders,
    (SELECT COUNT(*) FROM no_answer)   AS with_no_answer_timestamp,
    (SELECT COUNT(*) FROM tied_latest) AS with_differing_scores_at_latest_ts;
```

| Conflicting orders | No answer timestamp | Differing scores at latest timestamp |
| ---: | ---: | ---: |
| 202 | 0 | 0 |

The latest valid answered score rule therefore resolves all 202 orders without a tie: no order needs a fallback for a missing answer timestamp, and no order has two different scores sharing its most recent answer timestamp. The rule is defined in [Product Metrics](03_product_metrics.md#97-review-score-selection-for-order-level-analysis) and applied in `sql/order_level_dataset.sql`.

Reconciling the remaining eight MySQL row counts with the original CSVs stays outstanding but sits outside these three checks.

## Reproduce

Run [sql/data_exploration.sql](../sql/data_exploration.sql) against the imported `olist` schema. Sections 02–07 cover schema, counts, missingness, review multiplicity, date coverage, and numeric ranges. Sections 08–10 cover observed matches, relationship cardinality, and postal-prefix coverage.
