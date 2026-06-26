-- Part A: GROUP BY Queries

-- Q1: Total orders per region.
SELECT region, COUNT(order_id) AS total_orders
FROM sales 
GROUP BY region 
ORDER BY total_orders DESC;
-- Result: NCR 67, Mindanao 27, Visayas 19, Luzon 7

-- Q2: Total revenue per category (use SUM(total)), sorted descending.
SELECT category, SUM(total) AS total_revenue
FROM sales 
GROUP BY category 
ORDER BY total_revenue DESC;
-- Result: Electronics 1,981,500 | Accessories 179,200 | Storage 81,800

-- Q3: Monthly revenue: group by substr(order_date, 1, 7) and sum total.
SELECT substr(order_date, 1, 7) AS month, SUM(total) AS monthly_revenue
FROM sales 
GROUP BY substr(order_date, 1, 7);
-- Result: Peak month is 2025-08 (454,840), lowest is 2025-04 (9,130)

-- Q4: Average order value per region, rounded to 2 decimals.
SELECT region, ROUND(AVG(total), 2) AS avg_order_value
FROM sales 
GROUP BY region;
-- Result: NCR 22160.90, Visayas 14736.32, Mindanao 14637.04, Luzon 11790.00

-- Q5: For each product, the total units sold (SUM(quantity)) and total revenue. Sort by revenue desc.
SELECT product, SUM(quantity) AS total_units, SUM(total) AS total_revenue
FROM sales 
GROUP BY product 
ORDER BY total_revenue DESC;
/*Result:
product               | total_units   | total_revenue  
------------------------+---------------+----------------
Laptop Lenovo           | 24            | 840000         
Tablet Samsung          | 24            | 432000         
Desktop PC Ryzen 5      | 8             | 336000         
Monitor 24-inch         | 19            | 237500         
Printer Canon           | 16            | 136000         
External SSD 500GB      | 20            | 64000          
Headset HyperX          | 15            | 57000          
Keyboard Mechanical     | 15            | 37500          
Webcam HD               | 17            | 30600          
Wireless Mouse          | 22            | 18700          
Laptop Stand            | 10            | 15000          
Mouse Pad XL            | 24            | 10800          
SD Card 128GB           | 15            | 10200          
USB-C Hub               | 8             | 9600           
USB Flash Drive 64GB    | 20            | 7600           
*/ 

-- Q6: Count of orders per quantity value (1, 2, 3, 4, 5). This is a frequency distribution.
SELECT quantity, COUNT(order_id) AS order_count
FROM sales 
GROUP BY quantity 
ORDER BY quantity ASC;
-- Result: 1 unit: 49, 2 units: 34, 3 units: 16, 4 units: 13, 5 units: 8

-- Q7: Top 5 customers by total spend.
SELECT customer_name, SUM(total) AS total_spend
FROM sales 
GROUP BY customer_name 
ORDER BY total_spend DESC 
LIMIT 5;
-- Result: Sofia Mendoza 307190, Patricia Lim 299600, Carlos Garcia 235980, Nicole Ramos 200330, Grace Domingo 168390.

-- Q8: Number of distinct customers per region.
SELECT region, COUNT(DISTINCT customer_id) AS distinct_customers
FROM sales 
GROUP BY region;
-- Result: NCR 11, Mindanao 4, Visayas 4, Luzon 1


-- Part B: HAVING & Subqueries

-- Q9: Customers who placed 8 or more orders. (HAVING)
SELECT customer_name, COUNT(order_id) AS total_orders
FROM sales 
GROUP BY customer_name 
HAVING COUNT(order_id) >= 8;
-- Result: Grace Domingo (14), Carlos Garcia (10), Leo Pascual (10), Joy Bautista (8), Kenneth Sy (8)

-- Q10: Products that sold MORE than 50 total units. (HAVING)
SELECT product, SUM(quantity) AS total_units_sold
FROM sales 
GROUP BY product 
HAVING SUM(quantity) > 50;
-- Result: (Empty Result Set. No product sold more than 50 units.)

-- Q11: Customers whose total spend is above the average customer spend. (Subquery)
SELECT customer_name, SUM(total) AS total_spend
FROM sales
GROUP BY customer_name
HAVING SUM(total) > (
    SELECT AVG(per_customer)
    FROM (SELECT SUM(total) AS per_customer FROM sales GROUP BY customer_name)
);
-- Result: Sofia Mendoza 307190, Patricia Lim 299600, Carlos Garcia 235980, Nicole Ramos 200330, Grace Domingo 168390, Roberto Flores 127900, Miguel Torres 144750, Leo Pascual 128700, Joy Bautista 124800.


-- Part C: Query Optimization

-- Q12: Run EXPLAIN QUERY PLAN on Q3 from Part A. Paste the result as a comment.
EXPLAIN QUERY PLAN 
SELECT substr(order_date, 1, 7) AS month, SUM(total) AS monthly_revenue 
FROM sales 
GROUP BY substr(order_date, 1, 7);

/* Q12 Result: 
id  parent  notused  detail
6   0       0        SCAN sales
8   0       0        USE TEMP B-TREE FOR GROUP BY

Explanation: 
Without an index, the SQLite query planner executes a full "SCAN" of the sales table. 
Because we are grouping by a dynamic string function (substr), the engine is forced 
to construct a temporary B-tree in memory to sort and process the GROUP BY logic. 
At enterprise scale, building temporary B-trees on the fly is highly memory-intensive.
*/

-- Q13: Create an index on the order_date column. Then re-run Q3. Note any difference.
CREATE INDEX idx_sales_date ON sales(order_date);

/* Q13 Observation:
There is no difference in performance. Because we applied a function (substr) to 
the order_date column, the database ignores the new index and still performs a 
full table scan.
*/