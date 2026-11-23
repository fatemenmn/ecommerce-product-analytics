"""Reproduce two committed SQL analyses in Python and reconcile them.

What it does
------------
1. Marketplace performance: purchase-month delivered GMV and delivered order
   counts, validated against sql/marketplace_performance.sql.
2. Delivery versus reviews: eligibility, review coverage, average score and the
   1-2 score rate by timing group, validated against sql/delivery_vs_reviews.sql.

Both committed scripts are executed against the same MySQL connection, so the
comparison is always against a fresh run of the SQL in the repository.

Business rules reproduced
-------------------------
* Delivered order: order_status = 'delivered'.
* Merchandise GMV: sum of order_items.price, freight excluded.
* Timing eligibility: delivered, purchase timestamp, customer delivery timestamp
  not earlier than purchase, and a non-missing estimated delivery date.
* Late delivery: delivery calendar date AFTER the estimated calendar date, so
  delivery on the estimated date is on time.
* Review score: latest valid answered score. The score counts only when every
  valid review row at the latest answer timestamp carries the same score; tied
  latest scores with different values resolve to no score.

Usage
-----
    python python/reproduce_analysis.py

Charts are written to images/. Connection settings come from .env or the
environment, exactly as in python/load_mysql.py.
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path
from types import SimpleNamespace

import pandas as pd
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))

# Reuse the connection setup and statement splitter from the loader.
from load_mysql import connect, load_env_file, split_statements  # noqa: E402

IMAGES = ROOT / "images"
MARKETPLACE_SQL = ROOT / "sql" / "marketplace_performance.sql"
REVIEWS_SQL = ROOT / "sql" / "delivery_vs_reviews.sql"

BASELINE_DELIVERED = 96_478
BASELINE_GMV = 13_221_498.11
BASELINE_ELIGIBLE = 96_470
BASELINE_REVIEWED = 95_824
BASELINE_GAP_PP = 53.15

TREND_START = "2017-01"
TREND_END = "2018-08"


# --------------------------------------------------------------------------
# Data access
# --------------------------------------------------------------------------
def make_args() -> SimpleNamespace:
    return SimpleNamespace(
        host=__import__("os").getenv("MYSQL_HOST", "127.0.0.1"),
        port=int(__import__("os").getenv("MYSQL_PORT", "3306")),
        user=__import__("os").getenv("MYSQL_USER", "root"),
        password=__import__("os").getenv("MYSQL_PASSWORD", ""),
        database=__import__("os").getenv("MYSQL_DATABASE", "olist"),
    )


def query_df(con, sql: str) -> pd.DataFrame:
    """Fetch a result set as a DataFrame without pandas' sqlite3 code path."""
    with con.cursor() as cur:
        cur.execute(sql)
        cols = [d[0] for d in cur.description]
        rows = cur.fetchall()
    return pd.DataFrame(rows, columns=cols)


def read_source_tables(con) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    orders = query_df(
        con,
        """
        SELECT order_id, order_status, order_purchase_timestamp,
               order_delivered_customer_date, order_estimated_delivery_date
        FROM orders
        """,
    )
    items = query_df(con, "SELECT order_id, order_item_id, price FROM order_items")
    reviews = query_df(
        con,
        """
        SELECT order_id, review_id, review_score, review_answer_timestamp
        FROM order_reviews
        """,
    )
    for col in (
        "order_purchase_timestamp",
        "order_delivered_customer_date",
        "order_estimated_delivery_date",
    ):
        orders[col] = pd.to_datetime(orders[col], errors="coerce")
    reviews["review_answer_timestamp"] = pd.to_datetime(
        reviews["review_answer_timestamp"], errors="coerce"
    )
    return orders, items, reviews


def run_sql_file(con, path: Path) -> list[pd.DataFrame]:
    """Execute every statement in a committed SQL file and return its results."""
    statements = split_statements(path.read_text(encoding="utf-8"))
    frames: list[pd.DataFrame] = []
    for stmt in statements:
        with con.cursor() as cur:
            cur.execute(stmt)
            if cur.description is None:
                continue
            cols = [d[0] for d in cur.description]
            frames.append(pd.DataFrame(cur.fetchall(), columns=cols))
    return frames


