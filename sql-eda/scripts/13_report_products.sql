/*
===============================================================================
Raport: produkty
===============================================================================
Cel skryptu:
    - Analogicznie do raportu klientów: jeden widok zbierający wszystko,
      co warto wiedzieć o produkcie, gotowy do bezpośredniego odpytania.

W skrócie, widok:
    1. Zbiera podstawowe dane: nazwa, kategoria, podkategoria, koszt.
    2. Segmentuje produkty wg wygenerowanego przychodu (High-Performer /
       Mid-Range / Low-Performer).
    3. Liczy metryki na poziomie produktu: liczba zamówień, łączna sprzedaż,
       łączna sprzedana ilość, liczba unikalnych klientów, lifespan.
    4. Dolicza wskaźniki biznesowe: recency, średni przychód na zamówienie
       (AOR), średni przychód miesięczny.
===============================================================================
*/

IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

CREATE VIEW gold.report_products AS

WITH base_query AS (
/*-----------------------------------------------------------------------------
1) Zapytanie bazowe: podstawowe kolumny z fact_sales i dim_products
-----------------------------------------------------------------------------*/
SELECT
    s.order_number,
    s.order_date,
    s.customer_key,
    s.sales_amount,
    s.quantity,
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.cost
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
    ON s.product_key = p.product_key
WHERE s.order_date IS NOT NULL -- tylko sprzedaż z poprawną datą zamówienia
)

, product_aggregations AS (
/*-----------------------------------------------------------------------------
2) Agregacja: metryki policzone na poziomie pojedynczego produktu
-----------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
    MAX(order_date) AS last_sales_date,
    COUNT(DISTINCT order_number) AS total_orders,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS avg_selling_price
FROM base_query
GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)

/*-----------------------------------------------------------------------------
  3) Zapytanie końcowe: łączy wszystkie wyniki produktowe w jeden wynik
-----------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sales_date,
    DATEDIFF(MONTH, last_sales_date, GETDATE()) AS recency, -- uwaga: dane historyczne, patrz README
    CASE
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,
    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
    -- średni przychód na zamówienie (AOR)
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_revenue,
    -- średni przychód miesięczny
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue
FROM product_aggregations;
GO
