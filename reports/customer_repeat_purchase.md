# Customer repeat purchase

## Result 1 — Observed history across the dataset

| Metric | Value |
| --- | ---: |
| Unique buyers with at least one delivered order | 93,358 |
| Buyers with at least two delivered orders | 2,801 |
| Lifetime repeat buyer rate (4.2) | 3.00% |
| Average delivered orders per buyer | 1.033 |
| Total delivered orders | 96,478 |
| Most delivered orders placed by one buyer | 15 |
| Median days from first to second purchase (repeat buyers) | 29.0 |
| Mean days from first to second purchase (repeat buyers) | 81.2 |

## Result 2 — 90-day repeat purchase by first-purchase month

| First-purchase month | Cohort size | Second purchase within 90 days | 90-day repeat rate |
| --- | ---: | ---: | ---: |
| 2017-01 | 717 | 26 | 3.63% |
| 2017-02 | 1,628 | 28 | 1.72% |
| 2017-03 | 2,503 | 62 | 2.48% |
| 2017-04 | 2,256 | 48 | 2.13% |
| 2017-05 | 3,451 | 98 | 2.84% |
| 2017-06 | 3,037 | 86 | 2.83% |
| 2017-07 | 3,752 | 97 | 2.59% |
| 2017-08 | 4,057 | 112 | 2.76% |
| 2017-09 | 4,004 | 114 | 2.85% |
| 2017-10 | 4,328 | 97 | 2.24% |
| 2017-11 | 7,060 | 164 | 2.32% |
| 2017-12 | 5,338 | 92 | 1.72% |
| 2018-01 | 6,842 | 149 | 2.18% |
| 2018-02 | 6,288 | 188 | 2.99% |
| 2018-03 | 6,774 | 134 | 1.98% |
| 2018-04 | 6,582 | 112 | 1.70% |
| 2018-05 | 6,506 | 105 | 1.61% |
| 2018-06 | 316 | 6 | 1.90% |
| **Total** | **75,439** | **1,718** | **2.28%** |

**Reporting cutoff.** The observation window ends at the end of 2018-08-31 (23:59:59). A buyer
needs a complete 90-day follow-up, so only first purchases on or before 2018-06-02 23:59:59
are eligible. July and August 2018 cohorts therefore have no eligible buyers and are absent,
and the June 2018 cohort only includes buyers whose first purchase fell on or before June 2.

**Denominator.** Cohort size counts buyers whose first delivered purchase fell in that month
and who have a complete 90-day window. The numerator counts those same buyers if their second
delivered purchase occurred at most 90 days after the first. Numerator and denominator use the
same population.

## Definitions

| Term | Definition |
| --- | --- |
| Buyer | `customer_unique_id` (metric governance 9.1); orders are linked through `customer_id` |
| Delivered order | `order_status = 'delivered'` with a non-missing `order_purchase_timestamp` |
| Order sequence | Each buyer's delivered orders ordered by `order_purchase_timestamp`, then `order_id` to break ties |
| Lifetime repeat buyer rate | Buyers with ≥2 delivered orders ÷ buyers with ≥1 delivered order × 100 (4.2) |
| Time to second purchase | Days between the first and second delivered purchase timestamps, across buyers with ≥2 delivered orders (4.4) |
| 90-day repeat rate | Eligible buyers with a second delivered purchase ≤90 days after the first ÷ eligible first-time buyers × 100 (4.3, generalised from 30 to 90 days) |

First purchase means the buyer's first **observed** delivered purchase anywhere in this dataset,
not their first purchase in reality. Cohort assignment uses all earlier observed history, so a
buyer whose first order predates January 2017 is not treated as a new 2017 buyer.

## QA and reconciliation

| Check | Value | Expected | Status |
| --- | ---: | ---: | --- |
| Delivered orders in source | 96,478 | 96,478 | ✅ |
| Delivered orders used | 96,478 | 96,478 | ✅ |
| Excluded: missing purchase timestamp | 0 | 0 | ✅ |
| Excluded: no matching customer row | 0 | 0 | ✅ |
| Distinct buyers, independent query | 93,358 | 93,358 | ✅ |
| Distinct buyers, analysis CTE | 93,358 | 93,358 | ✅ |
| Deliveries accounted for by buyer history | 96,478 | 96,478 | ✅ |

The repeat count never exceeds the eligible buyer count: 2,801 ≤ 93,358 overall, and every
cohort returns `repeat_within_cohort = 1` (second purchases ≤ cohort size in all 18 months).

Cohort exclusions, which reconcile to the 93,358 total buyer count:

| Group | Buyers |
| --- | ---: |
| First purchase before 2017-01 (outside reporting period) | 264 |
| In-period first purchase without a complete 90-day window (after 2018-06-02) | 17,655 |
| Eligible for a cohort | 75,439 |
| **Total** | **93,358** |

## Limitations

- **The median describes buyers who returned.** 29 days is the median only across the 2,801
  buyers who made a second delivered purchase. The typical buyer in this dataset placed one
  delivered order, so this median is not the time a typical buyer takes to return.
- **The mean shows the tail.** The mean of 81.2 days is far above the 29-day median, so return
  intervals are right-skewed: most returning buyers come back within about a month, while a
  few return much later.
- **First purchase is first observed purchase.** Orders before 2016-09 or after 2018-10 are not
  in the dataset, so a buyer who purchased before the window looks like a first-time buyer
  inside it.
- **Delivered orders only.** Canceled and unavailable orders are excluded, so returns, refunds
  and failed checkouts do not appear. A buyer whose first order was canceled is counted here
  from their first delivered order.
- **Observation truncation.** Buyers late in the window are excluded rather than given a
  partial window, which removes July and August 2018 cohorts entirely and most of June 2018.
  Cohort sizes are not comparable at the edge of the period.
- **This is an observed-window measure.** Buyers with one delivered order may purchase again
  after 2018-10; the data cannot show that.

## Findings

**Repeat purchasing is rare in the observed window.** Only 3.00% of the 93,358 buyers placed
two or more delivered orders, and the 96,478 delivered orders spread across those buyers come
to 1.033 per buyer. Marketplace volume therefore rests almost entirely on buyers who order
once.

**Short-term repeat rates are low and flat.** Among 75,439 new buyers with a complete 90-day
window, 2.28% made a second delivered purchase within 90 days. Monthly rates ranged from 1.61%
in May 2018 to 3.63% in January 2017, with no sustained upward or downward movement across the
18 cohorts, so the data does not show repeat purchasing improving as the marketplace matured.

## Reproduce

Run [customer_repeat_purchase.sql](../sql/customer_repeat_purchase.sql) against the MySQL
`olist` database. The script returns the observed-history summary, the cohort table, and the QA
reconciliation block in that order.