# --------------------------------------------------------------------------
# Python implementations
# --------------------------------------------------------------------------
def compute_marketplace(orders: pd.DataFrame, items: pd.DataFrame) -> pd.DataFrame:
    """Delivered GMV and delivered order counts per purchase month.

    Months are taken from every placed order, so a month with no delivered
    orders still appears with zeros, matching the SQL monthly row set.
    """
    all_orders = orders[orders["order_purchase_timestamp"].notna()].copy()
    all_orders["purchase_month"] = all_orders["order_purchase_timestamp"].dt.strftime(
        "%Y-%m"
    )

    delivered = all_orders[all_orders["order_status"] == "delivered"].copy()
    item_totals = items.groupby("order_id", as_index=False)["price"].sum()
    delivered = delivered.merge(item_totals, on="order_id", how="left")
    delivered["price"] = delivered["price"].fillna(0.0)

    agg = delivered.groupby("purchase_month").agg(
        delivered_orders=("order_id", "nunique"),
        delivered_gmv_brl=("price", "sum"),
    )
    months = pd.Index(
        sorted(all_orders["purchase_month"].unique()), name="purchase_month"
    )
    monthly = agg.reindex(months, fill_value=0).reset_index()
    monthly["delivered_orders"] = monthly["delivered_orders"].astype(int)
    return monthly.sort_values("purchase_month").reset_index(drop=True)


def latest_valid_answered_score(reviews: pd.DataFrame) -> pd.DataFrame:
    """One score per order using the latest valid answered review.

    A score is returned only when all valid rows at the latest answer timestamp
    agree; otherwise the order resolves to no score (tied latest scores).
    """
    valid = reviews[
        reviews["review_score"].between(1, 5)
        & reviews["review_answer_timestamp"].notna()
    ].copy()
    if valid.empty:
        return pd.DataFrame(columns=["order_id", "review_score"])

    latest_ts = (
        valid.groupby("order_id")["review_answer_timestamp"].max().rename("latest_ts")
    )
    valid = valid.merge(latest_ts, left_on="order_id", right_index=True, how="left")
    at_latest = valid[valid["review_answer_timestamp"] == valid["latest_ts"]]

    grouped = at_latest.groupby("order_id")["review_score"]
    distinct = grouped.nunique()
    majority_free = distinct[distinct == 1].index
    scores = (
        grouped.max()
        .loc[majority_free]
        .rename("review_score")
        .reset_index()
    )
    return scores


def compute_delivery_reviews(
    orders: pd.DataFrame, reviews: pd.DataFrame
) -> tuple[pd.DataFrame, pd.DataFrame]:
    delivered = orders[orders["order_status"] == "delivered"].copy()

    eligible_mask = (
        delivered["order_purchase_timestamp"].notna()
        & delivered["order_delivered_customer_date"].notna()
        & delivered["order_estimated_delivery_date"].notna()
        & (
            delivered["order_delivered_customer_date"]
            >= delivered["order_purchase_timestamp"]
        )
    )
    eligible = delivered[eligible_mask].copy()

    # Calendar-date comparison: delivery on the estimated date is on time.
    delay_days = (
        eligible["order_delivered_customer_date"].dt.normalize()
        - eligible["order_estimated_delivery_date"].dt.normalize()
    ).dt.days
    eligible["delivery_timing"] = (delay_days > 0).map(
        {True: "late", False: "on_time"}
    )

    scores = latest_valid_answered_score(reviews)
    eligible = eligible.merge(scores, on="order_id", how="left")

    reviewed = eligible[eligible["review_score"].notna()].copy()
    reviewed["is_low"] = reviewed["review_score"] <= 2

    by_group = (
        eligible.groupby("delivery_timing")
        .agg(eligible_orders=("order_id", "nunique"))
        .reset_index()
    )
    reviewed_by_group = (
        reviewed.groupby("delivery_timing")
        .agg(
            reviewed_orders=("order_id", "nunique"),
            avg_review_score=("review_score", "mean"),
            low_orders=("is_low", "sum"),
        )
        .reset_index()
    )
    by_group = by_group.merge(reviewed_by_group, on="delivery_timing", how="left")
    by_group["review_coverage_pct"] = (
        100.0 * by_group["reviewed_orders"] / by_group["eligible_orders"]
    )
    by_group["low_score_pct"] = (
        100.0 * by_group["low_orders"] / by_group["reviewed_orders"]
    )
    by_group["low_score_rate_raw"] = by_group["low_score_pct"]

    late_raw = by_group.loc[by_group["delivery_timing"] == "late", "low_score_rate_raw"]
    on_time_raw = by_group.loc[
        by_group["delivery_timing"] == "on_time", "low_score_rate_raw"
    ]
    gap_raw = float(late_raw.iloc[0]) - float(on_time_raw.iloc[0])

    by_group["low_score_gap_pp"] = round(gap_raw, 2)
    by_group["avg_review_score"] = by_group["avg_review_score"].round(2)
    by_group["review_coverage_pct"] = by_group["review_coverage_pct"].round(2)
    by_group["low_score_pct"] = by_group["low_score_pct"].round(2)
    by_group["low_score_gap_raw"] = gap_raw
    return by_group, reviewed


