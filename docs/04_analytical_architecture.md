# Analytical Architecture

## 1. Purpose

This document defines how the Olist source data will be transformed into reliable analytical outputs. It establishes the intended data flow, analytical grains, join rules, and separation between source data, analysis logic, reporting models, and business interpretation.

The architecture is deliberately lightweight: it is designed for a portfolio-scale analytical project and does not imply that Olist's original production infrastructure is available.

## 2. End-to-End Data Flow

```text
Olist public CSV files
        |
        v
MySQL source schema
        |
        +--> Schema and data-quality validation
        |
        v
SQL analysis layer
        |
        +--> Reusable order-level aggregates
        +--> Customer-level aggregates
        +--> Item/category/seller aggregates
        |
        v
Python analytical validation and EDA
        |
        v
Power BI semantic model
        |
        +--> Executive marketplace overview
        +--> Customer and product performance
        +--> Delivery and customer experience
        |
        v
Findings, limitations, and recommendations
```

The stages are logically separated even if the implementation uses a single local MySQL database and a small number of scripts.

## 3. Source Data

The project uses the nine public Olist CSV tables:

| Source table | Native grain | Primary analytical role |
|---|---|---|
| `olist_orders_dataset` | One row per order | Order lifecycle and timestamps |
| `olist_order_items_dataset` | One row per order item | Merchandise value, freight, product and seller attribution |
| `olist_customers_dataset` | One row per customer record | Customer attributes and customer identity mapping |
| `olist_products_dataset` | One row per product | Product attributes and category |
| `olist_order_payments_dataset` | One row per payment record | Payment type, value and installments |
| `olist_order_reviews_dataset` | One row per review record | Customer feedback scores |
| `olist_sellers_dataset` | One row per seller | Seller attributes |
| `olist_geolocation_dataset` | Multiple rows may exist per postal-code prefix | Approximate geographic lookup |
| `product_category_name_translation` | One row per source category translation | English category labels |

Actual SQL table names and column types must be confirmed after import. The CSV filenames are reference names, not proof that the imported MySQL tables use identical names.

## 4. Analytical Entities and Grains

The project will preserve the native grain of each source table and create aggregated datasets only when a business question requires them.

| Analytical entity | Intended grain | Typical use |
|---|---|---|
| Order | One row per `order_id` | Order counts, AOV, cancellation and delivery metrics |
| Order item | One row per `order_id` + `order_item_id` | Item sales, freight, category and seller analysis |
| Customer | One row per `customer_unique_id` | Unique buyers and repeat purchasing |
| Customer order | One row per customer and order | Purchase sequence and time to second purchase |
| Payment | One row per payment record | Payment method and installment distributions |
| Order payment summary | One row per `order_id` | Safe order-level payment comparisons |
| Review | One row per review record unless explicitly aggregated | Review-score distributions |
| Seller | One row per `seller_id` | Seller sales contribution |
| Category | One row per translated product category | Category sales and purchasing patterns |

Every analytical output must state its grain. Joins must not silently change that grain.

## 5. Relationship and Join Controls

The principal relationships are:

- Orders to customers: `customer_id`.
- Orders to order items: `order_id`.
- Order items to products: `product_id`.
- Order items to sellers: `seller_id`.
- Orders to payments: `order_id`.
- Orders to reviews: `order_id`.
- Products to category translations: `product_category_name`.
- Customers and sellers to geolocation: postal-code prefix.

### Join safeguards

1. Aggregate order items to one row per order before joining them to other order-level aggregates.
2. Aggregate payment records to one row per order before joining them to order-level sales.
3. Inspect review multiplicity per order before choosing review-level or order-level reporting.
4. Do not assume postal-code prefixes uniquely identify a coordinate. Profile duplicates and define a documented aggregation rule before using geolocation.
5. Use `customer_unique_id` for customer-level purchasing analysis; use `customer_id` to connect an order to its customer record.
6. Validate unmatched keys and row counts before and after material joins.

## 6. Metric Population and Definitions

The KPI definitions in [Product Metrics & KPI Framework](03_product_metrics.md) are the governing reference.

The following population rules apply throughout the project:

- Completed-purchase metrics use delivered orders unless a metric explicitly defines another population.
- Cancellation rate uses all placed orders in the dataset as its denominator.
- Delivery metrics require the timestamps needed for the calculation; records with missing required timestamps are not silently classified as on-time.
- Delivered GMV is merchandise item value for delivered orders. Freight is excluded.
- AOV is calculated from order-level merchandise value and distinct delivered orders, not item rows.
- Repeat purchasing is based on `customer_unique_id` and distinct delivered orders.
- Review scores are feedback proxies, not a complete measure of customer satisfaction.

## 7. Technology Responsibilities

| Technology | Responsibility | Expected artifacts |
|---|---|---|
| MySQL | Source-table inspection, data validation and reusable analysis queries | SQL scripts and query outputs |
| Python | Exploratory analysis, statistical checks and visualization | Notebooks or scripts and exported figures |
| Power BI | Semantic model, DAX measures and interactive reporting | PBIX file and dashboard screenshots |
| GitHub | Version control, reproducibility and project communication | Documentation, source code and selected deliverables |

The exact Python environment, MySQL version, and Power BI model design will be documented when implementation is validated.

## 8. Data Quality Gates

No KPI should be treated as report-ready until its underlying data passes the relevant checks:

- Expected source tables and columns are present.
- Declared primary keys are unique at their stated grain.
- Foreign-key relationships have been profiled for unmatched records.
- Required timestamps and numeric fields have plausible values.
- Missingness is quantified and explained.
- One-to-many joins have been tested for row multiplication.
- Metric numerator, denominator, grain and eligible population are explicit.

Detailed checks will be implemented in the SQL exploration and validation scripts.

## 9. Analytical Boundaries

The dataset contains historical transaction and review records, not product event telemetry. Therefore, it cannot directly support website/app conversion, add-to-cart rate, checkout abandonment, engagement-based DAU/WAU/MAU, marketing attribution, or observed A/B test results.

Any experiment proposal will be presented as a proposed future measurement design, not as an experiment conducted on this dataset.

Likewise, associations between delivery, freight, payment behavior and review scores will be described as observational relationships. They will not be presented as causal effects.

## 10. Architecture Decision Log

| Decision | Rationale |
|---|---|
| Preserve source-table grain | Prevents accidental double counting and makes joins auditable. |
| Use explicit aggregated outputs for cross-table analysis | Controls one-to-many join fan-out. |
| Use `customer_unique_id` for buyer-level analysis | Represents repeat purchases across customer records. |
| Keep raw CSV files out of Git | Avoids committing large source data and keeps the repository reproducible through documented setup. |
| Separate SQL, Python, Power BI and reporting artifacts | Makes each analytical responsibility discoverable and reviewable. |
| Treat experimentation as a proposal only | The public dataset has no assignment or treatment/control records. |
