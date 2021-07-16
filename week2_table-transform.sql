/* --------------------
   Table Transform
   --------------------*/

-- Check data types
-- Clean and update the customer_orders table
UPDATE pizza_runner.customer_orders
SET 
	exclusions = 
		(CASE WHEN customer_orders.exclusions = ''
		 OR exclusions = 'null' THEN NULL
		 ELSE exclusions
		 END),	
	extras = 
		(CASE WHEN customer_orders.extras = ''
		 OR extras = 'null' THEN NULL
		 ELSE extras
		 END)
RETURNING *;

-- Clean and update the runner_orders table
-- Check https://bit.ly/2VNtdoz and https://topdev.vn/blog/regex-la-gi/ for expressions
UPDATE pizza_runner.runner_orders
SET
	pickup_time =
		(CASE WHEN pickup_time = 'null' THEN NULL
		 ELSE pickup_time::TIMESTAMP
		 END),
	distance = 
		(CASE WHEN distance = 'null' THEN NULL
		 ELSE REGEXP_REPLACE(distance, '[a-z]+', '')::NUMERIC
		 END),
	duration = 
		 (CASE WHEN duration = 'null' THEN NULL
		  ELSE REGEXP_REPLACE(duration, '[a-z]+', '')::NUMERIC
		  END),
    cancellation =
		 (CASE WHEN cancellation = 'null' 
		  OR cancellation = '' THEN NULL
		  ELSE cancellation
		  END)
RETURNING *;