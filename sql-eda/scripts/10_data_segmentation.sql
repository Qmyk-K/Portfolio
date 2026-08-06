/*
===============================================================================
Segmentacja danych
===============================================================================
Cel skryptu:
    - Podzielić produkty i klientów na sensowne grupy, zamiast patrzeć
      na każdy rekord osobno - łatwiej wtedy o wnioski i rekomendacje.

Wykorzystane funkcje:
    - CASE: definiuje logikę segmentacji
    - GROUP BY: grupuje dane w segmenty
===============================================================================
*/

-- Podział produktów na przedziały kosztowe i policzenie, ile produktów
-- wpada w każdy przedział
WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        cost,
        CASE
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM gold.dim_products
)
SELECT
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;

-- Podział klientów na trzy segmenty wg zachowań zakupowych:
--   VIP     - historia min. 12 miesięcy i wydane ponad 5000
--   Regular - historia min. 12 miesięcy, ale wydane 5000 lub mniej
--   New     - historia krótsza niż 12 miesięcy
-- i policzenie liczby klientów w każdym segmencie
WITH customer_spending AS (
    SELECT
        c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order,
        DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
)
SELECT
    customer_segment,
    COUNT(customer_key) AS total_customers
FROM (
    SELECT
        customer_key,
        CASE
            WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
            WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_spending
) AS segmented_customers
GROUP BY customer_segment
ORDER BY total_customers DESC;
