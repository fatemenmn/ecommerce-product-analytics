# Olist E-Commerce Product Metrics & KPIs Definition

This document establishes the primary metrics and Key Performance Indicators (KPIs) used to evaluate business performance, user retention, operational efficiency, and customer satisfaction on the Olist marketplace platform.

---

## 1. Growth & Revenue Metrics

| Metric Name | Description & Product Importance | Mathematical Formula / Business Logic | Primary Source Tables |
| :--- | :--- | :--- | :--- |
| **Gross Merchandise Value (GMV)** | Total sales value generated across the marketplace. Indicates platform transaction volume. | $$\text{GMV} = \sum (\text{item\_price})$$ *(Excluding freight charges unless specified).* | `olist_order_items_dataset` |
| **Average Order Value (AOV)** | Average dollar amount spent per single order. Tracks purchasing power and basket size. | $$\text{AOV} = \frac{\text{Total GMV}}{\text{Total Number of Delivered Orders}}$$ | `olist_order_items_dataset`, `olist_orders_dataset` |
| **Order Frequency** | Average number of orders placed by a single user over a given timeframe. | $$\text{Order Frequency} = \frac{\text{Total Delivered Orders}}{\text{Total Unique Customers}}$$ | `olist_orders_dataset`, `olist_customers_dataset` |
| **Platform Take Rate** | Estimated platform commission earned from seller sales. | $$\text{Take Rate (\%)} = \left( \frac{\text{Platform Fee Revenue}}{\text{Total GMV}} \right) \times 100$$ | `olist_order_items_dataset` |

---

## 2. Engagement & Retention Metrics

| Metric Name | Description & Product Importance | Mathematical Formula / Business Logic | Primary Source Tables |
| :--- | :--- | :--- | :--- |
| **Active User (Monthly)** | Define active buyers (MAU proxy) since Olist lacks event/clickstream logs. | **Logic:** Any unique customer (`customer_unique_id`) with $\ge 1$ purchase order in status `delivered` or `shipped` within a 30-day window. | `olist_orders_dataset`, `olist_customers_dataset` |
| **Repeat Purchase Rate** | Proportion of unique users who have made more than 1 transaction on Olist. | $$\text{Repurchase Rate (\%)} = \left( \frac{\text{Count of Users with } > 1 \text{ Order}}{\text{Total Unique Customers}} \right) \times 100$$ | `olist_customers_dataset`, `olist_orders_dataset` |
| **Order Cancellation Rate** | Percentage of initiated orders that fail to complete or reach delivery. | $$\text{Cancellation Rate (\%)} = \left( \frac{\text{Count of Canceled Orders}}{\text{Total Placed Orders}} \right) \times 100$$ | `olist_orders_dataset` |

---

## 3. Operations & Customer Experience (CX) Metrics

| Metric Name | Description & Product Importance | Mathematical Formula / Business Logic | Primary Source Tables |
| :--- | :--- | :--- | :--- |
| **Delivery Lead Time** | Average time taken from customer order placement to physical receipt. | $$\text{Lead Time (Days)} = \text{AVG}(\text{order\_delivered\_customer\_date} - \text{order\_purchase\_timestamp})$$ | `olist_orders_dataset` |
| **Delivery Delay Rate** | Percentage of orders delivered past the promised estimated delivery date. | $$\text{Delay Rate (\%)} = \left( \frac{\text{Count of Orders where Actual Delivery Date} > \text{Estimated Date}}{\text{Total Delivered Orders}} \right) \times 100$$ | `olist_orders_dataset` |
| **Average Review Score** | Primary CSAT metric measuring buyer satisfaction post-fulfillment. | $$\text{Average Review Score} = \frac{\sum (\text{review\_score})}{\text{Total Count of Reviews}}$$ | `olist_order_reviews_dataset` |

---

## 4. Key Metric Guardrails & Trade-offs

* **Primary Metric vs. Guardrail Metric:** When attempting to boost **GMV** or **AOV** (e.g., via seller promotions or cross-selling), **Delivery Lead Time** and **Order Cancellation Rate** serve as guardrail metrics to ensure service quality is not compromised.
* **CX Impact:** A high **Delivery Delay Rate** directly correlates with a lower **Average Review Score**, making fulfillment speed a key input metric for user retention.