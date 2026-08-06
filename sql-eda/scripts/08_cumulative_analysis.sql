/*
===============================================================================
Analiza kumulatywna
===============================================================================
Cel skryptu:
    - Policzyć narastające sumy i średnie kroczące - widać wtedy nie tylko
      wynik danego miesiąca/roku, ale i to, jak biznes rośnie od początku.

Wykorzystane funkcje:
    - Funkcje okienkowe: SUM() OVER(), AVG() OVER()
===============================================================================
*/

-- Sprzedaż per rok, suma narastająco od początku i średnia krocząca ceny
SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales,
    AVG(avg_price) OVER (ORDER BY order_date) AS moving_average_price
FROM
(
    SELECT
        DATETRUNC(year, order_date) AS order_date,
        SUM(sales_amount) AS total_sales,
        AVG(price) AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(year, order_date)
) t;
