# Katalog danych - warstwa Gold

## Przegląd

Warstwa gold to warstwa biznesowa - to na niej pracują raporty, dashboardy i analitycy. Składa się z dwóch tabel wymiarów (`dim_customers`, `dim_products`) i jednej tabeli faktów (`fact_sales`), ułożonych w schemat gwiazdy. Fizycznie są to widoki SQL, nie tabele - patrz [`scripts/gold/ddl_gold.sql`](../scripts/gold/ddl_gold.sql).

---

### 1. gold.dim_customers

**Cel:** dane klienta wzbogacone o informacje demograficzne i geograficzne z dwóch różnych źródeł (CRM i ERP).

| Kolumna | Typ danych | Opis |
|---|---|---|
| customer_key | INT | Klucz surogatny, generowany wewnątrz warstwy gold (`ROW_NUMBER`), jednoznacznie identyfikuje wiersz w tej tabeli. |
| customer_id | INT | Numeryczny identyfikator klienta, taki jak w systemie CRM. |
| customer_number | NVARCHAR(50) | Alfanumeryczny identyfikator klienta (`cst_key`), używany do łączenia z danymi ERP. |
| first_name | NVARCHAR(50) | Imię klienta. |
| last_name | NVARCHAR(50) | Nazwisko klienta. |
| country | NVARCHAR(50) | Kraj klienta, pochodzi z ERP (np. „Germany”, „United States”). |
| marital_status | NVARCHAR(50) | Stan cywilny po standaryzacji („Married”, „Single” albo „n/a”). |
| gender | NVARCHAR(50) | Płeć. CRM jest źródłem nadrzędnym, ERP uzupełnia braki. |
| birthdate | DATE | Data urodzenia, pochodzi z ERP. |
| create_date | DATE | Data założenia rekordu klienta w systemie źródłowym. |

---

### 2. gold.dim_products

**Cel:** atrybuty produktów, z uwzględnieniem kategorii i podkategorii z ERP.

| Kolumna | Typ danych | Opis |
|---|---|---|
| product_key | INT | Klucz surogatny, generowany wewnątrz warstwy gold. |
| product_id | INT | Identyfikator produktu z systemu źródłowego. |
| product_number | NVARCHAR(50) | Kod produktu (`prd_key`) po odcięciu prefiksu kategorii. |
| product_name | NVARCHAR(50) | Nazwa produktu wraz z atrybutami takimi jak kolor czy rozmiar. |
| category_id | NVARCHAR(50) | Identyfikator kategorii, wyciągnięty z pierwszych znaków `prd_key`. |
| category | NVARCHAR(50) | Kategoria produktu (np. „Bikes”, „Components”). |
| subcategory | NVARCHAR(50) | Podkategoria produktu. |
| maintenance | NVARCHAR(50) | Czy produkt wymaga serwisowania („Yes”/„No”). |
| cost | INT | Koszt bazowy produktu. |
| product_line | NVARCHAR(50) | Linia produktowa po standaryzacji (np. „Mountain”, „Road”). |
| start_date | DATE | Data, od której obowiązuje ta wersja produktu. Widok pokazuje tylko aktualną wersję (`prd_end_dt IS NULL`), historyczne zmiany cen/linii są odcięte. |

---

### 3. gold.fact_sales

**Cel:** transakcje sprzedażowe na poziomie pojedynczej pozycji zamówienia.

| Kolumna | Typ danych | Opis |
|---|---|---|
| order_number | NVARCHAR(50) | Numer zamówienia (np. „SO54496”). |
| product_key | INT | Klucz obcy do `dim_products` (klucz surogatny, nie naturalny numer produktu). |
| customer_key | INT | Klucz obcy do `dim_customers`. |
| order_date | DATE | Data złożenia zamówienia. |
| shipping_date | DATE | Data wysyłki. |
| due_date | DATE | Termin płatności. |
| sales_amount | INT | Wartość sprzedaży dla danej pozycji zamówienia. |
| quantity | INT | Zamówiona liczba sztuk. |
| price | INT | Cena jednostkowa. |

**Reguła spójności:** `sales_amount = quantity * price`. Warstwa silver dopilnowuje tego przeliczając wartość, gdy w źródle jest ona brakująca albo niespójna - patrz [`scripts/silver/proc_load_silver.sql`](../scripts/silver/proc_load_silver.sql).
