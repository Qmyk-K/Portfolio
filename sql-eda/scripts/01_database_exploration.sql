/*
===============================================================================
Eksploracja bazy danych
===============================================================================
Cel skryptu:
    - Rozejrzeć się po strukturze bazy: jakie schematy i tabele w niej są.
    - Sprawdzić kolumny i typy danych konkretnej tabeli, zanim zacznie się
      pisać właściwe zapytania analityczne.

Wykorzystane obiekty:
    - INFORMATION_SCHEMA.TABLES
    - INFORMATION_SCHEMA.COLUMNS
===============================================================================
*/

-- Lista wszystkich tabel i widoków w bazie
SELECT
    TABLE_CATALOG,
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES;

-- Kolumny i typy danych dla konkretnej tabeli (tu: dim_customers)
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';
