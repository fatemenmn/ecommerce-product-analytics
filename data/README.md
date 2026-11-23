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

## Local MySQL Server (portable, no admin)

A MySQL 8.0 server was installed in portable form at `C:\Users\User\mysql`. It is not
registered as a Windows service and does not require administrator rights.

| Item | Value |
|---|---|
| Server | MySQL Community Server 8.0.44 (x64 ZIP) |
| Binaries | `C:\Users\User\mysql\mysql-8.0.44-winx64\bin` |
| Config | `C:\Users\User\mysql\my.ini` |
| Data | `C:\Users\User\mysql\data` |
| Endpoint | `127.0.0.1:3306` |
| Login | user `root`, empty password (local development only) |
| Database | `olist` |
| Log | `C:\Users\User\mysql\mysql-error.log` |

Start and stop the server:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\start-mysql.ps1
powershell -ExecutionPolicy Bypass -File scripts\stop-mysql.ps1
```

### Loading the CSVs

`LOAD DATA LOCAL INFILE` needs the server `local_infile` setting and a `FILE`
privilege. The project instead loads CSVs through the driver, which works with a
plain user account:

```powershell
# create the database + all nine tables, then load every CSV in the project root
python python\load_mysql.py --create --load all

# or load one table
python python\load_mysql.py --load orders

# confirm what is loaded
python python\load_mysql.py --tables
```

`--create` reads its table definitions from [`sql/00_create_schema.sql`](../sql/00_create_schema.sql),
which mirrors the validated schema: table and column names, data types, primary keys, indexes and
engine were captured from `SHOW CREATE TABLE` on the imported tables. To test the whole workflow
without touching an existing database, send it to a throwaway schema:

```powershell
python python\load_mysql.py --database olist_repro_test --create --load all
```

Loaded tables and row counts (verified against the source CSVs):

| Table | CSV | Rows |
|---|---|---|
| `customers` | `olist_customers_dataset.csv` | 99,441 |
| `orders` | `olist_orders_dataset.csv` | 99,441 |
| `order_items` | `olist_order_items_dataset.csv` | 112,650 |
| `order_payments` | `olist_order_payments_dataset.csv` | 103,886 |
| `order_reviews` | `olist_order_reviews_dataset.csv` | 99,224 |
| `products` | `olist_products_dataset.csv` | 32,951 |
| `sellers` | `olist_sellers_dataset.csv` | 3,095 |
| `geolocation` | `olist_geolocation_dataset.csv` | 1,000,163 |
| `product_category_name_translation` | `product_category_name_translation.csv` | 71 |

Connection details come from `.env` (gitignored) or from env vars, and can also be
passed as flags:

```powershell
python python\load_mysql.py --host 127.0.0.1 --port 3306 --user root --password "" --database olist
```

### SQL scripts

| File | Purpose |
|---|---|
| `sql/00_create_schema.sql` | Database plus all nine table definitions (read by `load_mysql.py --create`) |
| `sql/data_exploration.sql` | Schema, row counts, nulls, ranges and relationship validation |
| `sql/order_level_dataset.sql` | Order-level grain with items, payments and order-level review score |
| `sql/marketplace_performance.sql` | Monthly delivered GMV, orders, AOV and cancellation |
| `sql/customer_repeat_purchase.sql` | Repeat buyers, 90-day cohorts and time to second purchase |
| `sql/category_seller_performance.sql` | Category and seller GMV contribution and concentration |
| `sql/payments_and_freight.sql` | Payment methods, installments, AOV groups and freight ratios |
| `sql/delivery_vs_reviews.sql` | Delivery timing and review scores |
| `sql/delivery_by_state.sql` | Buyer-state and seller-to-buyer state delivery timing |

Run a script without opening a client:

```powershell
python python\load_mysql.py -f sql\marketplace_performance.sql
python python\load_mysql.py -f sql\delivery_by_state.sql --out reports\delivery_by_state.csv
```

Or paste it straight into MySQL Workbench after connecting to `127.0.0.1:3306`.

**Notes on the import**

* `customer_zip_code_prefix` and `seller_zip_code_prefix` are `CHAR(5)` so leading
  zeros survive, e.g. `'01151'`.
* `product_name_lenght` and `product_description_lenght` keep the dataset's spelling
  so CSV columns map 1:1 to table columns.
* `order_reviews.review_id` is not unique in the source (814 duplicate ids), so the
  table has indexes but no primary key.
* `product_category_name_translation.csv` starts with a UTF-8 BOM; the loader reads
  with `utf-8-sig` to strip it.
* `order_items` is the grain for item revenue; `order_payments` is the grain for
  payment value. Summing both in one query double counts money.



## Data Handling

- Do not commit raw or processed source datasets.
- Do not overwrite the original CSV files.
- Document any exclusions, type conversions, deduplication or other transformations.
- Keep source data, transformed data and analytical outputs logically separate.
- Check the dataset provider's current terms before redistributing any source data.
