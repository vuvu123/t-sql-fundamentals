USE TSQLV4;

/*
	Chapter 2 Exercises
*/

-- Exercise 1: Write a query against the Sales.Orders table that returns orders placed in June 2015
SELECT
	orderid,
	orderdate,
	custid,
	empid
FROM Sales.Orders
WHERE orderdate >= '20150601' AND orderdate < '20150701';

-- Exercise 2: Write a query against the Sales.Orders table that returns orders placed on the last day of the month
SELECT
	orderid,
	orderdate,
	custid,
	empid
FROM Sales.Orders
WHERE orderdate = EOMONTH(orderdate);

-- Alternate solution. More complex, but more flexible. Can use it to compute the beginning or end of other parts (day, month, quarter, and year)
SELECT
	orderid,
	orderdate,
	DATEDIFF(month, '18991231', orderdate) DATE_DIFF,
	DATEADD(month, DATEDIFF(month, '18991231', orderdate), '18991231') DATE_ADD_DIFF,
	custid,
	empid
FROM Sales.Orders
WHERE orderdate = DATEADD(month, DATEDIFF(month, '18991231', orderdate), '18991231');

-- Exercise 3: Write a query against the HR.Employees table that returns employees with a last name containing the letter e twice or more
SELECT
	empid,
	firstname,
	lastname
FROM HR.Employees
WHERE LEN(lastname) - LEN(REPLACE(LOWER(lastname), 'e', '')) >= 2;

-- Book solution
SELECT
	empid,
	firstname,
	lastname
FROM HR.Employees
WHERE lastname LIKE '%e%e%';

-- Exercise 4: Write a query against the Sales.OrderDetails table that returns orders with a total value (quantity * unitprice) greater than 10,000, sorted by total value
SELECT
	orderid,
	SUM(qty * unitprice) AS totalvalue
FROM Sales.OrderDetails
GROUP BY orderid
HAVING SUM(qty * unitprice) > 10000
ORDER BY totalvalue DESC;

-- Exercise 5: To check the validity of the data, write a query against the HR.Employees table that returns employees with a last name that starts with a lowercase 
--			   English letter in the range a through z. Remember that the collation of the sample database is case insensitive (Latin1_General_CI_AS):

-- [a-z]% does not work because the Latin1_General_CS_AS collation uses dictionary sort order, i.e. a A b B c C d D ... z Z, so a-z includes all names except for capital Z
-- Fix: explicitly type out all characters abcdefghijklmnopqrstuvwxyz
SELECT
	empid,
	lastname
FROM HR.Employees
WHERE lastname COLLATE Latin1_General_CS_AS LIKE N'[abcdefghijklmnopqrstuvwxyz]%';

/*
Exercise 6: Explain the difference between the following two queries:
	-- Query 1
SELECT empid, COUNT(*) AS numorders
FROM Sales.Orders
WHERE orderdate < '20160501'
GROUP BY empid;

	-- Query 2
SELECT empid, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY empid
HAVING MAX(orderdate) < '20160501';

*/
SELECT empid, COUNT(*) AS numorders
FROM Sales.Orders
WHERE orderdate < '20160501'
GROUP BY empid;
-- The WHERE clause takes place BEFORE the group by empid (Filters for orderdates before May 2016)

SELECT empid, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY empid
HAVING MAX(orderdate) < '20160501';
-- The HAVING clause filter takes place AFTER the employees are grouped by employee ID. Employees that haven't placed an order since May 2016 will not be included in this query result.


-- Exercise 7: Write a query against the Sales.Orders table that returns the three shipped-to countries with the highest average freight in 2015:

SELECT TOP 3
	shipcountry,
	avg(freight) AS avg_freight
FROM Sales.Orders
WHERE orderdate >= '20150101' AND orderdate < '20160101'
GROUP BY shipcountry
ORDER BY avg_freight DESC;

-- Exercise 8: Write a query against the Sales.Orders table that calculates row numbers for orders based on order date ordering (using the order ID as the tiebreaker) 
--				for each customer separately:

SELECT
	custid,
	orderdate,
	orderid,
	ROW_NUMBER() OVER(PARTITION BY custid ORDER BY orderdate, orderid) AS row_num
FROM Sales.Orders;

-- Exercise 9: Using the HR.Employees table, write a SELECT statement that returns for each employee the gender based on the title of courtesy. 
--			   For ‘Ms.’ and ‘Mrs.’ return ‘Female’; for ‘Mr.’ return ‘Male’; and in all other cases (for example, ‘Dr.‘) return ‘Unknown’:

SELECT
	empid,
	firstname + ' ' + lastname AS fullname,
	titleofcourtesy,
	CASE
		WHEN titleofcourtesy IN ('Ms.', 'Mrs.') THEN 'Female'
		WHEN titleofcourtesy = 'Mr.' THEN 'Male'
		ELSE 'Unknown'
	END AS gender
FROM HR.Employees;

-- Exercise 10: Write a query against the Sales.Customers table that returns for each customer the customer ID and region. 
--				Sort the rows in the output by region, having NULLs sort last (after non-NULL values). 
--				Note that the default sort behavior for NULLs in T-SQL is to sort first (before non-NULL values):

SELECT
	custid,
	region
FROM Sales.Customers
ORDER BY 
	CASE WHEN region IS NULL THEN 1 ELSE 0 END,
	region;