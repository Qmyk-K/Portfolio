/*
===============================================================================
Kluczowe miary biznesowe
===============================================================================
Cel skryptu:
    - Policzyć podstawowe zagregowane liczby (sumy, średnie), które dają
      szybki obraz całości biznesu, zanim zejdzie się głębiej w szczegóły.

Wykorzystane funkcje:
    - COUNT(), SUM(), AVG()
===============================================================================
*/

-- Łączna wartość sprzedaży
SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales;

-- Łączna liczba sprzedanych sztuk
SELECT SUM(quantity) AS total_quantity FROM gold.fact_sales;

-- Średnia cena sprzedaży
SELECT AVG(price) AS avg_price FROM gold.fact_sales;

-- Liczba zamówień: bez i z odfiltrowaniem duplikatów numeru zamówienia
SELECT COUNT(order_number) AS total_orders FROM gold.fact_sales; -- liczy wiersze (pozycje zamówień)
SELECT COUNT(DISTINCT order_number) AS total_orders FROM gold.fact_sales; -- liczy faktyczne zamówienia

-- Liczba produktów
SELECT COUNT(product_name) AS total_products FROM gold.dim_products;

-- Liczba klientów w ogóle
SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers;

-- Liczba klientów, którzy faktycznie złożyli zamówienie
SELECT COUNT(DISTINCT customer_key) AS total_customers FROM gold.fact_sales;

-- Jedno zapytanie zbierające wszystkie kluczowe miary w formie raportu
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', COUNT(DISTINCT product_name) FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(customer_key) FROM gold.dim_customers;
