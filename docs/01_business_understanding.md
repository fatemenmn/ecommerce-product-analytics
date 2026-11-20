# Business Understanding – Olist E-Commerce Marketplace

## 1. Project Background

Olist is a Brazilian e-commerce marketplace that connects customers with independent sellers. The public Olist dataset contains transactional, customer, product, payment, review, seller, and logistics information.

This project analyzes the marketplace from three complementary perspectives:

- **Product Analytics:** Customer purchasing behavior, repeat purchases, retention proxies, and customer experience.
- **Business Analysis:** Marketplace performance, seller contribution, category performance, and operational bottlenecks.
- **Business Intelligence:** Reliable KPI definitions, data quality assessment, SQL-based analysis, and dashboard-ready metrics.

The goal is to transform raw marketplace data into actionable business insights and recommendations.

## 2. Business Objectives

The project aims to:

1. Understand customer purchasing and repeat-purchase behavior.
2. Evaluate delivery performance and its relationship with customer satisfaction.
3. Identify product categories and sellers that contribute most to marketplace sales.
4. Analyze payment preferences and their relationship with order value.
5. Identify operational and geographic logistics bottlenecks.
6. Define measurable KPIs and communicate the limitations of the available data.
7. Translate analytical findings into practical business recommendations.

## 3. Key Business & Product Questions

### Q1. Customer Retention & Repeat Purchase

**Business question:**

What percentage of unique customers place more than one delivered order, and how long does it typically take them to make their second purchase?

**Why it matters:**

Repeat purchasing helps assess customer loyalty and the marketplace's ability to retain existing customers.

**Analysis approach:**

- Identify customers using `customer_unique_id`.
- Count delivered orders per customer.
- Calculate lifetime repeat-purchase rate.
- Calculate the time between the first and second delivered purchases.
- Segment results by customer acquisition month where appropriate.

**Key metrics:**

- Lifetime Repeat Purchase Rate
- Orders per Customer
- Median Time to Second Purchase

**Data limitations:**

The dataset does not contain customer session or engagement events. Repeat purchasing is therefore measured through completed transactions rather than general platform activity.

---

### Q2. Delivery Performance vs. Customer Satisfaction

**Business question:**

How does late delivery relate to customer review scores? Are orders delivered later than promised more likely to receive low ratings?

**Why it matters:**

Delivery reliability can affect customer experience and future purchasing decisions.

**Analysis approach:**

- Compare actual delivery dates with estimated delivery dates.
- Classify delivered orders as on-time or late.
- Compare average review scores and low-score rates across these groups.
- Examine the relationship between delivery delay duration and review score.

**Key metrics:**

- Delivery Delay Rate
- Average Review Score
- Low Review Score Rate (1–2 stars)
- Median Delivery Delay Days

**Data limitations:**

Review scores are customer feedback proxies, not a complete measure of customer satisfaction. The analysis identifies associations and does not establish causation.

---

### Q3. Fulfillment Lead Time

**Business question:**

How long does it take for an order to be delivered after purchase, and how does delivery lead time vary across Brazilian states?

**Why it matters:**

Long fulfillment times can indicate operational inefficiencies and affect customer experience.

**Analysis approach:**

- Calculate the time between `order_purchase_timestamp` and `order_delivered_customer_date`.
- Analyze median and average delivery lead time.
- Compare delivery performance by customer state.
- Identify states with unusually long delivery times.

**Key metrics:**

- Median Delivery Lead Time
- Average Delivery Lead Time
- Delivery Lead Time by Customer State

**Data limitations:**

The dataset provides order-level timestamps but does not contain detailed warehouse processing or transportation event logs. Therefore, the analysis measures end-to-end delivery time rather than individual logistics stages.

---

### Q4. Product Category Performance

**Business question:**

Which product categories contribute most to delivered sales value, and which categories have the highest order cancellation rates?

**Why it matters:**

Category-level performance helps identify important revenue contributors and potential operational problems.

