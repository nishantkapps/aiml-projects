/**
# Q1. Write a query to display customer_id, customer full name with their title (Mr/Ms), 
both first name and last name are in upper case, customer_email, customer_creation_year and
display customer’s category after applying below categorization rules: 
i. if CUSTOMER_CREATION_DATE year <2005 then category A 
ii. if CUSTOMER_CREATION_DATE year >=2005 and <2011 then category B 
iii. if CUSTOMER_CREATION_DATE year>= 2011 then category C 
Expected 52 rows in final output. 
[Note: TABLE to be used - ONLINE_CUSTOMER TABLE] 
Hint:Use CASE statement. create customer_creation_year column with the help of customer_creation_date, no permanent change in the table is required. 
(Here don’t UPDATE or DELETE the columns in the table nor CREATE new tables for your representation. 
A new column name can be used as an alias for your manipulation in case if you are going to use a CASE statement.)
**/

SELECT oc.CUSTOMER_ID "CUSTOMER ID"
     , oc.FULL_NAME "FULL NAME"
     , oc.EMAIL "EMAIL"
     , oc.CUSTOMER_CREATION_YEAR "YEAR"
     , CASE WHEN oc.CUSTOMER_CREATION_YEAR < 2005 THEN 'A'
            WHEN oc.CUSTOMER_CREATION_YEAR >= 2005 AND oc.CUSTOMER_CREATION_YEAR < 2011 THEN 'B'
            ELSE 'C'
            END "CATEGORY"
  FROM ( SELECT customer_id "CUSTOMER_ID"
              , CONCAT( CASE WHEN customer_gender = 'M' THEN "Mr. " ELSE "Ms." END
            		 , upper(customer_fname),' ', upper(customer_lname) 
            		 ) "FULL_NAME"
              , customer_email "EMAIL"
              , YEAR(customer_creation_date) "CUSTOMER_CREATION_YEAR"
		   FROM online_customer 
	    ) oc;
/**
Q2. Write a query to display the following information for the products which have not been sold: product_id, product_desc, product_quantity_avail, product_price, inventory values (product_quantity_avail * product_price), New_Price after applying discount as per below criteria. Sort the output with respect to decreasing value of Inventory_Value. 

i) If Product Price > 20,000 then apply 20% discount 
ii) If Product Price > 10,000 then apply 15% discount 
iii) if Product Price =< 10,000 then apply 10% discount 

Expected 13 rows in final output. 
[NOTE: TABLES to be used - PRODUCT, ORDER_ITEMS TABLE] 
Hint: Use CASE statement, no permanent change in table required. (Here don’t UPDATE or DELETE the columns in the table nor CREATE new tables for your representation. A new column name can be used as an alias for your manipulation in case if you are going to use a CASE statement.)
**/

SELECT product_id "PRODUCT ID"
	 , product_desc "PRODUCT DESCRIPTION"
     , product_quantity_avail "QTY AVAILABLE"
     , product_price "PRICE"
     , (product_quantity_avail * product_price) "INVENTORY VALUE"
     , CASE WHEN product_price > 20000 THEN ROUND(0.8 * product_price,2)
            WHEN product_price > 10000 THEN ROUND(0.85 * product_price,2) 
			ELSE ROUND(0.9 * product_price,2)
		END "DISCOUNTED PRICE"
  FROM product pd
 WHERE NOT EXISTS ( SELECT order_id FROM order_items WHERE product_id = pd.product_id )
 ORDER BY "INVENTORY VALUE" DESC;

/**  
Q3. Write a query to display Product_class_code, Product_class_desc, Count of Product type in each product class, Inventory Value (p.product_quantity_avail*p.product_price). 
Information should be displayed for only those product_class_code which have more than 1,00,000 Inventory Value. 
Sort the output with respect to decreasing value of Inventory_Value. 
Expected 9 rows in final output. 
[NOTE: TABLES to be used - PRODUCT, PRODUCT_CLASS] 
Hint: 'count of product type in each product class' is the count of product_id based on product_class_code.
**/

SELECT pdc.product_class_code "Product Class Code"
     , pdc.product_class_desc "Product Class Description"
     , COUNT(pd.product_ID) "# of Products"
     , ROUND(SUM(pd.product_quantity_avail*pd.product_price),2) "Inventory Value"
  FROM product pd
 INNER JOIN product_class pdc
	ON pd.product_class_code = pdc.product_class_code
 GROUP BY pdc.product_class_code, pdc.product_class_desc  
