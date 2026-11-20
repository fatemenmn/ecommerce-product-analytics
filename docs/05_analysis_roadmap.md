# Analysis Roadmap

## 1. Objective

This roadmap translates the business questions and KPI framework into an ordered implementation plan. Work is sequenced so that data quality and metric correctness are established before dashboard development or business recommendations.

## 2. Workstreams

| Workstream | Scope | Primary deliverables | Completion evidence |
|---|---|---|---|
| 1. Foundation | Business scope, source inventory, architecture and metric governance | Business understanding, dataset dictionary, KPI framework, architecture | Definitions and analytical boundaries are documented and consistent |
| 2. Data validation | Schema inspection, row counts, keys, missingness, ranges and relationship checks | SQL exploration and data-quality scripts; validation summary | Checks run against the imported MySQL tables and findings are recorded |
| 3. Core SQL analysis | Marketplace, customer, category, seller, payment and delivery metrics | Reusable SQL analysis scripts and result extracts | Query grain, population and calculations are validated |
| 4. Python analysis | Distribution analysis, trend exploration, cohort and segment analysis, statistical checks | Reproducible notebooks/scripts and figures | Python outputs reconcile with selected SQL metrics |
| 5. BI model and dashboard | Model relationships, measures, filters and dashboard pages | Power BI model, DAX measures, PBIX and screenshots | Key measures reconcile to validated SQL outputs |
| 6. Synthesis | Prioritization, insight development, limitations and recommendations | Executive report and portfolio-ready project summary | Each recommendation is traceable to an observed finding |

## 3. Analysis Sequence

### 3.1 Data validation

1. Confirm the active MySQL database and imported table names.
2. Inspect columns and data types.
3. Record row counts for all source tables.
4. Test primary-key uniqueness at each source grain.
5. Profile missing values in analytical fields.
6. Check timestamp ranges, status values and numeric ranges.
7. Profile foreign-key coverage and one-to-many relationships.
8. Document exclusions, anomalies and any transformation rules.

**Gate:** Do not proceed to final KPI reporting until material data-quality issues and join behavior are understood.

### 3.2 Core SQL analysis

The analysis will be organized around reusable business domains rather than daily exercises:

- Marketplace performance: orders, delivered GMV, AOV and cancellations.
- Customer behavior: unique buyers, purchase frequency, repeat purchasing and time to second purchase.
- Category performance: delivered GMV, sales contribution and category-level order associations.
- Seller performance: delivered GMV and seller concentration.
- Delivery and customer experience: lead time, delay and review-score comparisons.
- Payments and freight: payment distributions, installment groups and freight ratios.
- Geographic operations: buyer/seller state comparisons and carefully qualified distance estimates.

Each script will include its purpose, source tables, output grain and important calculation notes.

### 3.3 Python analysis

Python will be used where it adds value beyond SQL:

- Distribution and outlier exploration.
- Monthly and cohort trend visualization.
- Customer purchasing behavior and segmentation.
- Relationship analysis between delivery, freight and review scores.
- Statistical uncertainty and robustness checks where appropriate.
- Reconciliation of selected outputs with SQL.

The analysis will avoid treating correlation as causation.

### 3.4 Power BI

The BI layer will be designed after the metric outputs are stable. Planned report areas:

1. Marketplace overview.
2. Customer behavior and repeat purchasing.
3. Product category and seller performance.
4. Delivery and customer experience.

The final page count and visual selection will be driven by findings, not fixed in advance. Every displayed KPI must have a documented definition and a validated calculation.

### 3.5 Final synthesis

The final report will distinguish:

- Observed facts and measured results.
- Interpretation and plausible explanations.
- Recommendations and their expected business rationale.
- Data limitations and additional data needed to validate hypotheses.

## 4. Quality and Review Criteria

A deliverable is considered complete only when it meets the relevant criteria:

### SQL
- Runs on the documented MySQL environment.
- Uses actual imported table and column names.
- States the output grain.
- Avoids fan-out and double counting.
- Handles NULLs and invalid values explicitly.
- Uses clear aliases and readable formatting.

### Python
- Runs from a documented environment.
- Loads data from a documented location or validated SQL extract.
- Uses reproducible transformations.
- Labels charts with units, population and time period.
- Reconciles selected metrics against SQL.

### Power BI
- Uses a documented relationship model.
- Avoids ambiguous or unintended many-to-many relationships.
- Uses explicit measures for key KPIs.
- Reconciles headline figures to SQL.
- Includes clear titles, units, definitions and filter context.

### Business communication
- Answers a defined business question.
- Quantifies the finding and states the population/time window.
- Separates correlation from causation.
- Explains why the finding matters.
- Proposes an actionable next step and identifies missing evidence.

## 5. Repository Deliverable Map

| Path | Purpose |
|---|---|
| `docs/` | Business context, data definitions, architecture and methodology |
| `sql/` | Schema inspection, data-quality checks and analytical queries |
| `python/` | Exploratory analysis, validation and visualizations |
| `powerbi/` | Power BI project files and model documentation |
| `reports/` | Final analytical narrative and recommendations |
| `images/` | Selected dashboard and analysis visuals |
| `data/` | Dataset setup instructions; raw source files remain local |

## 6. Current Status

| Area | Status |
|---|---|
| Business understanding | Documented |
| Dataset dictionary | Documented; source schema to be validated after import |
| KPI framework | Defined; calculations to be validated against source data |
| Analytical architecture | Defined |
| Analysis roadmap | Defined |
| SQL data validation | Pending execution against MySQL |
| Core SQL analysis | Pending |
| Python EDA | Pending |
| Power BI model and dashboard | Pending |
| Final insights and recommendations | Pending validated findings |

## 7. Definition of Done

The project is complete when a reviewer can:

1. Understand the business problem and scope from the README.
2. Identify the source data and reproduce the setup.
3. Trace each headline metric to a documented definition and query.
4. Review data-quality decisions and analytical limitations.
5. Reconcile dashboard KPIs with SQL outputs.
6. Follow the evidence from analysis to insight and recommendation.
