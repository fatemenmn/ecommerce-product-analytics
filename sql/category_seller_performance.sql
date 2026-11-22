-- ============================================================
-- category_seller_performance.sql — read-only analysis (no DDL, no writes)
--
-- Definitions follow docs/03_product_metrics.md:
--   * 7.1 Delivered GMV by Category
--   * 7.3 Delivered GMV by Seller
--   * 7.4 Top 5% Seller GMV Share
--
-- Base population: delivered order items. GMV is the sum of `price` and
-- excludes freight. The grain stays one row per (order_id, order_item_id)
-- through every join; `products` and `sellers` are joined on their primary
-- keys, so they cannot multiply item rows.
--
-- Category labels:
--   * English name when a translation exists.
--   * Original Portuguese name when no translation exists.
--   * '(no category)' when the product record has no category.
--   * '(missing product record)' when the item has no matching product row.
--
-- Category order counts overlap: an order with items from several categories
-- is counted once in each of those categories, so `delivered_orders` sums to
-- more than the number of delivered orders. See 7.2 notes.
--
-- Run:  mysql -u root --database=olist --table < sql/category_seller_performance.sql
-- ============================================================

USE olist;

-- ------------------------------------------------------------
-- Result 1 — Delivered GMV by category
-- ------------------------------------------------------------
WITH delivered_items AS (
    SELECT oi.order_id,
           oi.order_item_id,
           oi.product_id,
           oi.price
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
),
categorized AS (
    SELECT di.order_id,
           di.order_item_id,
           di.price,
           CASE
               WHEN p.product_id IS NULL THEN '(missing product record)'
               WHEN p.product_category_name IS NULL THEN '(no category)'
               ELSE COALESCE(t.product_category_name_english,
                             p.product_category_name)
           END AS category_name
    FROM delivered_items AS di
    LEFT JOIN olist.products AS p ON p.product_id = di.product_id
    LEFT JOIN olist.product_category_name_translation AS t
           ON t.product_category_name = p.product_category_name
)
SELECT
    category_name,
    COUNT(*)                                                  AS item_count,
    COUNT(DISTINCT order_id)                                  AS delivered_orders,
    ROUND(SUM(price), 2)                                      AS delivered_gmv_brl,
    ROUND(100.0 * SUM(price) / SUM(SUM(price)) OVER (), 2)    AS gmv_share_pct
FROM categorized
GROUP BY category_name
ORDER BY SUM(price) DESC, category_name;

-- ------------------------------------------------------------
-- Result 2 — Category concentration
-- Top 5 and top 10 category shares, calculated from unrounded GMV and
-- rounded once. Ranking ties are broken by category_name so the cut is
-- deterministic. The denominator is total delivered GMV.
-- ------------------------------------------------------------
WITH delivered_items AS (
    SELECT oi.order_id,
           oi.order_item_id,
           oi.product_id,
           oi.price
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
),
categorized AS (
    SELECT di.order_id,
           di.order_item_id,
           di.price,
           CASE
               WHEN p.product_id IS NULL THEN '(missing product record)'
               WHEN p.product_category_name IS NULL THEN '(no category)'
               ELSE COALESCE(t.product_category_name_english,
                             p.product_category_name)
           END AS category_name
    FROM delivered_items AS di
    LEFT JOIN olist.products AS p ON p.product_id = di.product_id
    LEFT JOIN olist.product_category_name_translation AS t
           ON t.product_category_name = p.product_category_name
),
category_agg AS (
    SELECT category_name,
           SUM(price) AS delivered_gmv_brl
    FROM categorized
    GROUP BY category_name
),
ranked AS (
    SELECT category_name,
           delivered_gmv_brl,
           ROW_NUMBER() OVER (ORDER BY delivered_gmv_brl DESC, category_name)
               AS category_rank,
           COUNT(*) OVER () AS category_count
    FROM category_agg
)
SELECT
    MAX(category_count)                                         AS categories_with_delivered_items,
    ROUND(100.0 * SUM(CASE WHEN category_rank <= 5
                           THEN delivered_gmv_brl END)
          / SUM(delivered_gmv_brl), 2)                          AS top5_category_gmv_share_pct,
    ROUND(100.0 * SUM(CASE WHEN category_rank <= 10
                           THEN delivered_gmv_brl END)
          / SUM(delivered_gmv_brl), 2)                          AS top10_category_gmv_share_pct,
    ROUND(SUM(delivered_gmv_brl), 2)                            AS total_delivered_gmv_brl
FROM ranked;

-- ------------------------------------------------------------
-- Result 3 — Delivered GMV by seller, ranked by delivered GMV
-- Ties are broken by seller_id so the ranking is deterministic.
-- ------------------------------------------------------------
WITH delivered_items AS (
    SELECT oi.order_id,
           oi.order_item_id,
           oi.seller_id,
           oi.price
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
),
seller_joined AS (
    SELECT di.order_id,
           di.order_item_id,
           di.seller_id,
           s.seller_state,
           di.price
    FROM delivered_items AS di
    LEFT JOIN olist.sellers AS s ON s.seller_id = di.seller_id
),
seller_agg AS (
    SELECT seller_id,
           COUNT(*)                AS item_count,
           COUNT(DISTINCT order_id) AS delivered_orders,
           SUM(price)              AS delivered_gmv_brl
    FROM seller_joined
    GROUP BY seller_id
)
SELECT
    seller_id,
    item_count,
    delivered_orders,
    ROUND(delivered_gmv_brl, 2) AS delivered_gmv_brl,
    ROUND(100.0 * delivered_gmv_brl
          / SUM(delivered_gmv_brl) OVER (), 2)  AS gmv_share_pct,
    ROW_NUMBER() OVER (ORDER BY delivered_gmv_brl DESC, seller_id) AS seller_rank