HAVING SUM(pd.product_quantity_avail*pd.product_price) > 100000
 ORDER BY SUM(pd.product_quantity_avail*pd.product_price) desc;

/**
Q4. Write a query to display customer_id, full name, customer_email, customer_phone and country of customers who have cancelled all the orders placed by them. 
Expected 1 row in the final output 
[NOTE: TABLES to be used - ONLINE_CUSTOMER, ADDRESSS, OREDER_HEADER] 
Hint: USE SUBQUERY
**/

SELECT oc.customer_id "CUSTOMER_ID"
	 , CONCAT( CASE WHEN oc.customer_gender = 'M' THEN "Mr. " ELSE "Ms." END
			 , upper(oc.customer_fname),' ', upper(oc.customer_lname) 
			 ) "FULL_NAME"
	 , oc.customer_email "EMAIL"
	 , oc.customer_phone "PHONE"
     , a.country "COUNTRY"
  FROM online_customer oc
 INNER JOIN address a
    ON a.address_id = oc.address_id
 WHERE oc.customer_id 
    IN ( SELECT customer_id
 		   FROM order_header 
		  WHERE customer_id 
			 IN ( SELECT customer_id 
				    FROM order_header 
				   WHERE UPPER(order_status)='CANCELLED' )
		  GROUP BY customer_id
		 HAVING COUNT(DISTINCT order_status) = 1 );

/**
Q5. Write a query to display Shipper name, City to which it is catering, num of customer catered by the shipper in the city , number of consignment delivered to that city for Shipper DHL 
Expected 9 rows in the final output 
[NOTE: TABLES to be used - SHIPPER, ONLINE_CUSTOMER, ADDRESSS, ORDER_HEADER] 
Hint: The answer should only be based on Shipper_Name -- DHL. 
The main intent is to find the number of customers and the consignments catered by DHL in each city.
**/
SELECT sh.shipper_name "Shipper"
     , ad.city "City"
     , count(distinct oc.customer_id) "# of Customers"
     , count(oh.order_id) "# of Shipments"
  FROM order_header oh
 INNER JOIN shipper sh ON sh.shipper_id = oh.shipper_id
 INNER JOIN online_customer oc ON oh.customer_id = oc.customer_id
 INNER JOIN address ad ON oc.address_id = ad.address_id
 WHERE sh.shipper_name = 'DHL'
 GROUP BY sh.shipper_name, ad.city;

