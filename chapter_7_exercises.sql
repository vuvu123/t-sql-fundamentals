USE TSQLV4;

-- Exercise 1: Write a query against the dbo.Orders table that computes both a rank and a dense rank for each customer order, partitioned by custid and ordered by qty
SELECT
	custid,
	orderid,
	qty,
	RANK() OVER(PARTITION BY custid ORDER BY qty) AS rnk,
	DENSE_RANK() OVER(PARTITION BY custid ORDER BY qty) AS drnk
FROM dbo.Orders;

/*
 Exercise 2: Earlier in the chapter in the section “Ranking window functions,” 
  		     I provided the following query against the Sales.OrderValues view to return distinct values and their associated row numbers:

				SELECT val, ROW_NUMBER() OVER(ORDER BY val) AS rownum
				FROM Sales.OrderValues
				GROUP BY val;

			 Can you think of an alternative way to achieve the same task?
*/

-- Alternate 1
SELECT val, ROW_NUMBER() OVER(ORDER BY val) AS rownum
FROM (
	SELECT DISTINCT val
	FROM Sales.OrderValues
)t

-- Alternate 2
WITH distinct_vals AS (
	SELECT DISTINCT val
	FROM Sales.OrderValues
)
SELECT
	val,
	ROW_NUMBER() OVER(ORDER BY val) AS rownum
FROM distinct_vals;

-- Exercise 3: Write a query against the dbo.Orders table that computes for each customer order both the difference between the current order quantity and the 
--			   customer’s previous order quantity and the difference between the current order quantity and the customer’s next order quantity
SELECT
	custid,
	orderid,
	qty,
	qty - LAG(qty) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS diffprev,
	qty - LEAD(qty) OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS diffnext
FROM dbo.Orders;

-- Exercise 4: Write a query against the dbo.Orders table that returns a row for each employee, a column for each order year, and the count of orders for each employee and order year
-- Pivot Using grouped query
SELECT
	empid,
	COUNT(CASE WHEN YEAR(orderdate) = 2014 THEN 1 END) AS 'cnt2014',
	COUNT(CASE WHEN YEAR(orderdate) = 2015 THEN 1 END) AS 'cnt2015',
	COUNT(CASE WHEN YEAR(orderdate) = 2016 THEN 1 END) AS 'cnt2016'
FROM dbo.Orders
GROUP BY empid;

-- Pivot Using Pivot Operator
SELECT 
	empid, 
	[2014] AS cnt2014, 
	[2015] AS cnt2015, 
	[2016] AS cnt2016
FROM (
	SELECT empid, YEAR(orderdate) AS orderyear
	FROM dbo.Orders
) AS T
PIVOT(COUNT(orderyear) FOR orderyear IN([2014], [2015], [2016])) AS P;

-- Exercise 5: Write a query against the EmpYearOrders table that unpivots the data, returning a row for each employee and order year with the number of orders. 
--			   Exclude rows in which the number of orders is 0 (in this example, employee 3 in the year 2015).
SELECT * FROM dbo.EmpYearOrders;

-- Unpivot using CROSS APPLY
SELECT empid, orderyear, numorders
FROM dbo.EmpYearOrders
CROSS APPLY (VALUES(2014, cnt2014), (2015, cnt2015), (2016, cnt2016)) AS C(orderyear, numorders)
WHERE orderyear <> 0;

-- Unpivot using UNPIVOT operator
SELECT empid, CAST(RIGHT(orderyear, 4) AS INT) AS orderyear, numorders
FROM dbo.EmpYearOrders
UNPIVOT(numorders FOR orderyear IN (cnt2014, cnt2015, cnt2016)) AS U
WHERE numorders <> 0;

-- Exercise 6: Write a query against the dbo.Orders table that returns the total quantities for each of the following: 
--			   (employee, customer, and order year), (employee and order year), and (customer and order year). 
--			   Include a result column in the output that uniquely identifies the grouping set with which the current row is associated:
SELECT
	GROUPING_ID(empid, custid, YEAR(orderdate)) AS groupingset,
	empid, custid, YEAR(orderdate) AS orderyear, SUM(qty) AS totalqty
FROM dbo.Orders
GROUP BY
	GROUPING SETS(
	(empid, custid, YEAR(orderdate)),
	(empid, YEAR(orderdate)),
	(custid, YEAR(orderdate))
	)
ORDER BY groupingset, orderyear, empid, custid;