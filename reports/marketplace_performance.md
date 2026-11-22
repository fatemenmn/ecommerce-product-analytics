# Monthly marketplace performance

## Result table

Reporting month is the order purchase month. Amounts are in BRL.

| Month | Placed orders | Delivered orders | Delivered with items | Canceled orders | Delivered GMV | AOV | Cancellation rate |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2016-09 | 4 | 1 | 1 | 2 | 134.97 | 134.97 | 50.00% |
| 2016-10 | 324 | 265 | 265 | 24 | 40,325.11 | 152.17 | 7.41% |
| 2016-12 | 1 | 1 | 1 | 0 | 10.90 | 10.90 | 0.00% |
| 2017-01 | 800 | 750 | 750 | 3 | 111,798.36 | 149.06 | 0.38% |
| 2017-02 | 1,780 | 1,653 | 1,653 | 17 | 234,223.40 | 141.70 | 0.96% |
| 2017-03 | 2,682 | 2,546 | 2,546 | 33 | 359,198.85 | 141.08 | 1.23% |
| 2017-04 | 2,404 | 2,303 | 2,303 | 18 | 340,669.68 | 147.92 | 0.75% |
| 2017-05 | 3,700 | 3,546 | 3,546 | 29 | 489,338.25 | 138.00 | 0.78% |
| 2017-06 | 3,245 | 3,135 | 3,135 | 16 | 421,923.37 | 134.58 | 0.49% |
| 2017-07 | 4,026 | 3,872 | 3,872 | 28 | 481,604.52 | 124.38 | 0.70% |
| 2017-08 | 4,331 | 4,193 | 4,193 | 27 | 554,699.70 | 132.29 | 0.62% |
| 2017-09 | 4,285 | 4,150 | 4,150 | 20 | 607,399.67 | 146.36 | 0.47% |
| 2017-10 | 4,631 | 4,478 | 4,478 | 26 | 648,247.65 | 144.76 | 0.56% |
| 2017-11 | 7,544 | 7,289 | 7,289 | 37 | 987,765.37 | 135.51 | 0.49% |
| 2017-12 | 5,673 | 5,513 | 5,513 | 11 | 726,033.19 | 131.69 | 0.19% |
| 2018-01 | 7,269 | 7,069 | 7,069 | 34 | 924,645.00 | 130.80 | 0.47% |
| 2018-02 | 6,728 | 6,555 | 6,555 | 73 | 826,437.13 | 126.08 | 1.09% |
| 2018-03 | 7,211 | 7,003 | 7,003 | 26 | 953,356.25 | 136.14 | 0.36% |
| 2018-04 | 6,939 | 6,798 | 6,798 | 15 | 973,534.09 | 143.21 | 0.22% |
| 2018-05 | 6,873 | 6,749 | 6,749 | 24 | 977,544.69 | 144.84 | 0.35% |
| 2018-06 | 6,167 | 6,099 | 6,099 | 18 | 856,077.86 | 140.36 | 0.29% |
| 2018-07 | 6,292 | 6,159 | 6,159 | 41 | 867,953.46 | 140.92 | 0.65% |
| 2018-08 | 6,512 | 6,351 | 6,351 | 84 | 838,576.64 | 132.04 | 1.29% |
| 2018-09 | 16 | 0 | 0 | 15 | 0.00 | NULL | 93.75% |
| 2018-10 | 4 | 0 | 0 | 4 | 0.00 | NULL | 100.00% |
| **Total** | **99,441** | **96,478** | **96,478** | **625** | **13,221,498.11** | **137.04** | **0.63%** |

**Partial months.** September 2016 and December 2016 contain 4 and 1 placed orders, and
September 2018 and October 2018 contain 16 and 4. These sit at the edges of the observed
window (first purchase 2016-09-04, last 2018-10-17), so their rates are not comparable
with full months: the two 2018 months have no delivered orders at all, which is why AOV is
NULL and the cancellation rate reads 93.75% and 100.00%. November 2016 has no orders and
therefore no row. Trends and month-to-month comparisons below use the 20 full months from
2017-01 to 2018-08.

## KPI definitions and denominators

| Metric | Definition | Denominator |
| --- | --- | --- |
| Reporting month | `DATE_FORMAT(order_purchase_timestamp, '%Y-%m')` | one row per purchase month |
| Placed orders | orders with a purchase timestamp in the month | not applicable; this is the base count |
| Delivered orders | orders in the month with `order_status = 'delivered'` | not applicable |
| Delivered orders with items | delivered orders that also have at least one `order_items` row | not applicable |
| Canceled orders | orders in the month with `order_status = 'canceled'` | not applicable |
| Delivered GMV (BRL) | sum of `order_items.price` across delivered orders in the month | freight excluded |
| AOV (BRL) | `delivered_gmv / delivered_orders_with_items` | delivered orders **with items** |
| Cancellation rate | `canceled_orders / placed_orders × 100` | all placed orders |

Attribution uses the purchase month, not the delivery month, so an order counts in the month
it was placed even if it is delivered later or never delivered.

## Validation

Monthly output was compared with independent queries against `olist.orders` and
`olist.order_items`, and with the previously validated snapshot.

| Measure | Monthly table total | Independent source query | Snapshot | Match |
| --- | ---: | ---: | ---: | --- |
| Months represented | 25 | 25 distinct purchase months | — | ✅ |
| Placed orders | 99,441 | 99,441 | 99,441 | ✅ |
| Delivered orders | 96,478 | 96,478 | 96,478 | ✅ |
| Delivered orders with items | 96,478 | 96,478 | — | ✅ |
| Canceled orders | 625 | 625 | 625 | ✅ |
| Delivered GMV | 13,221,498.11 | 13,221,498.11 | 13,221,498.11 | ✅ |

Delivered orders equal delivered orders with items in every month, which is consistent with
the earlier validation result that all 775 itemless orders carry a non-delivered status.

Overall figures derived from the reconciled totals: AOV **R$ 137.04**
(13,221,498.11 / 96,478) and cancellation rate **0.63%** (625 / 99,441).

## Findings

**Volume drove growth; basket size stayed flat.** Delivered GMV rose from R$ 111,798 in
January 2017 to R$ 924,645 in January 2018, while AOV moved only between R$ 124.38 and
R$ 152.17 across the full months and settled at R$ 137.04 overall. Growth therefore came
from more orders, not from larger baskets, which makes order acquisition and repeat
purchasing the levers that matter for revenue.

**November 2017 is the clear peak.** With 7,544 placed orders and R$ 987,765.37 in delivered
GMV, it is the largest month and about 7.5% of all delivered GMV, roughly 1.6 times the
September 2017 level. Cancellation stayed at 0.49% that month, so the peak was absorbed
without a visible operational penalty in this metric, although delivery timing is the better
test for peak-period strain.

Cancellation is low and stable overall (0.63%), ranging from 0.19% in December 2017 to
1.29% in August 2018 among full months. That range is narrow enough that cancellations are
not a material driver of the revenue trend, but the August 2018 uptick is worth monitoring
rather than treating as structural.

## Reproduce

Run [marketplace_performance.sql](../sql/marketplace_performance.sql) against the MySQL
`olist` database to reproduce the monthly table, and use the validation queries above to
confirm the totals.
