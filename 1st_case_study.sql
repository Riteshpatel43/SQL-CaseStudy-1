create database if not exists case_studies;
use case_studies;

 

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
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
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
select * from sales;
select * from menu;
select * from members;


-- Each of the following case study questions can be answered using a single SQL statement:

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- 	   not just sushi - how many points do customer A and B have at the end of January?


-- SOLUTIONS :

-- Q.1 What is the total amount each customer spent at the restaurant?

select s.customer_id as customers,
sum(m.price) as total_amount 
from sales s 
join menu m on s.product_id = m.product_id 
group by customers;
  
-- Q.2 How many days has each customer visited the restaurant?

select customer_id as customer , count(distinct order_date) as customer_visited 
from sales 
group by customer_id;

-- Q3. What was the first item from the menu purchased by each customer?

select s.customer_id,s.order_date,s.product_id,s.occurence,m.product_name,m.price 
from (select customer_id,order_date,product_id,row_number() over(partition by customer_id ) as occurence  from sales ) s 
join menu m 
on s.product_id = m.product_id 
where occurence =1 ;
 

-- Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select    prod , name  ,  most_ordered
from (select  s.product_id as prod , m.product_name as name,
		count(s.product_id)  as most_ordered  
		from sales s 
		join menu m 
		on s.product_id = m.product_id  
		group by s.product_id, m.product_name ) t  order by most_ordered desc limit 1;
 
-- Q5. Which item was the most popular for each customer?
 
 with ranked_items as (
 
select customer_id,product_id,COUNT(product_id) AS purchase_count,
row_number() over(partition by customer_id order by count(product_id) desc) as rang from sales GROUP BY 
    customer_id, product_id
 )
 select customer_id,product_id,purchase_count from ranked_items where rang = 1;
 
 
-- Q6. Which item was purchased first by the customer after they became a member?

WITH first_purchase AS (
  SELECT 
    s.customer_id,
    s.product_id,
    m.join_date,
    s.order_date,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rang
  FROM 
    sales s
  JOIN 
    members m ON s.customer_id = m.customer_id
  WHERE 
    s.order_date >= m.join_date
)
SELECT 
  customer_id,
  product_id,
  order_date
FROM 
  first_purchase
WHERE 
  rang = 1;
 
-- Q7. Which item was purchased just before the customer became a member?
 

with before_mem as 
(select s.customer_id,s.product_id,s.order_date, m.join_date,row_number() over(partition by s.customer_id order by s.order_date desc) as rang 
from sales s 
join members m 
on s.customer_id = m.customer_id 
where s.order_date < m.join_date)
SELECT 
  customer_id,
  product_id,
  order_date
FROM 
  before_mem
WHERE 
  rang = 1;
  
-- Q8. What is the total items and amount spent for each member before they became a member?

select s.customer_id, count(s.product_id)  , sum(m.price) from sales s
join menu m on s.product_id = m.product_id
join members mem on s.customer_id = mem.customer_id
where s.order_date < mem.join_date
group by s.customer_id
;


-- Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

 select s.customer_id, sum(
 
 case
	when m.product_name = 'sushi' then m.price * 10 *2
    else m.price * 10
 end
 ) as total_points
 from sales s 
 join menu m 
 on s.product_id = m.product_id 
 group by s.customer_id;

 
-- Q10.  In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
--       not just sushi - how many points do customer A and B have at the end of January?


SELECT 
    s.customer_id,
    SUM(
        CASE
            WHEN s.order_date BETWEEN mem.join_date AND mem.join_date + INTERVAL 6 DAY 
                THEN 
                    CASE 
                        WHEN m.product_name = 'sushi' THEN m.price * 10 * 2 * 2 -- First week, sushi
                        ELSE m.price * 10 * 2                              -- First week, other items
                    END
            ELSE 
                CASE 
                    WHEN m.product_name = 'sushi' THEN m.price * 10 * 2       -- Standard sushi
                    ELSE m.price * 10                                    -- Standard other items
                END
        END
    ) AS total_points
FROM 
    sales s
JOIN 
    menu m ON s.product_id = m.product_id
JOIN 
    members mem ON s.customer_id = mem.customer_id
WHERE 
    s.order_date <= '2024-01-31' -- Only consider purchases until end of January
    AND s.customer_id IN ('A', 'B') -- Only for customers A and B
GROUP BY 
    s.customer_id;

