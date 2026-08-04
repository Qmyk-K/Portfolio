/*
===============================================================================
Skrypt: init_database.sql
===============================================================================
Cel skryptu:
    Zakłada od zera bazę danych 'DataWarehouse' oraz trzy schematy odpowiadające
    warstwom architektury medalowej: bronze, silver, gold.

    Jeżeli baza o tej nazwie już istnieje, zostaje najpierw usunięta, więc skrypt
    zawsze startuje z czystego stanu.

UWAGA:
    Ten skrypt bezpowrotnie usuwa bazę 'DataWarehouse', jeśli już istnieje,
    razem z całą jej zawartością. Przed uruchomieniem upewnij się, że nie ma
    tam danych, na których Ci zależy.
===============================================================================
*/

USE master;
GO

-- Jeśli baza już istnieje, przełącz ją w tryb single-user i usuń
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Trzy schematy = trzy warstwy medalowej architektury
CREATE SCHEMA bronze; -- surowe dane, dokładnie takie, jak w źródle
GO

CREATE SCHEMA silver; -- dane po czyszczeniu i standaryzacji
GO

CREATE SCHEMA gold; -- widoki gotowe do raportowania i analiz
GO
