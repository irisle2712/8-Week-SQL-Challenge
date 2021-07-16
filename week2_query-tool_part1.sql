/* --------------------
   Case Study Questions:
   Pizza Metrics
   --------------------*/

-- 1. How many pizzas were ordered?
-- 2. How many unique customer orders were made?
-- 3. How many successful orders were delivered by each runner?
-- 4. How many of each type of pizza was delivered?
-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
-- 6. What was the maximum number of pizzas delivered in a single order?
-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- 8. How many pizzas were delivered that had both exclusions and extras?
-- 9. What was the total volume of pizzas ordered for each hour of the day?
-- 10. What was the volume of orders for each day of the week?

-- Q1: How many pizzas were ordered?
-- (assume that this also include the orders are cancelled)
SELECT COUNT(*) AS total_pizza_ord
FROM pizza_runner.customer_orders;

-- Q2: How many unique customer orders were made?
SELECT COUNT(DISTINCT(order_id)) AS unique_customer_ord
FROM pizza_runner.customer_orders;

-- Q3: How many successful orders were delivered by each runner?
SELECT runner_id,
	   COUNT(order_id) AS successful_ord
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL OR 
	  cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
GROUP BY runner_id
ORDER BY runner_id;

-- Q4: How many of each type of pizza was delivered?
SELECT 
	p.pizza_name,
	COUNT(c.*) AS delivered_pizza_count
FROM pizza_runner.customer_orders AS c
INNER JOIN pizza_runner.runner_orders AS r
	ON c.order_id = r.order_id
INNER JOIN pizza_runner.pizza_names AS p
	ON c.pizza_id = p.pizza_id
WHERE r.cancellation IS NULL OR
	  r.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
GROUP BY p.pizza_name;

-- OR USE LEFT SEMI JOIN / WHERE EXISTS https://www.w3schools.com/sql/sql_exists.asp
SELECT 
	p.pizza_name,
	COUNT(c.*) AS delivered_pizza_count
FROM pizza_runner.customer_orders AS c
INNER JOIN pizza_runner.pizza_names AS p
	ON c.pizza_id = p.pizza_id
WHERE EXISTS (
			  SELECT 1 FROM pizza_runner.runner_orders AS r
			  WHERE c.order_id = r.order_id
			  AND (
			  		r.cancellation IS NULL OR
					r.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
			  )
)
GROUP BY p.pizza_name
ORDER BY P.pizza_name;

-- Q5: How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
	customer_id,
	SUM(CASE WHEN pizza_id = 1 THEN 1 ELSE 0 END) AS meatlovers,
	SUM(CASE WHEN pizza_id = 2 THEN 1 ELSE 0 END) AS vegetarian
FROM pizza_runner.customer_orders
GROUP BY customer_id
ORDER BY customer_id;

-- Q6: What was the maximum number of pizzas delivered in a single order?
SELECT MAX(pizza_count) AS max_count
FROM (
		SELECT 
			c.order_id,
			COUNT(c.pizza_id) AS pizza_count 
		FROM pizza_runner.customer_orders AS c
		INNER JOIN pizza_runner.runner_orders AS r
			ON c.order_id = r.order_id
		WHERE r.cancellation IS NULL OR
			  r.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
	 	GROUP BY c.order_id
	) AS my_count;

-- OR USING RANK() 
WITH cte_ranked_orders AS (
	SELECT 
		order_id,
		COUNT(*) AS pizza_count,
		RANK() OVER(ORDER BY COUNT(*) DESC) AS count_rank
	FROM pizza_runner.customer_orders AS c
	WHERE EXISTS(
		SELECT 1 FROM pizza_runner.runner_orders AS r
		WHERE r.order_id = c.order_id
		AND (
			r.cancellation IS NULL OR
			r.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
		)
	)
	GROUP BY order_id
)
SELECT pizza_count FROM cte_ranked_orders WHERE count_rank = 1;

-- Q7: For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
	c.customer_id,
	SUM(CASE WHEN c.exclusions IS NOT NULL OR c.extras IS NOT NULL THEN 1 ELSE 0 END) AS as_least_1_change,
	SUM(CASE WHEN c.exclusions IS NULL AND c.extras IS NULL THEN 1 ELSE 0 END) AS no_changes
FROM pizza_runner.customer_orders AS c
INNER JOIN pizza_runner.runner_orders AS r
	ON c.order_id = r.order_id
WHERE r.cancellation IS NULL OR
	  r.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
GROUP BY c.customer_id
ORDER BY c.customer_id;

-- OR USING CTE AND LEFT SEMI JOIN
WITH cte_delivered_ord AS (
	SELECT 
		order_id,
		customer_id,
		pizza_id,
		order_time,
		CASE WHEN exclusions IN ('null','') THEN '1' ELSE exclusions END AS exclusions,
		CASE WHEN extras IN ('null', '') THEN '1' ELSE extras END AS extras
	FROM pizza_runner.customer_orders
)
SELECT 
	customer_id,
	SUM(CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 ELSE 0 END) AS at_least_1_change,
	SUM(CASE WHEN exclusions IS NULL AND extras IS NULL THEN 1 ELSE 0 END) AS no_changes
FROM cte_delivered_ord AS cte
WHERE EXISTS(
	SELECT 1 FROM pizza_runner.runner_orders AS r
	WHERE r.order_id = cte.order_id
	AND (
		r.cancellation IS NULL OR
		r.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation')
	)
)
GROUP BY customer_id
ORDER BY customer_id;

-- Q8: How many pizzas were delivered that had both exclusions and extras?
SELECT 
	SUM(CASE WHEN extras IS NOT NULL AND exclusions IS NOT NULL THEN 1 ELSE 0 END) AS delivered_ord_w_changes
FROM pizza_runner.customer_orders AS c
INNER JOIN pizza_runner.runner_orders AS r
	ON c.order_id = r.order_id
WHERE r.cancellation IS NULL OR
	  r.cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation');
	  
-- Q9: What was the total volume of pizzas ordered for each hour of the day?
-- USING DATE_PART(interval, date)
SELECT
  DATE_PART('hour', order_time::TIMESTAMP) AS hour_of_day,
  COUNT(*) AS total_pizza_ord
FROM pizza_runner.customer_orders
WHERE order_time IS NOT NULL
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- Q10: What was the volume of orders for each day of the week?
-- USING TO_CHAR() w/ a 'Day' format to directly output the day name directly from the date field instead of the number index
SELECT
  TO_CHAR(order_time, 'Day') AS day_of_week,
  COUNT(*) AS total_pizza_ord
FROM pizza_runner.customer_orders
WHERE order_time IS NOT NULL
GROUP BY day_of_week, DATE_PART('dow', order_time)
ORDER BY DATE_PART('dow', order_time);