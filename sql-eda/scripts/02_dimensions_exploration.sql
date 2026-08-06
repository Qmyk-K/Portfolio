/*
===============================================================================
Eksploracja wymiarów
===============================================================================
Cel skryptu:
    - Poznać rzeczywistą zawartość tabel wymiarów, zanim zbuduje się na nich
      analizy - jakie wartości tam faktycznie występują.

Wykorzystane funkcje:
    - DISTINCT, ORDER BY
===============================================================================
*/

-- Lista unikalnych krajów, z których pochodzą klienci
SELECT DISTINCT
    country
FROM gold.dim_customers
ORDER BY country;

-- Lista unikalnych kombinacji kategoria / podkategoria / produkt
SELECT DISTINCT
    category,
    subcategory,
    product_name
FROM gold.dim_products
ORDER BY category, subcategory, product_name;
