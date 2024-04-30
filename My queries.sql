# Exploring the dataset:

USE magist;
# 1. how many orders are there in the dataset? 
SELECT 
    COUNT(order_id) AS total_orders
FROM
    orders;
    
# 2. are the orders actually delivered? 
SELECT DISTINCT order_status FROM orders;
SELECT 
    order_status, COUNT(*) AS total_orders
FROM
    orders
GROUP BY order_status ORDER BY total_orders DESC;

# 3. Is Magist having user growth? numbers of orders by year and month 
SELECT 
    COUNT(customer_id) AS total_orders,
    YEAR(order_purchase_timestamp) AS year,
    MONTH(order_purchase_timestamp) AS month
FROM
    orders
GROUP BY YEAR(order_purchase_timestamp) , MONTH(order_purchase_timestamp)
ORDER BY year;

# 4. how many products are there on the products table? no duplicates
SELECT 
    COUNT(DISTINCT product_id) AS total_products
FROM
    products;
    
# 5. which are the categories with the most products? how many products in each category? 
  # counting rows in products and grouping them by category 
  

SELECT DISTINCT
    p.product_category_name, t.product_category_name_english
FROM
    products p
        JOIN
    product_category_name_translation t ON p.product_category_name = t.product_category_name;
    
SELECT 
    COUNT(product_id) AS total_products, product_category_name
FROM
    products
GROUP BY product_category_name
ORDER BY total_products DESC;
# combing botht queries (translated name and the amount)
SELECT DISTINCT
    p.product_category_name,
    t.product_category_name_english,
    total_products
FROM
    (
        SELECT
            COUNT(product_id) AS total_products,
            product_category_name
        FROM
            products
        GROUP BY
            product_category_name ORDER BY total_products DESC
    ) AS products_count
    JOIN products p ON products_count.product_category_name = p.product_category_name
    JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name;
    
# 6. how many of the products have been present in actual transactions? products and order_items tables
    
    SELECT 
	count(DISTINCT product_id) AS total_products
FROM
	order_items;

#7. price of the most expensive and cheapest product

SELECT 
    MIN(price) AS cheapest, 
    MAX(price) AS most_expensive
FROM 
	order_items;
    
#8. highest and lowest payment values?
SELECT MAX(payment_value) AS highest, MIN(payment_value) as lowest FROM order_payments;

# max someone has paid for an order:
SELECT
    SUM(payment_value) AS top_order
FROM
    order_payments
GROUP BY
    order_id
ORDER BY
    top_order DESC
LIMIT
    1;USE magist;
    
#Main business questions:
#1. what is the average time between the order being placed and the product being delivered?
SELECT 
    order_purchase_timestamp, order_delivered_customer_date
FROM
    orders; 

SELECT 
    AVG(TIMESTAMPDIFF(SECOND, order_delivered_customer_date, order_purchase_timestamp)) AS average_delivery_time
FROM
    orders
WHERE
    order_delivered_customer_date IS NOT NULL;
    
SELECT 
  CONCAT(
    FLOOR(AVG(TIMESTAMPDIFF(SECOND, order_delivered_customer_date, order_purchase_timestamp)) / (24*3600)), ' days ',
    FLOOR((AVG(TIMESTAMPDIFF(SECOND, order_delivered_customer_date, order_purchase_timestamp)) % (24*3600)) / 3600), ' hours'
  ) AS average_delivery_time
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

#2. how many orders are delivered on time vs. orders delivered with a delay?

#total orders
SELECT COUNT(*) AS total_orders
FROM orders;

#on time
SELECT COUNT(*) AS on_time_orders
FROM orders
WHERE order_delivered_customer_date <= order_estimated_delivery_date;

#on time (percentage)
SELECT 
    (COUNT(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 END) / COUNT(*)) * 100 AS on_time_orders_percentage
FROM 
    orders;

