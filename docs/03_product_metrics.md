# Olist E-Commerce Product Metrics & KPI Framework

## 1. Purpose

This document defines the key Product, Business, and Operational KPIs used to analyze the Olist marketplace dataset.

Each metric includes:

- Business purpose
- Measurement definition
- Calculation logic
- Source tables
- Population and filtering rules
- Important assumptions and limitations

The purpose is to ensure that all SQL queries, Python analyses, and Power BI dashboards use consistent metric definitions.

---

## 2. Metric Status Legend

| Status | Meaning | Portfolio Application |
|---|---|---|
| 🟢 Directly Measurable | Required data fields are available in the dataset. | Can be calculated from available transactional records with defined assumptions. |
| 🟡 Proxy Metric | An available field approximates a broader business or product concept. | Must be presented with its measurement limitations. |
| 🔴 Not Measurable | Required data is not available in the dataset. | Must not be reported as an observed KPI. |

**Important distinction:** A metric can be mathematically calculated from the dataset while still being a proxy for a broader concept. For example, delivered purchases can measure purchasing activity, but they cannot measure all forms of user activity.

---

# 3. Revenue & Marketplace Scale Metrics

| Metric | Status | Business Purpose |
|---|---|---|
| Delivered GMV | 🟢 | Measures the value of delivered merchandise. |
| Average Order Value (AOV) | 🟢 | Measures average merchandise value per delivered order. |
| Delivered Orders | 🟢 | Measures completed order volume. |
| Orders per Customer | 🟢 | Measures average delivered order frequency per buyer. |

### 3.1 Delivered Gross Merchandise Value (Delivered GMV)

**Definition:**

The total item value of orders with a final status of `delivered`.

**Formula:**

\[
Delivered\ GMV = \sum Item\ Price
\]

**Calculation logic:**

- Join `olist_orders_dataset` with `olist_order_items_dataset` using `order_id`.
- Include only orders where `order_status = 'delivered'`.
- Sum `price` across the included order items.

**Source tables:**

- `olist_orders_dataset`
- `olist_order_items_dataset`

**Population:**

All delivered orders with associated order items.

**Important notes:**

- `price` is an item-level value.
- Freight charges are excluded.
- This project uses Delivered GMV as its operational definition of GMV.
- It is not net revenue, profit, or Olist's recognized accounting revenue.
- The dataset does not provide the complete commission, refund, or cost information required to calculate marketplace net revenue.

### 3.2 Average Order Value (AOV)

**Definition:**

The average merchandise value per delivered order, excluding freight charges.

**Formula:**

\[
AOV = \frac{Delivered\ GMV}{Distinct\ Delivered\ Orders}
\]

**Calculation logic:**

1. Aggregate item prices by `order_id`.
2. Join the order-level result to the orders table.
3. Filter to delivered orders.
4. Calculate the average order item value.

**Source tables:**

- `olist_orders_dataset`
- `olist_order_items_dataset`

**Population:**

Distinct delivered orders with associated order items.

**Important notes:**

- The denominator is the number of distinct orders, not the number of order items.
- Do not calculate AOV directly after joining raw order items to payments or reviews.
- Freight is excluded to keep AOV focused on merchandise value.

### 3.3 Delivered Orders

**Definition:**

The number of distinct orders with final status `delivered`.

**Formula:**

\[
Delivered\ Orders = COUNT(DISTINCT\ order\_id)
\]

**Source table:**

- `olist_orders_dataset`

**Population:**

Orders with `order_status = 'delivered'`.

### 3.4 Orders per Customer

**Definition:**

The average number of delivered orders per unique buyer with at least one delivered order.

**Formula:**

\[
Orders\ per\ Customer =
\frac{Total\ Delivered\ Orders}
{Distinct\ Delivered\ Buyers}
\]

**Calculation logic:**

- Join orders to customers through `customer_id`.
- Group by `customer_unique_id`.
- Count distinct delivered `order_id` values per buyer.
- Divide total delivered orders by the number of buyers with at least one delivered order.

