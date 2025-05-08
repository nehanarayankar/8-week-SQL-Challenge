
--Each of the following case study questions can be answered using a single SQL statement:

--#1. What is the total amount each customer spent at the restaurant?

select 	
	s.customer_id as customer,
	sum(mn.price) as total_amount
from dannys_diner.sales s
join dannys_diner.menu mn on mn.product_id = s.product_id
group by s.customer_id
order by s.customer_id



--#2. How many days has each customer visited the restaurant?

select 
	customer_id as customer,
	count(distinct order_date) as num_of_visits
from dannys_diner.sales
group by customer_id




--#3. What was the first item from the menu purchased by each customer?

with first_item_purchased as(
	select 
		customer_id as customer,
		m.product_name as item,
		order_date,
		row_number() over(partition by customer_id order by order_date asc, s.product_id) as rn
	from dannys_diner.sales s
	join dannys_diner.menu m on m.product_id = s.product_id
)

select 
	customer,
	item
from first_item_purchased
where rn = 1


--#4. What is the most purchased item on the menu and how many times was it purchased by all customers?


select 
	m.product_name as most_purchased_item,
	count(s.product_id) as num_of_times_pruchased
from dannys_diner.sales s
join dannys_diner.menu m on m.product_id = s.product_id
group by m.product_name





--#5. Which item was the most popular for each customer?

with popular_items as
	(
	select 
		s.customer_id as customer, 
		m.product_name as product,
		count(s.product_id) as num_of_items_purchased,
		row_number()over(partition by s.customer_id order by count(s.product_id) desc) as rn
		
	from dannys_diner.sales s
	join dannys_diner.menu m on m.product_id = s.product_id
	group by s.customer_id, m.product_name
)

select 
	customer,
	product
from popular_items
where rn = 1


--#6. Which item was purchased first by the customer after they became a member?

with first_purchased as
	(
	select 
		s.customer_id as customer,
		m.join_date,
		s.order_date,
		s.product_id as product,
		rank()over(partition by s.customer_id order by s.order_date asc) as rn
	from dannys_diner.sales s
	left join dannys_diner.members m on m.customer_id = s.customer_id
	where s.order_date >= m.join_date
)

select 
	customer, 
	product
from first_purchased 
where rn  = 1
	



--#7. Which item was purchased just before the customer became a member?

with purchase_before_join as
	(
	select
		s.customer_id as customer,
		s.product_id as product,
		s.order_date,
		m.join_date,
		rank()over(partition by s.customer_id order by order_date asc) as rn	
	from dannys_diner.sales s 
	left join dannys_diner.members m on m.customer_id = s.customer_id
	where order_date <= join_date
)

select 
	customer,
	product
from purchase_before_join 
where rn = 1
	


--#8. What is the total items and amount spent for each member before they became a member?


select 
	s.customer_id as customer,
	count(mn.product_name) as total_items,
	sum(mn.price) as amount_spent
from dannys_diner.sales s
join dannys_diner.members m on m.customer_id = s.customer_id
join dannys_diner.menu mn on mn.product_id = s.product_id
where s.order_date < m.join_date
group by s.customer_id



--#9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with points as 
	(
	select 
		s.customer_id as customer,
		product_name as product,
		price as price,
		(
		case 
			when product_name = 'sushi' then 2*10*price
			else 10*price
			end) as points
	from dannys_diner.sales s
	join dannys_diner.menu m on m.product_id = s.product_id
)

select 
	customer,
	product,
	sum(points) as total_points
from points
group by customer, product
order by customer, product, total_points desc


--#10. In the first week after a customer joins the program (including their join date) 
--they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

with table1 as
	(
	select 
		s.customer_id as customer,
		order_date,
		join_date,
		product_name as product,
		price,
		CASE
            WHEN s.order_date >= m.join_date AND s.order_date < m.join_date + INTERVAL '7 days' THEN price * 2 * 10
            ELSE price * 10
        END AS points
	from dannys_diner.sales s
	join dannys_diner.members m on m.customer_id = s.customer_id
	join dannys_diner.menu mn on mn.product_id = s.product_id
	where  s.order_date <= DATE '2021-01-31'
)

select 
	customer,
	product,
	sum(points) as total_points
from table1
group by customer, product
order by customer


--Bonus Question


--#1. Join all the Things


select
	s.customer_id,
	s.order_date,
	mn.product_name,
	mn.price,
	case 
		when order_date >= join_date then 'Y'
		else 'N'
		end as member
from dannys_diner.sales s
left join dannys_diner.members m on m.customer_id = s.customer_id
left join dannys_diner.menu mn on mn.product_id = s.product_id
order by customer_id, order_date, product_name




--#2. Rank all Things




with diner_members as
	(
	select 
		s.customer_id,
		s.order_date,
		mn.product_name,
		mn.price,
		case 
			when order_date >= join_date then 'Y'
			else 'N'
			end as member
	from dannys_diner.sales s
	left join dannys_diner.members m on m.customer_id = s.customer_id
	left join dannys_diner.menu mn on mn.product_id = s.product_id
	
)


select 
	*,
	case 
		when member = 'Y' then rank()over(partition by member,customer_id order by order_date asc)
		else null
		end as ranking
from diner_members
order by customer_id, order_date, product_name

