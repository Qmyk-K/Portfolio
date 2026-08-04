/*
===============================================================================
Skrypt: quality_checks_gold.sql
===============================================================================
Cel skryptu:
    Kontrola warstwy gold: unikalność kluczy surogatnych w wymiarach oraz
    integralność referencyjna między fact_sales a wymiarami. To ostatnia
    linia obrony przed tym, żeby błędny join dostał się do raportów.
===============================================================================
*/

-- ====================================================================
-- gold.dim_customers
-- ====================================================================
-- Unikalność customer_key
-- Oczekiwany wynik: brak wierszy
SELECT
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- gold.dim_products
-- ====================================================================
-- Unikalność product_key
-- Oczekiwany wynik: brak wierszy
SELECT
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- gold.fact_sales
-- ====================================================================
-- Każdy wiersz faktów musi znaleźć dopasowanie w obu wymiarach
-- Oczekiwany wynik: brak wierszy (brak sierocych kluczy)
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL;
