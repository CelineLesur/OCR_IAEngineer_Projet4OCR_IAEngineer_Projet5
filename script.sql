-- Requete 1 : commandes de moins de 3 mois reçues avec au moins 3 jours de retard (exclusion des commandes annulées)

WITH date_recente AS(
    SELECT MAX(order_purchase_timestamp) AS max_date ,DATE(MAX(order_purchase_timestamp), '-3 months') AS pivot_date
    FROM orders
)

SELECT order_id,customer_id,order_purchase_timestamp,order_estimated_delivery_date,order_delivered_customer_date
FROM orders,date_recente
 WHERE order_status<>'canceled' 
 AND DATE(order_purchase_timestamp) >= pivot_date
 AND DATE(order_estimated_delivery_date, '+3 days') <= DATE(order_delivered_customer_date)

 -- Requete 2 : vendeurs avec un CA de plus de 100 000 reals

WITH total AS (
SELECT seller_id,SUM(price) AS CA
  FROM order_items
  GROUP BY 1
)

SELECT *
FROM total
WHERE CA >100000
ORDER BY 2 DESC

 -- Requete 3 : nouveaux vendeurs (moins de 3 mois d'anciennete) ayant vendus plus de 30 produits

WITH date_recente AS(
    SELECT MAX(order_purchase_timestamp) AS max_date ,DATE(MAX(order_purchase_timestamp), '-3 months') AS pivot_date
    FROM orders
),

seller_exclu AS(
SELECT Distinct seller_id AS s
FROM orders,date_recente
LEFT OUTER JOIN order_items ON order_items.order_id=orders.order_id
WHERE DATE(order_purchase_timestamp) < pivot_date
),

seller_restant AS(
SELECT seller_id
FROM sellers
LEFT OUTER JOIN seller_exclu ON sellers.seller_id=seller_exclu.s
WHERE seller_exclu.s IS NULL
),

total AS (SELECT seller_restant.seller_id,SUM(order_item_id) AS quantite
FROM orders
LEFT OUTER JOIN order_items ON order_items.order_id=orders.order_id
LEFT OUTER JOIN seller_restant ON order_items.seller_id=seller_restant.seller_id
WHERE  order_items.seller_id=seller_restant.seller_id
GROUP BY 1
)

SELECT * 
FROM total
WHERE quantite>30
ORDER BY 2 DESC

 -- Requete 4 : les 5 codes postaux, avec plus de 30 reviews, qui a le pire review score moyen sur les 12 derniers mois

WITH date_recente AS(
    SELECT MAX(order_purchase_timestamp) AS max_date ,DATE(MAX(order_purchase_timestamp), '-12 months') AS pivot_date
    FROM orders
),

nb_review AS(
SELECT customer_zip_code_prefix,COUNT(review_id) AS quantite,AVG(review_score) AS score_moyen
  FROM order_reviews, date_recente
  LEFT OUTER JOIN orders ON order_reviews.order_id=orders.order_id
  LEFT OUTER JOIN customers ON customers.customer_id=orders.customer_id
  WHERE DATE(review_creation_date) >= pivot_date
  GROUP BY 1
)

SELECT * 
FROM nb_review
WHERE quantite > 30
ORDER BY 3
LIMIT 5