FROM seller_agg
ORDER BY seller_rank;

-- ------------------------------------------------------------
-- Result 4 — Seller concentration
-- Top 5% uses CEIL(0.05 × sellers with delivered items), rounded up.
-- The denominator for every share is total delivered GMV.
-- ------------------------------------------------------------
WITH delivered_items AS (
    SELECT oi.order_id,
           oi.seller_id,
           oi.price
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
),
seller_agg AS (
    SELECT seller_id, SUM(price) AS delivered_gmv_brl
    FROM delivered_items
    GROUP BY seller_id
),
ranked AS (
    SELECT seller_id,
           delivered_gmv_brl,
           ROW_NUMBER() OVER (ORDER BY delivered_gmv_brl DESC, seller_id) AS seller_rank,
           COUNT(*) OVER () AS seller_count
    FROM seller_agg
),
cutoffs AS (
    SELECT
        MAX(seller_count)                    AS sellers_with_delivered_items,
        CEIL(0.05 * MAX(seller_count))       AS top5pct_seller_count
    FROM ranked
)
SELECT
    c.sellers_with_delivered_items,
    10                                                    AS top10_seller_count,
    ROUND(100.0 * SUM(CASE WHEN r.seller_rank <= 10
                           THEN r.delivered_gmv_brl END)
          / SUM(r.delivered_gmv_brl), 2)                  AS top10_gmv_share_pct,
    c.top5pct_seller_count,
    ROUND(100.0 * SUM(CASE WHEN r.seller_rank <= c.top5pct_seller_count
                           THEN r.delivered_gmv_brl END)
          / SUM(r.delivered_gmv_brl), 2)                  AS top5pct_gmv_share_pct,
    ROUND(SUM(r.delivered_gmv_brl), 2)                    AS total_delivered_gmv_brl
FROM ranked AS r
CROSS JOIN cutoffs AS c
GROUP BY c.sellers_with_delivered_items, c.top5pct_seller_count;

-- ------------------------------------------------------------
-- Result 5 — QA and reconciliation
-- ------------------------------------------------------------
WITH delivered_items AS (
    SELECT oi.order_id,
           oi.order_item_id,
           oi.product_id,
           oi.seller_id,
           oi.price
    FROM olist.order_items AS oi
    JOIN olist.orders AS o ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
),
categorized AS (
    SELECT di.order_id,
           di.order_item_id,
           di.price,
           CASE
               WHEN p.product_id IS NULL THEN '(missing product record)'
               WHEN p.product_category_name IS NULL THEN '(no category)'
               ELSE COALESCE(t.product_category_name_english,
                             p.product_category_name)
           END AS category_name,
           CASE WHEN p.product_category_name IS NOT NULL
                     AND t.product_category_name_english IS NULL
                THEN 1 ELSE 0 END AS untranslated_fallback
    FROM delivered_items AS di
    LEFT JOIN olist.products AS p ON p.product_id = di.product_id
    LEFT JOIN olist.product_category_name_translation AS t
           ON t.product_category_name = p.product_category_name
),
seller_joined AS (
    SELECT di.order_id,
           di.order_item_id,
           di.price,
           di.seller_id,
           s.seller_id AS matched_seller_id
    FROM delivered_items AS di
    LEFT JOIN olist.sellers AS s ON s.seller_id = di.seller_id
),
category_shares AS (
    SELECT 100.0 * SUM(price) / SUM(SUM(price)) OVER () AS share_raw,
           ROUND(100.0 * SUM(price) / SUM(SUM(price)) OVER (), 2) AS share_rounded
    FROM categorized
    GROUP BY category_name
),
seller_shares AS (
    SELECT 100.0 * SUM(price) / SUM(SUM(price)) OVER () AS share_raw,
           ROUND(100.0 * SUM(price) / SUM(SUM(price)) OVER (), 2) AS share_rounded
    FROM seller_joined
    GROUP BY seller_id
)
SELECT
    (SELECT COUNT(*) FROM delivered_items)                     AS delivered_item_rows,
    (SELECT COUNT(*) FROM categorized)                         AS rows_after_category_join,
    (SELECT COUNT(*) FROM seller_joined)                       AS rows_after_seller_join,
    (SELECT COUNT(DISTINCT order_id, order_item_id)
       FROM delivered_items)                                   AS distinct_item_keys,
    (SELECT ROUND(SUM(price), 2)
       FROM olist.order_items AS oi
       JOIN olist.orders AS o ON o.order_id = oi.order_id
      WHERE o.order_status = 'delivered')                      AS independent_delivered_gmv,
    (SELECT ROUND(SUM(price), 2) FROM categorized)             AS category_gmv_total,
    (SELECT ROUND(SUM(price), 2) FROM seller_joined)           AS seller_gmv_total,
    (SELECT SUM(category_name = '(no category)') FROM categorized)
                                                               AS items_no_category,
    (SELECT SUM(category_name = '(missing product record)') FROM categorized)
                                                               AS items_missing_product,
    (SELECT SUM(untranslated_fallback) FROM categorized)       AS items_untranslated_original,
    (SELECT COUNT(*) FROM seller_joined
      WHERE matched_seller_id IS NULL)                         AS items_missing_seller,
    (SELECT ROUND(SUM(share_raw), 6) FROM category_shares)     AS category_share_sum_raw,
    (SELECT ROUND(SUM(share_rounded), 2) FROM category_shares) AS category_share_sum_rounded,
    (SELECT ROUND(SUM(share_raw), 6) FROM seller_shares)       AS seller_share_sum_raw,
    (SELECT ROUND(SUM(share_rounded), 2) FROM seller_shares)   AS seller_share_sum_rounded;
