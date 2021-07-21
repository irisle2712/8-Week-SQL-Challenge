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

--Results:
| registration_week        | runners_count |
| ------------------------ | ------------- |
| 2021-01-01T00:00:00.000Z | 2             |
| 2021-01-08T00:00:00.000Z | 1             |
| 2021-01-15T00:00:00.000Z | 1             |

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

--Results:
| avg_pickup_min |
| -------------- |
| 15.625         |

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

--Results:
| order_id | prepare_min | pizza_count |
| -------- | ----------- | ----------- |
| 1        | 10          | 1           |
| 2        | 10          | 1           |
| 3        | 21          | 2           |
| 4        | 29          | 3           |
| 5        | 10          | 1           |
| 7        | 10          | 1           |
| 8        | 20          | 1           |
| 10       | 15          | 2           |

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

--Results:
| customer_id | avg_distance |
| ----------- | ------------ |
| 101         | 20.00        |
| 102         | 16.73        |
| 103         | 23.40        |
| 104         | 10.00        |
| 105         | 25.00        |

--Q5: What was the difference between the longest and shortest delivery times for all orders?
SELECT 
	MAX(duration) - MIN(duration) AS max_difference
FROM updated_runner_orders;

--Results:
| max_difference |
| -------------- |
| 30             |

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

--Results:

| order_id | runner_id | hour_of_day | distance | duration | avg_speed |
| -------- | --------- | ----------- | -------- | -------- | --------- |
| 1        | 1         | 18          | 20       | 32       | 37.5      |
| 2        | 1         | 19          | 20       | 27       | 44.4      |
| 3        | 1         | 0           | 13.4     | 20       | 40.2      |
| 4        | 2         | 13          | 23.4     | 40       | 35.1      |
| 5        | 3         | 21          | 10       | 15       | 40.0      |
| 7        | 2         | 21          | 25       | 25       | 60.0      |
| 8        | 2         | 0           | 23.4     | 15       | 93.6      |
| 10       | 1         | 18          | 10       | 10       | 60.0      |

--Q7: What is the successful delivery percentage for each runner?
SELECT 
	runner_id,
	ROUND(
		SUM(CASE WHEN pickup_time IS NOT NULL THEN 1 ELSE 0 END)*100/COUNT(*)
	) AS successful_percentage
FROM updated_runner_orders
GROUP BY runner_id
ORDER BY runner_id;

--Results:
| runner_id | successful_percentage |
| --------- | --------------------- |
| 1         | 100                   |
| 2         | 75                    |
| 3         | 50                    |
