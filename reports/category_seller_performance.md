# Category and seller performance

Base population: delivered order items, with GMV computed from `order_items.price` and freight
excluded. The grain stays one row per `(order_id, order_item_id)` through every join.

## Category results

| Category | Item count | Delivered orders | Delivered GMV (BRL) | GMV share |
| --- | ---: | ---: | ---: | ---: |
| health_beauty | 9,465 | 8,647 | 1,233,131.72 | 9.33% |
| watches_gifts | 5,859 | 5,495 | 1,166,176.98 | 8.82% |
| bed_bath_table | 10,953 | 9,272 | 1,023,434.76 | 7.74% |
| sports_leisure | 8,431 | 7,530 | 954,852.55 | 7.22% |
| computers_accessories | 7,644 | 6,530 | 888,724.61 | 6.72% |
| furniture_decor | 8,160 | 6,307 | 711,927.69 | 5.38% |
| housewares | 6,795 | 5,743 | 615,628.69 | 4.66% |
| cool_stuff | 3,718 | 3,559 | 610,204.10 | 4.62% |
| auto | 4,140 | 3,810 | 578,966.65 | 4.38% |
| toys | 4,030 | 3,804 | 471,286.48 | 3.56% |
| garden_tools | 4,268 | 3,448 | 470,495.28 | 3.56% |
| baby | 2,982 | 2,809 | 400,421.84 | 3.03% |
| perfumery | 3,340 | 3,086 | 390,144.65 | 2.95% |
| telephony | 4,430 | 4,093 | 309,860.23 | 2.34% |
| office_furniture | 1,668 | 1,254 | 268,154.31 | 2.03% |
| **(no category)** | **1,537** | **1,392** | **170,726.63** | **1.29%** |
| All 74 categories | 110,197 | — | 13,221,498.11 | 100.00% |

The full result set returns all 74 labels sorted by GMV. **Category order counts overlap:** an
order that contains items from several categories is counted once in each of those categories,
so `delivered_orders` sums to far more than the number of delivered orders and must not be
added across rows. The same overlap applies to any rate built on those counts (metric 7.2). Only
item counts and GMV are additive.

**Category labels.** English names are used where a translation exists. Products whose category
has no English translation keep the original Portuguese label (22 delivered items). Products
with no category at all are grouped under `(no category)` (1,537 delivered items) instead of
being dropped; there were no delivered items whose product record was missing.

## Seller results

| Measure | Value |
| --- | ---: |
| Sellers with at least one delivered item | 2,970 |
| GMV share of the top 10 sellers | 13.27% |
| Top 5% seller count, `CEIL(0.05 × 2,970)` | 149 |
| GMV share of the top 5% of sellers (149) | 53.06% |
| Total delivered GMV (denominator) | R$ 13,221,498.11 |

| Rank | Seller | Item count | Delivered orders | Delivered GMV (BRL) | GMV share |
| ---: | --- | ---: | ---: | ---: | ---: |
| 1 | `4869f7a5dfa277a7dca6462dcf3b52b2` | 1,148 | 1,124 | 226,987.93 | 1.72% |
| 2 | `53243585a1d6dc2643021fd1853d8905` | 400 | 348 | 217,940.44 | 1.65% |
| 3 | `4a3ca9315b744ce9f8e9374361493884` | 1,949 | 1,772 | 196,882.12 | 1.49% |
| 4 | `fa1c13f2614d7b5c4749cbc52fecda94` | 579 | 578 | 190,917.14 | 1.44% |
| 5 | `7c67e1448b00f6e969d365cea6b010ab` | 1,355 | 973 | 186,570.05 | 1.41% |
| 6 | `7e93a43ef30c4f03f38b393420bc753a` | 322 | 319 | 165,981.49 | 1.26% |
| 7 | `da8622b14eb17ae2831f4ac5b9dab84a` | 1,548 | 1,311 | 159,816.87 | 1.21% |
| 8 | `7a67c85e85bb2ce8582c35f2203ad736` | 1,155 | 1,145 | 139,658.69 | 1.06% |
| 9 | `1025f0e2d44d7041d6cf58b6550e0bfa` | 1,420 | 910 | 138,208.56 | 1.05% |
| 10 | `955fee9216a65b617aa5c0531780ce60` | 1,472 | 1,261 | 131,836.71 | 1.00% |

The seller result set returns every seller with delivered items, ranked by delivered GMV with
`seller_id` breaking ties, so the ranking is deterministic. Seller order counts do not overlap
the way category counts do: an item belongs to exactly one seller.

## Definitions and denominators

