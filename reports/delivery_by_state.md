# Delivery performance by state

Timing figures use the rules in `docs/03_product_metrics.md`: median purchase-to-delivery days
(5.1), and a late order as one delivered **after** the estimated date (5.2). A delivery on the
estimated calendar date counts as on time. This analysis stays at state level and uses no
coordinates or distances (9.6).

**Eligibility** (96,470 orders): `order_status = 'delivered'`, a purchase timestamp, a customer
delivery timestamp that is not earlier than the purchase, and a non-missing estimated delivery
date. That gives 96,470 of 96,478 delivered orders; the median and the late rate share exactly
this denominator.

## 1. Buyer state — one row per order

| Buyer state | Delivered orders | Eligible orders | Median days | Late orders | Late rate |
| --- | ---: | ---: | ---: | ---: | ---: |
| SP | 40,501 | 40,494 | 7.0 | 1,820 | 4.49% |
| RJ | 12,350 | 12,350 | 12.0 | 1,495 | 12.11% |
| MG | 11,354 | 11,354 | 10.0 | 519 | 4.57% |
| RS | 5,345 | 5,344 | 13.0 | 325 | 6.08% |
| PR | 4,923 | 4,923 | 10.0 | 199 | 4.04% |
| SC | 3,546 | 3,546 | 13.0 | 291 | 8.21% |
| BA | 3,256 | 3,256 | 17.0 | 396 | 12.16% |
| DF | 2,080 | 2,080 | 11.0 | 118 | 5.67% |
| ES | 1,995 | 1,995 | 14.0 | 214 | 10.73% |
| GO | 1,957 | 1,957 | 14.0 | 128 | 6.54% |
| PE | 1,593 | 1,593 | 16.0 | 153 | 9.60% |
| CE | 1,279 | 1,279 | 18.0 | 176 | 13.76% |
| PA | 946 | 946 | 21.0 | 106 | 11.21% |
| MT | 886 | 886 | 16.0 | 53 | 5.98% |
| MA | 717 | 717 | 19.0 | 125 | 17.43% |
| MS | 701 | 701 | 14.0 | 68 | 9.70% |
| PB | 517 | 517 | 18.0 | 54 | 10.44% |
| PI | 476 | 476 | 16.0 | 66 | 13.87% |
| RN | 474 | 474 | 16.0 | 44 | 9.28% |
| AL | 397 | 397 | 22.0 | 85 | 21.41% |
| SE | 335 | 335 | 18.0 | 51 | 15.22% |
| TO | 274 | 274 | 16.0 | 27 | 9.85% |
| RO | 243 | 243 | 18.0 | 7 | 2.88% |
| AM | 145 | 145 | 26.0 | 4 | 2.76% |
| AC | 80 | 80 | 18.0 | 3 | 3.75% |
| AP | 67 | 67 | 25.0 | 2 | 2.99% |
| RR | 41 | 41 | 25.0 | 5 | 12.20% |
| **Total** | **96,478** | **96,470** | — | **6,534** | **6.77%** |

**Denominators.** `delivered_orders` counts every delivered order in the state, including the 8
with unusable timing dates. `eligible_orders` is the denominator for both the median and the
late rate. No customer state value is missing, so no `(unknown)` row appears.

**Small groups.** AC (80), AP (67) and RR (41) are below 100 eligible orders; their rates move
easily on a few orders and should be read as indicative only. AM (145) and RO (243) are also
small relative to the main states.

## 2. Seller state to buyer state

Order/state pairs come from order items joined to seller state and then to the buyer's state.
An order is counted **once per pair**, but an order buying from sellers in more than one state
appears in more than one pair: **509 orders span multiple seller states**, producing **96,994
order/state-pair rows for 96,478 orders** across **412 distinct pairs**. Pair counts therefore
overlap and must not be summed.

Within a pair, the timing figures are the **order-level purchase-to-delivery time associated
with that state pair**. They describe how long those orders took overall, not the shipping time
of an individual item or a leg of the journey.

The 24 pairs with the most eligible orders are below; the script returns all 412 with sample
sizes so small pairs are identifiable.

| Seller state | Buyer state | Eligible orders | Median days | Late orders | Late rate |
| --- | --- | ---: | ---: | ---: | ---: |
| SP | SP | 30,829 | 7.0 | 1,428 | 4.63% |
| SP | RJ | 8,188 | 13.0 | 1,152 | 14.07% |
| SP | MG | 7,469 | 11.0 | 393 | 5.26% |
| SP | RS | 3,613 | 14.0 | 238 | 6.59% |
| SP | PR | 3,130 | 11.0 | 138 | 4.41% |
| PR | SP | 2,959 | 9.0 | 90 | 3.04% |
| MG | SP | 2,578 | 9.0 | 91 | 3.53% |
| SP | SC | 2,336 | 14.0 | 222 | 9.50% |
| SP | BA | 2,313 | 18.0 | 297 | 12.84% |
| MG | MG | 1,539 | 7.0 | 39 | 2.53% |
| SP | ES | 1,467 | 14.0 | 180 | 12.27% |
| SP | GO | 1,424 | 14.0 | 106 | 7.44% |
| SP | DF | 1,386 | 12.0 | 89 | 6.42% |
| RJ | SP | 1,339 | 9.0 | 103 | 7.69% |
| SC | SP | 1,330 | 10.0 | 48 | 3.61% |
| MG | RJ | 1,145 | 11.0 | 94 | 8.21% |
| SP | PE | 1,134 | 16.0 | 111 | 9.79% |
| PR | RJ | 978 | 14.0 | 117 | 11.96% |
| SP | CE | 970 | 18.0 | 133 | 13.71% |
| RJ | RJ | 961 | 5.0 | 45 | 4.68% |
| PR | MG | 827 | 12.0 | 32 | 3.87% |
| PR | PR | 717 | 7.0 | 19 | 2.65% |
| SP | PA | 683 | 21.0 | 82 | 12.01% |
| RS | SP | 673 | 8.0 | 8 | 1.19% |

