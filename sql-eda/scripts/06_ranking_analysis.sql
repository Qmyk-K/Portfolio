/*
===============================================================================
Analiza rankingowa
===============================================================================
Cel skryptu:
    - Wyłonić liderów i maruderów: które produkty i którzy klienci wypadają
      najlepiej, a które najgorzej na tle reszty.

Wykorzystane funkcje:
    - Funkcje okienkowe: RANK(), DENSE_RANK(), ROW_NUMBER(), TOP
    - GROUP BY, ORDER BY
===============================================================================
*/

-- 5 produktów generujących najwyższy przychód - wersja prosta
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- To samo, ale przez funkcję okienkową RANK() - bardziej elastyczne
-- (np. łatwo zmienić na "top N per kategoria" przez dodanie PARTITION BY)
SELECT *
FROM (
    SELECT
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,
        RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.product_name
) AS ranked_products
WHERE rank_products <= 5;

-- 5 najsłabiej sprzedających się produktów
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue;

-- 10 klientów generujących najwyższy przychód
SELECT TOP 10
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_revenue DESC;

-- 3 klientów z najmniejszą liczbą złożonych zamówień
SELECT TOP 3
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_orders;
