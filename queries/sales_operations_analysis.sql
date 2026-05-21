-- **Scenario:**
-- You are a data analyst for a retail operations team. Management wants a monthly performance report to track sales health, delivery efficiency, and customer activity.
-- Q1 Monthly Sales KPI

SELECT 
DATE_FORMAT(order_date, '%Y-%m' ) AS Year_and_Month,
COUNT(order_id) AS total_num_orders,
ROUND(SUM(sales)) AS total_sales,
ROUND(SUM(profit)) AS total_profit,
ROUND(SUM(profit) / SUM(sales), 3) AS profit_margin,
ROUND(SUM(sales) / COUNT(order_id)) AS average_order_value
FROM orders
GROUP BY 1
ORDER BY 1;

-- Q2 month over month Sales growth
-- Calculate the sales for each month and show how much it grew or declined compared to the previous month in both absolute value and percentage.

SELECT
	date_format(order_date, '%m-%Y') AS `Year_Month`,
    ROUND(SUM(sales)) AS monthly_sales,
    ROUND(SUM(sales) - LAG(SUM(sales)) OVER (ORDER BY YEAR(order_date), MONTH(order_date))) AS Monthly_sales_change,
    ROUND((SUM(sales) - LAG(SUM(sales)) OVER (ORDER BY YEAR(order_date), MONTH(order_date))) / 
		LAG(SUM(sales)) OVER (ORDER BY YEAR(order_date), MONTH(order_date)) * 100, 2) AS Growth_pct
FROM orders
GROUP BY YEAR(order_date), MONTH(order_date), 1
ORDER BY YEAR(order_date);

-- **Q3 Running Total of Sales by Region**
-- Show a running cumulative total of sales per region ordered by date — so you can see how each region's revenue builds over time.

SELECT
    region,
    order_date,
    ROUND(SUM(sales)) AS total_sales,
    ROUND(SUM(SUM(sales)) OVER (PARTITION BY region ORDER BY order_date)) AS running_sales_total
FROM orders
GROUP BY region, order_date;

-- **Q4 Delivery Performance KPI**
-- For each ship mode calculate:
	-- Average delivery days
	-- Minimum and maximum delivery days
	-- % of orders delivered within expected timeframe
		-- Same Day: 0 days
		-- First Class: ≤ 2 days
		-- Second Class: ≤ 4 days
		-- Standard Class: ≤ 7 days

SELECT 
	region,
    ship_mode,
    AVG(datediff(ship_date, order_date)) AS AVG_Delivery_time,
    MAX(datediff(ship_date, order_date)) AS MAX_delivery_time,
    MIN(datediff(ship_date, order_date)) AS MIN_delivery_time,
    SUM(CASE 
		WHEN ship_mode = 'Same Day' AND datediff(ship_date, order_date) = 0 THEN 1 
        WHEN ship_mode = 'First Class' AND datediff(ship_date, order_date) <= 2 THEN 1
         WHEN ship_mode = 'Second Class' AND datediff(ship_date, order_date) <= 4 THEN 1
         WHEN ship_mode = 'Standard Class' AND datediff(ship_date, order_date) <= 7 THEN 1
        ELSE 0 END) *100 / count(order_id) AS percentage_orders_delivered_on_time
FROM orders
GROUP BY region, ship_mode
ORDER BY region, 3;

-- **Q5 — Customer Activity Report**
-- Classify each customer as:
-- 'High Value' — total purchases > 50,000
-- 'Mid Value' — total purchases between 20,000 and 50,000
-- 'Low Value' — total purchases below 20,000
-- Then count how many customers fall into each tier and what % of total revenue they represent.