**Source tables:**

- `olist_orders_dataset`
- `olist_customers_dataset`

**Population:**

Unique buyers with at least one delivered order.

**Important notes:**

Use `customer_unique_id` rather than `customer_id` for customer-level behavior.

---

# 4. Customer Retention & Purchasing Behavior Metrics

| Metric | Status | Business Purpose |
|---|---|---|
| Monthly Purchasing Buyers | 🟢 | Measures the number of unique buyers making delivered purchases each month. |
| Lifetime Repeat Purchase Rate | 🟢 | Measures the share of buyers with at least two delivered orders. |
| 30-Day Repeat Purchase Rate | 🟢 | Measures the share of eligible first-time buyers making a second delivered purchase within 30 days. |
| Time to Second Purchase | 🟢 | Measures the time between the first and second delivered purchases. |
| Category Repeat Purchase Share | 🟢 | Measures repeat purchasing within individual product categories. |

### 4.1 Monthly Purchasing Buyers

**Definition:**

The number of distinct buyers with at least one delivered order in a calendar month.

**Formula:**

\[
Monthly\ Purchasing\ Buyers =
COUNT(DISTINCT\ customer\_unique\_id)
\]

**Calculation logic:**

- Use `order_purchase_timestamp` to assign orders to calendar months.
- Include delivered orders.
- Count distinct `customer_unique_id` values per month.

**Source tables:**

- `olist_orders_dataset`
- `olist_customers_dataset`

**Population:**

Unique buyers with at least one delivered order in the selected month.

**Important notes:**

This metric measures purchasing activity, not total platform activity.

It should not be labeled MAU (Monthly Active Users), because the dataset does not contain session, login, or engagement events.

### 4.2 Lifetime Repeat Purchase Rate

**Definition:**

The percentage of unique buyers who have placed at least two delivered orders during the observed dataset period.

**Formula:**

\[
Lifetime\ Repeat\ Purchase\ Rate =
\frac{Buyers\ with\ \geq 2\ Delivered\ Orders}
{Buyers\ with\ \geq 1\ Delivered\ Order}
\times 100
\]

**Calculation logic:**

- Identify buyers using `customer_unique_id`.
- Count distinct delivered orders per buyer.
- Classify buyers with at least two delivered orders as repeat buyers.
- Divide repeat buyers by all buyers with at least one delivered order.

**Source tables:**

- `olist_orders_dataset`
- `olist_customers_dataset`

**Population:**

All unique buyers with at least one delivered order in the observed dataset.

**Important notes:**

This is an observed-period repeat-purchase rate, not a complete measure of long-term customer retention.

Customers who made only one purchase may still purchase again after the dataset observation period.

### 4.3 30-Day Repeat Purchase Rate

**Definition:**

The percentage of eligible first-time buyers who make their second delivered purchase within 30 days of their first delivered purchase.

**Formula:**

\[
30D\ Repeat\ Purchase\ Rate =
\frac{Eligible\ Buyers\ with\ Second\ Purchase\ within\ 30\ Days}
{Eligible\ First\text{-}Time\ Buyers}
\times 100
\]

**Calculation logic:**

1. Identify each buyer using `customer_unique_id`.
2. Select delivered orders.
3. Sort delivered orders by `order_purchase_timestamp` for each buyer.
4. Identify the first and second delivered purchase timestamps.
5. Calculate the difference between the first and second purchase timestamps.
6. Count buyers whose second purchase occurs within 30 days.
7. Exclude buyers whose first purchase occurred too close to the dataset observation end date to allow a complete 30-day observation window.

**Source tables:**

- `olist_orders_dataset`
- `olist_customers_dataset`

**Population:**

Eligible first-time buyers with at least 30 days of observable follow-up after their first delivered purchase date.

**Important notes:**

