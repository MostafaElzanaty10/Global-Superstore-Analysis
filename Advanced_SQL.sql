USE [salesproject];
GO


/* 1. Year-over-Year Growth */

WITH YearlySales AS (
    SELECT
        YEAR(Order_Date) AS Order_Year,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY YEAR(Order_Date)
),
Growth AS (
    SELECT
        Order_Year,
        Total_Sales,
        Total_Profit,
        LAG(Total_Sales) OVER (
            ORDER BY Order_Year
        ) AS Previous_Year_Sales,
        LAG(Total_Profit) OVER (
            ORDER BY Order_Year
        ) AS Previous_Year_Profit
    FROM YearlySales
)
SELECT
    Order_Year,
    Total_Sales,
    Total_Profit,
    Previous_Year_Sales,
    Previous_Year_Profit,

    ROUND(
        (Total_Sales - Previous_Year_Sales) * 100.0 /
        NULLIF(Previous_Year_Sales, 0),
        2
    ) AS Sales_Growth_Percent,

    ROUND(
        (Total_Profit - Previous_Year_Profit) * 100.0 /
        NULLIF(Previous_Year_Profit, 0),
        2
    ) AS Profit_Growth_Percent

FROM Growth
ORDER BY Order_Year;


/* 2. Running Total of Sales by Month */

