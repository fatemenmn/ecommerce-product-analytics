"""Load the Olist CSV files into MySQL, then run SQL against them.

Why this exists
---------------
`LOAD DATA LOCAL INFILE` needs the `local_infile` setting on the server and a
`FILE`/`LOCAL` privilege. This script instead streams rows through the driver,
so it works on a stock Windows MySQL install with a normal user account.

Setup
-----
    Python:  pip install pymysql
    Config:  set env vars, or put them in a .env file at the project root:

        MYSQL_HOST=localhost
        MYSQL_PORT=3306
        MYSQL_USER=root
        MYSQL_PASSWORD=yourpassword
        MYSQL_DATABASE=olist

Usage
-----
    # create the database + all tables, then load every CSV in the root
    python python/load_mysql.py --create --load all

    # load just one table
    python python/load_mysql.py --load orders

    # check what is there
    python python/load_mysql.py --tables

    # run an ad-hoc query
    python python/load_mysql.py -q "SELECT customer_state, COUNT(*) n FROM customers GROUP BY 1 ORDER BY 2 DESC LIMIT 5"

    # run the whole query file
    python python/load_mysql.py -f sql/customers_queries.sql

    # export the last result
    python python/load_mysql.py -f sql/customers_queries.sql --out reports/customers.csv

Connection details can also be passed explicitly:
    --host --port --user --password --database
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

import pandas as pd
import pymysql
from pymysql.constants import CLIENT

ROOT = Path(__file__).resolve().parent.parent

TABLE_DDL = """
CREATE TABLE IF NOT EXISTS `customers` (
    customer_id              CHAR(32)    NOT NULL,
    customer_unique_id       CHAR(32)    NOT NULL,
    customer_zip_code_prefix CHAR(5)         NULL,
    customer_city            VARCHAR(64)     NULL,
    customer_state           CHAR(2)         NULL,
    PRIMARY KEY (customer_id),
    KEY idx_customers_unique_id (customer_unique_id),
    KEY idx_customers_state (customer_state)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4
"""

# The single source of truth for table definitions.
SCHEMA_FILE = ROOT / "sql" / "00_create_schema.sql"

# table -> (csv path, columns in file order), in referential load order
TABLES: dict[str, tuple[Path, list[str]]] = {
    "customers": (
        ROOT / "olist_customers_dataset.csv",
        [
            "customer_id",
            "customer_unique_id",
            "customer_zip_code_prefix",
            "customer_city",
            "customer_state",
        ],
    ),
    "orders": (
        ROOT / "olist_orders_dataset.csv",
        [
            "order_id",
            "customer_id",
            "order_status",
            "order_purchase_timestamp",
            "order_approved_at",
            "order_delivered_carrier_date",
            "order_delivered_customer_date",
            "order_estimated_delivery_date",
        ],
    ),
    "order_items": (
        ROOT / "olist_order_items_dataset.csv",
        [
            "order_id",
            "order_item_id",
            "product_id",
            "seller_id",
            "shipping_limit_date",
            "price",
            "freight_value",
        ],
    ),
    "order_payments": (
        ROOT / "olist_order_payments_dataset.csv",
        [
            "order_id",
            "payment_sequential",
            "payment_type",
            "payment_installments",
            "payment_value",
        ],
    ),
    "order_reviews": (
        ROOT / "olist_order_reviews_dataset.csv",
        [
            "review_id",
            "order_id",
            "review_score",
            "review_comment_title",
            "review_comment_message",
            "review_creation_date",
            "review_answer_timestamp",
        ],
    ),
    "products": (
        ROOT / "olist_products_dataset.csv",
        [
            "product_id",
            "product_category_name",
            "product_name_lenght",
            "product_description_lenght",
            "product_photos_qty",
            "product_weight_g",
            "product_length_cm",
            "product_height_cm",
            "product_width_cm",
        ],
    ),
    "sellers": (
        ROOT / "olist_sellers_dataset.csv",
        [
            "seller_id",
            "seller_zip_code_prefix",
            "seller_city",
            "seller_state",
        ],
    ),
    "geolocation": (
        ROOT / "olist_geolocation_dataset.csv",
        [
            "geolocation_zip_code_prefix",
            "geolocation_lat",
            "geolocation_lng",
            "geolocation_city",
            "geolocation_state",
        ],
    ),
    "product_category_name_translation": (
        ROOT / "product_category_name_translation.csv",
        [
            "product_category_name",
            "product_category_name_english",
        ],
    ),
}


def load_env_file() -> None:
    """Read a simple KEY=VALUE .env file from the project root, if present."""
    env_path = ROOT / ".env"
    if not env_path.exists():
        return
    for raw in env_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key, value = key.strip(), value.strip().strip('"').strip("'")
        os.environ.setdefault(key, value)


def connect(args: argparse.Namespace, with_db: bool = True) -> pymysql.connections.Connection:
    return pymysql.connect(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database if with_db else None,
        charset="utf8mb4",
        autocommit=True,
        client_flag=CLIENT.MULTI_STATEMENTS,
    )


def split_statements(sql: str) -> list[str]:
    """Split a SQL script on ';' while ignoring quotes and comments."""
    out: list[str] = []
    buf: list[str] = []
    quote: str | None = None
    i, n = 0, len(sql)
    while i < n:
        ch, nxt = sql[i], (sql[i + 1] if i + 1 < n else "")
        if quote:
            buf.append(ch)
            if ch == quote:
                quote = None
            i += 1
            continue
        if ch in ("'", '"', "`"):
            quote = ch
            buf.append(ch)
            i += 1
            continue
        if ch == "-" and nxt == "-":
            while i < n and sql[i] != "\n":
                buf.append(sql[i])
                i += 1
            continue
        if ch == ";":
            stmt = "".join(buf).strip()
            if stmt:
                out.append(stmt)
            buf = []
            i += 1
            continue
        buf.append(ch)
        i += 1
    tail = "".join(buf).strip()
    if tail:
        out.append(tail)
    return out


def create_schema(args: argparse.Namespace) -> None:
    """Create the database and all tables from sql/00_create_schema.sql."""
    if not SCHEMA_FILE.exists():
        raise SystemExit(f"Schema file not found: {SCHEMA_FILE}")
    ddl = SCHEMA_FILE.read_text(encoding="utf-8")

    con = connect(args, with_db=False)
    with con.cursor() as cur:
        cur.execute(
            f"CREATE DATABASE IF NOT EXISTS `{args.database}` "
            "CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
        )
        cur.execute(f"USE `{args.database}`")
        created = 0
        for stmt in split_statements(ddl):
            # Strip leading comment lines so each statement can be classified
            # even when the schema file documents a table above its DDL.
            head = re.sub(r"^(?:\s*--[^\n]*\n)+", "", stmt).lstrip().upper()
            if head.startswith("CREATE DATABASE") or head.startswith("USE "):
                continue  # handled above so any database name works
            cur.execute(stmt)
            if head.startswith("CREATE TABLE"):
                created += 1
    con.close()
    print(f"Schema ready in '{args.database}': {created} tables created/verified.")


def _load_one(con, args: argparse.Namespace, table: str) -> int:
    csv_path, columns = TABLES[table]
    if not csv_path.exists():
        raise SystemExit(f"CSV not found: {csv_path}")

    # utf-8-sig strips a BOM if the file has one (the category file does).
    df = pd.read_csv(
        csv_path,
        dtype=str,
        keep_default_na=False,
        na_values=[""],
        encoding="utf-8-sig",
    )
    df.columns = [c.strip().lstrip("\ufeff") for c in df.columns]
    missing = [c for c in columns if c not in df.columns]
    if missing:
        raise SystemExit(f"{csv_path.name}: missing columns {missing}")

    df = df[columns]
    rows = [
        tuple(None if (isinstance(v, float) and pd.isna(v)) else v for v in rec)
        for rec in df.itertuples(index=False, name=None)
    ]

    placeholders = ", ".join(["%s"] * len(columns))
    col_sql = ", ".join(f"`{c}`" for c in columns)
    sql = f"INSERT INTO `{table}` ({col_sql}) VALUES ({placeholders})"

    con.autocommit(False)
    with con.cursor() as cur:
        cur.execute(f"TRUNCATE TABLE `{table}`")
        batch = 5000
        for start in range(0, len(rows), batch):
            cur.executemany(sql, rows[start : start + batch])
            con.commit()
    con.autocommit(True)
    return len(rows)


def load_table(args: argparse.Namespace, table: str) -> None:
    targets = list(TABLES) if table in ("all", "*") else [table]
    unknown = [t for t in targets if t not in TABLES]
    if unknown:
        raise SystemExit(f"Unknown table(s) {unknown}. Known: {', '.join(TABLES)}")

    con = connect(args)
    try:
        for name in targets:
            count = _load_one(con, args, name)
            print(f"  {name:<35} {count:>10,} rows")
    finally:
        con.close()
    print(f"Done: {len(targets)} table(s) loaded into '{args.database}'.")


def show_tables(args: argparse.Namespace) -> None:
    con = connect(args)
    with con.cursor() as cur:
        cur.execute("SHOW TABLES")
        names = [r[0] for r in cur.fetchall()]
        print(f"Tables in '{args.database}':")
        for name in names:
            cur.execute(f"SELECT COUNT(*) FROM `{name}`")
            print(f"  {name:<40} {cur.fetchone()[0]:>12,} rows")
    con.close()


def run_queries(args: argparse.Namespace) -> None:
    if args.file:
        path = Path(args.file)
        if not path.is_absolute():
            path = ROOT / path
        sql = path.read_text(encoding="utf-8")
    else:
        sql = args.query

    statements = split_statements(sql)
    con = connect(args)
    last_df: pd.DataFrame | None = None

    for idx, stmt in enumerate(statements, 1):
        with con.cursor() as cur:
            cur.execute(stmt)
            if cur.description is None:
                continue  # DDL / USE / etc.
            cols = [d[0] for d in cur.description]
            data = cur.fetchall()
        df = pd.DataFrame(data, columns=cols)
        if df.empty and not cols:
            continue
        last_df = df
        if len(statements) > 1:
            print(f"\n--- query {idx}/{len(statements)} ---")
        with pd.option_context(
            "display.max_rows", 200,
            "display.max_columns", None,
            "display.width", 200,
            "display.max_colwidth", 60,
        ):
            print(df.to_string(index=False))

    con.close()

    if args.out and last_df is not None:
        out = Path(args.out)
        if not out.is_absolute():
            out = ROOT / out
        out.parent.mkdir(parents=True, exist_ok=True)
        if out.suffix.lower() == ".parquet":
            last_df.to_parquet(out, index=False)
        elif out.suffix.lower() in (".json", ".jsonl"):
            last_df.to_json(out, orient="records", indent=2)
        else:
            last_df.to_csv(out, index=False)
        print(f"\nSaved {len(last_df):,} rows -> {out}")


def main() -> None:
    load_env_file()

    parser = argparse.ArgumentParser(
        description="Load Olist CSVs into MySQL and run SQL queries.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--host", default=os.getenv("MYSQL_HOST", "127.0.0.1"))
    parser.add_argument("--port", type=int, default=int(os.getenv("MYSQL_PORT", "3306")))
    parser.add_argument("--user", default=os.getenv("MYSQL_USER", "root"))
    parser.add_argument("--password", default=os.getenv("MYSQL_PASSWORD", ""))
    parser.add_argument("--database", default=os.getenv("MYSQL_DATABASE", "olist"))

    parser.add_argument("--create", action="store_true", help="Create database + tables")
    parser.add_argument(
        "--load",
        metavar="TABLE",
        help="Load a CSV into a table, or 'all' for every table",
    )
    parser.add_argument("--tables", action="store_true", help="List tables and row counts")
    parser.add_argument("-q", "--query", help="Run a single SQL query")
    parser.add_argument("-f", "--file", help="Run a .sql file (may contain several queries)")
    parser.add_argument("-o", "--out", help="Export last result to .csv/.parquet/.json")

    args = parser.parse_args()

    if args.create:
        create_schema(args)
    if args.load:
        load_table(args, args.load)
    if args.tables:
        show_tables(args)
    if args.query or args.file:
        run_queries(args)

    if not any([args.create, args.load, args.tables, args.query, args.file]):
        parser.print_help()


if __name__ == "__main__":
    main()
