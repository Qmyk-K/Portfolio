# Konwencje nazewnictwa

Krótki przewodnik po tym, jak nazwane są schematy, tabele, kolumny i procedury w tym projekcie. Cel jest prosty: patrząc na samą nazwę obiektu, od razu wiadomo, do której warstwy należy i co reprezentuje, bez zaglądania do definicji.

## Zasady ogólne

- **snake_case** wszędzie: małe litery, słowa rozdzielone podkreśleniem.
- **Angielski** jako język nazw obiektów SQL (schematy, tabele, kolumny) - niezależnie od języka dokumentacji i komentarzy w kodzie, które w tym repozytorium są po polsku.
- Unikanie słów zarezerwowanych SQL jako nazw obiektów.

## Nazewnictwo tabel

### Bronze

Nazwa zaczyna się od systemu źródłowego, a sama nazwa tabeli jest przepisana 1:1 z pliku źródłowego (bez tłumaczenia na bardziej „ludzkie” nazwy) - to celowe, bronze ma być lustrem źródła.

`<system>_<encja>`, np. `crm_cust_info` - dane klientów z systemu CRM.

### Silver

Ten sam wzorzec co w bronze (`<system>_<encja>`), bo to wciąż te same encje źródłowe, tylko po oczyszczeniu.

### Gold

Tu nazwy są już biznesowe, nie techniczne, i zaczynają się od prefiksu określającego rolę tabeli w modelu.

`<rola>_<encja>`, np. `dim_customers` (wymiar klientów), `fact_sales` (fakty sprzedażowe).

| Prefiks | Znaczenie | Przykład |
|---|---|---|
| `dim_` | tabela wymiaru | `dim_customers`, `dim_products` |
| `fact_` | tabela faktów | `fact_sales` |

## Nazewnictwo kolumn

### Klucze surogatne

Każdy klucz główny w tabeli wymiaru w warstwie gold ma sufiks `_key`, np. `customer_key`, `product_key`. To odróżnia go od naturalnych identyfikatorów pochodzących ze źródła (`customer_id`, `product_id`).

### Kolumny techniczne

Kolumny dodane przez sam proces ETL (nie pochodzące ze źródła) mają prefiks `dwh_`, np. `dwh_create_date` - moment załadowania rekordu do warstwy silver. Dzięki temu od razu widać, że to metadana procesu, a nie dana biznesowa.

## Nazewnictwo procedur

Procedury ładujące dane do danej warstwy nazwane są `<warstwa>.load_<warstwa>`, np. `bronze.load_bronze`, `silver.load_silver`. Prosto i przewidywalnie: nazwa procedury mówi wprost, co się stanie po jej uruchomieniu.
