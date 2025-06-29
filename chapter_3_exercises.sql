USE TSQLV4;

/*
	Chapter 3 Exercises
*/

-- Exercise 1-1: Write a query that generates five copies of each employee row
SELECT
	e.empid,
	e.firstname,
	e.lastname,
	n.n
FROM HR.Employees e
CROSS JOIN dbo.Nums n
WHERE n <= 5

-- Exercise 1-2: Write a query that returns a row for each employee and day in the range June 12, 2016 through June 16, 2016
WITH DateSequence AS (
    SELECT CAST('2016-06-12' AS DATE) AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateSequence
    WHERE DateValue < '2016-06-16'
)

SELECT
	e.empid,
	d.DateValue
FROM HR.Employees e
CROSS JOIN DateSequence d
ORDER BY e.empid

/* Exercise 2: Explain what’s wrong in the following query, and provide a correct alternative

SELECT Customers.custid, Customers.companyname, Orders.orderid, Orders.orderdate
FROM Sales.Customers AS C
  INNER JOIN Sales.Orders AS O
    ON Customers.custid = Orders.custid;

Either remove the table alias and use the long form table names or use the aliases
*/
SELECT c.custid, c.companyname, o.orderid, o.orderdate
FROM Sales.Customers AS c
  INNER JOIN Sales.Orders AS o
    ON c.custid = o.custid;

-- Exercise 3: Return US customers, and for each customer return the total number of orders and total quantities:
SELECT
	o.custid,
	COUNT(DISTINCT o.orderid) AS numorders,
	SUM(d.qty) AS totalqty
FROM Sales.Orders o
LEFT JOIN Sales.Customers c ON o.custid = c.custid
LEFT JOIN Sales.OrderDetails d ON o.orderid = d.orderid
WHERE c.country = 'USA'
GROUP BY o.custid
ORDER BY o.custid

-- Exercise 4: Return customers and their orders, including customers who placed no orders
SELECT
	c.custid,
	c.companyname,
	o.orderid,
	o.orderdate
FROM Sales.Customers c
LEFT JOIN Sales.Orders o ON c.custid = o.custid
ORDER BY c.custid, orderdate

-- Exercise 5: Return customers with orders placed on February 12, 2016, along with their orders
SELECT
	c.custid,
	c.companyname
FROM Sales.Customers c
LEFT JOIN Sales.Orders o ON c.custid = o.custid
WHERE o.orderdate IS NULL;

-- Exercise 6: Return customers with orders placed on February 12, 2016, along with their orders:
SELECT 
	c.custid,
	o.orderdate
FROM Sales.Orders o
LEFT JOIN Sales.Customers c ON o.custid = c.custid
WHERE o.orderdate = '2016-02-12'

-- Exercise 7: Write a query that returns all customers in the output, but matches them with their respective orders only if they were placed on February 12, 2016
WITH feb_12_2016_orders AS (
	SELECT
		c.custid, 
		o.orderid, 
		o.orderdate
	FROM Sales.Customers c
	LEFT JOIN Sales.Orders o ON c.custid = o.custid
	WHERE o.orderdate = '20160212'
)

SELECT
	c.custid,
	c.companyname,
	o.orderid,
	o.orderdate
FROM Sales.Customers c
LEFT JOIN feb_12_2016_orders o ON c.custid = o.custid
ORDER BY c.companyname

-- More efficient solution - better than my original solution
-- Read the book section about nonfinal matchin predicates
SELECT
	c.custid,
	c.companyname,
	o.orderid,
	o.orderdate
FROM Sales.Customers c
LEFT JOIN Sales.Orders o ON c.custid = o.custid AND o.orderdate = '20160212'
ORDER BY c.companyname

/* Exercise 8: Explain why the following query isn’t a correct solution query for Exercise 7

SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  	LEFT OUTER JOIN Sales.Orders AS O
    ON O.custid = C.custid
WHERE O.orderdate = '20160212'
   	OR O.orderid IS NULL;

*/
SELECT C.custid, C.companyname, O.orderid, O.orderdate
FROM Sales.Customers AS C
  	LEFT OUTER JOIN Sales.Orders AS O
    ON O.custid = C.custid
WHERE O.orderdate = '20160212'
   	OR O.orderid IS NULL;

-- It's incorrect because it doesn't return all the customers in the output. It starts from the Customers table and only returns the customers with the orderdate '20160212' (3 customers).
-- With the OR logical operator and O.orderid IS NULL predicate, it appends the customers that haven't placed an order (not found in the Sales.Orders table)


-- Exercise 9: Return all customers, and for each return a Yes/No value depending on whether the customer placed orders on February 12, 2016
WITH feb_12_2016_orders AS (
	SELECT
		c.custid, 
		o.orderid, 
		o.orderdate
	FROM Sales.Customers c
	LEFT JOIN Sales.Orders o ON c.custid = o.custid
	WHERE o.orderdate = '20160212'
)

SELECT
	c.custid,
	c.companyname,
	CASE 
		WHEN o.orderid IS NULL THEN 'No'
		ELSE 'Yes'
	END AS HasOrderOn20160212
FROM Sales.Customers c
LEFT JOIN feb_12_2016_orders o ON c.custid = o.custid
ORDER BY c.custid