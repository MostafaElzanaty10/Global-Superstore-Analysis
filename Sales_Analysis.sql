USE [salesproject];
GO


/* 1. Sales & Profit by Year */
SELECT
    YEAR(Order_Date) AS Order_Year,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY YEAR(Order_Date)
ORDER BY Order_Year;


/* 2. Sales & Profit by Month */
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


/* 3. Sales & Profit by Category */
SELECT
    Category,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Category
ORDER BY Total_Sales DESC;


/* 4. Sales & Profit by Sub-Category */
SELECT
    Sub_Category,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Sub_Category
ORDER BY Total_Sales DESC;


/* 5. Sales & Profit by Region */
SELECT
    Region,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Region
ORDER BY Total_Sales DESC;


/* 6. Sales & Profit by Country */
SELECT
    Country,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Country
ORDER BY Total_Sales DESC;


/* 7. Sales & Profit by State */
SELECT
    State,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY State
ORDER BY Total_Sales DESC;


/* 8. Sales & Profit by Segment */
SELECT
    Segment,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Segment
ORDER BY Total_Sales DESC;


/* 9. Sales & Profit by Ship Mode */
SELECT
    Ship_Mode,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Ship_Mode
ORDER BY Total_Sales DESC;


/* 10. Sales & Profit by Discount */
SELECT
    Discount,
    COUNT(*) AS Order_Lines,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) / NULLIF(SUM(Sales), 0) * 100,
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Discount
ORDER BY Discount;


/* 11. Top 10 Products by Sales */
SELECT TOP 10
    Product_Name,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Product_Name
ORDER BY Total_Sales DESC;


/* 12. Top 10 Products by Profit */
SELECT TOP 10
    Product_Name,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Product_Name
ORDER BY Total_Profit DESC;


/* 13. Top 10 Loss-Making Products */
SELECT TOP 10
    Product_Name,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Product_Name
HAVING SUM(Profit) < 0
ORDER BY Total_Profit ASC;


/* 14. Top 10 Customers by Sales */
SELECT TOP 10
    Customer_Name,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Customer_Name
ORDER BY Total_Sales DESC;


/* 15. Top 10 Customers by Profit */
SELECT TOP 10
    Customer_Name,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Customer_Name
ORDER BY Total_Profit DESC;


/* 16. Top 10 Loss-Making Customers */
SELECT TOP 10
    Customer_Name,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY Customer_Name
HAVING SUM(Profit) < 0
ORDER BY Total_Profit ASC;


/* 17. Top 10 States by Profit */
SELECT TOP 10
    State,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY State
ORDER BY Total_Profit DESC;


/* 18. Bottom 10 States by Profit */
SELECT TOP 10
    State,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Orders
GROUP BY State
ORDER BY Total_Profit ASC;


/* 19. Returned Orders */
SELECT
    COUNT(DISTINCT o.Order_ID) AS Returned_Orders
FROM Orders o
INNER JOIN Returns r
    ON o.Order_ID = r.Order_ID;


/* 20. Returned Sales & Profit */
SELECT
    SUM(o.Sales) AS Returned_Sales,
    SUM(o.Profit) AS Returned_Profit
FROM Orders o
INNER JOIN Returns r
    ON o.Order_ID = r.Order_ID;


/* 21. Returned vs Non-Returned Orders */
WITH ReturnedOrders AS (
    SELECT DISTINCT Order_ID
    FROM Returns
)
SELECT
    CASE
        WHEN r.Order_ID IS NOT NULL THEN 'Returned'
        ELSE 'Not Returned'
    END AS Return_Status,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    SUM(o.Sales) AS Total_Sales,
    SUM(o.Profit) AS Total_Profit
FROM Orders o
LEFT JOIN ReturnedOrders r
    ON o.Order_ID = r.Order_ID
GROUP BY
    CASE
        WHEN r.Order_ID IS NOT NULL THEN 'Returned'
        ELSE 'Not Returned'
    END;


/* 22. Return Rate by Region */
WITH TotalOrders AS (
    SELECT
        Region,
        COUNT(DISTINCT Order_ID) AS Total_Orders
    FROM Orders
    GROUP BY Region
),
ReturnedOrders AS (
    SELECT
        o.Region,
        COUNT(DISTINCT r.Order_ID) AS Returned_Orders
    FROM Orders o
    INNER JOIN Returns r
        ON o.Order_ID = r.Order_ID
    GROUP BY o.Region
)
SELECT
    t.Region,
    t.Total_Orders,
    COALESCE(r.Returned_Orders, 0) AS Returned_Orders,
    ROUND(
        COALESCE(r.Returned_Orders, 0) * 100.0
        / NULLIF(t.Total_Orders, 0),
        2
    ) AS Return_Rate_Percent
FROM TotalOrders t
LEFT JOIN ReturnedOrders r
    ON t.Region = r.Region
ORDER BY Return_Rate_Percent DESC;


/* 23. Return Rate by Category */
WITH TotalOrders AS (
    SELECT
        Category,
        COUNT(DISTINCT Order_ID) AS Total_Orders
    FROM Orders
    GROUP BY Category
),
ReturnedOrders AS (
    SELECT
        o.Category,
        COUNT(DISTINCT r.Order_ID) AS Returned_Orders
    FROM Orders o
    INNER JOIN Returns r
        ON o.Order_ID = r.Order_ID
    GROUP BY o.Category
)
SELECT
    t.Category,
    t.Total_Orders,
    COALESCE(r.Returned_Orders, 0) AS Returned_Orders,
    ROUND(
        COALESCE(r.Returned_Orders, 0) * 100.0
        / NULLIF(t.Total_Orders, 0),
        2
    ) AS Return_Rate_Percent
FROM TotalOrders t
LEFT JOIN ReturnedOrders r
    ON t.Category = r.Category
ORDER BY Return_Rate_Percent DESC;

