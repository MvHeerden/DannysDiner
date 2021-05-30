CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

  select * from sales;
  select * from members;
  select * from menu;

--1.Total amount each customer spent at the restaurant
  select s.customer_id, sum(m.price) as Total_amount from sales s
  join menu m
  on s.product_id = m.product_id
  group by s.customer_id;

--!!!
--2. Number of days each customer has visited the restaurant
drop table if exists #daysCount
create table #dayscount
(customer varchar(1),
orderDate date,
TimesPerDay int)

insert into #dayscount
select customer_id, order_date, count(*) from sales
group by customer_id, Order_date
order by customer_id;

select customer, count(orderdate) from #dayscount
group by customer;


--3. What was the first item from the menu purchased by each customer
  select s.customer_id, min(s.order_date) as First_date, m.product_name from sales s
  join menu m
  on s.product_id = m.product_id
  group by s.customer_id, product_name;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1 m.product_name, count(s.customer_id) from menu m
join sales s
on s.product_id = m.product_id
group by m.product_name
order by count(s.customer_id) desc;

--COMPLETED with a little help
--5. Which item was the most popular for each customer?
drop table if exists #MostPop
Create table #MostPop
(Customer varchar(1),
Product varchar (20),
NrOfItems int, 
order_rank int)
Insert into #mostPop
select s.customer_id, m.product_name, count(m.product_name) as Item_count, RANK() OVER (ORDER BY COUNT(m.product_name) DESC) AS order_rank from sales s
join menu m
on s.product_id = m.product_id
group by s.customer_id, m.product_name
order by s.customer_id;

select Customer, Product, order_rank from #mostPop
where order_rank = 1;


--!!!!
--6. Which item was purchased first by the customer after they became a member?

With DataRank as
(
Select sales.customer_id CusID, sales.order_date, menu.product_name Prod, members.join_date, rank() over (partition by sales.customer_id ORDER BY  max(order_date) desc) AS [order_rank] from sales
join members
on sales.customer_id = members.customer_id
join menu
on sales.product_id = menu.product_id
where members.join_date > sales.order_date 
group by sales.customer_id, sales.order_date, menu.product_name, members.join_date
)
select cusID, Prod, [order_rank] from DataRank
where [order_rank] = 1
order by order_rank;


--!!!
--7.Which item was purchased just before the customer became a member?
drop table if exists #LastPurchase
Create Table #LastPurchase
(
Customer nvarchar(1), 
Product varchar (20),
OrderDt date, 
JoinDt date,
Price int,
DaysInbetween int
)
Insert into #LastPurchase
select sales.customer_id, menu.product_name, sales.order_date, members.join_date, price, datediff("d",order_date, join_date) as DaysInbetween from sales
join members
on sales.customer_id = members.customer_id
join Menu
on menu.product_id = sales.product_id
where order_date < join_date;

with LP as 
(
select customer, Product, DaysInbetween, rank() over (partition by customer order by DaysInbetween) as ranks from #LastPurchase
group by customer, Product, DaysInbetween
)

select customer, Product, ranks
from LP 
where ranks = 1



--!!!
--8. What is the total items and amount spent for each member before they became a member?
drop table if exists #SpentB4Joining
Create Table #SpentB4Joining
(
Customer nvarchar(1), 
OrderDate date, 
JoinDate date,
Price int
)
Insert into #SpentB4Joining
select sales.customer_id, sales.order_date, members.join_date, price from sales
join members
on sales.customer_id = members.customer_id
join Menu
on menu.product_id = sales.product_id
where order_date < join_date;

Select Customer, sum(price) from #SpentB4Joining
group by Customer;



--!!
--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with cte as 
(
select sales.customer_id cus, menu.product_name prod, sum(menu.price) as Amt_Spent
, case 
	when product_name = 'sushi' then 2
	else 1
	end as dollar_worth
from sales
join menu
on sales.product_id = menu.product_id
group by sales.customer_id, menu.product_name
)
select cus, sum(amt_spent*dollar_worth) as Total_Points from cte
group by cus;

!!
--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
With AllPoints as 
(
select sales.customer_id cus, sales.order_date, members.join_date, menu.product_name, menu.price,
case 
	when DATEDIFF("d",members.join_date, sales.order_date) <=7 then menu.price*20
	when DATEDIFF("d",members.join_date, sales.order_date) > 7 and menu.product_name = 'Sushi' then menu.price*20
	else menu.price*10
	end as Points
from sales
join menu
on sales.product_id = menu.product_id
join members
on sales.customer_id = members.customer_id
where sales.order_date >= members.join_date and sales.order_date <= '2021-01-31'
)
select cus as CustomerID, sum(points) as TotalPoints from AllPoints
group by cus;

