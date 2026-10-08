USE [salesproject]
go


/* 1. Year-over-Year Sales & Profit Growth */
WITH Yearly AS (
    SELECT
        YEAR(Order_Date) AS Order_Year,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY YEAR(Order_Date)
)
SELECT
    Order_Year,
    Total_Sales,
    Total_Profit,
    LAG(Total_Sales) OVER (ORDER BY Order_Year) AS Previous_Year_Sales,
    ROUND(
        (Total_Sales - LAG(Total_Sales) OVER (ORDER BY Order_Year))
        * 100.0 /
        NULLIF(LAG(Total_Sales) OVER (ORDER BY Order_Year), 0),
        2
    ) AS Sales_Growth_Percent,
    ROUND(
        (Total_Profit - LAG(Total_Profit) OVER (ORDER BY Order_Year))
        * 100.0 /
        NULLIF(LAG(Total_Profit) OVER (ORDER BY Order_Year), 0),
        2
    ) AS Profit_Growth_Percent
FROM Yearly
ORDER BY Order_Year;


/* 2. Monthly Sales & Profit with Running Total */
WITH Monthly AS (
    SELECT
        YEAR(Order_Date) AS Order_Year,
        MONTH(Order_Date) AS Order_Month,
        SUM(Sales) AS Monthly_Sales,
        SUM(Profit) AS Monthly_Profit
    FROM Orders
    GROUP BY
        YEAR(Order_Date),
        MONTH(Order_Date)
)
SELECT
    Order_Year,
    Order_Month,
    Monthly_Sales,
    Monthly_Profit,
    SUM(Monthly_Sales) OVER (
        ORDER BY Order_Year, Order_Month
    ) AS Running_Sales,
    SUM(Monthly_Profit) OVER (
        ORDER BY Order_Year, Order_Month
    ) AS Running_Profit
FROM Monthly
ORDER BY Order_Year, Order_Month;


/* 3. Category Contribution to Total Sales */
SELECT
    Category,
    SUM(Sales) AS Total_Sales,
    ROUND(
        SUM(Sales) * 100.0 /
        SUM(SUM(Sales)) OVER (),
        2
    ) AS Sales_Contribution_Percent
FROM Orders
GROUP BY Category
ORDER BY Total_Sales DESC;


/* 4. Rank Products by Sales */
WITH ProductSales AS (
    SELECT
        Product_Name,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY Product_Name
)
SELECT
    Product_Name,
    Total_Sales,
    Total_Profit,
    RANK() OVER (ORDER BY Total_Sales DESC) AS Sales_Rank,
    RANK() OVER (ORDER BY Total_Profit DESC) AS Profit_Rank
FROM ProductSales
ORDER BY Sales_Rank;


/* 5. Rank Customers by Sales */
WITH CustomerSales AS (
    SELECT
        Customer_Name,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY Customer_Name
)
SELECT
    Customer_Name,
    Total_Sales,
    Total_Profit,
    RANK() OVER (ORDER BY Total_Sales DESC) AS Sales_Rank,
    RANK() OVER (ORDER BY Total_Profit DESC) AS Profit_Rank
FROM CustomerSales
ORDER BY Sales_Rank;


/* 6. Top 10 Products in Each Category */
WITH ProductRank AS (
    SELECT
        Category,
        Product_Name,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit,
        ROW_NUMBER() OVER (
            PARTITION BY Category
            ORDER BY SUM(Sales) DESC
        ) AS Product_Rank
    FROM Orders
    GROUP BY
        Category,
        Product_Name
)
SELECT
    Category,
    Product_Name,
    Total_Sales,
    Total_Profit,
    Product_Rank
FROM ProductRank
WHERE Product_Rank <= 10
ORDER BY Category, Product_Rank;


/* 7. Most Profitable Products by Category */
WITH ProductProfit AS (
    SELECT
        Category,
        Product_Name,
        SUM(Profit) AS Total_Profit,
        ROW_NUMBER() OVER (
            PARTITION BY Category
            ORDER BY SUM(Profit) DESC
        ) AS Profit_Rank
    FROM Orders
    GROUP BY
        Category,
        Product_Name
)
SELECT
    Category,
    Product_Name,
    Total_Profit,
    Profit_Rank
FROM ProductProfit
WHERE Profit_Rank <= 5
ORDER BY Category, Profit_Rank;


/* 8. Loss-Making Products */
SELECT
    Product_Name,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) * 100.0 /
        NULLIF(SUM(Sales), 0),
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Product_Name
HAVING SUM(Profit) < 0
ORDER BY Total_Profit;


/* 9. Discount vs Profit */
SELECT
    Discount,
    COUNT(*) AS Order_Lines,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) * 100.0 /
        NULLIF(SUM(Sales), 0),
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Discount
ORDER BY Discount;


/* 10. Return Rate by Region */
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
        COALESCE(r.Returned_Orders, 0) * 100.0 /
        NULLIF(t.Total_Orders, 0),
        2
    ) AS Return_Rate_Percent
FROM TotalOrders t
LEFT JOIN ReturnedOrders r
    ON t.Region = r.Region
