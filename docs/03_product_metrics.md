# Olist E-Commerce Product Metrics & KPI Framework

This document outlines the core product and business metrics defined for analyzing the Olist Marketplace dataset. It incorporates data governance status indicators, precise population definitions, statistical considerations (mean vs. median), and explicit data limitation constraints.

---

## 🟢 Metric Status Legend

| Status | Meaning | Portfolio Application |
| :--- | :--- | :--- |
| 🟢 **Directly Measurable** | The metric can be accurately calculated directly from the dataset. | Standard SQL queries with explicit population filters. |
| 🟡 **Proxy Metric** | The metric is approximated using an alternative behavioral data point. | Substituted due to missing event/clickstream logs. |
| 🔴 **Not Measurable** | Required data fields do not exist in the public Olist schema. | Explicitly documented under Data Limitations. |

---

## 1. Revenue & Scale Metrics

| Metric Name | Status | Description & Product Purpose | Mathematical / Logic Definition | Source Tables & Filtering Rules |
| :--- | :---: | :--- | :--- | :--- |
| **Gross Merchandise Value (GMV)** | 🟢 | Total net sales value of delivered orders. Measures actual realized marketplace size. | $$\text{GMV} = \sum (\text{item\_price})$$ | `olist_order_items`, `olist_orders`<br>*(Population Filter: `order_status = 'delivered'`)* |
| **Average Order Value (AOV)** | 🟢 | Average net item sales value per delivered order (excluding freight charges). | $$\text{AOV} = \frac{\text{GMV of Delivered Orders}}{\text{Total Count of Delivered Orders}}$$ | `olist_order_items`, `olist_orders`<br>*(Population aligned to `order_status = 'delivered'`)* |
| **Orders per Customer** | 🟢 | Average delivered order volume density per unique buyer over their lifetime. | $$\text{Orders/Customer} = \frac{\text{Total Delivered Orders}}{\text{Total Unique Customers}}$$ | `olist_orders`, `olist_customers`<br>*(Grouped by `customer_unique_id`)* |

---

## 2. Retention & Loyalty Metrics

| Metric Name | Status | Description & Product Purpose | Mathematical / Logic Definition | Source Tables & Filtering Rules |
| :--- | :---: | :--- | :--- | :--- |
| **Monthly Active Buyers** | 🟡 | Active user proxy. Unique buyers completing $\ge 1$ delivered purchase in a calendar month. | $$\text{Active Buyers} = \text{COUNT}(\text{DISTINCT } \text{customer\_unique\_id})$$ | `olist_orders`, `olist_customers`<br>*(Filter: `order_status = 'delivered'`)* |
| **Lifetime Repeat Purchase Rate** | 🟢 | Percentage of unique buyers who placed $\ge 2$ delivered orders over their lifetime. | $$\left( \frac{\text{Buyers with } \ge 2 \text{ Delivered Orders}}{\text{Total Unique Buyers with } \ge 1 \text{ Delivered Order}} \right) \times 100$$ | `olist_customers`, `olist_orders`<br>*(Filter: `order_status = 'delivered'`)* |
| **30-Day Repeat Purchase Rate** | 🟢 | Percentage of buyers placing a 2nd order within 30 days of their initial purchase date. | $$\left( \frac{\text{Buyers placing 2nd order within 30 days of Order 1}}{\text{Total First-Time Buyers}} \right) \times 100$$ | `olist_orders`, `olist_customers`<br>*(Day 0 defined as timestamp of initial order)* |
| **Time to Second Purchase** | 🟢 | Median days elapsed between a buyer's 1st and 2nd transaction. Measures retention velocity. | $$\text{Median}(\text{Timestamp}_{\text{Order 2}} - \text{Timestamp}_{\text{Order 1}})$$ | `olist_orders`, `olist_customers`<br>*(SQL Window Functions)* |
| **Category Repeat Share** | 🟢 | Proportion of category buyers who made $\ge 2$ purchases within the same category $C$. | $$\frac{\text{Unique Buyers with } \ge 2 \text{ Orders in Category } C}{\text{Total Unique Buyers in Category } C}$$ | `olist_products`, `olist_order_items`, `olist_customers`<br>*(Evaluates intra-category loyalty)* |

---

## 3. Operational & CX Guardrail Metrics

| Metric Name | Status | Description & Product Purpose | Mathematical / Logic Definition | Source Tables & Filtering Rules |
| :--- | :---: | :--- | :--- | :--- |
| **Median Delivery Lead Time** | 🟢 | Physical fulfillment speed. *Median prevents extreme delay distribution skewness.* | $$\text{Median}(\text{delivered\_date} - \text{purchase\_timestamp})$$ | `olist_orders`<br>*(Filter: `order_status = 'delivered'`)* |
| **Delivery Delay Rate** | 🟢 | **Guardrail + Diagnostic Metric.** % of delivered orders received past promised estimate. | $$\left( \frac{\text{Orders with Actual Delivery} > \text{Estimated Date}}{\text{Total Delivered Orders}} \right) \times 100$$ | `olist_orders`<br>*(Filter: `order_status = 'delivered'`)* |
| **Order Cancellation Rate** | 🟢 | Order lifecycle drop-off rate. Measures fulfillment, payment, or inventory failures. | $$\left( \frac{\text{Count of Canceled Orders}}{\text{Total Placed Orders}} \right) \times 100$$ | `olist_orders`<br>*(All order statuses included)* |
| **Average Review Score** | 🟢 | Customer Satisfaction Proxy. Average post-fulfillment rating score (1–5 scale). | $$\text{Average Rating} = \frac{\sum \text{review\_score}}{\text{Total Reviews}}$$ | `olist_order_reviews` |
| **Freight-to-Price Friction Ratio** | 🟢 | Shipping cost relative to item price. Identifies pricing friction in shipping fees. | $$\text{Median} \left( \frac{\text{freight\_value}}{\text{price}} \right)$$ | `olist_order_items` |

---

## 4. Explicit Data Limitations (Unmeasurable Metrics)

To ensure analytical rigor, the following product metrics are **explicitly acknowledged as non-measurable** in this dataset:

* 🔴 **Platform Revenue & Take Rate:** Olist's commission rates per category/seller are omitted.
* 🔴 **Customer Acquisition Cost (CAC) & Attribution:** Marketing spend and source channel data do not exist.
* 🔴 **Clickstream / Product Funnels:** Session logs, pageviews, add-to-cart, and checkout initiation events are absent.
* 🔴 **User Engagement / DAU & WAU:** Daily/Weekly active app users cannot be tracked due to lack of event logging.