**Analysis approach:**

- Join products with order items.
- Map category names using the product category translation table.
- Calculate delivered item sales by category.
- Calculate cancellation rates using orders associated with each category.
- Rank categories by sales contribution and cancellation rate.

**Key metrics:**

- Delivered GMV by Category
- Category Sales Contribution
- Category Cancellation Rate
- Number of Delivered Orders by Category

**Data limitations:**

Orders may contain products from multiple categories. For category-level cancellation analysis, an order is associated with every category represented in its order items. Category-level cancellation rates should therefore not be summed to calculate the marketplace-wide cancellation rate.

---

### Q5. Payment Preferences & Average Order Value

**Business question:**

Do orders paid through multiple installments have a different average order value compared with orders paid in a single installment?

**Why it matters:**

Understanding payment preferences can help evaluate the relationship between payment flexibility and transaction value.

**Analysis approach:**

- Aggregate payment records at the order level.
- Identify orders with installment payments.
- Compare order value across installment groups.
- Analyze payment types and installment distributions.

**Key metrics:**

- Average Order Value by Installment Group
- Median Order Value by Installment Group
- Payment Method Distribution
- Average Number of Installments

**Data limitations:**

An order may have multiple payment records or payment methods. Payment data must be aggregated to one row per order before joining it with order-level metrics. The analysis is observational and cannot prove that installments cause higher order values.

---

### Q6. Seller Concentration & Marketplace Dependency

**Business question:**

What proportion of delivered marketplace sales is generated by the top 5% of sellers? How dependent is the marketplace on its largest sellers?

**Why it matters:**

High seller concentration may expose the marketplace to supply-side risks if a small number of sellers account for a large share of sales.

**Analysis approach:**

- Aggregate delivered item sales by seller.
- Rank sellers by delivered GMV.
- Calculate the cumulative sales contribution of the top 5% of sellers.
- Compare sales concentration across seller groups.

**Key metrics:**

- Delivered GMV by Seller
- Top 5% Seller GMV Share
- Cumulative Seller GMV Contribution
- Number of Active Sellers

**Data limitations:**

This analysis measures sales concentration, not actual business risk. Seller capacity, inventory availability, contractual dependency, and seller churn are not available in the dataset.

---

### Q7. Order Cancellation & Status Distribution

**Business question:**

What proportion of placed orders is canceled, and how does cancellation vary over time, across product categories, and across customer or seller locations?

**Why it matters:**

Cancellations can indicate problems related to payment, inventory, fulfillment, or customer expectations.

**Analysis approach:**

- Analyze the distribution of final order statuses.
- Calculate the overall cancellation rate.
- Analyze cancellation trends over time.
- Compare cancellation rates across categories and geographic segments where the data supports the analysis.

**Key metrics:**

- Order Cancellation Rate
- Canceled Order Count
- Cancellation Rate by Month
- Cancellation Rate by Category

**Data limitations:**

The dataset contains order status fields and selected timestamps, but it does not provide a complete event history of every status transition. Therefore, a reliable stage-by-stage funnel drop-off analysis cannot be performed.

---

### Q8. Geographic Logistics Bottlenecks

**Business question:**

Which buyer-seller state pairs experience the longest delivery times? Is the approximate geographic distance between buyers and sellers associated with delivery time or freight cost?

**Why it matters:**

Geographic patterns can reveal potential logistics bottlenecks and opportunities for better seller coverage or fulfillment planning.

**Analysis approach:**

- Connect customer and seller locations to their respective order items.
- Compare buyer and seller states.
- Use postal-code coordinates to estimate geographic distance where possible.
- Compare estimated distance with delivery lead time and freight value.

**Key metrics:**

- Median Delivery Lead Time by Buyer-Seller State Pair
- Average Freight Value by Geographic Segment
- Approximate Buyer-Seller Distance
- Delivery Time vs. Approximate Distance

**Data limitations:**