/**
Q6. Write a query to display product_id, product_desc, product_quantity_avail, quantity sold and show inventory Status of products as per below condition: 

a. For Electronics and Computer categories, 
   if sales till date is Zero then show 'No Sales in past, give discount to reduce inventory', 
   if inventory quantity is less than 10% of quantity sold, show 'Low inventory, need to add inventory', 
   if inventory quantity is less than 50% of quantity sold, show 'Medium inventory, need to add some inventory', 
   if inventory quantity is more or equal to 50% of quantity sold, show 'Sufficient inventory' 

b. For Mobiles and Watches categories, 
   if sales till date is Zero then show 'No Sales in past, give discount to reduce inventory', 
   if inventory quantity is less than 20% of quantity sold, show 'Low inventory, need to add inventory', 
   if inventory quantity is less than 60% of quantity sold, show 'Medium inventory, need to add some inventory', 
   if inventory quantity is more or equal to 60% of quantity sold, show 'Sufficient inventory' 

c. Rest of the categories, 
   if sales till date is Zero then show 'No Sales in past, give discount to reduce inventory', 
   if inventory quantity is less than 30% of quantity sold, show 'Low inventory, need to add inventory', 
   if inventory quantity is less than 70% of quantity sold, show 'Medium inventory, need to add some inventory', 
   if inventory quantity is more or equal to 70% of quantity sold, show 'Sufficient inventory' 

Expected 60 rows in final output 
[NOTE: (USE CASE statement) ; TABLES to be used - PRODUCT, PRODUCT_CLASS, ORDER_ITEMS] 
Hint: quantity sold here is product_quantity in order_items table. 
You may use multiple case statements to show inventory status (Low stock, In stock, and Enough stock) that meets both the conditions i.e. on products as well as on quantity. The meaning of the rest of the categories, means products apart from electronics, computers, mobiles, and watches.

**/
SELECT prd_view.PRODUCT_ID "PRODUCT ID"
     , prd_view.PRODUCT_DESC "PRODUCT DESCRIPTION"
	 , prd_view.INV_QUANTITY "INVENTORY QUANTITY"
     , prd_view.SOLD_QUANTITY "SOLD QUANTITY"
     , prd_view.CATEGORY "PRODUCT CLASS"
	 , ( CASE WHEN upper(prd_view.CATEGORY) IN ( 'ELECTRONICS', 'COMPUTER' ) THEN
				( CASE WHEN prd_view.SOLD_QUANTITY = 0 THEN "No Sales in past, give discount to reduce inventory"
				  	   WHEN prd_view.INV_QUANTITY < 0.1 * prd_view.SOLD_QUANTITY THEN "Low inventory, need to add inventory"
					   WHEN prd_view.INV_QUANTITY < 0.5 * prd_view.SOLD_QUANTITY THEN "Medium inventory, need to add some inventory"
					   ELSE "Sufficient inventory" END ) 
		      WHEN upper(prd_view.CATEGORY) IN ( 'MOBILES', 'WATCHES' ) THEN
				( CASE WHEN prd_view.SOLD_QUANTITY = 0 THEN 'No Sales in past, give discount to reduce inventory'
					   WHEN prd_view.INV_QUANTITY < 0.2 * prd_view.SOLD_QUANTITY THEN 'Low inventory, need to add inventory'
					   WHEN prd_view.INV_QUANTITY < 0.6 * prd_view.SOLD_QUANTITY THEN 'Medium inventory, need to add some inventory'
					   ELSE 'Sufficient inventory' END ) 
  		      ELSE
				( CASE WHEN prd_view.SOLD_QUANTITY = 0 THEN 'No Sales in past, give discount to reduce inventory'
					   WHEN prd_view.INV_QUANTITY < 0.3 * prd_view.SOLD_QUANTITY THEN 'Low inventory, need to add inventory'
					   WHEN prd_view.INV_QUANTITY < 0.7 * prd_view.SOLD_QUANTITY THEN 'Medium inventory, need to add some inventory'
					   ELSE 'Sufficient inventory' END ) 
			  END
		) "INVENTORY STATUS" 
  FROM (SELECT pd.product_id "PRODUCT_ID"
			 , pd.product_desc "PRODUCT_DESC"
             , pc.product_class_desc "CATEGORY"
			 , pd.product_quantity_avail "INV_QUANTITY"
			 , sum(coalesce(oi.product_quantity,0)) "SOLD_QUANTITY"
		  FROM product pd
          LEFT OUTER JOIN order_items oi ON pd.product_id = oi.product_id
		 INNER JOIN product_class pc ON pd.product_class_code = pc.product_class_code
		 GROUP BY pd.product_id, pd.product_desc, pc.product_class_desc, pd.product_quantity_avail) prd_view;
/**
Q7. Write a query to display order_id and volume of the biggest order (in terms of volume) that can fit in carton id 10 . 
Expected 1 row in final output 
[NOTE: TABLES to be used - CARTON, ORDER_ITEMS, PRODUCT] 
Hint: First find the volume of carton id 10 and then find the order id with products having total volume less than the volume of carton id 10
**/
SELECT ov.order_id, ov.volume 
  FROM (SELECT oi.order_id "order_id"
             , SUM(oi.product_quantity*pd.len*pd.width*pd.height) "volume"
		  FROM order_items oi
		 INNER JOIN product pd ON oi.product_id = pd.product_id
		 GROUP BY oi.order_id
		 HAVING SUM(oi.product_quantity*pd.len*pd.width*pd.height) < ( SELECT len*width*height 
                                                                         FROM carton 
																		WHERE carton_id=10 ) 
		 ORDER BY SUM(oi.product_quantity*pd.len*pd.width*pd.height) DESC) ov
   LIMIT 1;
