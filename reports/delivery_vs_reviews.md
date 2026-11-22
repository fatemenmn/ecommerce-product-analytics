# Delivery delays and customer review scores

## Finding

Among orders with a valid review score, 62.42% of late deliveries
received a score of 1 or 2, compared with 9.27% of on-time deliveries.
The gap was 53.15 percentage points. The average score was 2.27
for late deliveries and 4.29 for on-time deliveries.

| Delivery timing | Eligible orders | Reviewed orders | Review coverage | Average score | Share rated 1–2 |
| --- | ---: | ---: | ---: | ---: | ---: |
| On time | 89,936 | 89,443 | 99.45% | 4.29 | 9.27% |
| Late | 6,534 | 6,381 | 97.66% | 2.27 | 62.42% |

## Method and validation

- Deliveries on or before the estimated calendar date count as on time.
- Each order contributes its latest valid answered review score, if available.
- The share rated 1–2 uses reviewed orders as its denominator. Review
  coverage uses all eligible orders in each group.
- The gap is the late rate minus the on-time rate, rounded after subtraction.
- Both MySQL reconciliation checks passed. The 96,470 eligible orders
  include 95,824 reviewed and 646 unreviewed orders.
- This is an observed association among reviewed orders. Review coverage
  was lower for late deliveries.

## Reproduce

Run [delivery_vs_reviews.sql](../sql/delivery_vs_reviews.sql) against
the MySQL `olist` database to reproduce the comparison and reconciliation.