- The 30-day window is based on purchase timestamps, not delivery timestamps.
- A second purchase must be a separate delivered order.
- The observation cutoff should be explicitly defined during analysis.
- The numerator and denominator must use the same eligible population.

### 4.4 Time to Second Purchase

**Definition:**

The median number of days between a buyer's first and second delivered purchases.

**Formula:**

\[
Time\ to\ Second\ Purchase =
Median(Second\ Purchase\ Timestamp - First\ Purchase\ Timestamp)
\]

**Calculation logic:**

- Identify delivered orders per `customer_unique_id`.
- Sort by `order_purchase_timestamp`.
- Select the first and second delivered orders.
- Calculate the time difference in days.
- Calculate the median across buyers with at least two delivered orders.

**Source tables:**

- `olist_orders_dataset`
- `olist_customers_dataset`

**Population:**

Unique buyers with at least two delivered orders.

**Important notes:**

- Use the median as the primary metric because purchase intervals may be highly skewed.
- The mean can be included as a secondary statistic.
- Use purchase timestamps consistently.

### 4.5 Category Repeat Purchase Share

**Definition:**

The percentage of buyers who purchase from the same product category in at least two distinct delivered orders.

**Formula:**

\[
Category\ Repeat\ Share =
\frac{Buyers\ with\ \geq 2\ Delivered\ Orders\ in\ Category}
{Buyers\ with\ \geq 1\ Delivered\ Order\ in\ Category}
\times 100
\]

**Calculation logic:**

- Join delivered order items to orders, customers, and products.
- Identify each buyer and product category.
- Count distinct delivered orders per buyer and category.
- Identify buyers with at least two distinct orders in the same category.
- Calculate the percentage per category.

**Source tables:**

- `olist_orders_dataset`
- `olist_order_items_dataset`
- `olist_customers_dataset`
- `olist_products_dataset`

**Population:**

Unique buyers with at least one delivered order containing an item from the selected category.

**Important notes:**

- Count distinct orders, not item rows.
- Multiple items from the same category within one order count as one purchasing occasion for that category.
- This metric measures repeat purchasing within a category, not overall customer retention.

---

# 5. Operational & Customer Experience Metrics

| Metric | Status | Business Purpose |
|---|---|---|
| Median Delivery Lead Time | 🟢 | Measures typical delivery duration. |
| Delivery Delay Rate | 🟢 | Measures the share of delivered orders arriving later than estimated. |
| Median Delivery Delay | 🟢 | Measures typical delay duration among late deliveries. |
| Order Cancellation Rate | 🟢 | Measures the proportion of placed orders that are canceled. |
| Average Review Score | 🟡 | Uses review scores as a customer satisfaction proxy. |
| Low Review Score Rate | 🟡 | Measures the proportion of reviews with scores of 1 or 2. |

### 5.1 Median Delivery Lead Time

**Definition:**

The median number of days between purchase and actual customer delivery.

**Formula:**

\[
Delivery\ Lead\ Time =
order\_delivered\_customer\_date -
order\_purchase\_timestamp
\]

\[
Median\ Delivery\ Lead\ Time =
Median(Delivery\ Lead\ Time)
\]

**Source table:**

- `olist_orders_dataset`

**Population:**

Delivered orders with valid purchase and actual delivery timestamps.

**Important notes:**

- Median is the primary measure because delivery times may contain extreme values.
- Average delivery lead time can be reported as a secondary metric.
- This measures end-to-end fulfillment time, not warehouse processing time alone.

### 5.2 Delivery Delay Rate

**Definition:**

The percentage of delivered orders that arrived after the estimated delivery date.

**Formula:**

\[
Delivery\ Delay\ Rate =
\frac{Late\ Delivered\ Orders}
{Delivered\ Orders\ with\ Valid\ Dates}
\times 100
\]

Where:

\[
Late\ Order =
order\_delivered\_customer\_date >
order\_estimated\_delivery\_date
\]

**Source table:**

- `olist_orders_dataset`

**Population:**

Delivered orders with both actual and estimated delivery timestamps available.

