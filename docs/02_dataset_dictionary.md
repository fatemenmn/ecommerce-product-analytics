# Olist E-Commerce Dataset Dictionary

This document provides an overview of the 8 relational datasets included in the Olist Brazilian E-Commerce database, detailing table primary/foreign keys, core fields, and their relevance to product analytics.

---

## Data Schema & Relationships Overview

[olist_customers] (customer_id) <---> (customer_id) [olist_orders]
[olist_orders]    (order_id)    <---> (order_id)    [olist_order_items]
[olist_orders]    (order_id)    <---> (order_id)    [olist_order_payments]
[olist_orders]    (order_id)    <---> (order_id)    [olist_order_reviews]
[olist_order_items] (product_id)<---> (product_id)  [olist_products]
[olist_order_items] (seller_id) <---> (seller_id)   [olist_sellers]


> ⚠️ **Key Product Analytics Distinction:**
> - `customer_id`: Unique identifier generated **per order** (transactional key).
> - `customer_unique_id`: Unique identifier for the **actual human user** (behavioral key).
> - **Rule:** Always use `customer_unique_id` when calculating User Retention, Repeat Purchase Rate, and Customer Lifetime Value (CLV).

---

## Tables & Field Definitions

### 1. `olist_orders_dataset`
Central table representing order lifecycle and timestamps.

| Field Name | Data Type | Primary/Foreign Key | Description & Product Use |
| :--- | :--- | :--- | :--- |
| `order_id` | String | Primary Key | Unique order identifier. |
| `customer_id` | String | Foreign Key | Links to transaction-level customer details. |
| `order_status` | String | - | Order lifecycle state (`delivered`, `canceled`, `shipped`, etc.). Essential for order drop-off analysis. |
| `order_purchase_timestamp` | Timestamp | - | Exact time purchase was made. Used for daily/monthly active metrics and time series. |
| `order_delivered_customer_date` | Timestamp | - | Actual delivery timestamp. Used for calculating fulfillment lead time. |
| `order_estimated_delivery_date` | Timestamp | - | Promised delivery date. Used for estimating Delivery Delay Rate. |

### 2. `olist_order_items_dataset`
Line items within each order, linking products and sellers.

| Field Name | Data Type | Primary/Foreign Key | Description & Product Use |
| :--- | :--- | :--- | :--- |
| `order_id` | String | Foreign Key | Order identifier. |
| `order_item_id` | Integer | - | Sequential number of items within the same order. |
| `product_id` | String | Foreign Key | Links to product catalog. |
| `seller_id` | String | Foreign Key | Links to merchant details. |
| `price` | Float | - | Item price per unit. Primary input for Gross Merchandise Value (GMV). |
| `freight_value` | Float | - | Shipping cost charged to the customer. |

### 3. `olist_customers_dataset`
Customer demographic mapping.

| Field Name | Data Type | Primary/Foreign Key | Description & Product Use |
| :--- | :--- | :--- | :--- |
| `customer_id` | String | Primary Key | Transactional customer ID. |
| `customer_unique_id` | String | - | Real user ID. Used for Retention, Cohorts, and Repurchase Analysis. |
| `customer_zip_code_prefix` | String | Foreign Key | Customer postal code prefix. |
| `customer_city` | String | - | Customer city location. |
| `customer_state` | String | - | Customer state (e.g., SP, RJ). |

### 4. `olist_products_dataset`
Catalog attributes of items sold on the platform.

| Field Name | Data Type | Primary/Foreign Key | Description & Product Use |
| :--- | :--- | :--- | :--- |
| `product_id` | String | Primary Key | Product identifier. |
| `product_category_name` | String | - | Category in Portuguese (cross-reference with translation table). |
| `product_weight_g` | Float | - | Weight in grams. Useful for logistics analysis. |
| `product_length_cm` / `height_cm` / `width_cm` | Float | - | Product dimensions for freight/shipping calculations. |

### 5. `olist_order_payments_dataset`
Payment methods and installment structures per order.

| Field Name | Data Type | Primary/Foreign Key | Description & Product Use |
| :--- | :--- | :--- | :--- |
| `order_id` | String | Foreign Key | Associated order ID. |
| `payment_type` | String | - | Payment channel (`credit_card`, `boleto`, `voucher`, `debit_card`). |
| `payment_installments` | Integer | - | Number of payment installments chosen by the customer. |
| `payment_value` | Float | - | Total monetary amount paid for the transaction. |

### 6. `olist_order_reviews_dataset`
Customer feedback and rating scores post-delivery.

| Field Name | Data Type | Primary/Foreign Key | Description & Product Use |
| :--- | :--- | :--- | :--- |
| `review_id` | String | Primary Key | Review record ID. |
| `order_id` | String | Foreign Key | Associated order ID. |
| `review_score` | Integer (1–5) | - | Satisfaction rating. Key CX metric (CSAT / Review Score Average). |
| `review_creation_date` | Timestamp | - | Survey creation date. |

### 7. `olist_sellers_dataset`
Merchant geographic and identity data.

| Field Name | Data Type | Primary/Foreign Key | Description & Product Use |
| :--- | :--- | :--- | :--- |
| `seller_id` | String | Primary Key | Merchant identifier. |
| `seller_city` | String | - | Seller city. |
| `seller_state` | String | - | Seller state location. |

### 8. `olist_geolocation_dataset`
Geographic coordinates for mapping logistics and distance.

| Field Name | Data Type | Primary/Foreign Key | Description & Product Use |
| :--- | :--- | :--- | :--- |
| `geolocation_zip_code_prefix` | String | - | Postal prefix key. |
| `geolocation_lat` / `geolocation_lng` | Float | - | Latitude and longitude values. |