WITH customer_classification AS (
    SELECT
        customer_id,
        region,
        COUNT(order_id) AS order_count,
        ROUND(SUM(sales)) AS Total_purchases,
        CASE
            WHEN ROUND(SUM(sales)) > 50000 THEN 'HIGH VALUE'
            WHEN ROUND(SUM(sales)) BETWEEN 20000 AND 50000 THEN 'MID VALUE'
            WHEN ROUND(SUM(sales)) < 20000 THEN 'LOW VALUE'
            ELSE NULL
        END AS Customer_class
    FROM orders
    GROUP BY customer_id, region
)
SELECT 
    customer_class,
    COUNT(customer_id) AS class_customer_count,
    SUM(total_purchases) AS class_total_purchase,
    -- Window functions applied AFTER group by to get overall grand totals:
   ROUND((COUNT(customer_id) / SUM(COUNT(customer_id)) OVER()) * 100, 2) AS grand_total_customer_count,
   ROUND((SUM(total_purchases) / SUM(SUM(total_purchases)) OVER()) * 100, 2) AS percentage_of_total_revenue
FROM customer_classification
GROUP BY customer_class;


-- **Scenario:**
-- You support an operations team managing product deliveries across regions. They need visibility into delivery bottlenecks, 
-- return patterns, and regional performance gaps.

-- **Q1 Return Rate by Category and Region**
	-- Total orders
	-- Total returned orders
	-- Return rate %
	-- Total profit lost from returned orders

SELECT 
	region,
    category,
    COUNT(return_id) AS return_order,
    ROUND((COUNT(rtn.return_id) / COUNT(ord.order_id)) * 100, 2) AS return_rate,
    ROUND(SUM( CASE WHEN return_id IS NOT NULL THEN ord.profit ELSE 0 END)) AS profit_lost
FROM orders AS ord
LEFT JOIN returns AS rtn
ON ord.order_id = rtn.order_id
GROUP BY 1, 2
ORDER BY 1, 2;

-- **Q2 Bottleneck Detection — Late Deliveries**
	-- Identify orders that were delivered late based on their ship mode expected timeframe (same thresholds as Set 1 Q4).
	-- Show:
		-- order_id
		-- customer_name
		-- region
		-- ship_mode
		-- actual delivery days
		-- expected max days
		-- days overdue

SELECT
	ord.order_id,
	cus.customer_name,
    ord.region,
    ord.ship_mode,
    datediff(ship_date, order_date) AS actual_delivery_days,
    CASE 
		WHEN ship_mode = 'Same Day' THEN 0 
        WHEN ship_mode = 'First Class' THEN 2
         WHEN ship_mode = 'Second Class' THEN 4
         WHEN ship_mode = 'Standard Class' THEN 7
        ELSE 0 END AS expected_MAX_days,
        CASE 
		WHEN ship_mode = 'Same Day' AND datediff(ship_date, order_date) > 0 THEN datediff(ship_date, order_date) - 0
        WHEN ship_mode = 'First Class' AND datediff(ship_date, order_date) > 2 THEN datediff(ship_date, order_date) - 2
         WHEN ship_mode = 'Second Class' AND datediff(ship_date, order_date) > 4 THEN datediff(ship_date, order_date) - 4
         WHEN ship_mode = 'Standard Class' AND datediff(ship_date, order_date) > 7 THEN datediff(ship_date, order_date) - 7
        ELSE 0 END AS day_overdue
FROM orders AS ord
JOIN customers AS cus
ON ord.customer_id = cus.customer_id;




-- **Q3 Region vs Overall Average Performance**
	-- For each region show total sales and whether it is above or below the overall average sales across all regions. 
	-- Label it as 'Above Average' or 'Below Average'

    
	SELECT
		region,
		ROUND(SUM(sales)) AS total_sales_per_region,
        CASE 
        WHEN SUM(sales) > AVG(SUM(sales)) OVER () THEN 'ABOVE AVERAGE'
        WHEN SUM(sales) < AVG(SUM(sales)) OVER () THEN 'BELOW AVERAGE'
        ELSE 'OVERALL SALES AVG' END AS Remarks
	FROM orders
    GROUP BY 1;
    
    
