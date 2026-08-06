/*
===============================================================================
Raport: klienci
===============================================================================
Cel skryptu:
    - Zebrać w jednym widoku wszystko, co warto wiedzieć o kliencie, zamiast
      za każdym razem pisać ten sam zestaw joinów i agregacji od nowa.

W skrócie, widok:
    1. Zbiera podstawowe dane: imię i nazwisko, wiek, numer klienta.
    2. Segmentuje klientów wg grupy wiekowej oraz zachowania zakupowego
       (VIP / Regular / New).
    3. Liczy metryki na poziomie klienta: liczba zamówień, łączna sprzedaż,
       łączna ilość, liczba różnych produktów, długość historii (lifespan).
    4. Dolicza wskaźniki biznesowe: recency (miesiące od ostatniego zamówienia,
       liczone względem GETDATE() - patrz zastrzeżenie w README), średnia
       wartość zamówienia, średni miesięczny wydatek.
===============================================================================
*/

IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_customers AS

WITH base_query AS (
/*-----------------------------------------------------------------------------
1) Zapytanie bazowe: podstawowe kolumny z fact_sales i dim_customers
-----------------------------------------------------------------------------*/
SELECT
    s.order_number,
    s.product_key,
    s.order_date,
    s.sales_amount,
    s.quantity,
    c.customer_key,
    c.customer_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    DATEDIFF(YEAR, c.birthdate, GETDATE()) AS customer_age
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
    ON s.customer_key = c.customer_key
WHERE s.order_date IS NOT NULL
)

, customer_aggregations AS (
/*-----------------------------------------------------------------------------
2) Agregacja: metryki policzone na poziomie pojedynczego klienta
-----------------------------------------------------------------------------*/
SELECT
    customer_key,
    customer_number,
    customer_name,
    customer_age,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    COUNT(product_key) AS total_products,
    MAX(order_date) AS last_order_date,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY
    customer_key,
    customer_number,
    customer_name,
    customer_age
)

SELECT
    customer_key,
    customer_number,
    customer_name,
    customer_age,
    CASE
        WHEN customer_age < 20 THEN 'Under 20'
        WHEN customer_age BETWEEN 20 AND 29 THEN '20-29'
        WHEN customer_age BETWEEN 30 AND 39 THEN '30-39'
        WHEN customer_age BETWEEN 40 AND 49 THEN '40-49'
        WHEN customer_age BETWEEN 50 AND 59 THEN '50-59'
        WHEN customer_age BETWEEN 60 AND 69 THEN '60-69'
        ELSE '70+'
    END AS age_group,
    CASE
        WHEN total_sales > 5000 AND lifespan >= 12 THEN 'VIP'
        WHEN total_sales <= 5000 AND lifespan >= 12 THEN 'Regular'
        ELSE 'New'
    END AS customer_segments,
    last_order_date,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency, -- uwaga: dane historyczne, patrz README
    lifespan,
    -- średnia wartość zamówienia (AOV)
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_value,
    -- średni miesięczny wydatek
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_spend
FROM customer_aggregations;
GO
