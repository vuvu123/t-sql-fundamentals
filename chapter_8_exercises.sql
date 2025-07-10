USE TSQLV4;

DROP TABLE IF EXISTS dbo.Customers;
CREATE TABLE dbo.Customers
(
	custid      INT          NOT NULL PRIMARY KEY,
	companyname NVARCHAR(40) NOT NULL,
	country     NVARCHAR(15) NOT NULL,
	region      NVARCHAR(15) NULL,
	city        NVARCHAR(15) NOT NULL
);

/*
	Exercise 1-1: Insert into the dbo.Customers table a row with the following information:  
			-custid: 100  
			-companyname: Coho Winery  
			-country: USA  
			-region: WA  
			-city: Redmond
*/
INSERT INTO dbo.Customers(custid, companyname, country, region, city)
OUTPUT
  inserted.custid,
  inserted.companyname,
  inserted.country,
  inserted.region,
  inserted.city
VALUES(100, N'Coho Winery', N'USA', N'WA', N'Redmond');

SELECT *
FROM dbo.Customers;

-- Exercise 1-2: Insert into the dbo.Customers table all customers from Sales.Customers who placed orders.
INSERT dbo.Customers(custid, companyname, country, region, city)
OUTPUT
  inserted.custid,
  inserted.companyname,
  inserted.country,
  inserted.region,
  inserted.city
SELECT DISTINCT c.custid, c.companyname, c.country, c.region, c.city
FROM Sales.Customers c
INNER JOIN Sales.Orders o ON c.custid = o.custid;

-- Alternate Solution: Using the EXISTS predicate in the WHERE clause (Recommended Standard SQL Solution)
INSERT dbo.Customers(custid, companyname, country, region, city)
OUTPUT
  inserted.custid,
  inserted.companyname,
  inserted.country,
  inserted.region,
  inserted.city
SELECT custid, companyname, country, region, city
FROM Sales.Customers c
WHERE EXISTS
	(SELECT * FROM Sales.Orders o
	WHERE c.custid = o.custid);

-- Exercise 1-3: Use a SELECT INTO statement to create and populate the dbo.Orders table with orders from the Sales.Orders table that were placed in the years 2014 through 2016
DROP TABLE IF EXISTS dbo.Orders;
CREATE TABLE dbo.Orders(
	orderid INT	NOT NULL,
	custid INT	NOT NULL,
	empid INT	NOT NULL,
	orderdate DATE,
	requireddate DATE,
	shippeddate DATE,
	shipperid INT,
	freight DECIMAL(10,2),
	shipname NVARCHAR(25),
	shipaddress NVARCHAR(50),
	shipcity NVARCHAR(20),
	shipregion NVARCHAR(10),
	shippostalcode INT,
	shipcountry NVARCHAR(25)
)

SELECT *
INTO dbo.Orders
FROM Sales.Orders
WHERE orderdate >= '20140101' AND orderdate < '20170101';

SELECT *
FROM dbo.Orders;

-- Exercise 2: Delete from the dbo.Orders table orders that were placed before August 2014. Use the OUTPUT clause to return the orderid and orderdate values of the deleted orders
DELETE FROM dbo.Orders
OUTPUT
  deleted.orderid,
  deleted.orderdate
WHERE orderdate < '20140801';

-- Exercise 3: Delete from the dbo.Orders table orders placed by customers from Brazil.
DELETE FROM o
OUTPUT
  deleted.orderid,
  deleted.shipcountry
FROM dbo.Orders o
INNER JOIN dbo.Customers c ON o.custid = c.custid
WHERE c.country = N'Brazil';

-- Alternate Solution: Using the EXISTS predicate in the WHERE clause (Recommended Standard SQL Solution)
DELETE FROM dbo.Orders
OUTPUT
  deleted.orderid,
  deleted.shipcountry
WHERE EXISTS
	(SELECT * FROM dbo.Customers c 
	WHERE Orders.custid = c.custid AND c.country = N'Brazil');


-- Exercise 4: Update the dbo.Customers table, and change all NULL region values to <None>. Use the OUTPUT clause to show the custid, oldregion, and newregion
UPDATE dbo.Customers
SET region = '<None>'
OUTPUT
  inserted.custid,
  deleted.region AS oldregion,
  inserted.region AS newregion
WHERE region IS NULL;

-- Exercise 5: Update all orders in the dbo.Orders table that were placed by United Kingdom customers, and set their shipcountry, shipregion, 
--				and shipcity values to the country, region, and city values of the corresponding customers.
UPDATE o
SET o.shipcountry = c.country, 
	o.shipregion = c.region, 
	o.shipcity = c.city