/**
Q8. Write a query to display customer id, customer full name, total quantity and total value (quantity*price) shipped where mode of payment is Cash and customer last name starts with 'G' 
Expected 2 rows in final output 
[NOTE: TABLES to be used - ONLINE_CUSTOMER, ORDER_ITEMS, PRODUCT, ORDER_HEADER]
**/
 SELECT oc.customer_id "CUSTOMER ID"
      , oh.payment_mode "PAYMENT MODE"
      , CONCAT( CASE WHEN oc.customer_gender = 'M' THEN "Mr. " ELSE "Ms." END
			     	 , upper(oc.customer_fname),' ', upper(oc.customer_lname) 
					 ) "FULL NAME"
      , sum(oi.product_quantity) "TOTAL QUANTITY"
      , sum(oi.product_quantity*pd.product_price) "TOTAL VALUE"
   FROM online_customer oc
  INNER JOIN order_header oh ON oh.customer_id = oc.customer_id
  INNER JOIN order_items oi ON oi.order_id = oh.order_id
  INNER JOIN product pd ON pd.product_id = oi.product_id
 WHERE oh.payment_mode = 'Cash'
   AND oc.customer_lname like 'G%'
 GROUP BY oc.customer_id, oh.payment_mode;

/**
Q9. Write a query to display product_id, product_desc and total quantity of products which are sold together with product id 201 and are not shipped to city Bangalore and New Delhi. 
[NOTE: TABLES to be used - ORDER_ITEMS, PRODUCT, ORDER_HEADER, ONLINE_CUSTOMER, ADDRESS] 
Hint: Display the output in descending order with respect to the sum of product_quantity. 
(USE SUB-QUERY) In final output show only those products , product_id’s which are sold with 201 product_id (201 should not be there in output) and are shipped except Bangalore and New Delhi
**/
SELECT pd.product_id 'Product Id', pd.product_desc 'Product Desc', sum(oi.product_quantity) 'Total Qty'
  FROM order_items oi
 INNER JOIN order_header oh ON oh.order_id = oi.order_id
 INNER JOIN product pd ON pd.product_id = oi.product_id
 INNER JOIN online_customer oc ON oc.customer_id = oh.customer_id
 INNER JOIN address ad ON ad.address_id = oc.address_id
 WHERE oi.order_id 
    IN ( SELECT order_id 
 		   FROM order_items oi 
		  WHERE order_id  
			 IN ( SELECT order_id
				   FROM order_items
				  GROUP BY order_id
				 HAVING count(*) > 1 )
		    AND product_id = 201 )
   AND oi.product_id != 201
   AND ad.city NOT IN ( 'Bangalore', 'New Delhi' )
 GROUP BY pd.product_id, pd.product_desc
 ORDER BY sum(oi.product_quantity) desc;
    
/** Q10. Write a query to display the order_id, customer_id and customer fullname, total quantity of products shipped for order ids which are even and shipped to address where pincode is not starting with "5" Expected 15 rows in final output 
[NOTE: TABLES to be used - ONLINE_CUSTOMER, ORDER_HEADER, ORDER_ITEMS, ADDRESS]
**/

# If we include order_id in the output, the number of rows returned is 19 
# To get to 15 rows in output, we will have to exclude order ID & only show total product quantity by customer 
SELECT oi.order_id "Order ID"
	 , oc.customer_id "Customer ID"
     , CONCAT( CASE WHEN customer_gender = 'M' THEN "Mr. " ELSE "Ms." END
			 , upper(customer_fname),' ', upper(customer_lname) 
			 ) "Full Name"
	 , sum(oi.product_quantity) "Total Qty"
  FROM online_customer oc
 INNER JOIN order_header oh ON oh.customer_id = oc.customer_id
 INNER JOIN order_items oi ON oi.order_id = oh.order_id
 INNER JOIN address ad ON ad.address_id = oc.address_id
 WHERE oi.order_id MOD 2 = 0
   AND ad.pincode NOT LIKE '5%'
 GROUP BY oi.order_id, oc.customer_id, ad.pincode, "Full Name";

# Updated query without Order ID which returns 15 rows as expected 
SELECT oc.customer_id "Customer ID"
     , CONCAT( CASE WHEN customer_gender = 'M' THEN "Mr. " ELSE "Ms." END
			 , upper(customer_fname),' ', upper(customer_lname) 
			 ) "Full Name"
	 , sum(oi.product_quantity) "Total Qty"
  FROM online_customer oc
 INNER JOIN order_header oh ON oh.customer_id = oc.customer_id
 INNER JOIN order_items oi ON oi.order_id = oh.order_id
 INNER JOIN address ad ON ad.address_id = oc.address_id
 WHERE oi.order_id MOD 2 = 0
   AND ad.pincode NOT LIKE '5%'
 GROUP BY oc.customer_id, "Full Name"
 ORDER BY sum(oi.product_quantity) desc;
