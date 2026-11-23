# Python analysis

Two scripts live here:

| Script | Purpose |
|---|---|
| `load_mysql.py` | Create the `olist` schema and load the source CSVs into MySQL; also runs ad-hoc SQL |
| `reproduce_analysis.py` | Recompute two committed SQL analyses in Python and reconcile them against fresh runs of the SQL |

## `reproduce_analysis.py`

Reads the source tables from the local MySQL `olist` database, recomputes the metrics in
pandas, executes the committed SQL scripts on the same connection, and compares the two outputs.

**Marketplace performance** — purchase-month delivered GMV and delivered order counts. Item
price only, freight excluded, delivered orders only. Validated against
[marketplace_performance.sql](../sql/marketplace_performance.sql), plus the overall baseline of
96,478 delivered orders and R$ 13,221,498.11 delivered GMV. Produces a monthly GMV chart for
January 2017 through August 2018.

**Delivery versus reviews** — eligible and reviewed order counts, review coverage, average score
and the 1–2 score rate by timing group. Uses the same rules as
[delivery_vs_reviews.sql](../sql/delivery_vs_reviews.sql): timing eligibility requires a valid
purchase and delivery timestamp and a non-missing estimate; a delivery on the estimated calendar
date counts as on time; the order-level score is the latest valid answered score, and tied latest
scores with different values resolve to no score. Produces a score-distribution chart by timing
group labelled with each group's reviewed denominator.

## Setup

1. Start MySQL and load the data once (see [Data Setup](../data/README.md)):

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\start-mysql.ps1
   python python\load_mysql.py --create --load all
   ```

2. Create a local `.env` at the project root. It is gitignored, so credentials never leave the
   machine:

   ```
   MYSQL_HOST=127.0.0.1
   MYSQL_PORT=3306
   MYSQL_USER=root
   MYSQL_PASSWORD=
   MYSQL_DATABASE=olist
   ```

3. Install the dependencies:

   ```powershell
   pip install -r requirements.txt
   ```

| Dependency | Purpose | Tested with |
|---|---|---|
| `pandas` | source-table loading and metric computation | 3.1.1 |
| `PyMySQL` | MySQL connection, shared with `load_mysql.py` | 2.2.8 |
| `Pillow` | chart rendering to PNG | 13.0.0 |

Charts are drawn with Pillow rather than matplotlib because the matplotlib `ft2font` extension
is blocked by the application-control policy on the reference machine. No plotting framework is
needed to reproduce the numbers.

## Run

```powershell
python python/reproduce_analysis.py
```

The script prints the Python-computed timing groups, a reconciliation summary, and the chart
paths. It exits `0` when every check passes and `1` when anything differs, listing each
discrepancy with the metric, month or group, and both values.

Comparison rules: counts must match exactly, monetary values must match to the cent, and rates
are compared at the precision used in the reports (two decimals).

### Running against another schema

`MYSQL_DATABASE` selects the database for **both** the pandas queries and the SQL reference
comparisons. The committed SQL files keep their documented `olist` references and stay runnable
on their own; the script retargets those references to the selected database at run time, so no
file has to be edited or copied.

```powershell
$env:MYSQL_DATABASE = "olist_repro_test"
$env:MYSQL_USER     = "repro_reader"
$env:MYSQL_PASSWORD = "<password>"
python python\reproduce_analysis.py
```

Use an account that can read only the target schema. That way an accidental reference to `olist`
fails with `ERROR 1142` instead of silently passing. This was verified end to end: with a
read-only account scoped to a freshly loaded temporary schema, `olist` access was denied and the
run still reported 25 monthly rows, 96,478 delivered orders, R$ 13,221,498.11 delivered GMV and a
53.15 percentage-point gap.

## Actual reconciliation results

Latest local run against `olist` (MySQL 8.0.44):

| Check | Python | SQL / baseline | Result |
|---|---:|---:|---|
| Marketplace months compared | 25 | 25 | ✅ |
| Delivered orders | 96,478 | 96,478 | ✅ |
| Delivered GMV | R$ 13,221,498.11 | R$ 13,221,498.11 | ✅ |
| Timing-eligible orders | 96,470 | 96,470 | ✅ |
| Reviewed orders | 95,824 | 95,824 | ✅ |
| Low-score gap (late − on time) | 53.15 pp | 53.15 pp | ✅ |

Per-group detail, identical in Python and SQL:

| Timing group | Eligible orders | Reviewed orders | Review coverage | Average score | 1–2 score rate |
|---|---:|---:|---:|---:|---:|
| on_time | 89,936 | 89,443 | 99.45% | 4.29 | 9.27% |
| late | 6,534 | 6,381 | 97.66% | 2.27 | 62.42% |

The gap is calculated before rounding (62.42 − 9.27 at full precision) and then rounded to
53.15 percentage points. All monthly GMV and delivered-order rows also match the committed SQL
month by month.

## Outputs

| Chart | Shows |
|---|---|
| [monthly_delivered_gmv_2017_2018.png](../images/monthly_delivered_gmv_2017_2018.png) | Delivered GMV by purchase month, Jan 2017 – Aug 2018 |
| [review_score_distribution_by_timing.png](../images/review_score_distribution_by_timing.png) | Score 1–5 distribution for on-time and late orders, with reviewed sample sizes |

Source SQL used as validation references:

- [sql/marketplace_performance.sql](../sql/marketplace_performance.sql)
- [sql/delivery_vs_reviews.sql](../sql/delivery_vs_reviews.sql)

Business definitions: [Product Metrics](../docs/03_product_metrics.md) (5.1, 5.2, 9.7) and
[Data Setup](../data/README.md).

## Data handling

- Raw extracts are not written to disk by the script and no data files are committed.
- Connection settings stay in `.env`, which is gitignored.
- Only the two PNG charts, this README, the scripts, and `requirements.txt` are versioned.