**Important notes:**

Orders with missing delivery timestamps must not be silently classified as on-time.

### 5.3 Median Delivery Delay

**Definition:**

The median number of days between actual and estimated delivery dates for late orders.

**Formula:**

\[
Delivery\ Delay =
Actual\ Delivery\ Date -
Estimated\ Delivery\ Date
\]

**Population:**

Delivered orders where actual delivery occurred after the estimated delivery date.

**Important notes:**

Only positive delays are included in this metric. On-time and early deliveries should be analyzed separately.

### 5.4 Order Cancellation Rate

**Definition:**

The percentage of all placed orders whose final recorded status is `canceled`.

**Formula:**

\[
Cancellation\ Rate =
\frac{Canceled\ Orders}
{All\ Placed\ Orders}
\times 100
\]

**Source table:**

- `olist_orders_dataset`

**Population:**

All orders in the dataset, regardless of final status.

**Important notes:**

- Use distinct `order_id` values.
- This is an overall cancellation rate based on final recorded status.
- It does not identify the exact operational stage or reason for cancellation.

### 5.5 Average Review Score

**Definition:**

The arithmetic mean of available customer review scores.

**Formula:**

\[
Average\ Review\ Score =
\frac{\sum review\_score}
{Count\ of\ Valid\ Review\ Scores}
\]

**Source table:**

- `olist_order_reviews_dataset`

**Population:**

Review records with valid scores from 1 to 5.

**Important notes:**

- Review score is a customer satisfaction proxy.
- The number of reviews should be reported alongside the average.
- If an order has multiple reviews, the analysis must define whether it measures review records or one aggregated score per order.

### 5.6 Low Review Score Rate

**Definition:**

The percentage of valid review records with a score of 1 or 2.

**Formula:**

\[
Low\ Review\ Rate =
\frac{Reviews\ with\ Score\ 1\ or\ 2}
{All\ Valid\ Review\ Records}
\times 100
\]

**Source table:**

- `olist_order_reviews_dataset`

**Population:**

Review records with valid scores from 1 to 5.

**Important notes:**

This is a review-level metric. If reporting an order-level low-score rate, first define how multiple reviews for the same order are handled.

---

# 6. Freight & Payment Metrics

| Metric | Status | Business Purpose |
|---|---|---|
| Item-Level Freight-to-Price Ratio | 🟢 | Measures shipping cost relative to item price. |
| Order-Level Freight-to-Price Ratio | 🟢 | Measures total shipping cost relative to total item value per order. |
| Payment Method Distribution | 🟢 | Measures payment method usage. |
| Average Installments | 🟢 | Measures installment behavior. |
| AOV by Installment Group | 🟢 | Compares merchandise order value across installment groups. |

### 6.1 Item-Level Freight-to-Price Ratio

**Definition:**

The shipping cost of an order item relative to its item price.

**Formula:**

\[
Item\ Freight\ Ratio =
\frac{freight\_value}{price}
\]

**Primary summary:**

Median item-level freight-to-price ratio.

**Source table:**

- `olist_order_items_dataset`

**Population:**

Order items with valid, positive item prices and valid freight values.

**Important notes:**

- Items with zero or negative prices must be inspected and handled explicitly.
- The ratio can be highly skewed, so median is preferred.
- This is an item-level metric and should not be described as an order-level ratio.

### 6.2 Order-Level Freight-to-Price Ratio

**Definition:**

Total freight value divided by total item value within an order.

**Formula:**

\[
Order\ Freight\ Ratio =
\frac{\sum freight\_value}
{\sum price}
\]

**Calculation logic:**

- Aggregate `price` and `freight_value` by `order_id`.
- Calculate the ratio after aggregation.
- Exclude orders with zero or invalid total item value.

**Source table:**

- `olist_order_items_dataset`

**Important notes:**

The order-level ratio is not the same as the average of item-level ratios. Both can be useful, but they answer different questions.

