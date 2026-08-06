/*
===============================================================================
Zmiana w czasie
===============================================================================
Cel skryptu:
    - Prześledzić trendy, wzrosty i spadki kluczowych miar w czasie.
    - Trzy różne sposoby grupowania po miesiącu - do wyboru, zależnie co
      wygodniej dalej przetwarzać (liczby, data czy tekst).

Wykorzystane funkcje:
    - Funkcje daty: DATEPART(), DATETRUNC(), FORMAT()
    - Funkcje agregujące: SUM(), COUNT(), AVG()
===============================================================================
*/

-- Wariant 1: osobne kolumny rok/miesiąc (najbardziej podstawowy)
SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);

-- Wariant 2: DATETRUNC() - grupowanie po ucięciu daty do miesiąca, wynik zostaje typu DATE
SELECT
    DATETRUNC(month, order_date) AS order_date,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
ORDER BY DATETRUNC(month, order_date);

-- Wariant 3: FORMAT() - czytelna etykieta tekstowa (np. "2011-Jan"), wygodna do wykresów
SELECT
    FORMAT(order_date, 'yyyy-MMM') AS order_date,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM');
