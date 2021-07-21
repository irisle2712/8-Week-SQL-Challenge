/* --------------------
   Case Study Questions:
   Runner and Customer Experience
   --------------------*/

--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
--3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
--4. What was the average distance travelled for each customer?
--5. What was the difference between the longest and shortest delivery times for all orders?
--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
--7. What is the successful delivery percentage for each runner?

/* --------------------
   Answers
   --------------------*/

--Q1: How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
-- Week input automatically takes the start of the week as the Monday date
-- Use DATE_TRUNC() with 'week' input
SELECT 
	DATE_TRUNC('week', registration_date):: DATE + 4 AS registration_week,
	COUNT(*) AS runners_count
FROM pizza_runner.runners
GROUP BY registration_week
ORDER BY registration_week;

--Q2: What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-- Cast pickup_time field into a timestamp & Use DATE_PART()
-- Use AGE func to extract number of minutes from the interval
WITH cte_pickup_minutes AS (
	SELECT 
    	DISTINCT(r.order_id),
     	DATE_PART('minute', AGE(r.pickup_time::TIMESTAMP, c.order_time::TIMESTAMP))::INTEGER AS pickup_minutes
    FROM updated_runner_orders AS r
    INNER JOIN updated_customer_orders AS c
		ON r.order_id = c.order_id
    WHERE r.pickup_time IS NOT NULL
)
SELECT 
	ROUND(AVG(pickup_minutes), 3) AS avg_pickup_min
FROM cte_pickup_minutes;

--Q3: Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT 
	DISTINCT(r.order_id),
	DATE_PART('minute', AGE(r.pickup_time::TIMESTAMP, c.order_time::TIMESTAMP))::INTEGER AS prepare_min,
	COUNT(r.order_id) AS pizza_count
FROM updated_runner_orders AS r
INNER JOIN updated_customer_orders AS c
	ON r.order_id = c.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY r.order_id, prepare_min
ORDER BY r.order_id;

--Q4: What was the average distance travelled for each customer?
SELECT 
	c.customer_id,
	ROUND(AVG(r.distance), 2) AS avg_distance
FROM updated_customer_orders AS c
JOIN updated_runner_orders AS r
	ON c.order_id = r.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY c.customer_id
ORDER BY c.customer_id;

--Q5: What was the difference between the longest and shortest delivery times for all orders?
SELECT 
	MAX(duration) - MIN(duration) AS max_difference
FROM updated_runner_orders;

--Q6: What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
	order_id,
	runner_id,
	DATE_PART('hour', pickup_time) AS hour_of_day,
	distance,
	duration,
	ROUND(distance/(duration/60),1) AS avg_speed
FROM updated_runner_orders
WHERE cancellation IS NULL
ORDER BY order_id;

--Q7: What is the successful delivery percentage for each runner?
SELECT 
	runner_id,
	ROUND(
		SUM(CASE WHEN pickup_time IS NOT NULL THEN 1 ELSE 0 END)*100/COUNT(*)
	) AS successful_percentage
FROM updated_runner_orders
GROUP BY runner_id
ORDER BY runner_id;