# --------------------------------------------------------------------------
# Reconciliation
# --------------------------------------------------------------------------
def reconcile_marketplace(py_monthly: pd.DataFrame, sql_monthly: pd.DataFrame) -> list[str]:
    problems: list[str] = []
    sql_monthly = sql_monthly.copy()
    sql_monthly["delivered_gmv_brl"] = sql_monthly["delivered_gmv_brl"].astype(float)

    merged = py_monthly.merge(
        sql_monthly, on="purchase_month", how="outer", suffixes=("_py", "_sql")
    )
    missing_py = merged["delivered_orders_py"].isna().sum()
    missing_sql = merged["delivered_orders_sql"].isna().sum()
    if missing_py or missing_sql:
        problems.append(
            f"month coverage differs: {missing_py} months only in SQL, "
            f"{missing_sql} months only in Python"
        )

    for _, row in merged.iterrows():
        month = row["purchase_month"]
        if pd.isna(row["delivered_orders_py"]) or pd.isna(row["delivered_orders_sql"]):
            continue
        if int(row["delivered_orders_py"]) != int(row["delivered_orders_sql"]):
            problems.append(
                f"{month}: delivered orders python={int(row['delivered_orders_py'])} "
                f"sql={int(row['delivered_orders_sql'])}"
            )
        if round(float(row["delivered_gmv_brl_py"]), 2) != round(
            float(row["delivered_gmv_brl_sql"]), 2
        ):
            problems.append(
                f"{month}: GMV python={row['delivered_gmv_brl_py']:.2f} "
                f"sql={row['delivered_gmv_brl_sql']:.2f}"
            )

    py_orders = int(py_monthly["delivered_orders"].sum())
    py_gmv = round(float(py_monthly["delivered_gmv_brl"].sum()), 2)
    if py_orders != BASELINE_DELIVERED:
        problems.append(f"delivered orders {py_orders} != baseline {BASELINE_DELIVERED}")
    if py_gmv != BASELINE_GMV:
        problems.append(f"delivered GMV {py_gmv:.2f} != baseline {BASELINE_GMV:.2f}")
    return problems