-- *Q4 Repeat Customers vs One Time Buyers**
	-- Identify which customers have placed more than one order (repeat buyers) vs only one order (one-time buyers).
	-- Show the count of each type and their respective total revenue contribution.

WITH customer_remark AS (
SELECT
	customer_id,
    count(order_id),
	CASE 
		WHEN count(order_id) > 1 THEN 'repeat buyers'
		WHEN count(order_id) = 1 THEN 'one time buyer'
	ELSE 'Unknown' END AS customer_remarks,
    ROUND(SUM(sales)) AS revenue
FROM orders
GROUP BY 1
)
SELECT 
	customer_remarks,
	COUNT(customer_remarks) customer_count,
    SUM(revenue) AS revenue_contribution
FROM customer_remark
GROUP BY 1;


-- **Q5 Product Subcategory Ranking Within Category**
	-- Rank each subcategory by total sales within its parent category.
	-- Show the rank, category, subcategory, total sales, and total profit.

SELECT
    RANK() OVER(PARTITION BY category ORDER BY SUM(sales) DESC) AS `rank`,	
    category,
    sub_category,
    ROUND(SUM(sales)) total_sales,
    ROUND(SUM(profit)) total_profit
FROM orders
GROUP BY category, sub_category;


-- **Scenario:**
-- Leadership wants a quarterly business review report. You need to produce clean, executive-level insights 
-- covering profitability, customer segments, discount strategy, and operational efficiency.

-- **Q1 Quarterly Profit & Loss Summary**
	-- Show per quarter (Q1/Q2/Q3/Q4) and year:
	-- Total sales
	-- Total profit
	-- Profit margin %
	-- Quarter over quarter profit growth %

SELECT 
	quarter(order_date) AS qrtr,
    year(order_date) AS `year`,
    ROUND(SUM(sales)) AS quarterly_sales,
    ROUND(SUM(profit)) AS quarterly_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100 ,2)AS `profit_margin%`,
    ROUND((SUM(profit) - LAG(SUM(profit)) OVER (ORDER BY YEAR (order_date), QUARTER (order_date)))) AS profit_change,
    ROUND((SUM(profit) - LAG(SUM(profit)) OVER (ORDER BY YEAR (order_date), QUARTER (order_date))) / 
    LAG(SUM(profit)) OVER (ORDER BY YEAR (order_date), QUARTER (order_date)) *100,2) AS `quarterly_profit_growth%`
FROM orders
GROUP BY qrtr, `year`
ORDER BY `year`, qrtr;

-- **Q2 Customer Segment Profitability**
	-- Compare Consumer, Corporate, and Home Office segments across:
	-- Total orders
	-- Total revenue
	-- Total profit
	-- Profit margin %
	-- Average discount given
	-- Return rate %

SELECT 
    ord.segment,
    COUNT(ord.order_id) AS total_orders,
    COUNT(rtn.return_id) AS total_returned,
    ROUND(SUM(CASE WHEN rtn.return_id IS NULL THEN sales ELSE 0 END)) AS total_revenue,
    ROUND(SUM(CASE WHEN rtn.return_id IS NULL THEN profit ELSE 0 END)) AS total_profit,
    ROUND(
        SUM(CASE WHEN rtn.return_id IS NULL THEN profit ELSE 0 END) /
        NULLIF(SUM(CASE WHEN rtn.return_id IS NULL THEN sales ELSE 0 END), 0) * 100
    , 2) AS profit_margin_pct,
    ROUND(AVG(CASE WHEN rtn.return_id IS NULL THEN ord.discount ELSE NULL END) * 100, 2) AS avg_discount_pct,
    ROUND(COUNT(rtn.return_id) / COUNT(ord.order_id) * 100, 2) AS return_rate_pct
FROM orders AS ord
LEFT JOIN returns AS rtn 
    ON ord.order_id = rtn.order_id
GROUP BY ord.segment
ORDER BY total_revenue DESC;


