# Olist E-Commerce Dataset Dictionary

## 1. Overview

The Olist Brazilian E-Commerce dataset contains relational data about orders, customers, products, sellers, payments, reviews, and geographic locations.

This document describes the main tables, their row-level granularity (grain), primary and foreign keys, important fields, and relationships.

The dataset contains **9 CSV tables**:

1. `olist_orders_dataset`
2. `olist_order_items_dataset`
3. `olist_customers_dataset`
4. `olist_products_dataset`
5. `olist_order_payments_dataset`
6. `olist_order_reviews_dataset`
7. `olist_sellers_dataset`
8. `olist_geolocation_dataset`
9. `product_category_name_translation`

> Table names in this document refer to the original CSV files. The actual SQL table names may differ depending on the database import process.

---

## 2. Data Model & Relationships

### 2.1 Main Relationships

```text
olist_customers_dataset
        |
        | customer_id
        |
olist_orders_dataset
        |
        | order_id
        |
        +--------------------+
        |                    |
        |                    |
olist_order_items_dataset   olist_order_payments_dataset
        |                    |
        |                    |
        |                    |
        +---- olist_products_dataset
        |
        +---- olist_sellers_dataset

olist_orders_dataset
        |
        +---- olist_order_reviews_dataset

olist_products_dataset
        |
        +---- product_category_name_translation
```

Geolocation is a separate geographic lookup table:

```text
olist_customers_dataset.customer_zip_code_prefix
        |
        | postal code prefix
        |
olist_geolocation_dataset.geolocation_zip_code_prefix

olist_sellers_dataset.seller_zip_code_prefix
        |
        | postal code prefix
        |
olist_geolocation_dataset.geolocation_zip_code_prefix
```

### 2.2 Important Relationship Notes

- `customer_id` links an order to a customer record.
- `customer_unique_id` identifies the same customer across multiple customer records and is the preferred identifier for repeat-purchase analysis.
- `order_id` links orders to order items, payments, and reviews.
- `product_id` links order items to product information.
- `seller_id` links order items to seller information.
- `product_category_name` links products to translated category names.
- Postal code prefixes can be used to connect customers and sellers to geographic coordinates, but this relationship is not necessarily one-to-one.

---

## 3. Table Definitions

### 3.1 `olist_orders_dataset`

**Description:** Central transaction table containing order status and lifecycle timestamps.

**Grain:** One row per order.

**Primary Key:** `order_id`

**Foreign Key:** `customer_id` references `olist_customers_dataset.customer_id`.

| Field Name | Data Type | Key | Description & Analytical Use |
|---|---|---|---|
| `order_id` | String | PK | Unique order identifier. |
| `customer_id` | String | FK | Customer record associated with the order. |
| `order_status` | String | - | Final recorded order status, such as delivered, shipped, canceled, unavailable, or invoiced. |
| `order_purchase_timestamp` | Timestamp | - | Timestamp when the order was placed. |
| `order_approved_at` | Timestamp | - | Timestamp when the order was approved. |
| `order_delivered_carrier_date` | Timestamp | - | Timestamp when the order was handed to the carrier. |
| `order_delivered_customer_date` | Timestamp | - | Timestamp when the order was delivered to the customer. |
| `order_estimated_delivery_date` | Timestamp | - | Estimated delivery date communicated to the customer. |

**Analytical Use Cases:**

- Order volume and trends
- Order cancellation rate
- Delivery lead time
- Delivery delay rate
- Monthly purchasing activity
- Customer repeat-purchase behavior

**Important Notes:**

- Some timestamps may be NULL depending on the order status.
- Delivery performance calculations should generally use delivered orders with valid actual and estimated delivery timestamps.
- `order_id` should be unique in this table.

---

### 3.2 `olist_order_items_dataset`

**Description:** Contains the individual product items included in each order.

**Grain:** One row per order item (one product line within an order).

**Primary Key:** Composite key of `order_id` and `order_item_id`.

**Foreign Keys:**
- `order_id` references `olist_orders_dataset.order_id`.
- `product_id` references `olist_products_dataset.product_id`.
- `seller_id` references `olist_sellers_dataset.seller_id`.