def reconcile_reviews(py_groups: pd.DataFrame, sql_groups: pd.DataFrame) -> list[str]:
    problems: list[str] = []
    merged = py_groups.merge(sql_groups, on="delivery_timing", suffixes=("_py", "_sql"))

    for _, row in merged.iterrows():
        group = row["delivery_timing"]
        if int(row["eligible_orders_py"]) != int(row["eligible_orders_sql"]):
            problems.append(
                f"{group}: eligible python={int(row['eligible_orders_py'])} "
                f"sql={int(row['eligible_orders_sql'])}"
            )
        if int(row["reviewed_orders_py"]) != int(row["reviewed_orders_sql"]):
            problems.append(
                f"{group}: reviewed python={int(row['reviewed_orders_py'])} "
                f"sql={int(row['reviewed_orders_sql'])}"
            )
        for col, digits in (
            ("review_coverage_pct", 2),
            ("avg_review_score", 2),
            ("low_score_pct", 2),
        ):
            py_val = round(float(row[f"{col}_py"]), digits)
            sql_val = round(float(row[f"{col}_sql"]), digits)
            if py_val != sql_val:
                problems.append(f"{group}: {col} python={py_val} sql={sql_val}")

    eligible_total = int(py_groups["eligible_orders"].sum())
    reviewed_total = int(py_groups["reviewed_orders"].sum())
    gap = round(float(py_groups["low_score_gap_raw"].iloc[0]), 2)

    if eligible_total != BASELINE_ELIGIBLE:
        problems.append(f"eligible orders {eligible_total} != baseline {BASELINE_ELIGIBLE}")
    if reviewed_total != BASELINE_REVIEWED:
        problems.append(f"reviewed orders {reviewed_total} != baseline {BASELINE_REVIEWED}")
    if gap != BASELINE_GAP_PP:
        problems.append(f"low-score gap {gap} != baseline {BASELINE_GAP_PP}")
    return problems


# --------------------------------------------------------------------------
# Charts
# Rendered with Pillow rather than matplotlib: matplotlib's ft2font extension
# is blocked by the application-control policy on this machine.
# --------------------------------------------------------------------------
FONT_CANDIDATES = (
    r"C:\Windows\Fonts\segoeui.ttf",
    r"C:\Windows\Fonts\arial.ttf",
    r"C:\Windows\Fonts\DejaVuSans.ttf",
)
SCORE_COLORS = {
    1: "#b2182b",
    2: "#ef8a62",
    3: "#fddbc7",
    4: "#67a9cf",
    5: "#2166ac",
}


def _font(size: int):
    for path in FONT_CANDIDATES:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                continue
    return ImageFont.load_default()


def _compact(value: float) -> str:
    if value >= 1_000_000:
        return f"{value / 1_000_000:.1f}M"
    if value >= 1_000:
        return f"{value / 1_000:.0f}k"
    return f"{value:.0f}"


def _nice_step(raw: float) -> float:
    if raw <= 0:
        return 1.0
    exponent = math.floor(math.log10(raw))
    base = raw / (10 ** exponent)
    for candidate in (1, 2, 2.5, 5, 10):
        if base <= candidate:
            return candidate * (10 ** exponent)
    return 10 * (10 ** exponent)


def _rotated_text(img: Image.Image, xy, text: str, font, fill: str) -> None:
    """Draw text rotated 90 degrees (bottom-to-top) with the top-left at xy."""
    probe = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    box = probe.textbbox((0, 0), text, font=font)
    width, height = box[2] - box[0], box[3] - box[1]
    label = Image.new("RGBA", (width + 6, height + 6), (255, 255, 255, 0))
    ImageDraw.Draw(label).text(
        (3 - box[0], 3 - box[1]), text, font=font, fill=fill
    )
    label = label.rotate(90, expand=True)
    img.paste(label, (int(xy[0]), int(xy[1])), label)