OUTPUT
  inserted.orderid,
  inserted.custid,
  inserted.orderdate,
  deleted.shipcountry AS oldshipcountry,
  deleted.shipregion AS oldshipregion,
  deleted.shipcity AS oldshipcity,
  inserted.shipcountry AS newshipcountry,
  inserted.shipregion AS newshipregion,
  inserted.shipcity AS newshipcity
FROM dbo.Orders o
INNER JOIN dbo.Customers c ON o.custid = c.custid
WHERE shipcountry = N'UK';

-- CTE Update Alternative
WITH CTE_UPD AS
(
  SELECT
  O.shipcountry AS ocountry, 
  C.country AS ccountry,
  O.shipregion AS oregion,  
  C.region AS cregion,
  O.shipcity AS ocity,   
  C.city AS ccity
  FROM dbo.Orders AS O
    INNER JOIN dbo.Customers AS C
      ON O.custid = C.custid
  WHERE C.country = N'UK'
)
UPDATE CTE_UPD
SET ocountry = ccountry, oregion = cregion, ocity = ccity;

-- Merge Update Alternative
MERGE INTO dbo.Orders AS O
USING (SELECT * FROM dbo.Customers WHERE country = N'UK') AS C
  ON O.custid = C.custid
WHEN MATCHED THEN
  UPDATE SET shipcountry = C.country,
             shipregion = C.region,
             shipcity = C.city;

-- Exercise 6: Write and test the T-SQL code that is required to truncate both tables, and make sure your code runs successfully.

-- Create tables and insert data from Sales.Orders and Sales.OrderDetails
USE TSQLV4;

DROP TABLE IF EXISTS dbo.OrderDetails, dbo.Orders;
CREATE TABLE dbo.Orders
(
  orderid        INT          NOT NULL,
  custid         INT          NULL,
  empid          INT          NOT NULL,
  orderdate      DATE         NOT NULL,
  requireddate   DATE         NOT NULL,
  shippeddate    DATE         NULL,
  shipperid      INT          NOT NULL,
  freight        MONEY        NOT NULL
    CONSTRAINT DFT_Orders_freight DEFAULT(0),
  shipname       NVARCHAR(40) NOT NULL,
  shipaddress    NVARCHAR(60) NOT NULL,
  shipcity       NVARCHAR(15) NOT NULL,
  shipregion     NVARCHAR(15) NULL,
  shippostalcode NVARCHAR(10) NULL,
  shipcountry    NVARCHAR(15) NOT NULL,
  CONSTRAINT PK_Orders PRIMARY KEY(orderid)
);

CREATE TABLE dbo.OrderDetails
(
  orderid   INT           NOT NULL,
  productid INT           NOT NULL,
  unitprice MONEY         NOT NULL
  CONSTRAINT DFT_OrderDetails_unitprice DEFAULT(0),
  qty       SMALLINT      NOT NULL
    CONSTRAINT DFT_OrderDetails_qty DEFAULT(1),
  discount  NUMERIC(4, 3) NOT NULL
    CONSTRAINT DFT_OrderDetails_discount DEFAULT(0),
  CONSTRAINT PK_OrderDetails PRIMARY KEY(orderid, productid),
  CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY(orderid)
    REFERENCES dbo.Orders(orderid),
  CONSTRAINT CHK_discount  CHECK (discount BETWEEN 0 AND 1),
  CONSTRAINT CHK_qty  CHECK (qty > 0),
  CONSTRAINT CHK_unitprice CHECK (unitprice >= 0)
);
GO

INSERT INTO dbo.Orders SELECT * FROM Sales.Orders;
INSERT INTO dbo.OrderDetails SELECT * FROM Sales.OrderDetails;

-- Drop all foreign key constraints referencing the table BEFORE truncating the tables
ALTER TABLE dbo.OrderDetails DROP CONSTRAINT FK_OrderDetails_Orders;

TRUNCATE TABLE dbo.Orders
TRUNCATE TABLE dbo.OrderDetails;

SELECT * FROM dbo.Orders;
SELECT * FROM dbo.OrderDetails;

-- Re-add foreign key constraints referencing the dbo.Orders table
ALTER TABLE dbo.OrderDetails 
ADD CONSTRAINT FK_OrderDetails_Orders 
FOREIGN KEY(orderid) REFERENCES dbo.Orders(orderid);

-- Clean Up
DROP TABLE IF EXISTS dbo.OrderDetails, dbo.Orders, dbo.Customers;

