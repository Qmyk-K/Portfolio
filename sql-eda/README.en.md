*[Czytaj po polsku](README.md)*

# SQL EDA: exploratory data analysis and reporting on the warehouse (SQL Server)

A set of 13 SQL scripts that build on each other: from getting to know the database structure, through magnitude, ranking, and time-trend analysis, to two ready-to-query reporting views (`gold.report_customers`, `gold.report_products`). Everything was run against the real `DataWarehouse` database from the [SQL Data Warehouse](../sql-data-warehouse/) project - the numbers below aren't sample figures, they're the actual output of these queries.

---

## Table of contents

1. [Project goal](#1-project-goal)
2. [Where the data comes from](#2-where-the-data-comes-from)
3. [Script structure](#3-script-structure)
4. [Analysis and findings](#4-analysis-and-findings)
5. [Limitations and caveats](#5-limitations-and-caveats)
6. [How to run](#6-how-to-run)
7. [Skills demonstrated](#7-skills-demonstrated)

---

## 1. Project goal

The warehouse itself (the gold layer: `dim_customers`, `dim_products`, `fact_sales`) is only the starting point. This project answers the next question: now that the data is clean and joined together, what does it actually show? The scripts move from general to specific - first getting familiar with the structure, then basic measures, then increasingly targeted analysis (ranking, time trends, segmentation), ending in two reporting views that consolidate everything in one place.

## 2. Where the data comes from

This project assumes the `DataWarehouse` database already exists and is loaded - see [SQL Data Warehouse](../sql-data-warehouse/#9-how-to-run-this-project) for the full build process (Bronze/Silver/Gold, ETL, quality tests). This project only reads from the finished `gold` layer.

## 3. Script structure

| File | What it does |
|---|---|
| [`01_database_exploration.sql`](scripts/01_database_exploration.sql) | List of tables and columns in the database (`INFORMATION_SCHEMA`) |
| [`02_dimensions_exploration.sql`](scripts/02_dimensions_exploration.sql) | Distinct values in the dimensions: countries, product categories |
| [`03_date_range_exploration.sql`](scripts/03_date_range_exploration.sql) | Order date range and customer age range |
| [`04_measures_exploration.sql`](scripts/04_measures_exploration.sql) | Core measures: total sales, order count, customer count, product count |
| [`05_magnitude_analysis.sql`](scripts/05_magnitude_analysis.sql) | Breakdown by dimension: country, gender, category |
| [`06_ranking_analysis.sql`](scripts/06_ranking_analysis.sql) | Top / bottom products and customers (`TOP`, `RANK() OVER`) |
| [`07_change_over_time_analysis.sql`](scripts/07_change_over_time_analysis.sql) | Sales trend over time (`DATETRUNC`, `FORMAT`) |
| [`08_cumulative_analysis.sql`](scripts/08_cumulative_analysis.sql) | Running total and moving average (`SUM() OVER`) |
| [`09_performance_analysis.sql`](scripts/09_performance_analysis.sql) | Year-over-year product performance (`LAG()`) |
| [`10_data_segmentation.sql`](scripts/10_data_segmentation.sql) | Product segmentation by cost, customer segmentation by behavior (VIP/Regular/New) |
| [`11_part_to_whole_analysis.sql`](scripts/11_part_to_whole_analysis.sql) | Each category's percentage share of total sales |
| [`12_report_customers.sql`](scripts/12_report_customers.sql) | `gold.report_customers` view: a full customer report in one place |
| [`13_report_products.sql`](scripts/13_report_products.sql) | `gold.report_products` view: a full product report in one place |

## 4. Analysis and findings

Every number below comes from actually running these scripts against the `DataWarehouse` database.

**Data scale:** 60,398 order line items, 27,659 distinct orders, 18,484 customers, 295 products. Orders span 37 months, from 2010-12-29 to 2014-01-28. Total sales: 29,356,250, at an average price of 486.

**Sales are extremely concentrated in one category.** Bikes account for 96.46% of all sales (28.3M), Accessories 2.39%, Clothing 1.16%. The Components category (127 products in the catalog) generated **zero** sales, verified with a direct join, not just a missing aggregate row. These are catalog-only parts that were never sold as a standalone line item in this dataset.

**The top 5 products are variants of a single model.** The top 5 by revenue are all color/size variants of the Mountain-200 (1.29-1.37M each): one very strong model drives a disproportionate share of the result. At the other end: socks, patch kits, and low-cost accessories at a few thousand each.

**Customers: the US accounts for 40% of the base.** Breakdown by country: US 7,482 (40%), Australia 3,591 (19%), UK 1,913, France 1,810, Germany 1,780, Canada 1,571. Gender is almost exactly 50/50 (9,341 male, 9,128 female).

**Customer segmentation: 79% are "New".** Per `gold.report_customers` (VIP: ≥12 months history and sales >5,000 / Regular: ≥12 months history and sales ≤5,000 / New: history <12 months): New 14,629 (79%), Regular 2,200 (12%), VIP 1,653 (9%). Average spend for VIP is 6,509 versus 757 for New, an 8.6x difference, which tracks given the VIP definition explicitly requires higher spend.

**2013 shows a clear jump.** Sales by year: 2011 - 7.08M, 2012 - 5.84M, 2013 - 16.34M (+180% year-over-year). 2010 and 2014 only cover single months (December and January respectively), so they can't be compared 1:1 against full years.

**Product segmentation by revenue (`gold.report_products`):** High-Performer 66 products (avg 418,844 revenue), Mid-Range 58 (avg 28,824), Low-Performer 6 (avg 5,949): a heavily skewed distribution, consistent with the Bikes-category dominance noted above.

## 5. Limitations and caveats

- **`recency` and customer age are computed against `GETDATE()`, not against the dataset's own last order date.** This is a historical dataset (data ends in January 2014), so running these queries today returns a recency of 150+ months for every segment, simply because that much real time has passed since the dataset ended, **not because customers actually stopped buying that long ago relative to each other**. The same applies to age: the youngest customer in the dataset (born 1986) is 40 today, so the `age_group` breakdown in `gold.report_customers` no longer shows any group under 40, even though the original dataset included younger customers. In a real production setting, these metrics should be computed against a fixed analysis date or the dataset's own maximum date, not the live `GETDATE()`.
- **One customer has a birthdate of 1916-02-10 (age 110).** This falls outside the range assumed by the silver-layer quality tests in the [SQL Data Warehouse](../sql-data-warehouse/tests/quality_checks_silver.sql) project (1924+): likely a bad or default value that slipped through cleaning.
- **7 products have no assigned category** (`category IS NULL`): orphaned catalog entries.
- The analysis is descriptive, not predictive: it shows what happened, not what will happen next.

## 6. How to run

1. Requires a built and loaded `DataWarehouse` database - see [SQL Data Warehouse](../sql-data-warehouse/#9-how-to-run-this-project).
2. Scripts 01-11 are independent exploratory queries: run them individually, in any order.
3. Scripts 12-13 create views (`CREATE VIEW`): run them once to set up `gold.report_customers` and `gold.report_products`, then query the views directly with a plain `SELECT`.

## 7. Skills demonstrated

T-SQL (window functions: `RANK`, `LAG`, `SUM() OVER`, `AVG() OVER`) · date functions (`DATEDIFF`, `DATETRUNC`, `FORMAT`) · aggregation and `GROUP BY` · segmentation via `CASE` · designing reporting views · reading results and drawing conclusions from them, including spotting limitations in the calculation method itself.

---
**LinkedIn:** [Kamil Krzosek](https://www.linkedin.com/in/kamil-krzosek-b17921418/)