def chart_monthly_gmv(monthly: pd.DataFrame) -> Path:
    trend = monthly[
        (monthly["purchase_month"] >= TREND_START)
        & (monthly["purchase_month"] <= TREND_END)
    ].copy()
    IMAGES.mkdir(parents=True, exist_ok=True)
    out = IMAGES / "monthly_delivered_gmv_2017_2018.png"

    width, height = 1040, 560
    left, right, top, bottom = 95, 35, 85, 135
    img = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(img)
    title_font, sub_font, axis_font, label_font = (
        _font(19),
        _font(12),
        _font(10),
        _font(11),
    )

    draw.text(
        (left, 18),
        "Delivered GMV by purchase month, January 2017 to August 2018",
        font=title_font,
        fill="#1a1a1a",
    )
    draw.text(
        (left, 46),
        "Item price only, freight excluded; delivered orders",
        font=sub_font,
        fill="#555555",
    )

    months = trend["purchase_month"].tolist()
    values = trend["delivered_gmv_brl"].tolist()
    vmax = max(values)
    step = _nice_step(vmax / 5)
    ymax = math.ceil(vmax / step) * step
    plot_w, plot_h = width - left - right, height - top - bottom
    base_y = top + plot_h

    tick = 0.0
    while tick <= ymax + 1e-9:
        y = base_y - plot_h * (tick / ymax)
        draw.line([(left, y), (width - right, y)], fill="#e6e6e6")
        label = _compact(tick)
        box = draw.textbbox((0, 0), label, font=axis_font)
        draw.text(
            (left - 10 - (box[2] - box[0]), y - 7),
            label,
            font=axis_font,
            fill="#444444",
        )
        tick += step
    draw.line([(left, top), (left, base_y)], fill="#888888")
    draw.line([(left, base_y), (width - right, base_y)], fill="#888888")

    slot = plot_w / len(values)
    bar_w = slot * 0.62
    for index, (month, value) in enumerate(zip(months, values)):
        x0 = left + slot * index + (slot - bar_w) / 2
        y0 = base_y - plot_h * (value / ymax)
        draw.rectangle([x0, y0, x0 + bar_w, base_y], fill="#2f6db3")
        _rotated_text(
            img,
            (x0 + bar_w / 2 - 7, base_y + 10),
            month,
            label_font,
            "#333333",
        )

    draw.text(
        (left, base_y + 92), "Purchase month", font=label_font, fill="#333333"
    )
    _rotated_text(
        img,
        (16, top + plot_h / 2 - 70),
        "Delivered GMV (BRL)",
        label_font,
        "#333333",
    )

    peak_index = values.index(vmax)
    note = f"peak {months[peak_index]}: R$ {vmax:,.2f}"
    box = draw.textbbox((0, 0), note, font=axis_font)
    note_w, note_h = box[2] - box[0], box[3] - box[1]
    note_x = left + 12
    note_y = top + 8
    draw.rectangle(
        [note_x - 5, note_y - 4, note_x + note_w + 5, note_y + note_h + 4],
        fill="white",
        outline="#d9d9d9",
    )
    draw.text((note_x, note_y), note, font=axis_font, fill="#b2182b")

    img.save(out)
    return out


