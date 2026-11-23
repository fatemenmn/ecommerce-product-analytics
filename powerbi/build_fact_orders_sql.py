"""Generate powerbi/fact_orders.sql from the validated order-level SQL.

The Power BI model must not fork the analytical logic, so the FactOrders
native query is generated from sql/order_level_dataset.sql. Running this
script with --check fails when the two drift apart.

Usage
-----
    python powerbi/build_fact_orders_sql.py           # rewrite fact_orders.sql
    python powerbi/build_fact_orders_sql.py --check   # verify it is current
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "python"))

# Reuse the statement splitter that already understands this project's SQL, and
# the tested rewrite that drops the `olist.` qualifiers. Stripping them means
# the query reads whichever database the Power BI connection selects, so a
# copy of the schema can never silently fall back to `olist`.
from load_mysql import split_statements  # noqa: E402
from reproduce_analysis import strip_schema_references  # noqa: E402

SOURCE_SQL = ROOT / "sql" / "order_level_dataset.sql"
TARGET_SQL = ROOT / "powerbi" / "fact_orders.sql"

HEADER = """\
-- FactOrders: Power BI source query (MySQL 8.0).
--
-- GENERATED FILE - do not edit by hand.
-- Regenerate with:  python powerbi/build_fact_orders_sql.py
--
-- Body mirrors sql/order_level_dataset.sql; the only additions are the
-- date-only `purchase_date` column and the removal of the `olist.` table
-- qualifiers, so the query resolves against the database the Power BI
-- connection selects.
--
-- Grain: one row per orders.order_id, every order status preserved.
"""


def build() -> str:
    """Return the full text of powerbi/fact_orders.sql."""
    statements = split_statements(SOURCE_SQL.read_text(encoding="utf-8"))
    if len(statements) != 1:
        raise SystemExit(
            f"expected one statement in {SOURCE_SQL.name}, found {len(statements)}"
        )
    body = strip_schema_references(statements[0].rstrip().rstrip(";"))
    if "olist." in body:
        raise SystemExit("schema qualifier survived the rewrite; refusing to emit")
    indented = "\n".join(
        f"    {line}" if line.strip() else line for line in body.splitlines()
    )
    return (
        f"{HEADER}\n"
        "SELECT f.*,\n"
        "       DATE(f.order_purchase_timestamp) AS purchase_date\n"
        "FROM (\n"
        f"{indented}\n"
        ") AS f;\n"
    )


def normalize(text: str) -> str:
    """Compare content only: Windows checkouts rewrite LF to CRLF."""
    return text.replace("\r\n", "\n").replace("\r", "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check", action="store_true", help="fail if the file is out of date"
    )
    args = parser.parse_args()

    expected = build()
    name = TARGET_SQL.relative_to(ROOT).as_posix()

    if args.check:
        actual = TARGET_SQL.read_text(encoding="utf-8") if TARGET_SQL.exists() else ""
        if normalize(actual) != normalize(expected):
            print(f"FAIL {name} is out of date with {SOURCE_SQL.name}")
            return 1
        print(f"OK   {name} matches {SOURCE_SQL.name}")
        return 0

    TARGET_SQL.write_text(expected, encoding="utf-8", newline="\n")
    print(f"wrote {name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
