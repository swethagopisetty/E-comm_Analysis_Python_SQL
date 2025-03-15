/*Create a View to Show Order Information*/
CREATE OR REPLACE VIEW ORDER_ANALYSIS AS
SELECT
	o.order_id, o.order_number, o.order_dow, o.order_hour_of_day, o.days_since_prior_order,
           op.product_id, op.add_to_cart_order, op.reordered,
           p.product_name, p.aisle_id, p.department_id
FROM
	ORDERS O,
	ORDER_PRODUCTS OP,
	PRODUCTS P
WHERE
	O.ORDER_ID = OP.ORDER_ID
	AND OP.PRODUCT_ID = P.PRODUCT_ID;

/*Create a view for Product Analysis that groups the orders by product and finds the total number of times each product was purchased,
the total number of times each product was reordered, and the average number of times each product was added to a cart*/
CREATE OR REPLACE VIEW PRODUCT_ANALYSIS AS
select product_id,product_name,count(order_id) as "Number of orders",sum(reordered) as "Total Reorders",cast(avg(add_to_cart_order) as numeric(10,2)) as "Average time product added to cart" from order_products group by product_id,product_name;


/*Create a View that groups the orders by department and finds the total number of products purchased, 
the total number of unique products purchased, the total number of products purchased on weekdays vs weekends, and the average time of day that products in each department are ordered.*/
CREATE OR REPLACE VIEW DEPARTMENT_ANALYSIS AS 
SELECT
	D.DEPARTMENT,
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
select A.AISLE,count(P.PRODUCT_ID) as "Total Products Purchased in Aisle",count(distinct P.PRODUCT_ID) as "Total Unique Products Purchased in Aisle"
FROM
	ORDERS O,
	ORDER_PRODUCTS OP,
	PRODUCTS P,
	AISLES A
WHERE
	O.ORDER_ID = OP.ORDER_ID
	AND OP.PRODUCT_ID = P.PRODUCT_ID
	AND P.AISLE_ID = A.AISLE_ID
	group by A.AISLE_ID
	ORDER BY count(P.PRODUCT_ID) desc
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
		  p_qry := 'copy (select * from ORDER_ANALYSIS) to '''||loc||''' DELIMITER '','' CSV HEADER';
		  execute p_qry;
		  p_msg := 'File Successfully Created.';
	  	EXCEPTION WHEN OTHERS THEN
		  raise 'File Creation Failed.Error Message: %. %Query Generated:%',SQLERRM,chr(10),p_qry; ---chr(10) for line break
		END;
	return p_msg;
  END;
  $$ LANGUAGE PLPGSQL;

	
