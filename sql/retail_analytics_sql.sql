use retail_analytics;
show tables;
select * from customer_profiles;
select * from product_inventory;
select * from sales_transaction;

# Business Problem :
-- The retail company is facing stagnant growth and unclear customer engagement trends.
-- This analysis aims to evaluate product performance, customer segmentation,
-- and revenue patterns to identify key growth drivers and improvement areas.

-- =========================================
# Project Objectives:
-- 1. Clean and validate transactional data using SQL.
-- 2. Identify top and low performing products.
-- 3. Segment customers based on total purchase quantity.
-- 4. Analyze repeat purchasing behavior and loyalty patterns.
-- =========================================

## Identify and eliminate duplicate records from the Sales_transaction table to ensure data integrity and consistency.
 
select 
transactionid,
count(*)
 from sales_transaction
 group by transactionid
 having count(*) >1;

 create table sales_trans as
 select distinct transactionid,
 customerid,
 productid,
 quantitypurchased,
 transactiondate,
 price
 from sales_transaction;

 select * from sales_trans;

drop table sales_transaction;

rename table sales_trans to sales_transaction;

##  identify the discrepancies in the price of the same product in "sales_transaction" and "product_inventory" tables. 
-- Also, update those discrepancies to match the price in both the tables.

select st.transactionid, st.price as TransactionPrice, pi.price as InventoryPrice
from sales_transaction as st
join product_inventory as pi
on st.productid = pi.productid
where pi.price <> st.price;

update sales_transaction as st
join product_inventory as pi
on st.productid = pi.productid
set st.price = pi.price
where pi.price <> st.price;
 
select transactionid, customerid,
productid,
quantitypurchased,
transactiondate,
price
 from sales_transaction
order by transactionid, productid;

##  identify the null values in the dataset and replace those by “Unknown”.

select count(*)
from customer_profiles
where location is null;

update customer_profiles
set location = 'Unknown'
where location is null;

select * from customer_profiles;

## Convert the TransactionDate column from TEXT to DATE format
-- and replace the existing table with a cleaned version
-- to enable accurate date-based analysis.

create table cleaned_Sales as
select *,
str_to_date(transactiondate, '%Y-%m-%d') as transactiondate_updated from sales_transaction;

drop table sales_transaction;

rename table cleaned_Sales to sales_transaction;

select * from sales_transaction;

##  Calculate total sales revenue and total quantity sold per product
-- to assess overall product performance.

select
productid,
sum(quantitypurchased) as totalunitsSold,
sum(quantitypurchased * price) as totalsales
from sales_transaction
group by productid
order by totalsales desc;

# Insight :
-- Although ProductID 51 has lower units sold compared to some other products,
--  it generates the highest revenue, indicating a higher selling price or premium positioning.


## count the number of transactions per customer to understand purchase frequency.

select
customerid,
count(*) as NumberOfTransactions
from sales_transaction
group by customerid
order by NumberOfTransactions desc;

## Evaluate total sales by product category to identify
-- high and low performing categories for marketing focus.

select
category,
sum(quantitypurchased) as totalUnitsSold,
sum(quantitypurchased * st.price) as totalSales
from sales_transaction as st
join product_inventory as pi
on st.productid = pi.ï»¿ProductID
group by category
order by totalSales desc;

# Insight :
-- Clothing drives the major role in overall revenue growth of the company compared to other category.


## top 10 products with the highest total sales revenue from the sales transactions.

select
productid,
sum(quantitypurchased * price) as TotalRevenue
from sales_transaction
group by productid
order by TotalRevenue desc
limit 10;

##  ten products with the least amount of units sold from the sales transactions,
-- provided that at least one unit was sold for those products.

select productid,
sum(quantitypurchased) as TotalUnitsSold
from sales_transaction
group by productid
having sum(quantitypurchased) > 1
order by TotalUnitsSold asc
limit 10;

##  identify the sales trend to understand the revenue pattern of the company.

select 
date_format(transactiondate, '%Y-%m-%d') as datetrans,
count(ï»¿transactionid) as transaction_count,
sum(quantitypurchased) as TotalUnitsSold,
round(sum(quantitypurchased * price),2) as TotalSales
from sales_transaction
group by datetrans
order by datetrans desc;

# Insight :
-- Monthly performance shows relatively stable transaction count(mostly 24 per month) while fluctuation
-- in total sales are primarly driven by changes in average order value. 

##  To understand the month on month growth rate of sales of the company which will help
-- understand the growth trend of the company.

with sales as
(select
month(transactiondate) as month,
round(sum(quantitypurchased * price),2) as total_sales,
lag(round(sum(quantitypurchased * price),2)) over(order by month(transactiondate)) as previous_month_sales
from sales_transaction
group by month
order by month)

select *,
round((total_sales - previous_month_sales) / previous_month_sales * 100,2) as mom_growth_percentage
from sales;

## Insight :
-- Revenue shows overall volatility with multiple months experiencing negative growth.
-- However, one month recorded a significant positive growth of 116%,
-- indicating a possible seasonal spike, promotional campaign impact,
-- or abnormal sales surge during that period.


##  Identify customers with more than 10 transactions
-- and total spending greater than 1000
-- to detect high-frequency, high-value customers.

