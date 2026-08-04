/*
===============================================================================
Skrypt: quality_checks_silver.sql
===============================================================================
Cel skryptu:
    Zbiór zapytań kontrolnych do uruchomienia po każdym ładowaniu warstwy
    silver. Sprawdzają klucze główne, spacje w tekstach, spójność wartości
    i poprawność dat. Każde zapytanie ma jasno opisaną oczekiwaną odpowiedź -
    jeśli zwraca wiersze tam, gdzie oczekiwany jest brak wyników, to znak,
    że coś w danych źródłowych albo w ETL-u wymaga poprawki.
===============================================================================
*/

-- ====================================================================
-- silver.crm_cust_info
-- ====================================================================
-- Duplikaty lub NULL-e w kluczu głównym
-- Oczekiwany wynik: brak wierszy
SELECT
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Niepożądane spacje w kluczu klienta
-- Oczekiwany wynik: brak wierszy
SELECT
    cst_key
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key);

-- Podgląd wartości po standaryzacji, do ręcznej weryfikacji
SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info;

-- ====================================================================
-- silver.crm_prd_info
-- ====================================================================
-- Duplikaty lub NULL-e w kluczu głównym
-- Oczekiwany wynik: brak wierszy
SELECT
    prd_id,
    COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Niepożądane spacje w nazwie produktu
-- Oczekiwany wynik: brak wierszy
SELECT
    prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Ujemny albo brakujący koszt
-- Oczekiwany wynik: brak wierszy
SELECT
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Podgląd wartości linii produktowej po standaryzacji
SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;

-- Data startu późniejsza niż data końca (błędna kolejność)
-- Oczekiwany wynik: brak wierszy
SELECT
    *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- ====================================================================
-- silver.crm_sales_details
-- ====================================================================
-- Nieprawidłowe daty jeszcze w bronze (kontrola przed konwersją)
-- Oczekiwany wynik: brak nieprawidłowych dat
SELECT
    NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0
    OR LEN(sls_due_dt) != 8
    OR sls_due_dt > 20500101
    OR sls_due_dt < 19000101;

-- Data zamówienia późniejsza niż wysyłki albo terminu płatności
-- Oczekiwany wynik: brak wierszy
SELECT
    *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- Zgodność: sales = quantity * price
-- Oczekiwany wynik: brak wierszy
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- ====================================================================
-- silver.erp_cust_az12
-- ====================================================================
-- Daty urodzenia poza rozsądnym zakresem
-- Oczekiwany wynik: daty urodzenia mieszczą się między 1924-01-01 a dziś
SELECT DISTINCT
    bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01'
   OR bdate > GETDATE();

-- Podgląd wartości płci po standaryzacji
SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;

-- ====================================================================
-- silver.erp_loc_a101
-- ====================================================================
-- Podgląd wartości kraju po standaryzacji
SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;

-- ====================================================================
-- silver.erp_px_cat_g1v2
-- ====================================================================
-- Niepożądane spacje w kategorii, podkategorii albo polu maintenance
-- Oczekiwany wynik: brak wierszy
SELECT
    *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
   OR subcat != TRIM(subcat)
   OR maintenance != TRIM(maintenance);

-- Podgląd wartości maintenance
SELECT DISTINCT
    maintenance
FROM silver.erp_px_cat_g1v2;