| Field Name | Data Type | Key | Description & Analytical Use |
|---|---|---|---|
| `order_id` | String | Composite PK / FK | Associated order identifier. |
| `order_item_id` | Integer | Composite PK | Sequential item number within an order. |
| `product_id` | String | FK | Product included in the order. |
| `seller_id` | String | FK | Seller responsible for the item. |
| `shipping_limit_date` | Timestamp | - | Seller shipping deadline. |
| `price` | Float | - | Price of the item. |
| `freight_value` | Float | - | Freight value associated with the item. |

**Analytical Use Cases:**

- Delivered GMV
- Average Order Value
- Product category performance
- Seller sales contribution
- Freight cost analysis
- Product and seller relationships

**Important Notes:**

- One order can contain multiple items.
- One order can contain products from multiple sellers.
- `price` is an item-level value, not an order-level total.
- Summing `price` by order produces the order's item value.
- Summing `price` across delivered order items produces Delivered GMV under this project's definition.
- `freight_value` is recorded at the order-item level.

---

### 3.3 `olist_customers_dataset`

**Description:** Contains customer records and geographic information.

**Grain:** One row per customer record (`customer_id`).

**Primary Key:** `customer_id`

| Field Name | Data Type | Key | Description & Analytical Use |
|---|---|---|---|
| `customer_id` | String | PK | Customer record identifier associated with an order. |
| `customer_unique_id` | String | - | Persistent customer identifier across multiple customer records. |
| `customer_zip_code_prefix` | String | - | Customer postal code prefix. |
| `customer_city` | String | - | Customer city. |
| `customer_state` | String | - | Customer state abbreviation. |

**Analytical Use Cases:**

- Unique customer count
- Repeat-purchase analysis
- Customer segmentation
- Geographic analysis
- Monthly purchasing buyers

**Important Notes:**

- `customer_id` is not the correct identifier for lifetime customer behavior across orders.
- Use `customer_unique_id` to identify repeat buyers and calculate customer-level metrics.
- A customer may have multiple `customer_id` records associated with different orders.
- Postal code prefixes are geographic identifiers, not guaranteed unique geographic coordinates.

---

### 3.4 `olist_products_dataset`

**Description:** Contains product catalog attributes.

**Grain:** One row per product.

**Primary Key:** `product_id`

| Field Name | Data Type | Key | Description & Analytical Use |
|---|---|---|---|
| `product_id` | String | PK | Unique product identifier. |
| `product_category_name` | String | FK-like lookup | Product category name in Portuguese. |
| `product_name_lenght` | Integer | - | Product name character length (original dataset spelling). |
| `product_description_lenght` | Integer | - | Product description character length (original dataset spelling). |
| `product_photos_qty` | Integer | - | Number of product photos. |
| `product_weight_g` | Float | - | Product weight in grams. |
| `product_length_cm` | Float | - | Product length in centimeters. |
| `product_height_cm` | Float | - | Product height in centimeters. |
| `product_width_cm` | Float | - | Product width in centimeters. |

**Analytical Use Cases:**

- Product category performance
- Product catalog analysis
- Product dimension and weight analysis
- Freight and logistics exploration

**Important Notes:**

- The original dataset uses the column names `product_name_lenght` and `product_description_lenght`; preserve these spellings when querying the raw data.
- Product category names can be translated using `product_category_name_translation`.
- Some product attributes may be NULL.

---

### 3.5 `olist_order_payments_dataset`

**Description:** Contains payment information for orders.

**Grain:** One row per payment record within an order.

**Primary Key:** No single declared primary key in the raw dataset. A practical row identifier can be formed using `order_id` and `payment_sequential`.

**Foreign Key:** `order_id` references `olist_orders_dataset.order_id`.

| Field Name | Data Type | Key | Description & Analytical Use |
|---|---|---|---|
| `order_id` | String | FK | Associated order identifier. |
| `payment_sequential` | Integer | Composite row identifier | Sequential payment number within an order. |
| `payment_type` | String | - | Payment method, such as credit card, boleto, voucher, or debit card. |
| `payment_installments` | Integer | - | Number of installments selected. |
| `payment_value` | Float | - | Value associated with the payment record. |

