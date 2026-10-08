USE [salesproject];
GO

/* SALES ANALYSIS PROJECT
   Data Quality & Exploratory Analysis
   Database: Sales Project  */


/* SECTION 1 — DATASET OVERVIEW */

/* Preview source tables */
SELECT * FROM Returns;
SELECT * FROM People;
SELECT * FROM Orders;


/* Record count for each table */
SELECT COUNT(*) AS Returns_Rows
FROM Returns;

SELECT COUNT(*) AS People_Rows
FROM People;

SELECT COUNT(*) AS Orders_Rows
FROM Orders;


/* SECTION 2 — PEOPLE TABLE CLEANUP */

/* Rename imported columns */
EXEC sp_rename 'People.column1', 'Person', 'COLUMN';
EXEC sp_rename 'People.column2', 'Region', 'COLUMN';

/* Remove the original header row imported as data */
DELETE FROM People
WHERE Person = 'Person';

/* Verify People table */
SELECT *
FROM People;


/* SECTION 3 — ORDERS TABLE STRUCTURE */

/* Review Orders column names and data types */
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Orders';


/* SECTION 4 — DATA QUALITY CHECKS */

/* Check for duplicate Row_ID values */
SELECT
    Row_ID,
    COUNT(*) AS Duplicate_Count
FROM Orders
GROUP BY Row_ID
HAVING COUNT(*) > 1;


/* Check order date range */
SELECT
    MIN(Order_Date) AS First_Order_Date,
    MAX(Order_Date) AS Last_Order_Date
FROM Orders;


/* Check for return records without a matching Order_ID */
SELECT
    COUNT(*) AS Unmatched_Returns
FROM Returns r
LEFT JOIN (
    SELECT DISTINCT Order_ID
    FROM Orders
) o
    ON r.Order_ID = o.Order_ID
WHERE o.Order_ID IS NULL;


/* Check whether any orders were shipped before they were ordered */
SELECT
    COUNT(*) AS Shipped_Before_Ordered
FROM Orders
WHERE Ship_Date < Order_Date;


/* Check important NULL values */
SELECT
    SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) AS Null_Sales,
    SUM(CASE WHEN Profit IS NULL THEN 1 ELSE 0 END) AS Null_Profit,
    SUM(CASE WHEN Postal_Code IS NULL THEN 1 ELSE 0 END) AS Null_Postal_Code
FROM Orders;


/* Check numeric ranges */
SELECT
    MIN(Discount) AS Min_Discount,
    MAX(Discount) AS Max_Discount,
    MIN(Quantity) AS Min_Quantity,
    MAX(Quantity) AS Max_Quantity,
    MIN(Sales) AS Min_Sales,
    MAX(Sales) AS Max_Sales
FROM Orders;


/* SECTION 5 — PRIMARY KEY VALIDATION */

/* Set Row_ID as NOT NULL */
ALTER TABLE Orders
ALTER COLUMN Row_ID INT NOT NULL;
GO

/* Create primary key */
ALTER TABLE Orders
ADD CONSTRAINT PK_Orders PRIMARY KEY (Row_ID);
GO

/* Verify primary key */
SELECT
    KCU.COLUMN_NAME,
    TC.CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU
    ON TC.CONSTRAINT_NAME = KCU.CONSTRAINT_NAME
WHERE TC.TABLE_NAME = 'Orders'
  AND TC.CONSTRAINT_TYPE = 'PRIMARY KEY';


/* SECTION 6 — MISSING PROFIT INVESTIGATION */  

/* Identify records with missing Profit */
SELECT
    Row_ID
FROM Orders
WHERE Profit IS NULL
ORDER BY Row_ID;


/* Inspect missing-Profit records */
SELECT
    Row_ID,
    Sales,
    Quantity,
    Discount,
    Shipping_Cost,
    Profit
FROM Orders
WHERE Profit IS NULL
ORDER BY Row_ID;


/* Diagnostic calculation for missing-Profit records
   Note: Net_Sales here is only a diagnostic calculation
   and is NOT treated as the official Profit value. */
SELECT
    Row_ID,
    Sales,
    Quantity,
    Discount,
    Shipping_Cost,
    Profit,
    Sales - (Sales * Discount) AS Diagnostic_Net_Sales
FROM Orders
WHERE Profit IS NULL
ORDER BY Row_ID;


/* Final review of missing-Profit records */
SELECT
    Row_ID,
    Sales,
    Quantity,
    Discount,
    Shipping_Cost,
    Profit
FROM Orders
WHERE Profit IS NULL
ORDER BY Row_ID;


/* SECTION 7 — CORE KPIs */

/* Overall business KPIs */
SELECT
    COUNT(*) AS Total_Order_Lines,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    AVG(Sales) AS Average_Order_Line_Value,
    SUM(Quantity) AS Total_Quantity
FROM Orders;


