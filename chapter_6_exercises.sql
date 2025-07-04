USE TSQLV4;

-- ==============
-- SET OPERATORS
-- ==============

/* 
	Exercise 1:
	Explain the difference between the UNION ALL and UNION operators. In what cases are the two equivalent? When they are equivalent, which one should you use?

	UNION appends rows from both table results, stacks them on top of another and removes duplicates.
	UNION all does the same, but doesn't remove duplicates.
	If the result set using UNION and UNION ALL are the same, you should use UNION ALL because it has better performance.

	Book Explanation:
	The UNION ALL operator unifies the two input query result sets and doesn’t remove duplicates from the result. 
	The UNION operator (implied DISTINCT) also unifies the two input query result sets, but it does remove duplicates from the result. 
	The two have different meanings when the result can potentially have duplicates. 
	They have an equivalent meaning when the result can’t have duplicates, such as when you’re unifying disjoint sets (for example, sales 2015 with sales 2016). 
	When they do have the same meaning, you need to use UNION ALL by default. 
	That’s to avoid paying unnecessary performance penalties for the work involved in removing duplicates when they don’t exist.
*/

-- Exercise 2: Write a query that generates a virtual auxiliary table of 10 numbers in the range 1 through 10 without using a looping construct. 
--			   You do not need to guarantee any order of the rows in the output of your solution:
SELECT 1 AS n
UNION ALL
SELECT 2
UNION ALL
SELECT 3
UNION ALL
SELECT 4
UNION ALL
SELECT 5
UNION ALL
SELECT 6
UNION ALL
SELECT 7
UNION ALL
SELECT 8
UNION ALL
SELECT 9
UNION ALL
SELECT 10;

-- Alternate Solution
SELECT n
FROM (VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) AS Nums(n);

-- Exercise 3: Write a query that returns customer and employee pairs that had order activity in January 2016 but not in February 2016
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160101' AND orderdate < '20160201'

EXCEPT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160201' AND orderdate < '20160301'

-- Exercise 4: Write a query that returns customer and employee pairs that had order activity in both January 2016 and February 2016
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160101' AND orderdate < '20160201'

INTERSECT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160201' AND orderdate < '20160301'

-- Exercise 5: Write a query that returns customer and employee pairs that had order activity in both January 2016 and February 2016 but not in 2015
SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160101' AND orderdate < '20160201'

INTERSECT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20160201' AND orderdate < '20160301'

EXCEPT

SELECT custid, empid
FROM Sales.Orders
WHERE orderdate >= '20150101' AND orderdate < '20160101'

/*

You are given the following query: 

SELECT country, region, city
FROM HR.Employees

UNION ALL

SELECT country, region, city
FROM Production.Suppliers; 

You are asked to add logic to the query so that it guarantees that the rows from Employees are returned in the output before the rows from Suppliers. 
Also, within each segment, the rows should be sorted by country, region, and city

*/

WITH UNION_ALL AS (
	SELECT 
	1 AS source,
	country, region, city
	FROM HR.Employees

	UNION ALL

	SELECT
	2 AS source,
	country, region, city
	FROM Production.Suppliers
)

SELECT
	country,
	region,
	city
FROM UNION_ALL
ORDER BY source, country, region, city;