**Analytical Use Cases:**

- Payment method distribution
- Installment behavior
- Payment value analysis
- AOV comparison by payment behavior

**Important Notes:**

- An order may have multiple payment records.
- Payment records must be aggregated to the order level before joining them with order-level metrics.
- Joining raw payment rows directly to order items can multiply rows and inflate sales or payment totals.
- Payment value and item price are different measures and should not be treated as interchangeable without reconciliation.

---

### 3.6 `olist_order_reviews_dataset`

**Description:** Contains customer reviews and feedback associated with orders.

**Grain:** One row per review record.

**Primary Key:** `review_id`

**Foreign Key:** `order_id` references `olist_orders_dataset.order_id`.

| Field Name | Data Type | Key | Description & Analytical Use |
|---|---|---|---|
| `review_id` | String | PK | Review record identifier. |
| `order_id` | String | FK | Associated order identifier. |
| `review_score` | Integer | - | Review score from 1 to 5. |
| `review_comment_title` | String | - | Optional review title. |
| `review_comment_message` | String | - | Optional written review. |
| `review_creation_date` | Timestamp | - | Review creation timestamp. |
| `review_answer_timestamp` | Timestamp | - | Timestamp when the review was answered. |

**Analytical Use Cases:**

- Average review score
- Low review score rate
- Delivery performance vs. customer feedback
- Review trends over time
- Customer experience analysis

**Important Notes:**

- Review scores are a proxy for customer satisfaction, not a complete measure of it.
- An order can have multiple review records in the raw dataset.
- Review data should be aggregated to the intended analytical grain before joining with other one-to-many tables.
- Do not assume `order_id` is unique in the reviews table without validating the data.

---

### 3.7 `olist_sellers_dataset`

**Description:** Contains seller identity and geographic information.

**Grain:** One row per seller.

**Primary Key:** `seller_id`

| Field Name | Data Type | Key | Description & Analytical Use |
|---|---|---|---|
| `seller_id` | String | PK | Unique seller identifier. |
| `seller_zip_code_prefix` | String | - | Seller postal code prefix. |
| `seller_city` | String | - | Seller city. |
| `seller_state` | String | - | Seller state abbreviation. |

**Analytical Use Cases:**

- Seller sales contribution
- Seller concentration
- Seller geographic distribution
- Buyer-seller geographic analysis

**Important Notes:**

- Seller-level GMV should be calculated from order items.
- The seller table does not contain a direct seller rating or seller profitability measure.
- Seller review analysis requires a clearly defined method for attributing order-level reviews to sellers.

---

### 3.8 `olist_geolocation_dataset`

**Description:** Contains geographic coordinates associated with Brazilian postal code prefixes.

**Grain:** One row per recorded geographic coordinate entry.

**Primary Key:** No declared primary key in the raw dataset.

| Field Name | Data Type | Key | Description & Analytical Use |
|---|---|---|---|
| `geolocation_zip_code_prefix` | String | Lookup key | Postal code prefix. |
| `geolocation_lat` | Float | - | Latitude coordinate. |
| `geolocation_lng` | Float | - | Longitude coordinate. |
| `geolocation_city` | String | - | City associated with the coordinate. |
| `geolocation_state` | String | - | State abbreviation. |

**Analytical Use Cases:**

- Approximate buyer-seller distance
- Geographic distribution
- Logistics analysis
- Mapping customers and sellers

**Important Notes:**

- A postal code prefix may have multiple coordinate records.
- Joining this table directly to customers or sellers can multiply rows.
- Before using it in analytical joins, create a validated geographic lookup, for example by aggregating coordinates to one representative point per postal code prefix.
- Any calculated straight-line distance is an approximation and does not represent actual transportation distance.

---

### 3.9 `product_category_name_translation`

**Description:** Maps Portuguese product category names to English translations.

**Grain:** One row per Portuguese product category name.

**Primary Key:** `product_category_name`

| Field Name | Data Type | Key | Description & Analytical Use |
|---|---|---|---|
| `product_category_name` | String | PK | Original category name in Portuguese. |
| `product_category_name_english` | String | - | English category translation. |

**Analytical Use Cases:**