/* Average Order Value based on unique Order_ID */
SELECT
    SUM(Sales) /
    NULLIF(COUNT(DISTINCT Order_ID), 0) AS Average_Order_Value
FROM Orders;


/* SECTION 8 — SALES & PROFIT ANALYSIS */

/* Sales & Profit by Year */
SELECT
    YEAR(Order_Date) AS Order_Year,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY YEAR(Order_Date)
ORDER BY Order_Year;


/* Sales & Profit by Category */
SELECT
    Category,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Category
ORDER BY Total_Sales DESC;


/* Sales & Profit by Region */
SELECT
    Region,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Region
ORDER BY Total_Sales DESC;


/* Sales & Profit by Country */
SELECT
    Country,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Country
ORDER BY Total_Sales DESC;


/* Sales & Profit by State */
SELECT
    State,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY State
ORDER BY Total_Sales DESC;


/* SECTION 9 — PRODUCT ANALYSIS*/

/* Top 10 Products by Sales */
SELECT TOP 10
    Product_Name,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Product_Name
ORDER BY Total_Sales DESC;


/* Top 10 Most Profitable Products */
SELECT TOP 10
    Product_Name,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Product_Name
ORDER BY Total_Profit DESC;


/* Top 10 Loss-Making Products */
SELECT TOP 10
    Product_Name,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Product_Name
HAVING SUM(Profit) < 0
ORDER BY Total_Profit ASC;


/* Sales & Profit by Sub-Category */
SELECT
    Sub_Category,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) /
        NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Sub_Category
ORDER BY Total_Sales DESC;


/* SECTION 10 — CUSTOMER ANALYSIS */

/* Top 10 Customers by Sales */
SELECT TOP 10
    Customer_Name,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Customer_Name
ORDER BY Total_Sales DESC;


/* Top 10 Most Profitable Customers */
SELECT TOP 10
    Customer_Name,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Customer_Name
ORDER BY Total_Profit DESC;


/* Top 10 Loss-Making Customers */
SELECT TOP 10
    Customer_Name,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Customer_Name
HAVING SUM(Profit) < 0
ORDER BY Total_Profit ASC;


/* SECTION 11 — PROFITABILITY ANALYSIS */

/* Profit Margin by Category */
SELECT
    Category,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) /
        NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Category
ORDER BY Profit_Margin_Percent DESC;


/* Profit Margin by Region */
SELECT
    Region,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) /
        NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Region
ORDER BY Profit_Margin_Percent DESC;


/* Profitability by Segment */
SELECT
    Segment,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) /
        NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Segment
ORDER BY Total_Sales DESC;


/* SECTION 12 — ORDER & SHIPPING ANALYSIS */

/* Sales & Profit by Ship Mode */
SELECT
    Ship_Mode,
    COUNT(*) AS Total_Order_Lines,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Ship_Mode
ORDER BY Total_Sales DESC;


/* SECTION 13 — TIME-BASED ANALYSIS */

/* Monthly Sales & Profit */
SELECT
    YEAR(Order_Date) AS Order_Year,
    MONTH(Order_Date) AS Order_Month,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY
    YEAR(Order_Date),
    MONTH(Order_Date)
ORDER BY
    Order_Year,
    Order_Month;


/* SECTION 14 — DISCOUNT ANALYSIS */

/* Discount vs Sales & Profit */
SELECT
    Discount,
    COUNT(*) AS Total_Order_Lines,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Discount
ORDER BY Discount;


/* SECTION 15 — RETURNS ANALYSIS */

/* Total Returned Orders */
SELECT
    COUNT(DISTINCT o.Order_ID) AS Returned_Orders
FROM Orders o
INNER JOIN Returns r
    ON o.Order_ID = r.Order_ID;


/* Sales & Profit from Returned Orders */
SELECT
    SUM(o.Sales) AS Returned_Sales,
    SUM(o.Profit) AS Returned_Profit
FROM Orders o
INNER JOIN Returns r
    ON o.Order_ID = r.Order_ID;


/* Returned vs Non-Returned Orders */
SELECT
    CASE
        WHEN r.Order_ID IS NOT NULL THEN 'Returned'
        ELSE 'Not Returned'
    END AS Return_Status,
    COUNT(DISTINCT o.Order_ID) AS Orders_Count,
    SUM(o.Sales) AS Total_Sales,
    SUM(o.Profit) AS Total_Profit
FROM Orders o
LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID
GROUP BY
    CASE
        WHEN r.Order_ID IS NOT NULL THEN 'Returned'
        ELSE 'Not Returned'
    END;

   /*SECTION 16 — STATE PERFORMANCE*/


/* Top 10 States by Profit */
SELECT TOP 10
    State,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY State
ORDER BY Total_Profit DESC;


/* Bottom 10 States by Profit */
SELECT TOP 10
    State,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY State
ORDER BY Total_Profit ASC;


