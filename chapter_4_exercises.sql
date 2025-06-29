USE TSQLV4;

-- Miscellaneous: String_AGG practice
SELECT
	o.custid,
	COUNT(o.orderid) AS total_orders,
	SUM(od.qty) AS total_qty_ordered,
	SUM(od.qty * (od.unitprice * (1 - od.discount))) AS total_sales,
	SUM(od.qty * od.unitprice) AS total_sales_wo_discount,
	STRING_AGG(RIGHT(p.productname, CHARINDEX(' ', REVERSE(p.productname)) - 1), ', ') AS products_purchased
FROM Sales.Orders o
LEFT JOIN Sales.OrderDetails od ON o.orderid = od.orderid
LEFT JOIN Production.Products p ON od.productid = p.productid
GROUP BY custid


-- Exercise 1: Write a query that returns all orders placed on the last day of activity that can be found in the Orders table
SELECT
	o1.orderid,
	o1.orderdate,
	o1.custid,
	o1.empid
FROM Sales.Orders O1
WHERE orderdate = 
	(SELECT MAX(orderdate)
	FROM Sales.Orders);

-- Exercise 2: Write a query that returns all orders placed by the customer(s) who placed the highest number of orders. 
--			   Note that more than one customer might have the same number of orders
WITH order_cnt AS (
	SELECT
		custid,
		COUNT(orderid) AS num_orders
	FROM Sales.Orders
	GROUP BY custid
), order_cnt_rnk AS (
	SELECT
		custid,
		num_orders,
		RANK() OVER(ORDER BY num_orders DESC) AS rnk
	FROM order_cnt
)

SELECT
	custid,
	orderid,
	orderdate,
	empid
FROM Sales.Orders
WHERE custid IN (SELECT custid FROM order_cnt_rnk WHERE rnk = 1)
ORDER BY orderid;

-- Exercise 3: Write a query that returns employees who did not place orders on or after May 1, 2016
SELECT
	empid,
	firstname,
	lastname
FROM HR.Employees
WHERE empid NOT IN (
	SELECT empid
	FROM Sales.Orders
	WHERE orderdate >= '2016-05-01'
);

-- Exercise 4: Write a query that returns countries where there are customers but not employees
SELECT DISTINCT c.country
FROM Sales.Customers c
WHERE country NOT IN (
	SELECT e.country
	FROM HR.Employees e
)
ORDER BY c.country

-- Exercise 5: Write a query that returns for each customer all orders placed on the customer’s last day of activity
SELECT 
	o1.custid,
	o1.orderid,
	o1.orderdate,
	o1.empid
FROM Sales.Orders o1
WHERE orderdate IN (
	SELECT MAX(orderdate) 
	FROM Sales.Orders o2 
	WHERE o2.custid = o1.custid
)
ORDER BY o1.custid

-- Exercise 6: Write a query that returns customers who placed orders in 2015 but not in 2016
SELECT c.custid, c.companyname
FROM Sales.Customers C
WHERE c.custID IN (
	SELECT custid
	FROM Sales.Orders
	WHERE orderdate >= '2015-01-01' AND orderdate < '2016-01-01'
) AND c.custID NOT IN (
	SELECT custid
	FROM Sales.Orders
	WHERE orderdate >= '2016-01-01' AND orderdate < '2017-01-01'
)
ORDER BY c.custid

-- Exercise 7: Write a query that returns customers who ordered product 12
SELECT DISTINCT
	c.custid,
	c.companyname
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.custid = o.custid
INNER JOIN Sales.OrderDetails od ON o.orderid = od.orderid
WHERE od.productid = 12
ORDER BY c.companyname;

-- Exercise 8: Write a query that calculates a running-total quantity for each customer and month
SELECT
	custid,
	ordermonth,
	qty,
	SUM(qty) OVER(PARTITION BY custid ORDER BY ordermonth) AS runqty
FROM Sales.CustOrders
ORDER BY custid, ordermonth

/*
Exercise 9: Explain the difference between IN and EXISTS

IN compares a value to a list of values. IN with NULLs can cause unexpected results. Example would be it returning no rows if the value 
is compared to a NULL unless it's explicitly handled (IS NOT NULL).

EXISTS checks whether subquery returns any rows. It ignores NULLs safely because it just checks if an row exists. 
It is usually faster for larger datasets because it only checks for existence.
*/

-- Exercise 10: Write a query that returns for each order the number of days that passed since the same customer’s previous order. 
--				To determine recency among orders, use orderdate as the primary sort element and orderid as the tiebreaker
-- LAG window function solution
SELECT
	custid,
	orderid,
	orderdate,
	LAG(orderdate) OVER(PARTITION BY custid ORDER BY orderdate) AS last_order_date,
	DATEDIFF(day, LAG(orderdate) OVER(PARTITION BY custid ORDER BY orderdate), orderdate) AS diff
FROM Sales.Orders;

-- Subquery Solution
SELECT
	o1.custid,
	o1.orderid,
	o1.orderdate,
	(SELECT MAX(o2.orderdate)
	 FROM Sales.Orders o2
	 WHERE o2.orderid < o1.orderid AND o2.custid = o1.custid
	) AS last_order_date,
	DATEDIFF(
		day, 
		(SELECT MAX(o2.orderdate)
		 FROM Sales.Orders o2
		 WHERE o2.orderid < o1.orderid AND o2.custid = o1.custid),
		 o1.orderdate) AS diff
FROM Sales.Orders o1
ORDER BY o1.custid, o1.orderdate