Same-state orders (34,827 pair rows) move faster than cross-state ones (62,167 pair rows):
RJ→RJ has a 5-day median, PR→PR and SP→SP 7 days, RS→RS 6 days, while SP→RJ takes a 13-day
median and 14.07% arrive late.

## 3. Definitions and denominators

| Term | Definition |
| --- | --- |
| Delivered order | `order_status = 'delivered'` (5.2 population) |
| Eligible order | delivered with valid purchase and delivery timestamps, delivery not before purchase, and a non-missing estimate |
| Median days | median of `DATEDIFF(delivered, purchase)` over eligible orders (5.1) |
| Late order | `DATEDIFF(delivered, estimated) > 0`; delivery on the estimated date is on time (5.2) |
| Late rate | late orders ÷ eligible orders × 100 |
| Order/state pair | distinct (`order_id`, `seller_state`, `buyer_state`) |
| Multi-state order | delivered order whose items come from sellers in more than one state |

## 4. QA and reconciliation

| Check | Result | Expected | Status |
| --- | ---: | ---: | --- |
| Delivered orders in source | 96,478 | 96,478 | ✅ |
| Buyer-state rows | 96,478 | 96,478 | ✅ |
| Timing-eligible orders | 96,470 | 96,470 | ✅ |
| Late orders | 6,534 | 6,534 | ✅ |
| Missing buyer state | 0 | 0 | ✅ |
| Items with missing seller id | 0 | 0 | ✅ |
| Sellers with missing state | 0 | 0 | ✅ |
| Order/state-pair rows | 96,994 | ≥ 96,478 (overlap) | ✅ |
| Distinct pair keys | 96,994 | equals row count | ✅ |
| Multi-state orders | 509 | reported | ✅ |
| Distinct orders inside pairs | 96,478 | 96,478 | ✅ |
| Eligible orders missing from pairs | 0 | 0 | ✅ |

Buyer-state totals reconcile to the validated baseline of 96,478 delivered and 96,470 eligible
orders with no unknown-state bucket. Late orders reconcile to the 6,534 baseline from the
delivery-versus-reviews analysis, because eligibility matches exactly. The pair table adds 516
rows purely from the 509 multi-state orders — each adds one row per additional seller state —
and every pair key is unique, so no join has duplicated an order inside a pair.

**Why pair counts differ from order counts.** 96,994 − 96,478 = 516 extra rows. Interpret pair
counts as "orders involving this state pair", never as a partition of all orders.

## 5. Limitations

- **State level only.** No coordinates, distances, routes or cities are used, and straight-line
  distance would not represent route distance (9.6).
- **Timing is order-level.** In a pair table, the median belongs to the orders associated with
  that pair, not to an individual item shipped between the two states.
- **Counts overlap.** The 412 pairs cover 96,994 rows for 96,478 orders; sums across pairs exceed
  the order total and cannot be aggregated into a marketplace total.
- **Late rate is punctuality, not speed.** It compares delivery with the promise made for that
  destination. Regions with long promises can look punctual (AM, 26-day median, 2.76% late)
  while faster regions can look late (RJ, 12-day median, 12.11% late).
- **Small groups are unstable.** States and pairs with fewer than ~100 eligible orders can move
  by several points from a handful of orders.
- **Delivered orders only.** Canceled and in-transit orders are excluded, so the picture covers
  completed deliveries.

## 6. Findings

**Lateness is concentrated in a few buyer states.** Alagoas has the highest late rate at 21.41%
among 397 eligible orders, followed by Maranhão at 17.43% (717), Sergipe at 15.22% (335) and
Piauí at 13.87% (476). At the other end, Paraná (4.04%, n = 4,923), São Paulo (4.49%, n = 40,494)
and Minas Gerais (4.57%, n = 11,354) combine large volumes with low late rates.

**A long delivery time is not the same as a late delivery.** Amazonas takes the longest median
(26 days) yet only 2.76% of its 145 orders arrived late, and Rondônia has an 18-day median with
2.88% late, because the promised dates for those destinations are correspondingly long. Rio de
Janeiro, with a shorter 12-day median, still runs 12.11% late. Late rate measures whether the
estimate was met, not how far away the buyer is.

**Distance between seller and buyer state is associated with slower delivery.** Same-state pairs
are the fastest in the output — RJ→RJ 5-day median, RS→RS 6, SP→SP and MG→MG and PR→PR 7 — while
the large cross-country pairs take far longer: SP→RJ a 13-day median and 14.07% late over 8,188
orders, SP→BA 18 days, SP→PA 21 days, and SP→MA 20 days with a 19.07% late rate over 493 orders.
These are observed associations between state pairs and timing; they do not identify the cause
of the delay.

## 7. Reproduce

Run [delivery_by_state.sql](../sql/delivery_by_state.sql) against the MySQL `olist` database.
The script returns the buyer-state table, the complete seller-state/buyer-state pair table, and
the QA reconciliation block in that order.
