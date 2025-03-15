/*Create a View to Show Order Information*/
CREATE OR REPLACE VIEW ORDER_ANALYSIS AS
SELECT
	O.USER_ID AS "User_ID",
	O.ORDER_ID AS "Order_ID",
	O.ORDER_NUMBER AS "Order#",
	CASE
		WHEN O.ORDER_DOW = 0 THEN 'Sunday'
		WHEN O.ORDER_DOW = 1 THEN 'Monday'
		WHEN O.ORDER_DOW = 2 THEN 'Tuesday'
		WHEN O.ORDER_DOW = 3 THEN 'Wednesday'
		WHEN O.ORDER_DOW = 4 THEN 'Thursday'
		WHEN O.ORDER_DOW = 5 THEN 'Friday'
		WHEN O.ORDER_DOW = 6 THEN 'Saturday'
	END AS "Ordered Day of Week",
	O.ORDER_HOUR_OF_DAY AS "Ordered Hour of Day",
	O.DAYS_SINCE_PRIOR_ORDER AS "Days Since Last Order",
	OP.PRODUCT_ID AS "Product_ID",
	P.PRODUCT_NAME AS "Product_Name",
	OP.ADD_TO_CART_ORDER AS "No. of Products Added to Cart",
	CASE
		WHEN OP.REORDERED = 1 THEN 'Yes'
		ELSE 'No'
	END AS "Product Re-ordered Before"
FROM
	ORDERS O,
	ORDER_PRODUCTS OP,
	PRODUCTS P
WHERE
	O.ORDER_ID = OP.ORDER_ID
	AND OP.PRODUCT_ID = P.PRODUCT_ID;

/* CREATE A VIEW FOR PRODUCt Analysis that groups the orders by product and finds the total number of times each product was purchased,
the total number of times each product was reordered, and the average number of times each product was added to a cart*/
CREATE OR REPLACE VIEW PRODUCT_ANALYSIS AS
SELECT
	P.PRODUCT_ID as "Product ID",
	P.PRODUCT_NAME as "Product Name",
	COUNT(ORDER_ID) AS "Number of orders",
	SUM(REORDERED) AS "Total Reorders",
	CAST(AVG(ADD_TO_CART_ORDER) AS NUMERIC(10, 2)) AS "Average no. of times product added to cart"
FROM
	PRODUCTS P,
	ORDER_PRODUCTS OP	
WHERE OP.PRODUCT_ID = P.PRODUCT_ID
GROUP BY
	P.PRODUCT_ID,PRODUCT_NAME;

/*Create a View that groups the orders by department and finds the total number of products purchased, 
the total number of unique products purchased, the total number of products purchased on weekdays vs weekends, and the average time of day that products in each department are ordered.*/
CREATE OR REPLACE VIEW DEPARTMENT_ANALYSIS AS 
SELECT
	D.DEPARTMENT as "Department Name",
	--STRING_AGG(DISTINCT PRODUCT_NAME, ','),
	COUNT(P.PRODUCT_ID) AS "Total Products Purchased",
	COUNT(DISTINCT P.PRODUCT_ID) AS "Unique Products Purchased",
	SUM(
		CASE
			WHEN ORDER_DOW NOT IN (0, 6) THEN 1
			ELSE 0
		END
	) AS "Total Orders on weekdays",
	SUM(
		CASE
			WHEN ORDER_DOW IN (0, 6) THEN 1
			ELSE 0
		END
	) AS "Total Orders on weekends",
	to_char(to_timestamp(AVG(order_hour_of_day) * 60),'MI:SS') as "Average Time of Day of Purchase"
FROM
	ORDERS O,
	ORDER_PRODUCTS OP,
	PRODUCTS P,
	DEPARTMENTS D
WHERE
	O.ORDER_ID = OP.ORDER_ID
	AND OP.PRODUCT_ID = P.PRODUCT_ID
	AND P.DEPARTMENT_ID = D.DEPARTMENT_ID
GROUP BY
	D.DEPARTMENT_ID,
	D.DEPARTMENT;

--Create a View that groups the orders by aisle and finds the top 10 most popular aisles,total product purchased and unique Product purchases
CREATE OR REPLACE VIEW TOP_AISLE_ANALYSIS AS
SELECT
	A.AISLE AS "Aisle Name",
	COUNT(P.PRODUCT_ID) AS "Total Products Purchased in Aisle",
	COUNT(DISTINCT P.PRODUCT_ID) AS "Total Unique Products Purchased in Aisle"
FROM
	ORDERS O,
	ORDER_PRODUCTS OP,
	PRODUCTS P,
	AISLES A
WHERE
	O.ORDER_ID = OP.ORDER_ID
	AND OP.PRODUCT_ID = P.PRODUCT_ID
	AND P.AISLE_ID = A.AISLE_ID
GROUP BY
	A.AISLE_ID
ORDER BY
	COUNT(P.PRODUCT_ID) DESC
LIMIT 10;

--Create a function to generate an Analysis CSV based on fixed input set:Orders,Products,Departments,Aisles and save to the path requested
CREATE OR REPLACE FUNCTION GENERATE_ANALYSIS_CSV (FILE_TYPE TEXT, LOC TEXT) RETURNS TEXT AS $$
  declare
  p_msg varchar(1000);
  p_qry varchar(1000);
  v_name varchar(100);
  BEGIN
  	case
		when upper(file_type) = 'ORDERS' THEN
	  		v_name := 'ORDER_ANALYSIS';
		when upper(file_type) = 'PRODUCTS' THEN
	  		v_name := 'PRODUCT_ANALYSIS';
		when upper(file_type) = 'DEPARTMENTS' THEN
	  		v_name := 'DEPARTMENT_ANALYSIS';
		when upper(file_type) = 'AISLES' THEN
	  		v_name := 'TOP_AISLE_ANALYSIS';
		ELSE
	  		p_msg := 'Incorrect File Type. Please Choose from: Orders,Products,Departments,Aisles';
			return p_msg;
		END CASE;
	  	BEGIN  --Exception Handling
		  p_qry := 'copy (select * from '||v_name||') to '''||loc||''' DELIMITER '','' CSV HEADER';
		  execute p_qry;
		  p_msg := 'File Successfully Created.';
	  	EXCEPTION WHEN OTHERS THEN
		  raise 'File Creation Failed.Error Message: %. %Query Generated:%',SQLERRM,chr(10),p_qry; --chr(10) for line break
		END;
	return p_msg;
  END;
  $$ LANGUAGE PLPGSQL;
	