-- **Q3 Discount Strategy Effectiveness**
	-- Group orders into discount bands:
		-- No Discount (0%)
		-- Low (1–10%)
		-- Medium (11–20%)
		-- High (21%+)
	-- For each band show total orders, total sales, total profit, and profit margin %. 
    -- Conclude which discount band is most damaging to profitability.

WITH discount AS (
	SELECT 
		order_id,
        	CASE
		WHEN discount = 0 THEN 'No Discount'
        WHEN discount between 0.01 AND 0.10 THEN 'Low Discount'
        WHEN discount between 0.11 AND 0.20 THEN 'Medium Discount'
        WHEN discount >= 0.21 THEN 'High Discount'
	ELSE 'No Discount' END AS discount_band
    FROM orders
)
SELECT 
	discount_band,
	ROUND(SUM(sales)) AS total_revenue,
    ROUND(SUM(unit_price * quantity)) AS revenue_full_price,
    ROUND(SUM(unit_price * quantity) - SUM(sales)) AS revenue_lost_to_discount,
	ROUND((SUM(profit) / SUM(sales)) * SUM(unit_price * quantity)) AS projected_profit,
    ROUND(SUM(profit)) AS actual_profit,
    ROUND(((SUM(profit) / SUM(sales)) * SUM(unit_price * quantity) - SUM(profit)) / ((SUM(profit) / SUM(sales)) * SUM(unit_price * quantity)) * 100, 2) AS profit_impact_pct
FROM orders AS ord
JOIN discount AS band
ON ord.order_id = band.order_id
GROUP BY 1
ORDER BY profit_impact_pct DESC;

-- **Q4 Top Performing vs Bottom Performing Products**
	-- Using a single query show:
	-- Top 3 subcategories by profit margin %
	-- Bottom 3 subcategories by profit margin %

	-- Label them as 'Top Performer' or 'Bottom Performer'.

WITH sub_cat AS(
	SELECT 
		sub_category,
		ROUND(SUM(profit) / SUM(sales) *100 ,2) AS profit_margin_pct,
        RANK() OVER(ORDER BY ROUND(SUM(profit) / SUM(sales) *100 ,2) DESC) AS top_rank,
        RANK() OVER(ORDER BY ROUND(SUM(profit) / SUM(sales) *100 ,2) ASC) AS bottom_rank
	FROM orders
	GROUP BY sub_category
)
SELECT *
FROM sub_cat
WHERE top_rank <= 3 OR bottom_rank <= 3
ORDER BY top_rank;


-- **Q5 Data Quality Check**
	-- Write a query that flags potential data quality issues:
	-- Orders where ship_date is BEFORE order_date
	-- Orders where profit is NULL
	-- Orders where quantity is zero or negative
	-- Orders where discount is greater than 1 (impossible value)

	-- Show the order_id, issue type, and the problematic value for each flagged record.

WITH data_QC AS (
SELECT
	order_id,
    CASE WHEN datediff(ship_date, order_date) < 0 THEN 'wrong ship date' ELSE 'No Issue' END AS issue_type,
    CASE WHEN datediff(ship_date, order_date) < 0 THEN ship_date ELSE 'None' END AS problematic_value
FROM orders

UNION ALL

SELECT
	order_id,
    CASE WHEN profit IS NULL THEN 'the profit is null' ELSE 'No Issue' END AS issue_type,
    CASE WHEN profit IS NULL THEN profit ELSE 'None' END AS problematic_value
FROM orders

UNION ALL

SELECT
	order_id,
    CASE WHEN quantity <= 0 THEN 'Order has no quantity' ELSE 'No Issue' END AS issue_type,
    CASE WHEN quantity <= 0 THEN quantity ELSE 'None' END AS problematic_value
FROM orders

UNION ALL

SELECT
    order_id,
    'Discount Error' AS issue_type,
    'Multiple Discounts' AS problematic_value
FROM orders
GROUP BY order_id
HAVING MAX(discount) > 1
)
SELECT *
FROM data_QC
WHERE issue_type <> 'No Issue';