ORDER BY Return_Rate_Percent DESC;


/* 11. Return Rate by Category */
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
        COALESCE(r.Returned_Orders, 0) * 100.0 /
        NULLIF(t.Total_Orders, 0),
        2
    ) AS Return_Rate_Percent
FROM TotalOrders t
LEFT JOIN ReturnedOrders r
    ON t.Category = r.Category
ORDER BY Return_Rate_Percent DESC;


/* 12. Customer Lifetime Value */
SELECT
    Customer_Name,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Sales) /
        NULLIF(COUNT(DISTINCT Order_ID), 0),
        2
    ) AS Avg_Order_Value
FROM Orders
GROUP BY Customer_Name
ORDER BY Total_Sales DESC;


/* 13. Customer Segmentation */
WITH CustomerStats AS (
    SELECT
        Customer_Name,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY Customer_Name
)
SELECT
    Customer_Name,
    Total_Sales,
    Total_Profit,
    CASE
        WHEN Total_Sales >= 10000 AND Total_Profit > 2000
            THEN 'High Value'
        WHEN Total_Sales >= 5000
            THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Customer_Segment
FROM CustomerStats
ORDER BY Total_Sales DESC;


/* 14. State Performance Ranking */
WITH StatePerformance AS (
    SELECT
        State,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY State
)
SELECT
    State,
    Total_Sales,
    Total_Profit,
    RANK() OVER (ORDER BY Total_Sales DESC) AS Sales_Rank,
    RANK() OVER (ORDER BY Total_Profit DESC) AS Profit_Rank
FROM StatePerformance
ORDER BY Profit_Rank;


/* 15. Best & Worst States */
WITH StatePerformance AS (
    SELECT
        State,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY State
),
Ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY Total_Profit DESC) AS Best_Rank,
        ROW_NUMBER() OVER (ORDER BY Total_Profit ASC) AS Worst_Rank
    FROM StatePerformance
)
SELECT
    State,
    Total_Sales,
    Total_Profit,
    CASE
        WHEN Best_Rank <= 10 THEN 'Top 10'
        WHEN Worst_Rank <= 10 THEN 'Bottom 10'
    END AS Performance_Group
FROM Ranked
WHERE Best_Rank <= 10
   OR Worst_Rank <= 10
ORDER BY Total_Profit DESC;


/* 16. Year + Category Performance */
SELECT
    YEAR(Order_Date) AS Order_Year,
    Category,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) * 100.0 /
        NULLIF(SUM(Sales), 0),
        2
    ) AS Profit_Margin_Percent,
    RANK() OVER (
        PARTITION BY YEAR(Order_Date)
        ORDER BY SUM(Sales) DESC
    ) AS Category_Rank
FROM Orders
GROUP BY
    YEAR(Order_Date),
    Category
ORDER BY
    Order_Year,
    Category_Rank;


/* 17. Best Category Each Year */
WITH CategoryYear AS (
    SELECT
        YEAR(Order_Date) AS Order_Year,
        Category,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit,
        ROW_NUMBER() OVER (
            PARTITION BY YEAR(Order_Date)
            ORDER BY SUM(Sales) DESC
        ) AS Category_Rank
    FROM Orders
    GROUP BY
        YEAR(Order_Date),
        Category
)
SELECT
    Order_Year,
    Category,
    Total_Sales,
    Total_Profit
FROM CategoryYear
WHERE Category_Rank = 1
ORDER BY Order_Year;


/* 18. Monthly Growth */
WITH Monthly AS (
    SELECT
        YEAR(Order_Date) AS Order_Year,
        MONTH(Order_Date) AS Order_Month,
        SUM(Sales) AS Total_Sales
    FROM Orders
    GROUP BY
        YEAR(Order_Date),
        MONTH(Order_Date)
)
SELECT
    Order_Year,
    Order_Month,
    Total_Sales,
    LAG(Total_Sales) OVER (
        ORDER BY Order_Year, Order_Month
    ) AS Previous_Month_Sales,
    ROUND(
        (Total_Sales - LAG(Total_Sales) OVER (
            ORDER BY Order_Year, Order_Month
        )) * 100.0 /
        NULLIF(
            LAG(Total_Sales) OVER (
                ORDER BY Order_Year, Order_Month
            ), 0
        ),
        2
    ) AS Monthly_Growth_Percent
FROM Monthly
ORDER BY Order_Year, Order_Month;


/* 19. Profit Margin by Customer */
SELECT
    Customer_Name,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) * 100.0 /
        NULLIF(SUM(Sales), 0),
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Customer_Name
HAVING SUM(Sales) > 0
ORDER BY Profit_Margin_Percent DESC;


/* 20. High Sales but Low Profit Products */
SELECT
    Product_Name,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    ROUND(
        SUM(Profit) * 100.0 /
        NULLIF(SUM(Sales), 0),
        2
    ) AS Profit_Margin_Percent
FROM Orders
GROUP BY Product_Name
HAVING SUM(Sales) > 5000
   AND SUM(Profit) < 500
ORDER BY Total_Sales DESC;