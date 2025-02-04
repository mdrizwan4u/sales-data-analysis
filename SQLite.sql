
sql_content = """
-- 1. Top 10 loyal customers based on LoyaltyPoints
SELECT CustomerID, SUM(LoyaltyPoints) AS TotalLoyaltyPoints, 
       COUNT(TransactionID) AS TotalTransactions
FROM sales_data
GROUP BY CustomerID
ORDER BY TotalLoyaltyPoints DESC
LIMIT 10;

-- 2. Average transaction amount by CustomerAge group
SELECT 
    CASE 
        WHEN CustomerAge < 18 THEN 'Under 18'
        WHEN CustomerAge BETWEEN 18 AND 30 THEN '18-30'
        WHEN CustomerAge BETWEEN 31 AND 45 THEN '31-45'
        WHEN CustomerAge BETWEEN 46 AND 60 THEN '46-60'
        ELSE '60+' END AS AgeGroup,
    AVG(TransactionAmount) AS AvgTransactionAmount
FROM sales_data
GROUP BY AgeGroup;

-- 3. City and region with highest number of repeat customers
WITH RepeatCustomers AS (
    SELECT CustomerID, City, Region, COUNT(*) AS RepeatCount
    FROM sales_data
    GROUP BY CustomerID, City, Region
    HAVING COUNT(DISTINCT TransactionDate) > 1
)
SELECT City, Region, COUNT(CustomerID) AS TotalRepeatCustomers
FROM RepeatCustomers
GROUP BY City, Region
ORDER BY TotalRepeatCustomers DESC
LIMIT 1;

-- 4. Customer retention rate (monthly)
WITH MonthlyTransactions AS (
    SELECT CustomerID, DATE_TRUNC('month', TransactionDate) AS Month
    FROM sales_data
    GROUP BY CustomerID, Month
),
RecurringCustomers AS (
    SELECT DISTINCT a.CustomerID, a.Month
    FROM MonthlyTransactions a
    JOIN MonthlyTransactions b
    ON a.CustomerID = b.CustomerID AND a.Month = b.Month + INTERVAL '1 month'
)
SELECT 
    COUNT(DISTINCT RecurringCustomers.CustomerID) * 100.0 / COUNT(DISTINCT MonthlyTransactions.CustomerID) 
    AS RetentionRate
FROM MonthlyTransactions
LEFT JOIN RecurringCustomers 
ON MonthlyTransactions.CustomerID = RecurringCustomers.CustomerID;

-- 5. Total revenue, discount offered, and net revenue over time
SELECT DATE_TRUNC('month', TransactionDate) AS Month, 
       SUM(TransactionAmount) AS TotalRevenue,
       SUM(TransactionAmount * DiscountPercent / 100) AS TotalDiscount,
       SUM(TransactionAmount * (1 - DiscountPercent / 100)) AS NetRevenue
FROM sales_data
GROUP BY Month
ORDER BY Month;

-- 6. Top products contributing to revenue, by region
SELECT Region, ProductName, 
       SUM(TransactionAmount) AS TotalRevenue,
       RANK() OVER (PARTITION BY Region ORDER BY SUM(TransactionAmount) DESC) AS RankByRegion
FROM sales_data
GROUP BY Region, ProductName
HAVING RankByRegion <= 5
ORDER BY Region, RankByRegion;

-- 7. Monthly revenue trends for seasonality analysis
SELECT DATE_TRUNC('month', TransactionDate) AS Month, 
       SUM(TransactionAmount) AS MonthlyRevenue
FROM sales_data
GROUP BY Month
ORDER BY Month;

-- 8. Average discount and its effect on transaction amount
SELECT AVG(DiscountPercent) AS AvgDiscount,
       AVG(TransactionAmount) AS AvgTransactionAmount,
       CORR(DiscountPercent, TransactionAmount) AS Correlation
FROM sales_data;

-- 9. Products with the highest return rates
SELECT ProductName, 
       COUNT(*) AS TotalTransactions,
       SUM(CASE WHEN Returned = 'Yes' THEN 1 ELSE 0 END) AS TotalReturns,
       SUM(CASE WHEN Returned = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS ReturnRate
FROM sales_data
GROUP BY ProductName
ORDER BY ReturnRate DESC
LIMIT 10;

-- 10. Low-performing products based on revenue
SELECT ProductName, 
       SUM(TransactionAmount) AS TotalRevenue
FROM sales_data
GROUP BY ProductName
ORDER BY TotalRevenue ASC
LIMIT 10;

-- 11. Best-selling products by city and region
SELECT City, Region, ProductName, 
       COUNT(*) AS TotalUnitsSold
FROM sales_data
GROUP BY City, Region, ProductName
ORDER BY TotalUnitsSold DESC
LIMIT 10;

-- 12. Frequently bought-together products
WITH ProductPairs AS (
    SELECT a.TransactionID, a.ProductName AS ProductA, b.ProductName AS ProductB
    FROM sales_data a
    JOIN sales_data b
    ON a.TransactionID = b.TransactionID AND a.ProductName < b.ProductName
)
SELECT ProductA, ProductB, COUNT(*) AS PairCount
FROM ProductPairs
GROUP BY ProductA, ProductB
ORDER BY PairCount DESC
LIMIT 10;

-- Query 13: Impact of Promotions on Revenue and Transaction Value
SELECT 
    IsPromotional, 
    SUM(TransactionAmount) AS TotalRevenue,
    AVG(TransactionAmount) AS AvgTransactionValue
FROM sales_data
GROUP BY IsPromotional;

-- Query 14: Percentage of Positive Feedback During Promotions
SELECT 
    IsPromotional, 
    COUNT(CASE WHEN FeedbackScore >= 4 THEN 1 END) * 100.0 / COUNT(*) AS PositiveFeedbackPercentage
FROM sales_data
WHERE IsPromotional = 1
GROUP BY IsPromotional;

-- Query 15: Average Delivery Time by Region and Impact on Feedback
SELECT 
    Region, 
    AVG(DeliveryTimeDays) AS AvgDeliveryTime,
    AVG(FeedbackScore) AS AvgFeedbackScore
FROM sales_data
GROUP BY Region;

-- Query 16: Cities/Regions with Highest Shipping Costs and Profitability Impact
SELECT 
    City, 
    Region, 
    AVG(ShippingCost) AS AvgShippingCost,
    SUM(TransactionAmount - ShippingCost) AS NetProfit
FROM sales_data
GROUP BY City, Region
ORDER BY AvgShippingCost DESC;

-- Query 17: Payment Method with Highest Average Transaction Amount
SELECT 
    PaymentMethod, 
    AVG(TransactionAmount) AS AvgTransactionAmount
FROM sales_data
GROUP BY PaymentMethod
ORDER BY AvgTransactionAmount DESC;

-- Query 18: Average Transaction Value: Retail vs Online Stores
SELECT 
    StoreType, 
    AVG(TransactionAmount) AS AvgTransactionValue
FROM sales_data
GROUP BY StoreType;

-- Query 19: Factors Influencing Feedback Score
SELECT 
    AVG(FeedbackScore) AS AvgFeedbackScore,
    AVG(DiscountPercent) AS AvgDiscount,
    AVG(DeliveryTimeDays) AS AvgDeliveryTime
FROM sales_data
GROUP BY DiscountPercent, DeliveryTimeDays
ORDER BY AvgFeedbackScore DESC;
"""