WITH MonthlySales AS (
    SELECT
        YEAR(Order_Date) AS Order_Year,
        MONTH(Order_Date) AS Order_Month,
        SUM(Sales) AS Monthly_Sales
    FROM Orders
    GROUP BY
        YEAR(Order_Date),
        MONTH(Order_Date)
)
SELECT
    Order_Year,
    Order_Month,
    Monthly_Sales,

    SUM(Monthly_Sales) OVER (
        ORDER BY Order_Year, Order_Month
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS Running_Total_Sales

FROM MonthlySales
ORDER BY
    Order_Year,
    Order_Month;


/* 3. Month-over-Month Growth */

WITH MonthlySales AS (
    SELECT
        YEAR(Order_Date) AS Order_Year,
        MONTH(Order_Date) AS Order_Month,
        SUM(Sales) AS Monthly_Sales
    FROM Orders
    GROUP BY
        YEAR(Order_Date),
        MONTH(Order_Date)
),
PreviousMonth AS (
    SELECT
        Order_Year,
        Order_Month,
        Monthly_Sales,

        LAG(Monthly_Sales) OVER (
            ORDER BY Order_Year, Order_Month
        ) AS Previous_Month_Sales

    FROM MonthlySales
)
SELECT
    Order_Year,
    Order_Month,
    Monthly_Sales,
    Previous_Month_Sales,

    ROUND(
        (Monthly_Sales - Previous_Month_Sales) * 100.0 /
        NULLIF(Previous_Month_Sales, 0),
        2
    ) AS Growth_Percent

FROM PreviousMonth
ORDER BY
    Order_Year,
    Order_Month;


/* 4. Customer Ranking by Sales */

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

    RANK() OVER (
        ORDER BY Total_Sales DESC
    ) AS Sales_Rank

FROM CustomerSales
ORDER BY Sales_Rank;


/* 5. Top 3 Customers in Each Segment */

WITH CustomerSales AS (
    SELECT
        Segment,
        Customer_Name,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY
        Segment,
        Customer_Name
),
RankedCustomers AS (
    SELECT
        Segment,
        Customer_Name,
        Total_Sales,
        Total_Profit,

        ROW_NUMBER() OVER (
            PARTITION BY Segment
            ORDER BY Total_Sales DESC
        ) AS Customer_Rank

    FROM CustomerSales
)
SELECT
    Segment,
    Customer_Name,
    Total_Sales,
    Total_Profit,
    Customer_Rank

FROM RankedCustomers

WHERE Customer_Rank <= 3

ORDER BY
    Segment,
    Customer_Rank;


/* 6. Product Performance Classification */

WITH ProductStats AS (
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

    CASE
        WHEN Total_Profit > 1000
            THEN 'Highly Profitable'

        WHEN Total_Profit > 0
            THEN 'Profitable'

        WHEN Total_Profit = 0
            THEN 'Break Even'

        ELSE 'Loss Making'
    END AS Product_Status

FROM ProductStats

ORDER BY Total_Profit DESC;


/* 7. Customer Segmentation Using Sales and Profit */

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
        WHEN Total_Sales >= 10000
             AND Total_Profit >= 2000
            THEN 'High Value'

        WHEN Total_Sales >= 5000
             AND Total_Profit > 0
            THEN 'Medium Value'

        WHEN Total_Profit <= 0
            THEN 'At Risk'

        ELSE 'Low Value'
    END AS Customer_Segment

FROM CustomerStats

ORDER BY Total_Sales DESC;


/* 8. Customer Profit Margin Ranking */

WITH CustomerProfit AS (
    SELECT
        Customer_Name,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit,

        SUM(Profit) * 100.0 /
        NULLIF(SUM(Sales), 0) AS Profit_Margin

    FROM Orders
    GROUP BY Customer_Name
)
SELECT
    Customer_Name,
    Total_Sales,
    Total_Profit,
    ROUND(Profit_Margin, 2) AS Profit_Margin_Percent,

    RANK() OVER (
        ORDER BY Profit_Margin DESC
    ) AS Margin_Rank

FROM CustomerProfit

WHERE Total_Sales > 0

ORDER BY Margin_Rank;


/* 9. Products with High Sales but Poor Profitability */

WITH ProductStats AS (
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

    ROUND(
        Total_Profit * 100.0 /
        NULLIF(Total_Sales, 0),
        2
    ) AS Profit_Margin_Percent

FROM ProductStats

WHERE Total_Sales > 5000
  AND Total_Profit < 500

ORDER BY Total_Sales DESC;


/* 10. State Performance Score */

WITH StateStats AS (
    SELECT
        State,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY State
),
RankedStates AS (
    SELECT
        State,
        Total_Sales,
        Total_Profit,

        RANK() OVER (
            ORDER BY Total_Sales DESC
        ) AS Sales_Rank,

        RANK() OVER (
            ORDER BY Total_Profit DESC
        ) AS Profit_Rank

    FROM StateStats
)
SELECT
    State,
    Total_Sales,
    Total_Profit,
    Sales_Rank,
    Profit_Rank,

    CASE
        WHEN Sales_Rank <= 10
             AND Profit_Rank <= 10
            THEN 'Top Performer'

        WHEN Sales_Rank <= 10
             AND Profit_Rank > 10
            THEN 'High Sales - Low Profit'

        WHEN Sales_Rank > 10
             AND Profit_Rank <= 10
            THEN 'Low Sales - High Profit'

        ELSE 'Average'
    END AS Performance_Type

FROM RankedStates

ORDER BY Profit_Rank;


/* 11. Category Performance by Year */

WITH CategoryYear AS (
    SELECT
        YEAR(Order_Date) AS Order_Year,
        Category,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY
        YEAR(Order_Date),
        Category
)
SELECT
    Order_Year,
    Category,
    Total_Sales,
    Total_Profit,

    RANK() OVER (
        PARTITION BY Order_Year
        ORDER BY Total_Sales DESC
    ) AS Sales_Rank,

    RANK() OVER (
        PARTITION BY Order_Year
        ORDER BY Total_Profit DESC
    ) AS Profit_Rank

FROM CategoryYear

ORDER BY
    Order_Year,
    Sales_Rank;


/* 12. Best Category in Each Year */

WITH CategoryYear AS (
    SELECT
        YEAR(Order_Date) AS Order_Year,
        Category,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY
        YEAR(Order_Date),
        Category
),
RankedCategories AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Order_Year
            ORDER BY Total_Sales DESC
        ) AS Category_Rank
    FROM CategoryYear
)
SELECT
    Order_Year,
    Category,
    Total_Sales,
    Total_Profit

FROM RankedCategories

WHERE Category_Rank = 1

ORDER BY Order_Year;


/* 13. Customer Order Frequency */

SELECT
    Customer_Name,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,

    ROUND(
        SUM(Sales) /
        NULLIF(COUNT(DISTINCT Order_ID), 0),
        2
    ) AS Average_Order_Value

FROM Orders

GROUP BY Customer_Name

ORDER BY Total_Orders DESC;


/* 14. Customers with Multiple Orders */

WITH CustomerOrders AS (
    SELECT
        Customer_Name,
        COUNT(DISTINCT Order_ID) AS Total_Orders,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY Customer_Name
)
SELECT
    Customer_Name,
    Total_Orders,
    Total_Sales,
    Total_Profit

FROM CustomerOrders

WHERE Total_Orders > 1

ORDER BY Total_Orders DESC;


/* 15. Return Impact on Sales */

WITH ReturnedOrders AS (
    SELECT DISTINCT
        Order_ID
    FROM Returns
),
OrderStatus AS (
    SELECT
        CASE
            WHEN r.Order_ID IS NOT NULL
                THEN 'Returned'
            ELSE 'Not Returned'
        END AS Order_Status,

        o.Order_ID,
        o.Sales,
        o.Profit

    FROM Orders o

    LEFT JOIN ReturnedOrders r
        ON o.Order_ID = r.Order_ID
)
SELECT
    Order_Status,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,

    ROUND(
        SUM(Profit) * 100.0 /
        NULLIF(SUM(Sales), 0),
        2
    ) AS Profit_Margin_Percent

FROM OrderStatus

GROUP BY Order_Status;


/* 16. Running Profit by Year */

WITH YearlyProfit AS (
    SELECT
        YEAR(Order_Date) AS Order_Year,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY YEAR(Order_Date)
)
SELECT
    Order_Year,
    Total_Profit,

    SUM(Total_Profit) OVER (
        ORDER BY Order_Year
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS Running_Profit

FROM YearlyProfit

ORDER BY Order_Year;


/* 17. Profit Margin by Category */

WITH CategoryStats AS (
    SELECT
        Category,
        SUM(Sales) AS Total_Sales,
        SUM(Profit) AS Total_Profit
    FROM Orders
    GROUP BY Category
)
SELECT
    Category,
    Total_Sales,
    Total_Profit,

    ROUND(
        Total_Profit * 100.0 /
        NULLIF(Total_Sales, 0),
        2
    ) AS Profit_Margin_Percent,

    RANK() OVER (
        ORDER BY
        Total_Profit * 100.0 /
        NULLIF(Total_Sales, 0) DESC
    ) AS Margin_Rank

FROM CategoryStats

ORDER BY Margin_Rank;


/* 18. Sales Contribution by Region */

WITH RegionSales AS (
    SELECT
        Region,
        SUM(Sales) AS Total_Sales
    FROM Orders
    GROUP BY Region
)
SELECT
    Region,
    Total_Sales,

    ROUND(
        Total_Sales * 100.0 /
        SUM(Total_Sales) OVER (),
        2
    ) AS Sales_Contribution_Percent

FROM RegionSales

ORDER BY Total_Sales DESC;


/* 19. High-Value Orders */

WITH OrderTotals AS (
    SELECT
        Order_ID,
        Customer_Name,
        SUM(Sales) AS Order_Sales,
        SUM(Profit) AS Order_Profit
    FROM Orders
    GROUP BY
        Order_ID,
        Customer_Name
)
SELECT
    Order_ID,
    Customer_Name,
    Order_Sales,
    Order_Profit,

    RANK() OVER (
        ORDER BY Order_Sales DESC
    ) AS Order_Value_Rank

FROM OrderTotals

WHERE Order_Sales > 1000

ORDER BY Order_Value_Rank;


/* 20. Final Business Performance Summary */

SELECT
    YEAR(Order_Date) AS Order_Year,
    Category,
    Region,

    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    SUM(Quantity) AS Total_Quantity,

    ROUND(
        SUM(Profit) * 100.0 /
        NULLIF(SUM(Sales), 0),
        2
    ) AS Profit_Margin_Percent,

    RANK() OVER (
        PARTITION BY YEAR(Order_Date)
        ORDER BY SUM(Profit) DESC
    ) AS Profit_Rank

FROM Orders

GROUP BY
    YEAR(Order_Date),
    Category,
    Region

ORDER BY
    Order_Year,
    Profit_Rank;