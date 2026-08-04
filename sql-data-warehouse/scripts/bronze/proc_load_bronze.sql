/*
===============================================================================
Procedura: bronze.load_bronze
===============================================================================
Cel procedury:
    Ładuje pliki CSV ze źródeł CRM i ERP do tabel warstwy 'bronze'.
    Dla każdej tabeli procedura:
    1. czyści tabelę poleceniem TRUNCATE (pełny reload, bez inkrementów),
    2. wczytuje dane poleceniem BULK INSERT bezpośrednio z pliku CSV.

    Nie ma tu żadnej logiki biznesowej ani czyszczenia danych - to zadanie
    warstwy silver. Bronze ma tylko odwzorować źródło 1:1.

Zanim uruchomisz:
    Ścieżki w BULK INSERT wskazują na lokalny dysk (SQL Server czyta pliki
    z perspektywy serwera, nie klienta), więc podmień je na ścieżkę do folderu
    'datasets' po sklonowaniu tego repozytorium na swój komputer.

Przykład użycia:
    EXEC bronze.load_bronze;
===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Ładowanie warstwy Bronze';
        PRINT '================================================';

        PRINT '------------------------------------------------';
        PRINT 'Źródło: CRM';
        PRINT '------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Czyszczenie tabeli: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT '>> Wczytywanie danych do: bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info
        FROM 'C:\sql-data-warehouse\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Czas ładowania: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' s';
        PRINT '-----------------';

        SET @start_time = GETDATE();
        PRINT '>> Czyszczenie tabeli: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT '>> Wczytywanie danych do: bronze.crm_prd_info';
        BULK INSERT bronze.crm_prd_info
        FROM 'C:\sql-data-warehouse\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Czas ładowania: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' s';
        PRINT '-----------------';

        SET @start_time = GETDATE();
        PRINT '>> Czyszczenie tabeli: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '>> Wczytywanie danych do: bronze.crm_sales_details';
        BULK INSERT bronze.crm_sales_details
        FROM 'C:\sql-data-warehouse\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Czas ładowania: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' s';
        PRINT '-----------------';

        PRINT '------------------------------------------------';
        PRINT 'Źródło: ERP';
        PRINT '------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Czyszczenie tabeli: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT '>> Wczytywanie danych do: bronze.erp_cust_az12';
        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\sql-data-warehouse\datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Czas ładowania: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' s';
        PRINT '-----------------';

        SET @start_time = GETDATE();
        PRINT '>> Czyszczenie tabeli: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT '>> Wczytywanie danych do: bronze.erp_loc_a101';
        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\sql-data-warehouse\datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Czas ładowania: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' s';
        PRINT '-----------------';

        SET @start_time = GETDATE();
        PRINT '>> Czyszczenie tabeli: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT '>> Wczytywanie danych do: bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\sql-data-warehouse\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Czas ładowania: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' s';
        PRINT '-----------------';

        SET @batch_end_time = GETDATE();
        PRINT '**********************************************';
        PRINT 'Ładowanie warstwy Bronze zakończone';
        PRINT '  - Całkowity czas: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' s';
        PRINT '**********************************************';
    END TRY
    BEGIN CATCH
        PRINT '=======================================';
        PRINT 'BŁĄD PODCZAS ŁADOWANIA WARSTWY BRONZE';
        PRINT 'Komunikat: ' + ERROR_MESSAGE();
        PRINT 'Numer błędu: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Stan błędu: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '=======================================';
    END CATCH
END
GO
