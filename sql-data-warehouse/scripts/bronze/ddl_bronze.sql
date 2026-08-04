/*
===============================================================================
Skrypt: ddl_bronze.sql
===============================================================================
Cel skryptu:
    Definiuje strukturę tabel w schemacie 'bronze'. Każda tabela jest lustrzanym
    odbiciem jednego pliku źródłowego (CRM albo ERP) - bez żadnych przekształceń,
    bez walidacji typów, bez czyszczenia. Kolumny nazwane i otypowane tak,
    żeby bez problemu przyjąć dane 1:1 z CSV.

    Każda tabela jest najpierw usuwana (jeśli istnieje), a potem tworzona od nowa,
    więc skrypt można uruchamiać wielokrotnie bez błędów.
===============================================================================
*/

-- Dane klientów z systemu CRM
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(50),
    cst_create_date     DATE
);
GO

-- Dane produktów z systemu CRM
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info (
    prd_id       INT,
    prd_key      NVARCHAR(50),
    prd_nm       NVARCHAR(50),
    prd_cost     INT,
    prd_line     NVARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt   DATETIME
);
GO

-- Szczegóły zamówień sprzedażowych z CRM. Daty wciąż jako INT (format YYYYMMDD z pliku źródłowego),
-- konwersja na typ DATE dzieje się dopiero w warstwie silver.
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num  NVARCHAR(50),
    sls_prd_key  NVARCHAR(50),
    sls_cust_id  INT,
    sls_order_dt INT,
    sls_ship_dt  INT,
    sls_due_dt   INT,
    sls_sales    INT,
    sls_quantity INT,
    sls_price    INT
);
GO

-- Lokalizacja klientów (kraj) z systemu ERP
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
CREATE TABLE bronze.erp_loc_a101 (
    cid   NVARCHAR(50),
    cntry NVARCHAR(50)
);
GO

-- Dodatkowe dane demograficzne klientów (data urodzenia, płeć) z systemu ERP
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
CREATE TABLE bronze.erp_cust_az12 (
    cid   NVARCHAR(50),
    bdate DATE,
    gen   NVARCHAR(50)
);
GO

-- Kategorie i podkategorie produktów z systemu ERP
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2 (
    id          NVARCHAR(50),
    cat         NVARCHAR(50),
    subcat      NVARCHAR(50),
    maintenance NVARCHAR(50)
);
GO