def chart_score_distribution(reviewed: pd.DataFrame, groups: pd.DataFrame) -> Path:
    IMAGES.mkdir(parents=True, exist_ok=True)
    out = IMAGES / "review_score_distribution_by_timing.png"

    counts = (
        reviewed.groupby(["delivery_timing", "review_score"])
        .size()
        .unstack(fill_value=0)
        .reindex(columns=[1, 2, 3, 4, 5], fill_value=0)
    )
    counts = counts.reindex(
        [g for g in ("on_time", "late") if g in counts.index]
    )
    shares = counts.div(counts.sum(axis=1), axis=0) * 100.0
    sample = groups.set_index("delivery_timing")["reviewed_orders"]

    width, height = 960, 560
    left, right, top, bottom = 95, 235, 105, 95
    img = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(img)
    title_font, sub_font, axis_font, label_font = (
        _font(18),
        _font(11),
        _font(10),
        _font(12),
    )

    draw.text(
        (left, 18),
        "Review score distribution by delivery timing",
        font=title_font,
        fill="#1a1a1a",
    )
    draw.text(
        (left, 46),
        "Denominator: reviewed orders in each group (orders with a valid score)",
        font=sub_font,
        fill="#555555",
    )

    plot_w, plot_h = width - left - right, height - top - bottom
    base_y = top + plot_h

    for tick in range(0, 101, 20):
        y = base_y - plot_h * (tick / 100)
        draw.line([(left, y), (left + plot_w, y)], fill="#e6e6e6")
        label = f"{tick}%"
        box = draw.textbbox((0, 0), label, font=axis_font)
        draw.text(
            (left - 10 - (box[2] - box[0]), y - 7),
            label,
            font=axis_font,
            fill="#444444",
        )
    draw.line([(left, top), (left, base_y)], fill="#888888")
    draw.line([(left, base_y), (left + plot_w, base_y)], fill="#888888")

    slot = plot_w / len(shares)
    bar_w = 140
    for index, group in enumerate(shares.index):
        x0 = left + slot * index + (slot - bar_w) / 2
        y = base_y
        for score in shares.columns:
            share = float(shares.loc[group, score])
            segment = plot_h * share / 100.0
            y -= segment
            draw.rectangle(
                [x0, y, x0 + bar_w, y + segment], fill=SCORE_COLORS[score]
            )
            if segment > 16:
                draw.text(
                    (x0 + 8, y + segment / 2 - 6),
                    f"{share:.1f}%",
                    font=axis_font,
                    fill="#ffffff" if score in (1, 2, 5) else "#333333",
                )
        caption = f"{group} (n={int(sample.loc[group]):,} reviewed)"
        box = draw.textbbox((0, 0), caption, font=label_font)
        draw.text(
            (x0 + bar_w / 2 - (box[2] - box[0]) / 2, base_y + 10),
            caption,
            font=label_font,
            fill="#333333",
        )

    draw.text(
        (left, base_y + 46),
        "Share of reviewed orders",
        font=label_font,
        fill="#333333",
    )

    legend_x = left + plot_w + 25
    legend_y = top + 20
    draw.text((legend_x, legend_y - 18), "Score", font=label_font, fill="#333333")
    for offset, score in enumerate([1, 2, 3, 4, 5]):
        y = legend_y + offset * 24
        draw.rectangle([legend_x, y, legend_x + 14, y + 14], fill=SCORE_COLORS[score])
        draw.text(
            (legend_x + 22, y + 1), f"{score}", font=label_font, fill="#333333"
        )

    img.save(out)
    return out


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------
def print_table(groups: pd.DataFrame) -> None:
    print("\nDelivery timing groups (Python):")
    print(
        groups[
            [
                "delivery_timing",
                "eligible_orders",
                "reviewed_orders",
                "review_coverage_pct",
                "avg_review_score",
                "low_score_pct",
                "low_score_gap_pp",
            ]
        ].to_string(index=False)
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.parse_args()

    load_env_file()
    args = make_args()
    con = connect(args)

    try:
        print(f"Connected to {args.database} at {args.host}:{args.port}")
        orders, items, reviews = read_source_tables(con)
        print(
            f"Loaded {len(orders):,} orders, {len(items):,} items, "
            f"{len(reviews):,} review rows"
        )

        py_monthly = compute_marketplace(orders, items)
        py_groups, reviewed = compute_delivery_reviews(orders, reviews)
        print_table(py_groups)

        sql_marketplace = run_sql_file(con, MARKETPLACE_SQL)[0]
        sql_reviews = run_sql_file(con, REVIEWS_SQL)[0]
    finally:
        con.close()

    problems = reconcile_marketplace(py_monthly, sql_marketplace)
    problems += reconcile_reviews(py_groups, sql_reviews)

    gmv_chart = chart_monthly_gmv(py_monthly)
    score_chart = chart_score_distribution(reviewed, py_groups)

    print("\nReconciliation")
    print("-" * 72)
    print(f"Marketplace months compared          : {len(py_monthly)}")
    print(f"Delivered orders (total)             : {int(py_monthly['delivered_orders'].sum()):,}")
    print(f"Delivered GMV (total)                : R$ {py_monthly['delivered_gmv_brl'].sum():,.2f}")
    print(f"Timing-eligible orders               : {int(py_groups['eligible_orders'].sum()):,}")
    print(f"Reviewed orders                      : {int(py_groups['reviewed_orders'].sum()):,}")
    print(f"Low-score gap (late - on time)       : {py_groups['low_score_gap_pp'].iloc[0]} pp")
    print("\nCharts")
    print("-" * 72)
    print(f"  {gmv_chart.relative_to(ROOT).as_posix()}")
    print(f"  {score_chart.relative_to(ROOT).as_posix()}")

    if problems:
        print("\nDISCREPANCIES")
        print("-" * 72)
        for problem in problems:
            print(f"  FAIL {problem}")
        return 1

    print("\nAll reconciliations passed: counts exact, money to the cent, rates at 2 dp.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
