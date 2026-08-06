/*
===============================================================================
Analiza część-do-całości
===============================================================================
Cel skryptu:
    - Sprawdzić, jaki procent całości stanowi dana kategoria - nie sama
      wartość bezwzględna, tylko jej udział w torcie.

Wykorzystane funkcje:
    - SUM(), AVG(): agregacja wartości do porównania
    - Funkcje okienkowe: SUM() OVER() do policzenia sumy całkowitej
===============================================================================
*/

-- Które kategorie mają największy udział w łącznej sprzedaży?
WITH category_sales AS (
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON p.product_key = f.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales, -- suma po całej tabeli, bez GROUP BY
    ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2) AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;
