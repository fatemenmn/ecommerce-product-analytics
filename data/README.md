# Data Setup

## Source

This project uses the [Olist Brazilian E-Commerce Public Dataset on Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

Download the dataset from the source page and keep the original CSV files unchanged. The raw files are intentionally excluded from version control.

## Source Files

The dataset is expected to contain these nine CSV files:

| CSV file | Description |
|---|---|
| `olist_orders_dataset.csv` | Order status and lifecycle timestamps |
| `olist_order_items_dataset.csv` | Items, sellers, item prices and freight values |
| `olist_customers_dataset.csv` | Customer records and unique customer identifiers |
| `olist_products_dataset.csv` | Product attributes and source category names |
| `olist_order_payments_dataset.csv` | Payment records, methods, values and installments |
| `olist_order_reviews_dataset.csv` | Customer review records and scores |
| `olist_sellers_dataset.csv` | Seller attributes |
| `olist_geolocation_dataset.csv` | Postal-code prefix coordinates |
| `product_category_name_translation.csv` | Source category to English category mapping |

## Local Directory

After downloading, place the original files in:

```text
data/
└── raw/
    ├── olist_orders_dataset.csv
    ├── olist_order_items_dataset.csv
    ├── olist_customers_dataset.csv
    ├── olist_products_dataset.csv
    ├── olist_order_payments_dataset.csv
    ├── olist_order_reviews_dataset.csv
    ├── olist_sellers_dataset.csv
    ├── olist_geolocation_dataset.csv
    └── product_category_name_translation.csv
```

Do not rename or edit the source files unless a transformation is explicitly documented. Keep cleaned or derived data separate from the original files.

## MySQL Import

Import the nine CSV files into a dedicated MySQL database. The original CSV filenames are used as reference names in the documentation; table names may differ depending on the import method.

After import:

1. Select the intended database.
2. List the imported tables.
3. Inspect each table's columns and data types.
4. Record row counts.
5. Validate primary-key uniqueness and foreign-key coverage.
6. Confirm date/time and numeric columns were imported with suitable types.

The SQL scripts will use the actual table and column names confirmed during this validation step. Do not assume that an import tool preserved the expected names or inferred data types correctly.

## Data Handling

- Do not commit raw or processed source datasets.
- Do not overwrite the original CSV files.
- Document any exclusions, type conversions, deduplication or other transformations.
- Keep source data, transformed data and analytical outputs logically separate.
- Check the dataset provider's current terms before redistributing any source data.
