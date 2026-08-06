/*
===============================================================================
Zakresy dat
===============================================================================
Cel skryptu:
    - Sprawdzić granice czasowe danych: od kiedy do kiedy sięgają zamówienia,
      w jakim przedziale wieku są klienci.
    - To ustala punkt odniesienia dla wszystkich dalszych analiz czasowych.

Wykorzystane funkcje:
    - MIN(), MAX(), DATEDIFF()
===============================================================================
*/

-- Pierwsza i ostatnia data zamówienia oraz długość całego okresu w miesiącach
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS order_range_months
FROM gold.fact_sales;

-- Najstarszy i najmłodszy klient na podstawie daty urodzenia
SELECT
    MIN(birthdate) AS oldest_birthdate,
    DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS oldest_age,
    MAX(birthdate) AS youngest_birthdate,
    DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS youngest_age
FROM gold.dim_customers;
