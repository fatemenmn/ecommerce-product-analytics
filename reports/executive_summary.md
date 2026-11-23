# Executive summary

This summary consolidates the five completed analyses plus the geographic delivery check, using
the Olist Brazilian E-Commerce Public Dataset imported into MySQL. Metrics cover **delivered
orders only**, merchandise value comes from item price (freight excluded), and every figure below
links to the report that defines and validates it. Purchase timestamps span 4 September 2016 to
17 October 2018; monthly trends use the selected window January 2017 through August 2018.

## Marketplace scale and trend

Delivered merchandise value reached **R$ 13,221,498.11 across 96,478 delivered orders**, giving an
overall AOV of **R$ 137.04** and a cancellation rate of **0.63%** of 99,441 placed orders
([Marketplace Performance](marketplace_performance.md)).

Growth came from order volume rather than basket size. Between January 2017 and January 2018,
delivered orders rose from **750 to 7,069** while AOV fell from **R$ 149.06 to R$ 130.80**; delivered
GMV still grew from **R$ 111,798.36 to R$ 924,645.00** ([Marketplace Performance](marketplace_performance.md)).
November 2017 is the peak month at **7,544 placed orders and R$ 987,765.37** delivered GMV, with a
0.49% cancellation rate ([Marketplace Performance](marketplace_performance.md)).

Denominators: delivered orders by purchase month; AOV uses delivered orders with items. The first
and last observed months are partial and are excluded from trend statements.

## Repeat purchasing

Only **3.00%** of the **93,358** buyers with at least one delivered order placed two or more, and
the 96,478 delivered orders average **1.033 per buyer**. Among the 2,801 buyers who returned, the
median time to a second purchase was **29.0 days** against a mean of **81.2 days**
([Customer Repeat Purchase](customer_repeat_purchase.md)).

Short-term repetition is similar: **2.28%** of the **75,439** new buyers with a complete 90-day
window made a second delivered purchase within 90 days (1,717 buyers), with cohorts ranging from
1.61% to 3.63% ([Customer Repeat Purchase](customer_repeat_purchase.md)). Denominators exclude
buyers whose 90-day window extends past the 31 August 2018 cutoff.

## Category and seller concentration

Category demand is broad but head-heavy: the ten largest of **74** categories generate **62.43%**
of delivered GMV and the five largest **39.83%**, led by `health_beauty` at **9.33%**
(R$ 1,233,131.72) over **110,197** delivered item rows ([Category and Seller Performance](category_seller_performance.md)).

Seller activity is more concentrated than category activity. Of **2,970** sellers with delivered
items, the top 10 account for **13.27%** of delivered GMV and the top 5% (**149 sellers**,
`CEIL(0.05 × 2,970)`) for **53.06%** ([Category and Seller Performance](category_seller_performance.md)).
Category order counts overlap because one order can span several categories, so those counts are
not additive.

## Payments and freight

Recorded payment value totals **R$ 16,008,872.12** over 103,886 payment rows, with credit cards
carrying **78.34%** of that value and `boleto` 17.92% ([Payments and Freight](payments_and_freight.md)).
Among 96,478 delivered orders with items, **49,661 multi-installment orders** hold
R$ 8,542,651.90 of merchandise GMV at **R$ 172.02 AOV**, against **46,814 single-installment
orders** at **R$ 99.94** ([Payments and Freight](payments_and_freight.md)).

Freight totals **R$ 2,198,275.64** on the same delivered population. The **median order freight
ratio is 22.44%** of item value, while the **aggregate ratio is 16.63%**; the two measure different
things and should not be interchanged ([Payments and Freight](payments_and_freight.md)).

## Delivery timing and customer reviews

Of **96,470** timing-eligible delivered orders, **95,824** carry a usable review score.
On-time orders average **4.29** with a **9.27%** 1-2 score rate, while late orders average **2.27**
with **62.42%** of reviewed orders scoring 1 or 2, a gap of **53.15 percentage points**
([Delivery vs Reviews](delivery_vs_reviews.md)). Review coverage is high in both groups (99.45%
on time, 97.66% late), so the gap is not an artefact of differential reviewing.

