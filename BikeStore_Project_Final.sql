
use bikestore;

-- 1. Total Sales Revenue
Select
sum(list_price*quantity) as revenue 
from order_items;

-- 2. Top 5 Best-Selling Products
Select
products.product_name,
sum(order_items.list_price*order_items.quantity) as Revenue
from
products join order_items
on products.product_id = order_items.product_id
group by product_name
order by revenue desc limit 5;

-- 4. Top 10 Customers by Total Amount Spent
Select
concat(customers.first_name,' ', customers.last_name) as customer,
sum(order_items.list_price*order_items.quantity) as revenue
from 
customers join orders
on customers.customer_id = orders.customer_id
join order_items
on order_items.order_id = orders.order_id
group by
customer
order by revenue desc limit 10;

-- What is the total sales amount for each product category?
select 
categories.category_name,
sum(order_items.list_price*order_items.quantity) as Revenue
from order_items join products
on order_items.product_id = products.product_id
join categories
on categories.category_id = products.category_id
group by category_name;

-- Which brands have the highest total sales amount?
select 
brands.brand_name,
sum(order_items.list_price*order_items.quantity) as Revenue
from order_items join products
on order_items.product_id = products.product_id
join brands
on brands.brand_id = products.brand_id
group by brand_name;

-- How many orders have each customer placed?
select
concat(customers.first_name,' ',customers.last_name) as customer,
count(orders.order_id)
 from customers join orders
 on customers.customer_id = orders.customer_id
 group by
concat(customers.first_name,' ',customers.last_name)
order by 
count(orders.customer_id) desc
 ;
 
 



  -- What is the average value of an order?
  -- break down of question - (a) we need to calculate total amount of orders then the average out of it
  
select
avg(revenue)
from
(select
order_id,
sum(list_price*quantity) as revenue
from order_items
group by order_id) sale;
  
  
-- What is the total quantity of each product currently in stock across all stores?

select
product_id,
sum(quantity) as stock_maintained
from stocks
group by product_id;


-- How have sales trends changed over the last year?
select
monthname(ord.order_date) as monthly_sale,
round(sum(oi.list_price * oi.quantity)) as revenue
from orders ord join order_items oi
on ord.order_id= oi.order_id
group by monthly_sale;

-- Which store generates the highest total sales?

select 
stores.store_name,
stores.store_id,
sum(order_items.list_price*order_items.quantity) as Revenue
from orders join stores
on stores.store_id = orders.store_id
join order_items
on orders.order_id = order_items.order_id
group by store_name,
store_id;


-- What are the top 5 best-selling products by quantity sold?

select
products.product_name,
stocks.product_id,
sum(stocks.quantity) as stock_maintained
from stocks join products
on stocks.product_id = products.product_id
group by product_name,
product_id
order by stock_maintained desc
limit 5;

-- What are the characteristics (e.g., average order value, frequency) of the top 10% of customers?
select 
avg(revenue)
from 
(Select
concat(customers.first_name,' ', customers.last_name) as customer,
sum(order_items.list_price*order_items.quantity) as revenue
from 
customers join orders
on customers.customer_id = orders.customer_id
join order_items
on order_items.order_id = orders.order_id
group by
customer
order by revenue desc limit 10) sale;

select
avg(revenue/no_of_orders_placed) as average_order_placed
from
(Select
concat(customers.first_name,' ', customers.last_name) as customer,
sum(order_items.list_price*order_items.quantity) as revenue,
count(order_items.order_id) as no_of_orders_placed
from 
customers join orders
on customers.customer_id = orders.customer_id
join order_items
on order_items.order_id = orders.order_id
group by
customer
order by revenue desc limit 10) sale;


-- Which staff members have the highest number of sales or orders handled?
select
concat(staffs.first_name,' ',staffs.last_name) as staff_name,
orders.staff_id,
count(orders.order_id) as orders_received
from staffs join orders
on staffs.staff_id = orders.staff_id
group by
concat(first_name,' ',last_name),
staff_id
order by orders_received desc;


-- Based on historical sales data, what is the forecasted sales amount for the next quarter?  
   
  with quarter_sales as (
   select
   extract(quarter from o.order_date) quarters,
   sum(oi.list_price * oi.quantity) as total_sales
   from orders o join order_items oi
   on o.order_id = oi.order_id 
   group by quarters
   ),
   moving_avg as (
   select
   total_sales,
   quarters,
   avg(total_sales) over(order by quarters rows between 3 preceding and current row) as avg_sales
   from quarter_sales )
   select
   quarters,
   avg_sales as sales_forecasted
   from moving_avg
   where quarters = (select max(quarters) from quarter_sales);
   

-- What is the estimated lifetime value of each customer segment?

with customer_revenue as
(
select
o.customer_id,
sum(oi.list_price*oi.quantity) as revenue
from order_items oi join orders o
on oi.order_id = o.order_id
group by 
customer_id
),
customer_segment as (
select
customer_id,
case
when revenue >= 30000 then 'High Value'
when revenue between 20000 and 30000 then 'Middle Value'
else 'Low Value'
end as segment,
revenue
from customer_revenue 
)

select
segment,
avg(revenue) as estimated_life_value
from customer_segment
group by segment
order by estimated_life_value desc;


-- What percentage of customers have not placed any orders in the last 6 months? What are their characteristics?

select 
customer_id
from orders
where not exists (
select
customer_id,
count(order_id)
from orders

group by customer_id
)
;

with last_date as (
select max(order_date) as cutt from orders
),
6_month_date as (
select 
cutt,
date_sub(cutt, interval 6 month) as last_6_months
from last_date
),
customer_orders as 
(
select distinct
customer_id
from orders 
where order_date >= (select last_6_months from 6_month_date)
),
inactive_customers as (
select
customer_id
from customers
where customer_id not in (select customer_id from customer_orders)
),
inactive_customers_percetage as (
select
count(*)*100/(select count(*)customer_id from customers) as percentage
from inactive_customers
)
select
ic.customer_id,
c.first_name,
c.last_name,
c.email,
c.street,
c.city,
c.state
from inactive_customers ic
join customers c
on
ic.customer_id = c.customer_id
;

-- Which customers have placed orders, and what is their order status? Include customers who have not placed any orders.

select
concat(c.first_name,' ',c.last_name),
o.order_id,
o.order_status
from customers c left join orders o
on c.customer_id = o.customer_id;

-- Show all stores and the staff assigned to them, including stores that do not have any staff assigned.
select
store_name,
concat(first_name,' ',last_name) as staff_name
from staffs st
right join stores s 
on st.store_id = s.store_id;


-- Retrieve a complete list of products and their stock levels across all stores, including products that are not in stock at any store.
select
pr.product_name,
sum(st.quantity),
stores.store_name
from products pr 
left join stocks st 
on pr.product_id = st.product_id
join stores
on stores.store_id = st.store_id
group by 
product_name,store_name; 



-- Find all staff members and their managers. 
select
concat(st1.first_name,' ',st1.last_name) as staff_name,
concat(st2.first_name,st2.last_name) as manager_name
from staffs st1 join staffs st2
on 
st1.staff_id = st2.manager_id;


-- Calculate the total quantity of products sold per order.
select
order_id,
count(quantity)
from order_items
group by 
order_id;


-- Get the list of customers who have made purchases and the corresponding order details, only for orders that were shipped.
select
concat(c.first_name,' ' ,c.last_name),
o.order_id,
o.order_date,
o.shipped_date
from
customers c join orders o
on c.customer_id = o.customer_id
where o.shipped_date is not null;



-- Create a list of all combinations of products and categories.
select
p.product_name,
c.category_name
from products p join categories c;