### 6.3 Payment Method Distribution

**Definition:**

The number and percentage of payment records by payment type.

**Formula:**

\[
Payment\ Type\ Share =
\frac{Payment\ Records\ by\ Type}
{All\ Valid\ Payment\ Records}
\times 100
\]

**Source table:**

- `olist_order_payments_dataset`

**Population:**

Valid payment records.

**Important notes:**

This is a payment-record-level distribution. An order may contain multiple payment records or payment types.

For an order-level payment method analysis, define an explicit classification rule for orders with multiple payment types.

### 6.4 Average Installments

**Definition:**

The average number of installments across valid payment records.

**Formula:**

\[
Average\ Installments =
AVG(payment\_installments)
\]

**Source table:**

- `olist_order_payments_dataset`

**Population:**

Valid payment records with a positive installment count.

**Important notes:**

This is a payment-record-level metric, not necessarily an order-level metric.

### 6.5 AOV by Installment Group

**Definition:**

Compares average delivered order item value between orders with single-installment and multi-installment payment records.

**Suggested classification:**

- Single-installment order: all valid payment records for the order have `payment_installments = 1`.
- Multi-installment order: at least one valid payment record for the order has `payment_installments > 1`.

**Calculation logic:**

1. Aggregate order items to one row per order.
2. Aggregate payment records to one row per order.
3. Assign each order to an installment group using the classification above.
4. Join the aggregated order-level tables.
5. Filter to delivered orders.
6. Compare AOV between installment groups.

**Source tables:**

- `olist_orders_dataset`
- `olist_order_items_dataset`
- `olist_order_payments_dataset`

**Important notes:**

- Orders with conflicting or missing installment information should be inspected separately.
- The analysis is observational.
- A difference in AOV does not prove that installment availability causes higher spending.

---

# 7. Seller & Category Performance Metrics

| Metric | Status | Business Purpose |
|---|---|---|
| Delivered GMV by Category | 🟢 | Identifies categories contributing most to delivered merchandise value. |
| Category Cancellation Rate | 🟢 | Compares cancellation rates across product categories. |
| Delivered GMV by Seller | 🟢 | Measures seller contribution to marketplace sales. |
| Top 5% Seller GMV Share | 🟢 | Measures sales concentration among the largest sellers. |

### 7.1 Delivered GMV by Category

**Definition:**

The sum of item prices for delivered orders, grouped by product category.

**Calculation logic:**

- Join orders to order items.
- Join order items to products.
- Join products to the category translation table.
- Filter to delivered orders.
- Group by translated product category.

**Source tables:**

- `olist_orders_dataset`
- `olist_order_items_dataset`
- `olist_products_dataset`
- `product_category_name_translation`

**Important notes:**

Use a consistent fallback for categories without an English translation. Do not silently drop products with missing category translations.

### 7.2 Category Cancellation Rate

**Definition:**

The percentage of orders associated with a category that have a final status of `canceled`.

**Formula:**

\[
Category\ Cancellation\ Rate =
\frac{Distinct\ Canceled\ Orders\ in\ Category}
{Distinct\ Orders\ in\ Category}
\times 100
\]

**Calculation logic:**

- Join order items to products and orders.
- Associate each order with every category represented in its items.
- Count distinct orders per category.
- Count distinct canceled orders per category.
- Calculate the rate.

**Important notes:**

An order containing items from multiple categories is included in each relevant category's denominator. Category cancellation rates therefore cannot be summed or averaged to reconstruct the overall marketplace cancellation rate.

### 7.3 Delivered GMV by Seller

**Definition:**

The sum of item prices for delivered order items grouped by seller.

**Calculation logic:**

- Join orders to order items.
- Filter to delivered orders.
- Group by `seller_id`.
- Sum item prices.

**Source tables:**

- `olist_orders_dataset`
- `olist_order_items_dataset`
- `olist_sellers_dataset`

**Important notes:**

