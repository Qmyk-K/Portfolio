*[Read this in English](README.en.md)*

# SQL EDA: eksploracyjna analiza danych i raporty na hurtowni (SQL Server)

Zestaw 13 skryptów SQL budujących się jeden na drugim: od poznania struktury bazy, przez analizy wielkości, rankingów i trendów czasowych, aż po dwa gotowe widoki raportowe (`gold.report_customers`, `gold.report_products`). Wszystko uruchomione na realnej bazie `DataWarehouse` z projektu [SQL Data Warehouse](../sql-data-warehouse/) - to nie są przykładowe liczby, tylko rzeczywisty wynik zapytań z tego repozytorium.

---

## Spis treści

1. [Cel projektu](#1-cel-projektu)
2. [Skąd biorą się dane](#2-skąd-biorą-się-dane)
3. [Struktura skryptów](#3-struktura-skryptów)
4. [Analiza i wnioski](#4-analiza-i-wnioski)
5. [Ograniczenia i uwagi](#5-ograniczenia-i-uwagi)
6. [Jak uruchomić](#6-jak-uruchomić)
7. [Użyte umiejętności](#7-użyte-umiejętności)

---

## 1. Cel projektu

Sama hurtownia danych (warstwa gold: `dim_customers`, `dim_products`, `fact_sales`) to dopiero punkt startowy. Ten projekt odpowiada na pytanie: skoro dane są już czyste i połączone, to co właściwie z nich wynika? Skrypty idą od ogółu do szczegółu - najpierw rozejrzenie się po strukturze, potem podstawowe miary, potem coraz bardziej celowane analizy (ranking, trend w czasie, segmentacja), a na końcu dwa widoki raportowe konsolidujące wszystko w jednym miejscu.

## 2. Skąd biorą się dane

Ten projekt zakłada, że baza `DataWarehouse` już istnieje i jest zasilona - patrz [SQL Data Warehouse](../sql-data-warehouse/) po pełny proces budowy (Bronze/Silver/Gold, ETL, testy jakości). Tu korzysta się już tylko z gotowej warstwy `gold`.

## 3. Struktura skryptów

| Plik | Co robi |
|---|---|
| [`01_database_exploration.sql`](scripts/01_database_exploration.sql) | Lista tabel i kolumn w bazie (`INFORMATION_SCHEMA`) |
| [`02_dimensions_exploration.sql`](scripts/02_dimensions_exploration.sql) | Unikalne wartości w wymiarach: kraje, kategorie produktów |
| [`03_date_range_exploration.sql`](scripts/03_date_range_exploration.sql) | Zakres dat zamówień i wieku klientów |
| [`04_measures_exploration.sql`](scripts/04_measures_exploration.sql) | Podstawowe miary: suma sprzedaży, liczba zamówień, klientów, produktów |
| [`05_magnitude_analysis.sql`](scripts/05_magnitude_analysis.sql) | Rozkład wg wymiarów: kraj, płeć, kategoria |
| [`06_ranking_analysis.sql`](scripts/06_ranking_analysis.sql) | Top / bottom produkty i klienci (`TOP`, `RANK() OVER`) |
| [`07_change_over_time_analysis.sql`](scripts/07_change_over_time_analysis.sql) | Trend sprzedaży w czasie (`DATETRUNC`, `FORMAT`) |
| [`08_cumulative_analysis.sql`](scripts/08_cumulative_analysis.sql) | Suma narastająco i średnia krocząca (`SUM() OVER`) |
| [`09_performance_analysis.sql`](scripts/09_performance_analysis.sql) | Wydajność produktu rok do roku (`LAG()`) |
| [`10_data_segmentation.sql`](scripts/10_data_segmentation.sql) | Segmentacja produktów wg kosztu i klientów wg zachowań (VIP/Regular/New) |
| [`11_part_to_whole_analysis.sql`](scripts/11_part_to_whole_analysis.sql) | Udział procentowy kategorii w całości sprzedaży |
| [`12_report_customers.sql`](scripts/12_report_customers.sql) | Widok `gold.report_customers`: pełny raport klienta w jednym miejscu |
| [`13_report_products.sql`](scripts/13_report_products.sql) | Widok `gold.report_products`: pełny raport produktu w jednym miejscu |

## 4. Analiza i wnioski

Wszystkie liczby poniżej pochodzą z realnego uruchomienia tych skryptów na bazie `DataWarehouse`.

**Skala danych:** 60 398 pozycji zamówień, 27 659 odrębnych zamówień, 18 484 klientów, 295 produktów. Zamówienia obejmują 37 miesięcy, od 2010-12-29 do 2014-01-28. Łączna sprzedaż: 29 356 250, przy średniej cenie 486.

**Sprzedaż jest skrajnie skoncentrowana w jednej kategorii.** Rowery (Bikes) to 96,46% całej sprzedaży (28,3 mln), Akcesoria 2,39%, Odzież 1,16%. Kategoria Components (127 produktów w katalogu) wygenerowała **zero** sprzedaży - sprawdzone bezpośrednim joinem, nie tylko brakiem w agregacie. To komponenty katalogowe, które w tym zbiorze danych nigdy nie zostały sprzedane jako osobna pozycja.

**5 najlepszych produktów to warianty jednego modelu.** Top 5 wg przychodu to same warianty koloru/rozmiaru Mountain-200 (1,29-1,37 mln każdy) - jeden bardzo silny model odpowiada za nieproporcjonalnie dużą część wyniku. Na przeciwległym biegunie: skarpety, zestawy naprawcze, akcesoria po kilka tysięcy.

**Klienci: USA odpowiada za 40% bazy.** Rozkład wg kraju: USA 7 482 (40%), Australia 3 591 (19%), UK 1 913, Francja 1 810, Niemcy 1 780, Kanada 1 571. Płeć niemal idealnie 50/50 (9 341 mężczyzn, 9 128 kobiet).

**Segmentacja klientów: 79% to "New".** Wg `gold.report_customers` (VIP: historia ≥12 mies. i sprzedaż >5000 / Regular: historia ≥12 mies. i sprzedaż ≤5000 / New: historia <12 mies.): New 14 629 (79%), Regular 2 200 (12%), VIP 1 653 (9%). Średnia sprzedaż VIP-a to 6 509 wobec 757 dla New - 8,6-krotna różnica, co ma sens, bo definicja VIP-a wprost wymaga wyższej sprzedaży.

**2013 to wyraźny skok.** Sprzedaż wg roku: 2011 - 7,08 mln, 2012 - 5,84 mln, 2013 - 16,34 mln (+180% rok do roku). Lata 2010 i 2014 obejmują tylko pojedyncze miesiące (odpowiednio grudzień i styczeń), więc nie da się ich porównywać 1:1 z pełnymi latami.

**Segmentacja produktów wg przychodu (`gold.report_products`):** High-Performer 66 produktów (średnio 418 844 przychodu), Mid-Range 58 (średnio 28 824), Low-Performer 6 (średnio 5 949) - mocno skośny rozkład, spójny z obserwacją o dominacji kategorii Bikes.

## 5. Ograniczenia i uwagi

- **`recency` i wiek klienta są liczone względem `GETDATE()`, nie względem daty ostatniego zamówienia w zbiorze.** To zbiór historyczny (dane kończą się w styczniu 2014), więc każde uruchomienie tych zapytań dziś zwróci recency rzędu 150+ miesięcy dla każdego segmentu, bo tyle czasu minęło od zakończenia zbioru do teraz - **nie dlatego, że klienci faktycznie tak dawno nie kupowali względem siebie nawzajem**. To samo z wiekiem: najmłodszy klient w zbiorze (ur. 1986) ma dziś 40 lat, więc w podziale `age_group` z `gold.report_customers` nie pojawia się już żadna grupa poniżej 40 lat, mimo że w oryginalnym zbiorze byli młodsi klienci. W realnym środowisku produkcyjnym te metryki liczy się względem stałej daty analizy albo maksymalnej daty w danych, nie względem bieżącego `GETDATE()`.
- **Jeden klient ma datę urodzenia 1916-02-10 (110 lat).** To poza zakresem przyjętym we własnych testach jakości warstwy silver w projekcie [SQL Data Warehouse](../sql-data-warehouse/tests/quality_checks_silver.sql) (1924+) - prawdopodobnie błędna albo domyślna wartość, która prześlizgnęła się przez czyszczenie danych.
- **7 produktów nie ma przypisanej kategorii** (`category IS NULL`) - osierocone wpisy w katalogu.
- Analiza jest opisowa, nie prognostyczna: pokazuje co się wydarzyło, nie przewiduje, co wydarzy się dalej.

## 6. Jak uruchomić

1. Wymagana zbudowana i zasilona baza `DataWarehouse` - patrz [SQL Data Warehouse](../sql-data-warehouse/#9-jak-uruchomić-projekt).
2. Skrypty 01-11 to niezależne zapytania eksploracyjne - można uruchamiać pojedynczo, w dowolnej kolejności.
3. Skrypty 12-13 tworzą widoki (`CREATE VIEW`) - uruchom je raz, żeby założyć `gold.report_customers` i `gold.report_products`, a potem odpytuj je zwykłym `SELECT`.

## 7. Użyte umiejętności

T-SQL (funkcje okienkowe: `RANK`, `LAG`, `SUM() OVER`, `AVG() OVER`) · funkcje daty (`DATEDIFF`, `DATETRUNC`, `FORMAT`) · agregacje i `GROUP BY` · segmentacja przez `CASE` · projektowanie widoków raportowych · czytanie wyników i wyciąganie z nich wniosków, łącznie z wykrywaniem ograniczeń samej metody liczenia.

---

**LinkedIn:** [Kamil Krzosek](https://www.linkedin.com/in/kamil-krzosek-b17921418/)
