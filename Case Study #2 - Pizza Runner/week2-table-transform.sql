/* --------------------
   Table Transform
   --------------------*/

-- Check data types
-- Table 'customer_orders'
SELECT
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'customer_orders';

-- Table 'runner_orders'
SELECT
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'runner_orders';

-- Clean and create new view the customer_orders table
DROP VIEW IF EXISTS updated_customer_orders;
CREATE VIEW updated_customer_orders AS (
	SELECT 
		order_id,
		customer_id,
		pizza_id,
		(CASE WHEN customer_orders.exclusions = '' OR exclusions = 'null' THEN NULL
		 ELSE exclusions
		 END) AS exclusions,
		(CASE WHEN customer_orders.extras = '' OR extras = 'null' THEN NULL
		 ELSE extras
		 END) AS extras,
		order_time
	FROM pizza_runner.customer_orders
);
SELECT * FROM updated_customer_orders;

--Results: 
| order_id | customer_id | pizza_id | exclusions | extras | order_time               |
| -------- | ----------- | -------- | ---------- | ------ | ------------------------ |
| 1        | 101         | 1        |            |        | 2020-01-01T18:05:02.000Z |
| 2        | 101         | 1        |            |        | 2020-01-01T19:00:52.000Z |
| 3        | 102         | 1        |            |        | 2020-01-02T12:51:23.000Z |
| 3        | 102         | 2        |            |        | 2020-01-02T12:51:23.000Z |
| 4        | 103         | 1        | 4          |        | 2020-01-04T13:23:46.000Z |
| 4        | 103         | 1        | 4          |        | 2020-01-04T13:23:46.000Z |
| 4        | 103         | 2        | 4          |        | 2020-01-04T13:23:46.000Z |
| 5        | 104         | 1        |            | 1      | 2020-01-08T21:00:29.000Z |
| 6        | 101         | 2        |            |        | 2020-01-08T21:03:13.000Z |
| 7        | 105         | 2        |            | 1      | 2020-01-08T21:20:29.000Z |
| 8        | 102         | 1        |            |        | 2020-01-09T23:54:33.000Z |
| 9        | 103         | 1        | 4          | 1, 5   | 2020-01-10T11:22:59.000Z |
| 10       | 104         | 1        |            |        | 2020-01-11T18:34:49.000Z |
| 10       | 104         | 1        | 2, 6       | 1, 4   | 2020-01-11T18:34:49.000Z |

-- Clean and create new view the runner_orders table
-- Check https://bit.ly/2VNtdoz and https://topdev.vn/blog/regex-la-gi/ for expressions
DROP VIEW IF EXISTS updated_runner_orders;
CREATE VIEW updated_runner_orders AS (
	SELECT
		order_id,
        runner_id,
		(CASE WHEN pickup_time = '' OR pickup_time = 'null' THEN NULL
		 ELSE pickup_time 
		 END :: TIMESTAMP) AS pickup_time,
		(CASE WHEN distance = 'null' THEN NULL
		 ELSE REGEXP_REPLACE(distance,'[a-z]+', '')
		 END :: NUMERIC) AS distance,
		(CASE WHEN duration = 'null' THEN NULL
		 ELSE REGEXP_REPLACE(duration,'[a-z]+', '')
		 END :: NUMERIC) AS duration,
	    (CASE WHEN cancellation = '' OR cancellation = 'null' THEN NULL
		 ELSE cancellation
		 END) AS cancellation
	FROM pizza_runner.runner_orders
);
SELECT * FROM updated_runner_orders

--Results: 
| order_id | runner_id | pickup_time         | distance | duration | cancellation            |
| -------- | --------- | ------------------- | -------- | -------- | ----------------------- |
| 1        | 1         | 2020-01-01 18:15:34 | 20       | 32       |                         |
| 2        | 1         | 2020-01-01 19:10:54 | 20       | 27       |                         |
| 3        | 1         | 2020-01-02 00:12:37 | 13.4     | 20       |                         |
| 4        | 2         | 2020-01-04 13:53:03 | 23.4     | 40       |                         |
| 5        | 3         | 2020-01-08 21:10:57 | 10       | 15       |                         |
| 6        | 3         |                     |          |          | Restaurant Cancellation |
| 7        | 2         | 2020-01-08 21:30:45 | 25       | 25       |                         |
| 8        | 2         | 2020-01-10 00:15:02 | 23.4     | 15       |                         |
| 9        | 2         |                     |          |          | Customer Cancellation   |
| 10       | 1         | 2020-01-11 18:50:20 | 10       | 10       |        
