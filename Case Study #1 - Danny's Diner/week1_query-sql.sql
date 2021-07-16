/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

/* --------------------
   Answers
   --------------------*/
   
-- Q1: What is the total amount each customer spent at the restaurant?
SELECT
    sales.customer_id,
    SUM(menu.price) AS total_spent
FROM dannys_diner.sales
JOIN dannys_diner.menu
	ON sales.product_id = menu.product_id
GROUP BY customer_id
ORDER BY customer_id;

-- Q2: How many days has each customer visited the restaurant?
SELECT
    sales.customer_id,
    COUNT(DISTINCT sales.order_date) AS visiting_days
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id;

-- Q3: What was the first item from the menu purchased by each customer? (order_date does not have exact time --> first order item could be any item regardless of the order)
WITH cte_item_order AS(
  SELECT 
      sales.customer_id,
      menu.product_name,
      ROW_NUMBER() OVER(
        PARTITION BY sales.customer_id 
        ORDER BY sales.order_date, menu.product_id        
      ) AS item_order                  	
  FROM dannys_diner.sales
  JOIN dannys_diner.menu
      ON sales.product_id = menu.product_id
)
SELECT * 
FROM cte_item_order
WHERE item_order = 1;

-- Q4: What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
    menu.product_name,
    COUNT(sales.product_id) AS total_purchases
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
	ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY total_purchases DESC
LIMIT 1;

-- Q5: Which item was the most popular for each customer?
WITH cte_most_popular AS(
  SELECT
      sales.customer_id,
      menu.product_name,
      COUNT(sales.product_id) AS total_purchases,
  	  RANK() OVER(
        PARTITION BY sales.customer_id
        ORDER BY COUNT(sales.product_id) DESC
      ) AS item_rank                  
  FROM dannys_diner.sales
  INNER JOIN dannys_diner.menu
      ON sales.product_id = menu.product_id
  GROUP BY sales.customer_id, menu.product_name
)
SELECT customer_id,
       product_name,
       total_purchases
FROM cte_most_popular
WHERE item_rank = 1;

-- Create a temp table to check if the customer is a member or not (member_validation)
DROP TABLE IF EXISTS member_validation;

CREATE TEMP TABLE member_validation 
	AS
    SELECT 
    	sales.customer_id,
        sales.order_date,
        menu.product_name,
        menu.price,
        members.join_date,
        CASE WHEN members.join_date <= sales.order_date THEN 'Y'
        ELSE 'N'
        END AS membership       
    FROM dannys_diner.sales
    INNER JOIN dannys_diner.menu
    	ON sales.product_id = menu.product_id
    LEFT JOIN dannys_diner.members
    	ON sales.customer_id = members.customer_id
    WHERE join_date IS NOT NULL
    ORDER BY sales.customer_id,
    		 sales.order_date;		 
			 
-- Check the newly created table
SELECT *
FROM member_validation;

-- Q6: Which item was purchased first by the customer after they became a member?
WITH cte_first_after_mem AS (
  SELECT 
      member_validation.customer_id,
      member_validation.product_name,
  	  member_validation.join_date,
      RANK() OVER(
          PARTITION BY member_validation.customer_id
          ORDER BY member_validation.order_date
        ) AS item_rank      
  FROM member_validation
  WHERE membership = 'Y' 
)
SELECT *
FROM cte_first_after_mem
WHERE item_rank = 1;

-- Q7: Which item was purchased just before the customer became a member?
WITH cte_last_before_mem AS (
  SELECT 
      member_validation.customer_id,
      member_validation.product_name,
  	  member_validation.join_date,
      RANK() OVER(
          PARTITION BY member_validation.customer_id
          ORDER BY member_validation.order_date DESC
        ) AS item_rank      
  FROM member_validation
  WHERE membership = 'N' 
)
SELECT *
FROM cte_last_before_mem
WHERE item_rank = 1;

-- Q8: What is the total items and amount spent for each member before they became a member?
WITH cte_total_before_mem AS(
  SELECT
  	customer_id,
  	product_name,
  	order_date,
    price,
  	RANK() OVER(PARTITION BY customer_id
                ORDER BY order_date DESC
                ) AS item_order
  FROM member_validation
  WHERE membership = 'N'
)
SELECT 
	customer_id,
	COUNT(*) AS total_item,
    SUM(price) AS total_spent
FROM cte_total_before_mem
GROUP BY customer_id
ORDER BY customer_id;

-- Q9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
	customer_id,
    SUM(
      CASE WHEN product_name = 'sushi' THEN (price*10*2)
      ELSE (price*10)
      END
      ) AS total_points
FROM member_validation
GROUP BY customer_id
ORDER BY customer_id;

-- Q10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT 
	customer_id,
    SUM(
      CASE 
      	WHEN product_name = 'sushi' THEN (price*10*2)
      	WHEN order_date BETWEEN join_date AND (join_date + 6)
      		THEN (price*10*2)
      ELSE (price*10)
      END
    ) AS points  	
FROM member_validation
WHERE order_date < '2021-02-01'
GROUP BY customer_id
ORDER BY points DESC;

-- Bonus Quesion 11 & 12: Create a table includes further information about the ranking of customer products, without the ranking for non-member purchases (expects null ranking values for the records when customers are not yet part of the loyalty program)
WITH cte_mem_check_rank AS(
     SELECT 
     	sales.customer_id,
         sales.order_date,
         menu.product_name,
         menu.price,
         members.join_date,
         CASE WHEN members.join_date <= sales.order_date THEN 'Y'
         ELSE 'N'
         END AS membership       
     FROM dannys_diner.sales
     INNER JOIN dannys_diner.menu
     	ON sales.product_id = menu.product_id
     LEFT JOIN dannys_diner.members
     	ON sales.customer_id = members.customer_id
     ORDER BY sales.customer_id,
     		  sales.order_date
)
SELECT 
	*,
    CASE WHEN membership = 'Y' THEN(
         RANK() OVER(PARTITION BY customer_id, membership 
                     ORDER BY order_date))
    END AS ranking
FROM cte_mem_check_rank;