#delayed
SELECT COUNT(*) AS delayed_orders
FROM orders
WHERE order_delivered_customer_date > order_estimated_delivery_date;

#delayed (percentage)
SELECT 
    (COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END) / COUNT(*)) * 100 AS delayed_orders
FROM 
    orders;
    
#not delivered
SELECT COUNT(*) AS not_delivered 
FROM orders
WHERE order_delivered_customer_date IS NULL;

#not delivered (percentage)
SELECT 
    (COUNT(CASE WHEN order_delivered_customer_date IS NULL THEN 1 END) / COUNT(*)) * 100 AS delayed_orders
FROM 
    orders;
    
#all together in (percentage)

SELECT 
    total_orders,
    (not_delivered / total_orders) * 100 AS not_delivered_percentage,
    (delayed_orders / total_orders) * 100 AS delayed_orders_percentage,
    (on_time_orders_ / total_orders) * 100 AS on_time_orders_percentage
FROM (
    SELECT 
        COUNT(*) AS total_orders,
        COUNT(CASE WHEN order_delivered_customer_date IS NULL THEN 1 END) AS not_delivered,
        COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END) AS delayed_orders,
        COUNT(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 END) AS on_time_orders_
    FROM 
        orders
) AS subquery;

#all together in orders
SELECT 
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) AS on_time_orders,
    SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) AS delayed_orders,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS not_delivered 
FROM 
    orders;

# 3. delayed orders patterns 
# geography as a pattern

#total delayed orders
SELECT COUNT(*) AS delayed_orders
FROM orders
WHERE order_delivered_customer_date > order_estimated_delivery_date;

 
#delayed orders per city
SELECT 
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) AS delayed_orders,
    g.city
FROM 
    orders o
JOIN 
    customers c ON o.customer_id = c.customer_id
JOIN 
    geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
GROUP BY 
    g.city ORDER BY delayed_orders DESC;
    

#weight 

SELECT COUNT(*) AS delayed_orders
FROM orders
WHERE order_delivered_customer_date > order_estimated_delivery_date;

SELECT 
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) AS delayed_orders,
    p.product_weight_g
FROM 
    orders o
JOIN 
    order_items i ON o.order_id = i.order_id
JOIN 
    products p ON i.product_id = p.product_id
GROUP BY 
    p.product_weight_g ORDER BY delayed_orders DESC Limit 20;

# length/height/width

SELECT 
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) AS delayed_orders,
    p.product_length_cm, p.product_height_cm, p.product_width_cm
FROM 
    orders o
JOIN 
    order_items i ON o.order_id = i.order_id
JOIN 
    products p ON i.product_id = p.product_id
GROUP BY 
    p.product_length_cm, p.product_height_cm, p.product_width_cm ORDER BY delayed_orders DESC;
    
#category 

SELECT 
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) AS delayed_orders,
    p.product_category_name
FROM 
    orders o
JOIN 
    order_items i ON o.order_id = i.order_id
JOIN 
    products p ON i.product_id = p.product_id
GROUP BY 
    p.product_category_name ORDER BY delayed_orders DESC;

SELECT DISTINCT
    p.product_category_name, t.product_category_name_english
FROM
    products p
        JOIN
    product_category_name_translation t ON p.product_category_name = t.product_category_name;

#all together: name and orders 
SELECT 
    subq.product_category_name,
    subq.product_category_name_english,
    COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) AS delayed_orders
FROM (
    SELECT DISTINCT
        p.product_category_name,
        t.product_category_name_english
    FROM
        products p
    JOIN
        product_category_name_translation t ON p.product_category_name = t.product_category_name
) AS subq
JOIN 
    products p ON p.product_category_name = subq.product_category_name
JOIN 
    order_items i ON i.product_id = p.product_id
JOIN 
    orders o ON o.order_id = i.order_id
GROUP BY 
    subq.product_category_name, subq.product_category_name_english
ORDER BY 
    delayed_orders DESC;