Geographically, lateness clusters in a few buyer states: Alagoas **21.41%** late (n=397),
Maranhão **17.43%** (n=717) and Sergipe **15.22%** (n=335), against São Paulo **4.49%** (n=40,494)
and Paraná **4.04%** (n=4,923). Amazonas has the longest median at 26 days but only **2.76%** late,
so a long lead time does not imply a missed estimate ([Delivery by State](delivery_by_state.md)).
The **412** seller-state to buyer-state pairs cover 96,994 order/state-pair rows for 96,478 orders
because 509 orders span multiple seller states ([Delivery by State](delivery_by_state.md)).

## Denominators at a glance

| Metric | Value | Denominator |
|---|---:|---|
| Delivered GMV | R$ 13,221,498.11 | delivered orders, item price only |
| AOV | R$ 137.04 | 96,478 delivered orders |
| Cancellation rate | 0.63% | 99,441 placed orders |
| Repeat buyer rate | 3.00% | 93,358 buyers with a delivered order |
| 90-day repeat rate | 2.28% | 75,439 buyers with a complete 90-day window |
| Top 10 category GMV share | 62.43% | total delivered GMV |
| Top 5% seller GMV share | 53.06% | 2,970 sellers with delivered items |
| Median order freight ratio | 22.44% | delivered orders with positive item value |
| 1-2 score rate, late | 62.42% | 6,381 reviewed late orders |
| 1-2 score rate, on time | 9.27% | 89,443 reviewed on-time orders |

## Limitations

- **Delivered orders only.** Canceled, unavailable and in-transit orders are excluded, so shares
  describe realised sales rather than demand.
- **Observed window, no telemetry.** The dataset has transactions and reviews, not sessions or
  events. Conversion, add-to-cart and checkout abandonment cannot be measured, and no A/B test was
  run.
- **GMV is merchandise value.** It is the sum of item prices: not profit, not Olist commission and
  not net of refunds. Recorded payment value is a separate measure that includes freight.
- **Review scores are proxies.** They describe satisfaction in the observed records and cannot
  stand in for engagement.
- **Overlapping counts.** Category order counts and state-pair counts repeat an order across
  groups and must not be summed.
- **Small groups.** Several states and many state pairs have fewer than 100 eligible orders, where
  a handful of orders moves the rate by several points.
- **Associations, not causes.** Delivery timing, geography and review scores are observed as
  associated; no causal mechanism was tested in these analyses.

## Next steps to test

Two proposals follow from the observations above. Both are experiments to design and run, not
conclusions the current data can settle.

1. **Pilot late-delivery remediation in the highest-late-rate states.** Alagoas, Maranhão, Sergipe
   and Piauí combine small volumes with the highest late rates ([Delivery by State](delivery_by_state.md)),
   and late orders are strongly associated with low review scores ([Delivery vs Reviews](delivery_vs_reviews.md)).
   A pilot that tightens carrier allocation or the promised date in those states could be evaluated
   on late rate and the 1-2 score share, with a comparable state as control.
2. **Test a second-purchase trigger for one-time buyers.** With 3.00% repeat purchasing and a
   2.28% 90-day repeat rate ([Customer Repeat Purchase](customer_repeat_purchase.md)), the largest
   available lever is converting first orders. A trial that offers a timed incentive after a first
   delivered order in high-AOV, high-multi-installment categories ([Payments and Freight](payments_and_freight.md))
   could be measured against the 90-day repeat baseline, with cohort assignment randomised.

## What is next

The Power BI semantic model and dashboard are upcoming; every measure will be reconciled against
the validated SQL outputs in this repository. Experiment proposals above are design outlines and
have not been run.

## Related documents

- Metric definitions and populations: [Product Metrics & KPI Framework](../docs/03_product_metrics.md)
- Data validation and resolved checks: [Data Validation Findings](../docs/data_validation_findings.md)
- Python reproduction of the marketplace and delivery-versus-reviews analyses:
  [Python Reproduction](../python/README.md)
- Charts: [monthly delivered GMV](../images/monthly_delivered_gmv_2017_2018.png) and
  [review score distribution by timing](../images/review_score_distribution_by_timing.png)