| Term | Definition |
| --- | --- |
| Delivered item row | one `(order_id, order_item_id)` whose order has `order_status = 'delivered'` |
| Delivered GMV | sum of `order_items.price` for delivered item rows; freight excluded (7.1, 7.3) |
| Category GMV share | category GMV ÷ total delivered GMV × 100 |
| Seller GMV share | seller GMV ÷ total delivered GMV × 100 |
| Top 10 seller share | GMV of sellers ranked 1–10 ÷ total delivered GMV × 100 |
| Top 5% seller share | GMV of the first `CEIL(0.05 × sellers with delivered items)` = 149 sellers ÷ total delivered GMV × 100 (7.4) |

All shares use total delivered GMV (R$ 13,221,498.11) as the denominator and are calculated from
unrounded values, then rounded once for display.

## QA and reconciliation

| Check | Result | Expected | Status |
| --- | ---: | ---: | --- |
| Delivered item rows (base) | 110,197 | 110,197 | ✅ |
| Rows after the category joins | 110,197 | no change | ✅ |
| Rows after the seller join | 110,197 | no change | ✅ |
| Distinct `(order_id, order_item_id)` | 110,197 | 110,197 | ✅ |
| Independent delivered GMV | 13,221,498.11 | 13,221,498.11 | ✅ |
| Category GMV total | 13,221,498.11 | 13,221,498.11 | ✅ |
| Seller GMV total | 13,221,498.11 | 13,221,498.11 | ✅ |
| Items with no category | 1,537 | reported, not dropped | ✅ |
| Items with a missing product record | 0 | 0 | ✅ |
| Items with a missing seller | 0 | 0 | ✅ |
| Items keeping the Portuguese label | 22 | reported | ✅ |
| Category share sum, unrounded | 100.000000 | 100 | ✅ |
| Seller share sum, unrounded | 100.000001 | 100 | ✅ |
| Category share sum, sum of rounded values | 99.96 | ≈100 | ✅ |
| Seller share sum, sum of rounded values | 98.81 | ≈100 | ✅ |

No mismatches. Both GMV totals equal the independent source query to the cent, and the joins
add and drop nothing: 110,197 rows before, after the category joins, and after the seller join,
with 110,197 distinct item keys.

The two "sum of rounded" figures are **presentation drift, not a data error**. Each row is
rounded to two decimals before summing, so 74 rounded category shares total 99.96 and 2,970
rounded seller shares total 98.81. The unrounded shares sum to 100 (the seller figure shows
100.000001 from floating-point division). This is why shares are calculated before rounding.

The 2,453 item rows that are absent from the base belong to orders that are not delivered
(112,650 total item rows − 110,197 delivered item rows), which is the intended population
filter rather than a join loss.

## Limitations

- **Category order counts overlap.** Orders with items in multiple categories appear in each
  category, so `delivered_orders` and any category rate cannot be summed to a marketplace total
  (7.2).
- **GMV is merchandise value, not revenue.** It is the sum of item prices: not profit, not
  Olist commission, and not net of refunds.
- **Delivered orders only.** Canceled, unavailable, shipped, and in-process orders are excluded,
  so category and seller shares describe realised sales, not demand.
- **Unknown categories remain visible.** The 1,537 uncategorised items (R$ 170,726.63, 1.29% of
  GMV) sit in their own row; interpreting category mix without that row would overstate the
  named categories.
- **Ties in seller ranking.** Ranking uses GMV descending with `seller_id` ascending, so sellers
  with identical GMV are ordered by ID rather than by any business criterion. The top-5% cut at
  149 sellers could change with a different tie rule if it falls on a tied pair.
- **Concentration is not risk.** Top-5% GMV share measures sales concentration in the observed
  window; it is not a measure of platform dependency or seller risk (7.4 note).

## Findings

**Category demand is broad but top-heavy at the head.** With 74 category labels, the ten largest
generate 62.43% of delivered GMV and the five largest 39.83%. `health_beauty` leads at
R$ 1,233,131.72 (9.33%), followed by `watches_gifts` (8.82%) and `bed_bath_table` (7.74%), so no
single category dominates.

**Seller activity is concentrated.** Of 2,970 sellers with delivered items, the top 10 account
for 13.27% of delivered GMV, and the top 5% (149 sellers) account for 53.06%. More than half of
delivered merchandise value therefore comes from one seller in twenty, while the remaining
2,821 sellers share the other 46.94%.

## Reproduce

Run [category_seller_performance.sql](../sql/category_seller_performance.sql) against the MySQL
`olist` database. The script returns the category table, the category concentration summary, the
full ranked seller table, the seller concentration summary, and the QA reconciliation block in
that order.