- Readable category reporting
- Category-level GMV
- Category-level order analysis
- Product category dashboard filters

**Important Notes:**

- Join this table to `olist_products_dataset` using `product_category_name`.
- Some product records may have NULL category values or categories without a matching translation.
- Preserve the original category value when a translation is unavailable.

---

## 4. Grain & Join Risk Reference

Understanding table grain is essential to prevent double counting.

| Table | Grain | Expected Relationship to Orders |
|---|---|---|
| `olist_orders_dataset` | One row per order | Base order-level table |
| `olist_order_items_dataset` | One row per order item | One-to-many |
| `olist_order_payments_dataset` | One row per payment record | One-to-many |
| `olist_order_reviews_dataset` | One row per review record | Potentially one-to-many |
| `olist_customers_dataset` | One row per customer record | One-to-many across a customer's orders |
| `olist_products_dataset` | One row per product | One-to-many through order items |
| `olist_sellers_dataset` | One row per seller | One-to-many through order items |
| `olist_geolocation_dataset` | One row per coordinate record | Potentially one-to-many by postal prefix |
| `product_category_name_translation` | One row per category | One-to-many through products |

### Critical Join Risks

**1. Orders and Order Items**

One order may contain multiple items. Joining these tables changes the result grain from order-level to item-level.

**2. Orders and Payments**

One order may contain multiple payment records. Aggregate payments to one row per order before joining to other order-level or item-level metrics.

**3. Orders and Reviews**

An order may have multiple review records. Validate review uniqueness by `order_id` before joining.

**4. Customers and Geolocation**

A postal code prefix may have multiple coordinate records. Build a one-row-per-prefix geographic lookup before joining.

**5. Order Items, Products, and Sellers**

Each order item is associated with one product and one seller. Product and seller dimensions should be joined through the order item table.

---

## 5. Key Analytical Definitions

### Customer Identity

Use:

- `customer_id` for linking a specific order to its customer record.
- `customer_unique_id` for identifying a buyer across multiple orders.

For customer-level behavioral metrics, `customer_unique_id` is the preferred identifier.

### Delivered GMV

For this project:

**Delivered GMV = Sum of `price` across order items belonging to delivered orders.**

Freight charges are excluded from this definition.

### Order Value

**Order Item Value = Sum of `price` for all items within an order.**

An order-level aggregation is required before calculating AOV.

### Delivery Lead Time

**Delivery Lead Time = `order_delivered_customer_date` - `order_purchase_timestamp`.**

Use delivered orders with valid timestamps.

### Delivery Delay

**Delivery Delay = `order_delivered_customer_date` - `order_estimated_delivery_date`.**

A positive result indicates late delivery.

### Customer Repeat Purchase

A repeat buyer is a customer identified by `customer_unique_id` with at least two delivered orders.

---

## 6. Data Quality Considerations

The following checks should be completed during Data Exploration:

- Validate primary key uniqueness.
- Check foreign key integrity.
- Inspect NULL values in important fields.
- Identify duplicate records.
- Validate timestamp consistency.
- Inspect unexpected order statuses.
- Check negative or zero monetary values.
- Validate product and seller references.
- Check whether review and payment records are unique at the expected grain.
- Inspect postal code prefixes before geographic joins.
- Compare aggregated payment values with order item values where appropriate.

---

## 7. Source & Dataset Limitations

The dataset is historical transactional data, not a complete behavioral event stream.

It does not provide:

- Website or app sessions
- Product page views
- Add-to-cart events
- Checkout initiation events
- Marketing campaign attribution
- Marketing spend
- Seller commissions
- Complete logistics tracking events
- Direct seller ratings
- Customer profit or lifetime contribution margin

These limitations determine which product and business metrics can be calculated directly, approximated, or cannot be measured.

## 8. Analytical Best Practices

1. Always define the grain of a query before joining tables.
2. Aggregate one-to-many tables before joining them when calculating order-level metrics.
3. Use `customer_unique_id` for customer-level behavioral analysis.
4. Use delivered orders consistently when calculating completed-purchase metrics.
5. Keep item-level and order-level metrics separate.
6. Document assumptions and exclusions.
7. Validate every KPI against its population and source tables before using it in a dashboard.