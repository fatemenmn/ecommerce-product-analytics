# Olist E-Commerce Analytics

An end-to-end analytics case study using the Olist Brazilian E-Commerce Public Dataset. The project examines marketplace performance, customer purchasing behavior, product and seller contribution, delivery operations, and customer feedback, then translates validated findings into business recommendations.

The work combines **SQL, Python, and Power BI** with a documented business question and KPI framework.

## Project at a Glance

| Area | Focus |
|---|---|
| Product analytics | Repeat purchasing, customer behavior, review patterns and customer experience |
| Business analysis | Marketplace performance, category and seller contribution, operational opportunities |
| Business intelligence | Metric definitions, data validation, reusable SQL and Power BI reporting |
| Tools | MySQL, Python, pandas, NumPy, Power BI, Git and GitHub |

## Business Questions

The analysis is structured around questions such as:

1. What share of observed buyers place more than one delivered order, and how long does a second purchase take?
2. How do delivery delays relate to review scores?
3. How does end-to-end delivery lead time vary by customer geography?
4. Which product categories contribute most to delivered merchandise value?
5. How do order values differ across payment installment groups?
6. How concentrated is delivered merchandise value among sellers?
7. How does the order cancellation rate change over time?
8. Which buyer–seller state combinations have longer delivery lead times?
9. How does freight compare with item value, and how does it relate to review scores?
10. Which observable order characteristics are associated with higher or lower review scores?

The full business context and analytical boundaries are documented in [Business Understanding](docs/01_business_understanding.md).

## Data

The project uses the nine CSV tables in the public Olist dataset:

- Orders
- Order items
- Customers
- Products
- Payments
- Reviews
- Sellers
- Geolocation
- Product category translations

The raw dataset is not committed to this repository. See [Data Setup](data/README.md) for source and local setup guidance.

**Important measurement boundary:** the dataset contains historical transaction and review records, not website or app event telemetry. It does not support direct measurement of conversion rate, add-to-cart rate, checkout abandonment, engagement-based active users, marketing attribution, or actual A/B test results. Any experiment design included in the project will be clearly identified as a proposal, not a completed experiment.

## Analytical Approach

The project follows a traceable workflow:

**Business question → Metric definition → Data validation → SQL/Python analysis → Insight → Recommendation**

1. Define the business problem and scope.
2. Understand source tables, relationships and analytical grain.
3. Validate keys, missingness, timestamps, numeric ranges and join behavior.
4. Build reusable SQL analysis at the correct grain.
5. Use Python for exploratory analysis, visualization and statistical checks.
6. Build a Power BI semantic model and dashboard from validated measures.
7. Communicate findings, limitations and recommendations.

See [Analytical Architecture](docs/04_analytical_architecture.md) and the [Analysis Roadmap](docs/05_analysis_roadmap.md).

## Repository Structure

```text
ecommerce-product-analytics/
├── README.md
├── .gitignore
├── data/
│   └── README.md
├── docs/
│   ├── 01_business_understanding.md
│   ├── 02_dataset_dictionary.md
│   ├── 03_product_metrics.md
│   ├── 04_analytical_architecture.md
│   └── 05_analysis_roadmap.md
├── sql/
├── python/
├── powerbi/
├── reports/
└── images/
```

Directories will receive implementation artifacts as the corresponding analysis stages are completed.

## Documentation

| Document | Description |
|---|---|
| [Business Understanding](docs/01_business_understanding.md) | Business context, questions, scope and limitations |
| [Dataset Dictionary](docs/02_dataset_dictionary.md) | Source tables, fields, grains and relationships |
| [Product Metrics & KPI Framework](docs/03_product_metrics.md) | Metric definitions, populations and calculation rules |
| [Analytical Architecture](docs/04_analytical_architecture.md) | Data flow, analytical entities, join controls and quality gates |
| [Analysis Roadmap](docs/05_analysis_roadmap.md) | Workstreams, implementation sequence and acceptance criteria |

## Reproducibility

- Raw source data is downloaded separately and kept out of version control.
- SQL scripts target the imported MySQL schema; actual table and column names are validated before analysis.
- Python dependencies and execution instructions will be documented with the analysis artifacts.
- Power BI headline measures will be reconciled against validated SQL outputs.
- Metric populations, exclusions and limitations will be stated alongside results.

## Project Status

The business scope, source-data documentation, KPI framework, analytical architecture and implementation roadmap are documented. SQL validation and analytical implementation are the next stages. No numerical findings or business recommendations are claimed until they have been calculated and checked against the source data.

## Dataset Source

Olist Brazilian E-Commerce Public Dataset — [Kaggle dataset page](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

## License and Data Use

Refer to the dataset provider's terms and license on Kaggle before redistributing the source files. This repository contains project documentation and analysis artifacts, not the raw dataset.
