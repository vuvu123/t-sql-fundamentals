USE TSQLV4;

/* 
Exercise 1:

The following query attempts to filter orders that were not placed on the last day of the year. 
It’s supposed to return the order ID, order date, customer ID, employee ID, and respective end-of-year date for each order:

SELECT orderid, orderdate, custid, empid,
  DATEFROMPARTS(YEAR(orderdate), 12, 31) AS endofyear
FROM Sales.Orders
WHERE orderdate <> endofyear;

When you try to run this query, you get the following error: 
Msg 207, Level 16, State 1, Line 233

Explain what the problem is, and suggest a valid solution.

SQL has a query execution order of FROM, WHERE, GROUP BY, HAVING, SELECT, ORDER BY. At the time of execution of the WHERE clause,
the endofyear column and alias have not been established yet, therefore we get an error with invalid column name.
The simplest fix is to paste the DATEFROMPARTS(YEAR(orderdate), 12, 31) where endofyear is in the WHERE clause.

Working Solution:
SELECT orderid, orderdate, custid, empid,
  DATEFROMPARTS(YEAR(orderdate), 12, 31) AS endofyear
FROM Sales.Orders
WHERE orderdate <> DATEFROMPARTS(YEAR(orderdate), 12, 31);
*/

SELECT orderid, orderdate, custid, empid,
  DATEFROMPARTS(YEAR(orderdate), 12, 31) AS endofyear
FROM Sales.Orders
WHERE orderdate <> DATEFROMPARTS(YEAR(orderdate), 12, 31);

-- Exercise 2-1: Write a query that returns the maximum value in the orderdate column for each employee
SELECT
	empid,
	MAX(orderdate) AS maxorderdate
FROM Sales.Orders
GROUP BY empid;

-- Exercise 2-2: Encapsulate the query from Exercise 2-1 in a derived table. 
--				 Write a join query between the derived table and the Orders table to return the orders with the maximum order date for each employee:
SELECT
	o.empid,
	o.orderdate,
	o.orderid,
	o.custid
FROM Sales.Orders o
INNER JOIN (
	SELECT
		empid,
		MAX(orderdate) AS maxorderdate
	FROM Sales.Orders
	GROUP BY empid
) AS m ON o.empid = m.empid AND o.orderdate = m.maxorderdate;

-- Exercise 3-1: Write a query that calculates a row number for each order based on orderdate, orderid ordering
-- Window function solution
SELECT
	orderid,
	orderdate,
	custid,
	empid,
	ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rownum
FROM Sales.Orders;

-- Exercise 3-2: Write a query that returns rows with row numbers 11 through 20 based on the row-number definition in Exercise 3-1. 
--				 Use a CTE to encapsulate the code from Exercise 3-1
WITH orders AS (
	SELECT
		orderid,
		orderdate,
		custid,
		empid,
		ROW_NUMBER() OVER(ORDER BY orderdate, orderid) AS rownum
	FROM Sales.Orders
)

SELECT
	orderid,
	orderdate,
	custid,
	empid,
	rownum
FROM orders
WHERE rownum BETWEEN 11 AND 20;

-- Exercise 4: Write a solution using a recursive CTE that returns the management chain leading to Patricia Doyle (employee ID 9)
WITH emp_hierarchy AS (
	-- Anchor member
	SELECT empid, mgrid, firstname, lastname
	FROM HR.Employees
	WHERE empid = 9

	UNION ALL

	--Recursive member
	SELECT e.empid, e.mgrid, e.firstname, e.lastname
	FROM emp_hierarchy h
	INNER JOIN HR.Employees e
	ON h.mgrid = e.empid
)

SELECT empid, mgrid, firstname, lastname
FROM emp_hierarchy;

-- Exercise 5-1: Create a view that returns the total quantity for each employee and year
GO

CREATE VIEW Sales.VEmpOrders AS
SELECT
	o.empid,
	YEAR(o.orderdate) AS orderyear,
	SUM(od.qty) AS qty
FROM Sales.Orders o
LEFT JOIN Sales.OrderDetails od ON o.orderid = od.orderid
GROUP BY o.empid, YEAR(o.orderdate);

SELECT * FROM Sales.VEmpOrders ORDER BY empid, orderyear;

-- Exercise 5-2: Write a query against Sales.VEmpOrders that returns the running total quantity for each employee and year
SELECT
	empid,
	orderyear,
	qty,
	SUM(qty) OVER(PARTITION BY empid ORDER BY orderyear) AS runqty
FROM Sales.VEmpOrders 
ORDER BY empid, orderyear;

-- Exercise 6-1: Create an inline TVF that accepts as inputs a supplier ID (@supid AS INT) and a requested number of products (@n AS INT). 
--				 The function should return @n products with the highest unit prices that are supplied by the specified supplier ID:
USE TSQLV4;
DROP FUNCTION IF EXISTS Production.TopProducts;
GO
CREATE FUNCTION Production.TopProducts
(@supid AS INT, @n AS INT) 
RETURNS TABLE
AS
RETURN
	SELECT TOP (@n) productid, productname, unitprice
	FROM Production.Products
	WHERE supplierid = @supid
	ORDER BY unitprice DESC;
GO

SELECT * FROM Production.TopProducts(5, 2);

-- Exercise 6-2: Using the CROSS APPLY operator and the function you created in Exercise 6-1, return the two most expensive products for each supplier
SELECT
	s.supplierid,
	s.companyname,
	p.productid,
	p.productname,
	p.unitprice
FROM Production.Suppliers s
CROSS APPLY Production.TopProducts(s.supplierid, 2) AS p;