Seller GMV is based on merchandise item prices. It does not represent seller profit, Olist commission, or seller net revenue.

### 7.4 Top 5% Seller GMV Share

**Definition:**

The percentage of total delivered GMV generated by the top 5% of sellers, ranked by delivered GMV.

**Formula:**

\[
Top\ 5\%\ Seller\ GMV\ Share =
\frac{Delivered\ GMV\ from\ Top\ 5\%\ Sellers}
{Total\ Delivered\ GMV}
\times 100
\]

**Calculation logic:**

1. Calculate delivered GMV per seller.
2. Include sellers with at least one delivered item.
3. Rank sellers by delivered GMV in descending order.
4. Select the top 5% of sellers.
5. Sum their delivered GMV.
6. Divide by total delivered GMV.

**Important notes:**

Define the rounding rule for the number of sellers selected (for example, using the ceiling of 5% of active sellers). Apply the same rule consistently.

This metric measures sales concentration, not actual seller dependency or business risk.

---

# 8. Metrics That Cannot Be Directly Measured

The following metrics are outside the measurement scope of the Olist dataset.

| Metric | Status | Reason |
|---|---|---|
| Website / App Conversion Rate | 🔴 Not Measurable | No sessions, visits, product views, or conversion events. |
| Add-to-Cart Rate | 🔴 Not Measurable | No add-to-cart event records. |
| Checkout Abandonment Rate | 🔴 Not Measurable | No checkout initiation or abandonment events. |
| DAU / WAU / True MAU | 🔴 Not Measurable | No user engagement or activity event logs. |
| Customer Acquisition Cost (CAC) | 🔴 Not Measurable | No marketing spend or acquisition channel data. |
| Marketing Attribution | 🔴 Not Measurable | No campaign, referral, or acquisition source information. |
| A/B Test Results | 🔴 Not Measurable | No experiment assignments or treatment/control data. |
| Platform Net Revenue / Take Rate | 🔴 Not Measurable | No seller commission or platform revenue records. |
| Customer Lifetime Value (Profit-Based) | 🔴 Not Measurable | No complete customer-level revenue, margin, and cost information. |
| Direct Seller Rating | 🔴 Not Measurable | No independent seller rating field. |

---

# 9. Metric Governance & Calculation Rules

To maintain analytical consistency, the following rules apply across the project.

### 9.1 Customer Identity

Use `customer_unique_id` for:

- Unique buyer counts
- Repeat-purchase rate
- Customer purchasing frequency
- Time to second purchase
- Customer cohort analysis

Use `customer_id` only for linking an order to its customer record.

### 9.2 Order Population

For completed-purchase metrics, use orders with:

`order_status = 'delivered'`

For cancellation rate, use all placed orders as the denominator.

Do not mix these populations without explicitly documenting the reason.

### 9.3 Aggregation Before Joining

When combining tables with one-to-many relationships:

- Aggregate order items to order level before combining with payment records.
- Aggregate payment records to order level before combining with order-level sales.
- Aggregate review records to the required analytical grain before joining.
- Validate geographic lookup uniqueness before joining coordinates.

### 9.4 Missing Values

- Do not automatically replace missing timestamps with zero or arbitrary dates.
- Exclude records from metrics when required fields are missing, and report the excluded population.
- Distinguish between missing values and legitimate zero values.

### 9.5 Statistical Summaries

Use:

- **Median** for skewed durations, delays, and freight ratios.
- **Mean** for average monetary values where appropriate.
- **Counts and percentages** for population and distribution metrics.

Where useful, report both mean and median to reveal skewness.

### 9.6 Interpretation

- Correlation does not establish causation.
- Observed repeat purchases do not measure all forms of retention.
- Review scores are satisfaction proxies.
- Delivered GMV is not net revenue or profit.
- Geographic straight-line distance is not actual delivery route distance.

### 9.7 Review Score Selection for Order-Level Analysis

**Definition:**