select customerid,
count(ï»¿transactionid) as numberoftransactions,
sum(quantitypurchased * price) as Totalspent
from sales_transaction
group by customerid
having count(ï»¿transactionid) > 10 and sum(quantitypurchased * price) > 1000
order by Totalspent desc;

##  Identify customers with two or fewer transactions
-- to understand occasional or low-frequency buyers.

select
customerid,
count(ï»¿transactionid) as numberoftransactions,
sum(quantitypurchased * price) as totalspent
from sales_transaction
group by customerid
having count(ï»¿transactionid) <= 2 
order by numberoftransactions, totalspent desc;

# Insights :
-- A considerable number of customers have two or fewer transactions, 
-- indicating low engagement and an opportunity for targeted retention efforts.


## To understand the repeat customers in the company.

select
customerid,
productid,
count(ï»¿transactionid) as timespurchased
from sales_transaction
group by customerid, productid
having count(ï»¿transactionid) > 1
order by timespurchased desc;

## the duration between the first and the last purchase of the customer in that 
-- particular company to understand the loyalty of the customer.

with purchase as
(select
customerid,
min(str_to_date(transactiondate, '%Y-%m-%d')) as FirstPurchase,
max(str_to_date(transactiondate, '%Y-%m-%d')) as Lastpurchase
from sales_transaction
group by customerid)

select *, 
datediff(Lastpurchase, FirstPurchase) as daysbetweenpurchases
from purchase
where datediff(Lastpurchase, FirstPurchase) > 0
order by daysbetweenpurchases desc;

# Insight :
-- Many customers show a significant gap between their first and last purchase,
-- indicating sustained engagement over time rather than one-time buying behavior.

## Segment customers based on total quantity purchased
-- and count customers in each segment to support
-- targeted marketing initiatives.

create table customer_segment as
select
customerid,
sum(quantitypurchased) as  totalquantity,
case 
     when sum(quantitypurchased) between 1 and 10 then 'Low'
     when sum(quantitypurchased) between 11 and 30 then 'Med'
     when sum(quantitypurchased) > 30 then 'High'
     end as customersegment
from sales_transaction
group by customerid;

select customersegment,
count(*) 
from customer_segment
group by customersegment;

## Insight :
-- -- The majority of customers are medium buyers, with very few high-value customers.


## To determine which category played major role in Mom spike in 6th month

select category,
month(transactiondate) as month,
round(sum(quantitypurchased * s.price),2) as total_revenue
from product_inventory as p
join sales_transaction as s
on p.ï»¿ProductID = s.ProductID
group by category, month(transactiondate)
order by total_revenue desc, month;

# Insight :
-- Clothing category recorded a sharp revenue surge in Month 6,
-- contributing significantly to overall company growth.

## To identify increase in revenue due to volumn spike or price

select p.category,
month(s.transactiondate) as month,
round(sum(s.quantitypurchased),2) as total_units,
round(sum(s.quantitypurchased * s.price),2) as total_revenue,
round(avg(s.price),2) as avg_selling_price
from sales_transaction s
join product_inventory p
on s.productid = p.ï»¿productid
group by p.category, month(s.transactiondate)
order by total_revenue desc;

## Insight :
-- Higher average selling price in Clothing is the key driver
-- behind its revenue dominance compared to other categories.

 
 ## Top 10% Customers Contribution
 
 with cust_contri as (
 select
 customerid,
 sum(quantitypurchased * price) as totalrev
 from sales_transaction
 group by customerid ),
 
 ranked_cust as (
 select 
 customerid,
 totalrev,
 ntile(10) over(order by totalrev desc) as perc_dist
 from cust_contri )
 
 select
 sum(totalrev) as top_10_perc_rev
 from ranked_cust
 where perc_dist = 1;
 
 # Insight :
 -- Top 10% of customers contribute to around half of the company's total revenue.
 
 ## Identify which products are purchased multiple times by the same customer.
 
 SELECT 
    customerid,
    productid,
    COUNT(ï»¿transactionid) AS times_purchased
FROM sales_transaction
GROUP BY customerid, productid
HAVING COUNT(ï»¿transactionid) > 1
ORDER BY times_purchased DESC;

# Insight :
-- Most of the products are purchased twice across all products by all customers,
-- not repeated purchases


## To identify revenue growth by top 10% customers in clothing category
WITH cust_contri AS (
    SELECT 
        customerid,
        SUM(quantitypurchased * price) AS totalrev
    FROM sales_transaction
    GROUP BY customerid
),

ranked_cust AS (
    SELECT 
        customerid,
        NTILE(10) OVER (ORDER BY totalrev DESC) AS revenue_bucket
    FROM cust_contri
)

SELECT 
    p.category,
    MONTH(s.transactiondate) AS month,
    ROUND(SUM(s.quantitypurchased * s.price),2) AS total_revenue
FROM sales_transaction s
JOIN product_inventory p
    ON s.productid = p.ï»¿productid
JOIN ranked_cust r
    ON s.customerid = r.customerid
WHERE r.revenue_bucket = 1
AND p.category = 'Clothing'
GROUP BY p.category, MONTH(s.transactiondate)
ORDER BY month;

# Insight :
-- Huge growth in clothing category in month 6 and 7 by high value customers.



 
