"""Validate the FactOrders source query and the values the measures must return.

Power BI Desktop is not installed on the machine that prepared this branch, so
the semantic model cannot be created or refreshed here. This script checks the
layer underneath it: it runs the committed powerbi/fact_orders.sql against MySQL
and reproduces, in plain SQL, exactly what the five measures must return once
the model exists. Model-level results stay pending until they are checked in
Desktop.

Usage
-----
    python powerbi/validate_source.py
"""

from __future__ import annotations

import argparse
import os
import sys
from decimal import ROUND_HALF_UP, Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "python"))

from load_mysql import connect, load_env_file, split_statements  # noqa: E402

FACT_SQL = ROOT / "powerbi" / "fact_orders.sql"

CENT = Decimal("0.01")

EXPECTED_ROWS = 99_441
EXPECTED_DISTINCT = 99_441
EXPECTED_PLACED = 99_441
EXPECTED_DELIVERED = 96_478
EXPECTED_GMV = Decimal("13221498.11")
EXPECTED_AOV = Decimal("137.04")
EXPECTED_CANCEL_PCT = Decimal("0.63")
EXPECTED_JAN_DELIVERED = 7_069
EXPECTED_JAN_GMV = Decimal("924645.00")


def money(value) -> Decimal:
    """Round a Decimal/float result to two decimals, half up."""
    return Decimal(value).quantize(CENT, rounding=ROUND_HALF_UP)


def fact_query() -> str:
    """The committed FactOrders query wrapped as a subquery for aggregation."""
    statements = split_statements(FACT_SQL.read_text(encoding="utf-8"))
    if len(statements) != 1:
        raise SystemExit(f"expected one statement in {FACT_SQL.name}")
    return f"SELECT * FROM ({statements[0]}) AS f"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()

    load_env_file()
    args = argparse.Namespace(
        host=os.getenv("MYSQL_HOST", "127.0.0.1"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", ""),
        database=os.getenv("MYSQL_DATABASE", "olist"),
    )
    fact = fact_query()
    checks: list[tuple[str, object, object]] = []

    con = connect(args)
    try:
        with con.cursor() as cur:
            cur.execute(f"SELECT COUNT(*), COUNT(DISTINCT order_id) FROM ({fact}) AS q")
            rows, distinct = cur.fetchone()
            checks.append(("rows in FactOrders", int(rows), EXPECTED_ROWS))
            checks.append(("distinct order_id", int(distinct), EXPECTED_DISTINCT))

            cur.execute(
                f"""
                SELECT COUNT(*) AS placed_orders,
                       SUM(order_status = 'delivered') AS delivered_orders,
                       SUM(CASE WHEN order_status = 'delivered'
                                THEN merchandise_value END) AS delivered_gmv,
                       SUM(order_status = 'canceled') AS canceled_orders
                FROM ({fact}) AS q
                """
            )
            placed, delivered, gmv, canceled = cur.fetchone()
            checks.append(("Placed Orders", int(placed), EXPECTED_PLACED))
            checks.append(("Delivered Orders", int(delivered), EXPECTED_DELIVERED))
            checks.append(("Delivered GMV (BRL)", money(gmv), EXPECTED_GMV))
            checks.append(
                ("Delivered AOV (BRL)", money(Decimal(gmv) / delivered), EXPECTED_AOV)
            )
            checks.append(
                (
                    "Cancellation Rate (%)",
                    money(Decimal(100) * canceled / placed),
                    EXPECTED_CANCEL_PCT,
                )
            )

            cur.execute(
                f"""
                SELECT SUM(order_status = 'delivered') AS delivered_orders,
                       SUM(CASE WHEN order_status = 'delivered'
                                THEN merchandise_value END) AS delivered_gmv
                FROM ({fact}) AS q
                WHERE purchase_date BETWEEN DATE('2018-01-01')
                                        AND DATE('2018-01-31')
                """
            )
            jan_delivered, jan_gmv = cur.fetchone()
            checks.append(
                ("Delivered Orders, Jan 2018", int(jan_delivered), EXPECTED_JAN_DELIVERED)
            )
            checks.append(
                ("Delivered GMV (BRL), Jan 2018", money(jan_gmv), EXPECTED_JAN_GMV)
            )

            cur.execute(
                f"SELECT MIN(purchase_date), MAX(purchase_date) FROM ({fact}) AS q"
            )
            dmin, dmax = cur.fetchone()
            dim_dates = (dmax - dmin).days + 1
    finally:
        con.close()

    width = max(len(label) for label, _, _ in checks)
    print("FactOrders source validation")
    print(f"database : {args.database}")
    print(f"query    : {FACT_SQL.relative_to(ROOT).as_posix()}")
    print()

    failures = 0
    for label, actual, expected in checks:
        ok = actual == expected
        failures += 0 if ok else 1
        print(
            f"  {label:<{width}}  {str(actual):>14}  expected {str(expected):>14}  "
            f"{'OK' if ok else 'FAIL'}"
        )

    print()
    print(f"DimDate rows to create: {dim_dates:,} ({dmin} to {dmax})")
    print()

    if failures:
        print(f"FAIL {failures} of {len(checks)} source checks did not match")
        return 1

    print(f"PASS all {len(checks)} source checks matched")
    print("Model-level values still need to be refreshed in Power BI Desktop.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