Postal-code prefixes can map to multiple geographic coordinates. Coordinates must be handled carefully, and any calculated distance is an approximation (such as straight-line distance), not the actual transportation route distance.

---

### Q9. Freight Cost & Customer Experience

**Business question:**

How significant are shipping costs relative to item prices, and are orders with higher relative freight costs associated with lower review scores?

**Why it matters:**

High shipping costs may create friction in the purchasing experience and influence customer perceptions.

**Analysis approach:**

- Calculate freight-to-price ratios at the order-item level.
- Optionally aggregate freight and item prices at the order level to calculate an order-level ratio.
- Compare freight ratios across review score groups.
- Examine the relationship between freight cost and review scores.

**Key metrics:**

- Median Item-Level Freight-to-Price Ratio
- Median Order-Level Freight-to-Price Ratio
- Average Review Score by Freight Ratio Group
- Low Review Score Rate by Freight Ratio Group

**Data limitations:**

The dataset does not include product page visits, cart activity, checkout initiation, or conversion events. Therefore, the impact of shipping costs on conversion cannot be measured.

---

### Q10. Customer Satisfaction Drivers

**Business question:**

Which measurable order characteristics are associated with higher or lower customer review scores?

**Why it matters:**

Identifying factors associated with customer feedback can help prioritize improvements in delivery and marketplace operations.

**Analysis approach:**

- Compare review scores across delivery performance groups.
- Analyze the relationship between review scores and freight costs.
- Compare review scores across product categories and geographic segments.
- Examine differences between 1-star and 5-star reviewed orders.

**Key metrics:**

- Average Review Score
- Low Review Score Rate (1–2 stars)
- Review Score by Delivery Performance
- Review Score by Freight Ratio Group
- Review Score by Product Category

**Data limitations:**

The dataset does not contain a direct seller rating field. Review scores are linked to orders, not directly to sellers. Any seller-level review analysis must clearly define how order reviews are attributed to sellers, especially when an order contains items from multiple sellers.

## 4. Scope & Analytical Boundaries

### In Scope

- Historical transactional analysis
- Customer repeat-purchase behavior
- Order and payment analysis
- Product category performance
- Seller sales contribution
- Delivery and logistics performance
- Customer review analysis
- KPI development and dashboard reporting
- Business recommendations based on observed patterns

### Out of Scope

The following analyses cannot be reliably performed with the available dataset:

- Website or app conversion rate
- Product view-to-cart conversion
- Checkout funnel analysis
- Daily or weekly active users based on engagement events
- Customer acquisition cost (CAC)
- Marketing channel attribution
- A/B testing and causal experimentation
- Direct seller performance ratings
- Actual transportation route optimization
- Marketplace net revenue and profit calculation without commission and cost data

## 5. Analytical Approach

The project follows an end-to-end analytical workflow:

1. **Business Understanding:** Define business questions and analytical objectives.
2. **Data Understanding:** Inspect dataset structure, relationships, data types, and limitations.
3. **Data Quality Assessment:** Evaluate missing values, duplicates, invalid records, and consistency.
4. **SQL Analysis:** Build reusable queries and calculate business metrics.
5. **Python EDA:** Explore distributions, trends, relationships, and potential anomalies.
6. **Product & Business Insights:** Interpret results in the context of marketplace performance.
7. **Power BI Dashboard:** Present the most important metrics and findings.
8. **Recommendations:** Translate findings into actionable business opportunities.

## 6. Expected Deliverables

- Business Understanding Document
- Dataset Dictionary
- Product Metrics & KPI Framework
- SQL Data Exploration and Analysis
- Python Exploratory Data Analysis
- Power BI Dashboard
- Final Insights & Business Recommendations

## 7. Key Analytical Principle

Every analysis should follow this sequence:

**Business Question → Metric Definition → Data Validation → SQL/Python Analysis → Insight → Business Recommendation**

All conclusions must distinguish between observed relationships and causal explanations. Data limitations must be documented rather than hidden.