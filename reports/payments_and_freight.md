# Payments and freight

Merchandise GMV is the sum of `order_items.price` and excludes freight. Recorded payment value
is the sum of `order_payments.payment_value`. The two are reported side by side and never
combined into one measure.

## Payment methods

| Payment method | Payment rows | Recorded payment value (BRL) | Value share | Record share | Distinct orders |
| --- | ---: | ---: | ---: | ---: | ---: |
| credit_card | 76,795 | 12,542,084.19 | 78.34% | 73.92% | 76,505 |
| boleto | 19,784 | 2,869,361.27 | 17.92% | 19.04% | 19,784 |
| voucher | 5,775 | 379,436.87 | 2.37% | 5.56% | 3,866 |
| debit_card | 1,529 | 217,989.79 | 1.36% | 1.47% | 1,528 |
| not_defined | 3 | 0.00 | 0.00% | 0.00% | 3 |
| **Total** | **103,886** | **16,008,872.12** | **100.00%** | **100.00%** | — |

**Distinct orders overlap.** One order can carry several payment records and several payment
types, so the `distinct_orders` column sums to 101,686, more than the 99,441 orders in the
dataset. Those counts must not be added to produce an order total. Value and record shares use
all 103,886 payment rows as their denominator and are computed from unrounded values.

This is a payment-record-level distribution (6.3). `not_defined` is a source label with three
rows and zero value.

## Installments and AOV

Population: 96,478 delivered orders that have at least one item row. Payment rows are
aggregated to one row per order before joining to item totals, so item rows and payment rows
cannot multiply each other.

| Installment group | Orders | Delivered merchandise GMV (BRL) | AOV (BRL) | Item value per item (BRL) | Freight (BRL) | Recorded payment value (BRL) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| single_installment | 46,814 | 4,678,581.96 | 99.94 | 88.74 | 948,965.11 | 5,627,476.69 |
| multi_installment | 49,661 | 8,542,651.90 | 172.02 | 148.65 | 1,249,242.69 | 9,794,796.45 |
| no_payment | 1 | 134.97 | 134.97 | 44.99 | 8.49 | NULL |
| no_valid_installments | 2 | 129.28 | 64.64 | 43.09 | 59.35 | 188.63 |
| **Total** | **96,478** | **13,221,498.11** | — | — | **2,198,275.64** | **15,422,461.77** |

Classification follows 6.5, using only payment rows with a **positive** installment count:

- `single_installment`: every valid payment row on the order has exactly 1 installment.
- `multi_installment`: at least one valid payment row has more than 1 installment.
- `no_payment`: the order has no payment row at all (1 order).
- `no_valid_installments`: payment rows exist but none has a positive count, so the order
  cannot be classified (2 orders, both credit card rows recorded with zero installments).

These two exception groups are reported separately rather than forced into a group. Together the
four groups hold exactly 96,478 orders and R$ 13,221,498.11 of merchandise GMV.

The payment column is the sum of recorded payment value for the same orders
(R$ 15,422,461.77). It is a different measure from merchandise GMV and a smaller population than
the R$ 16,008,872.12 all-status payment total, because it covers delivered orders only and one
order can have several payment rows.

## Freight

Population: 96,478 delivered orders with items, a positive total item value, and a non-missing
freight value.

| Measure | Value |
| --- | ---: |
| Eligible orders | 96,478 |
| Total freight (BRL) | 2,198,275.64 |
| Total merchandise value (BRL) | 13,221,498.11 |
| **Median order-level freight-to-item-value ratio** | **0.2244 (22.44%)** |
| **Total freight ÷ total merchandise value** | **0.1663 (16.63%)** |

These are two different statistics and must not be interchanged:

- **Median order ratio** is the median of each order's `freight / item value`, treating every
  order equally. It answers "what does a typical order pay in freight relative to its goods".
- **Aggregate ratio** is total freight divided by total merchandise value. It is value-weighted,
  so large orders dominate it.

The median (22.44%) is higher than the aggregate (16.63%) because orders with small item values
carry proportionally larger freight, and the aggregate weights by value rather than by order.

**Handling of missing and zero values.** Orders with zero or invalid total item value are
excluded from the ratio because it would divide by zero (0 orders). Orders with a missing freight
value are excluded (0 orders). Zero freight is **kept**, because a zero is a recorded shipping
charge, not a missing one.