When a metric is calculated at order grain, each order carries one review score chosen by the **latest valid answered score** rule: the score from the review row with the most recent `review_answer_timestamp`, considering only rows with a score from 1 to 5 and a non-missing answer timestamp.

**Selection logic:**

1. Keep review rows where `review_score BETWEEN 1 AND 5` and `review_answer_timestamp IS NOT NULL`.
2. Rank the remaining rows per `order_id` by `review_answer_timestamp` descending.
3. Keep the first row. `review_id` descending breaks any remaining tie deterministically.
4. Orders with no qualifying row receive a NULL order-level score and are reported as `no_review`.

```sql
SELECT order_id, review_score, review_answer_timestamp
FROM (
    SELECT order_id,
           review_score,
           review_answer_timestamp,
           ROW_NUMBER() OVER (
               PARTITION BY order_id
               ORDER BY review_answer_timestamp DESC, review_id DESC
           ) AS rn
    FROM order_reviews
    WHERE review_score BETWEEN 1 AND 5
      AND review_answer_timestamp IS NOT NULL
) AS ranked
WHERE rn = 1;
```

**Source table:**

- `olist_order_reviews_dataset`

**Population:**

Orders that have at least one review row with a score from 1 to 5 and a non-missing answer timestamp. Orders without such a row keep a missing score and are excluded from order-level score averages while remaining visible in the order base.

**Validation evidence:**

- 202 orders contain more than one distinct review score.
- 0 of those orders have a missing `review_answer_timestamp`.
- 0 of those orders have different scores sharing their latest answer timestamp.

The rule therefore resolves every conflicting order without a tie in the current dataset, so no secondary preference for first, minimum, or mean score is needed.

**Scope:**

- Applies to order-level analysis: average score by delivery bucket, score by category at order grain, and order-level measures in Power BI.
- Does not replace the review-record definitions in 5.5 Average Review Score and 5.6 Low Review Score Rate. Those remain record-level metrics and must keep stating their grain.
- `sql/order_level_dataset.sql` exposes the selected value as `latest_review_score` and the outcome as `order_review_status`.

**If the rule changes:** rerun the validation queries in [Data Validation Findings](data_validation_findings.md) and record the effect on the delivery and review comparison before adopting a different rule.

---

# 10. KPI-to-Business Question Mapping

| Business Question | Primary Metrics |
|---|---|
| Q1. Customer Retention & Repeat Purchase | Lifetime Repeat Purchase Rate, 30-Day Repeat Purchase Rate, Time to Second Purchase |
| Q2. Delivery Performance vs. Satisfaction | Delivery Delay Rate, Average Review Score, Low Review Score Rate |
| Q3. Fulfillment Lead Time | Median Delivery Lead Time |
| Q4. Product Category Performance | Delivered GMV by Category, Category Cancellation Rate |
| Q5. Payment Preferences & AOV | AOV by Installment Group, Payment Method Distribution |
| Q6. Seller Concentration | Delivered GMV by Seller, Top 5% Seller GMV Share |
| Q7. Order Cancellation | Order Cancellation Rate, Cancellation Count |
| Q8. Geographic Logistics | Delivery Lead Time by State Pair, Approximate Distance |
| Q9. Freight Cost & Customer Experience | Item-Level and Order-Level Freight-to-Price Ratios, Review Score by Freight Group |
| Q10. Customer Satisfaction Drivers | Average Review Score, Low Review Score Rate, Review Score by Operational Segment |

---

# 11. Analytical Workflow

The metrics defined in this document will be implemented through the following workflow:

1. Validate source tables, keys, and relationships.
2. Perform data quality checks.
3. Explore data distributions and missing values.
4. Build reusable SQL aggregations at the correct grain.
5. Calculate and validate the defined KPIs.
6. Explore relationships and segments using Python.
7. Build Power BI dashboards.
8. Translate findings into business insights and recommendations.

**Core analytical principle:**

Business Question → Metric Definition → Population → Data Validation → SQL/Python Analysis → Insight → Recommendation