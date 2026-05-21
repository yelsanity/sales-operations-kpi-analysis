# Sales Operations & KPI Analysis

Built a structured SQL analysis to track 
- sales performance
- delivery efficiency
- customer behavior
- business profitability across a retail operations dataset.


## Project Overview
This project simulates the work of a data analyst supporting a retail operations team. Using a relational dataset of orders, customers, and returns, the analysis answers real business questions across three focus areas
- KPI reporting
- operational efficiency
- executive-level business intelligence.
The dataset contains 100 orders, 30 customers, and 20 return records spanning multiple regions, product categories, and customer segments.

## Business Problem
Retail operations teams need consistent, reliable reporting to make informed decisions. This project addresses three layers of analysis:

- Are we hitting our monthly and quarterly sales targets?
- Where are our delivery bottlenecks and return risks?
- Which customer segments, discount strategies, and product lines are most profitable?


## Project Structure
```
sales-operations-kpi-analysis/
│
├── data/
│   ├── orders.csv        # 100 order transactions with sales, profit, discount, shipping info
│   ├── customers.csv     # 30 customer records with segment and region
│   └── returns.csv       # 20 return records with reason and return date
│
├── queries/
│   └── sales_operations_analysis.sql   # All queries organized by set
│
└── README.md
```
---
 
## Tools & Technologies
 
| Tool | Purpose |
|------|---------|
| **MySQL** | Database engine and query execution |
| **MySQL Workbench** | SQL development environment |
| **Excel / CSV** | Source data format |
 
---
 
## Dataset Schema
 
### orders
| Column | Type | Description |
|--------|------|-------------|
| order_id | VARCHAR | Unique order identifier |
| order_date | DATE | Date order was placed |
| ship_date | DATE | Date order was shipped |
| ship_mode | VARCHAR | Shipping method (Same Day, First Class, etc.) |
| customer_id | VARCHAR | Foreign key to customers |
| segment | VARCHAR | Customer segment (Consumer, Corporate, Home Office) |
| city | VARCHAR | City of delivery |
| region | VARCHAR | Region (Luzon, Visayas, Mindanao) |
| category | VARCHAR | Product category |
| sub_category | VARCHAR | Product subcategory |
| quantity | INT | Units ordered |
| unit_price | DECIMAL | Original price before discount |
| discount | DECIMAL | Discount rate applied (0–1) |
| sales | DECIMAL | Actual revenue after discount |
| profit | DECIMAL | Profit after costs |
 
### customers
| Column | Type | Description |
|--------|------|-------------|
| customer_id | VARCHAR | Unique customer identifier |
| customer_name | VARCHAR | Full name |
| segment | VARCHAR | Customer segment |
| city | VARCHAR | Customer city |
| region | VARCHAR | Customer region |
| join_date | DATE | Date customer was acquired |
| email | VARCHAR | Customer email |
 
### returns
| Column | Type | Description |
|--------|------|-------------|
| return_id | VARCHAR | Unique return identifier |
| order_id | VARCHAR | Foreign key to orders |
| return_date | DATE | Date return was processed |
| reason | VARCHAR | Reason for return |
| returned | VARCHAR | Return status flag |
 
---
 
## Analysis Structure
 
The queries are organized into 3 sets, each targeting a different stakeholder need.
 
---
 
### Set 1 KPI Reporting & Performance Tracking
 
Designed for operations managers who need a monthly performance pulse.
 
| # | Question | Key Technique |
|---|----------|--------------|
| Q1 | Monthly sales KPI summary orders, revenue, profit, margin, avg order value | GROUP BY, DATE_FORMAT, aggregates |
| Q2 | Month over month sales growth absolute change and growth % | LAG() window function |
| Q3 | Running cumulative sales total per region over time | SUM() OVER(PARTITION BY) |
| Q4 | Delivery performance by ship mode avg/min/max days, on-time % | DATEDIFF, CASE inside SUM |
| Q5 | Customer value tiers High/Mid/Low with revenue % per tier | CTE, nested window aggregates |
 
---
 
### Set 2 Operations & Supply Chain Analysis
 
Designed for operations teams tracking delivery bottlenecks and return patterns.
 
| # | Question | Key Technique |
|---|----------|--------------|
| Q1 | Return rate and profit lost by category and region | LEFT JOIN, conditional SUM |
| Q2 | Late delivery detection days overdue per order | DATEDIFF, CASE, JOIN |
| Q3 | Region performance vs overall average above/below flag | AVG() OVER(), CASE |
| Q4 | Repeat vs one-time buyers count and revenue contribution | CTE, COUNT, CASE |
| Q5 | Subcategory ranking by sales within each category | RANK() OVER(PARTITION BY) |
 
---
 
### Set 3 — Business Intelligence & Executive Reporting
 
Designed for leadership quarterly business reviews.
 
| # | Question | Key Technique |
|---|----------|--------------|
| Q1 | Quarterly P&L sales, profit, margin, QoQ growth % | QUARTER(), LAG() |
| Q2 | Customer segment profitability revenue, profit, margin, discount, return rate | LEFT JOIN, CASE, multiple aggregates |
| Q3 | Discount band effectiveness profit impact per discount tier | CTE, CASE grouping, profit margin formula |
| Q4 | Top 3 vs Bottom 3 subcategories by profit margin | Double RANK() in CTE, WHERE filter |
| Q5 | Data quality checks late ships, nulls, zero quantity, invalid discounts | UNION ALL, CASE, HAVING |
 
---
 
## Key Findings
 
**1. Delivery Performance**
All ship modes are performing within expected thresholds on the sample dataset.
 
**2. Discount Impact**
High discount orders (21%+) show the highest profit margin loss. Medium discount bands (11–20%) represent the highest volume of orders making them the most operationally significant discount tier to monitor.
 
**3. Customer Segments**
Across the three customer segments Consumer, Corporate, and Home Office revenue contributions are relatively balanced, indicating the business is not overly reliant on a single segment. This healthy distribution reduces customer concentration risk

**4. Return Patterns**
Return rate and profit impact were analyzed by category and region. Visayas recorded the highest return rate and volume among all regions identifying it as the priority area for return reduction efforts. By quantifying the profit lost per returned order, operations teams can assess the true cost of returns beyond just volume and target the most damaging categories for intervention.
 
**5. Quarterly Trends**
Quarter over quarter profit growth shows high variance across periods, suggesting sales performance is not driven by seasonal patterns but rather by irregular demand fluctuations. The highest growth rate was recorded in Q2 2022 at 300%, while the highest absolute profit was achieved in Q4 2023
 
---
 
## What I Learned
 
**CTEs for Layered Logic**
Using CTEs to pre-aggregate data before applying a second layer of grouping or window functions cleaner and more readable than deeply nested subqueries.
 
**Window Functions vs GROUP BY**
Understanding when to use each GROUP BY collapses rows for aggregation, window functions keep row-level detail while adding aggregate context.
 
**NULL Handling in Joins**
Using LEFT JOIN + `IS NULL` and `IS NOT NULL` patterns to separate matched vs unmatched records particularly useful for return analysis where not every order has a corresponding return.
 
**Data Quality Thinking**
Writing systematic checks for common data issues (date inconsistencies, nulls, invalid values) using UNION ALL building the habit of validating data before trusting analysis results.
 
**Business Framing**
Every query was written to answer a specific business question not just to practice syntax. The discipline of asking "what decision does this output support?" before writing a query, produces more useful analysis.
 