## Definitions and denominators

| Term | Definition |
| --- | --- |
| Recorded payment value | sum of `order_payments.payment_value`; payment-record level |
| Value share | method payment value ÷ total recorded payment value × 100 |
| Record share | method payment rows ÷ all payment rows × 100 (6.3) |
| Valid payment row | a payment row with `payment_installments > 0` (6.4) |
| Single-installment order | all valid payment rows have exactly 1 installment (6.5) |
| Multi-installment order | at least one valid payment row has more than 1 installment (6.5) |
| AOV (installment group) | delivered merchandise GMV ÷ orders in the group (3.2, 6.5) |
| Median order freight ratio | median of per-order `freight / item value` (6.2) |
| Aggregate freight ratio | total freight ÷ total merchandise value (6.2) |

## QA and reconciliation

| Check | Result | Expected | Status |
| --- | ---: | ---: | --- |
| Independent payment total | 16,008,872.12 | 16,008,872.12 | ✅ |
| Payment total from per-method sums | 16,008,872.12 | 16,008,872.12 | ✅ |
| Merchandise GMV across installment groups | 13,221,498.11 | 13,221,498.11 | ✅ |
| Independent delivered GMV | 13,221,498.11 | 13,221,498.11 | ✅ |
| Independent delivered freight | 2,198,275.64 | — | ✅ |
| Freight total from the analysis base | 2,198,275.64 | 2,198,275.64 | ✅ |
| Installment analysis rows | 96,478 | 96,478 | ✅ |
| Distinct orders in installment analysis | 96,478 | one row per order | ✅ |
| Orders with no payment | 1 | reported separately | ✅ |
| Orders with no valid installments | 2 | reported separately | ✅ |
| Orders with zero item value | 0 | 0 | ✅ |
| Orders with missing freight | 0 | 0 | ✅ |
| Grouped orders lacking a payment row | 0 | 0 | ✅ |

No mismatches. Payment value reconciles to the validated R$ 16,008,872.12 across all payment
rows, and delivered merchandise reconciles to R$ 13,221,498.11 once the 1 no-payment and 2
no-valid-installment orders are included. The installment analysis has exactly one row per
order, and freight ties to the source item rows.

The R$ 15,422,461.77 column in the installment table is the payment value of the delivered
subset, not a competing total for the R$ 16,008,872.12 figure; the two cover different
populations by design.

## Limitations

- **Observational only.** The AOV difference between installment groups is an observed
  difference. It does not show that installments cause larger baskets: items priced higher may
  simply be more likely to be split into installments, and the groups differ in item value per
  item (88.74 vs 148.65).
- **Payment and merchandise are different measures.** Payment value includes freight and can
  include vouchers split across orders; merchandise GMV is item price only. They are not
  interchangeable and are not expected to be equal.
- **Payment-method order counts overlap.** Distinct-order counts by method cannot be summed
  (6.3).
- **Delivered orders only for installment and freight analysis.** Canceled, unavailable and
  in-transit orders are excluded, so the delivered subset carries less payment value than the
  full 16.0m.
- **Median versus aggregate freight.** The two freight ratios answer different questions and
  will differ whenever order size varies; neither is wrong and neither is a substitute for the
  other.
- **Freight is a recorded charge, not a cost.** It is what the customer was charged, not the
  carrier cost or margin.

## Observations

- **Credit card dominates value.** It carries 78.34% of recorded payment value on 73.92% of
  payment rows, with `boleto` second at 17.92% of value. Vouchers appear in 5.56% of rows but
  only 2.37% of value, consistent with small-value redemption.
- **Multi-installment orders are larger.** They account for 49,661 of 96,478 delivered orders
  (51.5%) and R$ 8,542,651.90 of R$ 13,221,498.11 merchandise GMV (64.6%), with an AOV of
  R$ 172.02 against R$ 99.94 for single-installment orders. The difference is observed, not
  established as a cause.
- **Freight is heavy for small orders.** The median order pays freight equal to 22.44% of its
  item value, while across all value the ratio is 16.63%, so freight weighs proportionally more
  on smaller baskets.

## Reproduce

Run [payments_and_freight.sql](../sql/payments_and_freight.sql) against the MySQL `olist`
database. The script returns the payment-method table, the installment and AOV groups, the
freight summary, and the QA reconciliation block in that order.
