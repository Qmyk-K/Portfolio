*[Read this in English](README.en.md)*

# Automatyzacja przetwarzania dokumentów kadrowych (Python)

Skrypt w Pythonie, który odszyfrowuje i parsuje PDF-y "Oświadczenie Zleceniobiorcy", wyciąga z nich dane osobowe, adresowe i podatkowe, waliduje je i zestawia w plik gotowy do importu w systemie ERP Enova365. Zamiast ręcznego przepisywania dziesiątek pól z każdego formularza, operator dostaje jeden arkusz `enova_import.xlsx` plus osobny arkusz `KONFLIKTY` ze wszystkim, co wymaga ręcznego sprawdzenia.

**Plik projektu:** [`odszyfruj_i_zestaw_enova.py`](odszyfruj_i_zestaw_enova.py)

---

## 1. Problem biznesowy

Dane zleceniobiorców trafiały do firmy jako zaszyfrowane PDF-y o niespójnej strukturze (różne warianty formularza, różne układy etykiet), a docelowy system kadrowy (Enova365) wymaga konkretnego, sztywnego układu kolumn przy imporcie. Ręczne przepisywanie ~50 pól na osobę jest wolne i podatne na błędy, a błąd w PESEL-u czy numerze rachunku bankowego ma realne konsekwencje.

## 2. Jak to działa

1. Skrypt czyta wszystkie PDF-y z folderu `PDF/` (razem z podfolderami), odszyfrowuje je hasłem i zapisuje jawne kopie do osobnego, znakowanego datą folderu.
2. Z tekstu każdego PDF-a wyciąga: dane osobowe, trzy bloki adresowe (zameldowanie / zamieszkanie / korespondencja), e-mail, numer rachunku bankowego, Urząd Skarbowy i Oddział NFZ.
3. Nazwy Urzędu Skarbowego i NFZ dopasowuje do kodów ze słowników (`Slowniki/US.csv`, `Slowniki/NFZ.csv`) kaskadą: dopasowanie dokładne → zawieranie → dopasowanie przybliżone (fuzzy, `difflib`), z rozstrzyganiem remisów po kodzie pocztowym z adresu urzędu.
4. Wszystkie pola przechodzą walidację (patrz niżej), a wynik trafia do `enova_import.xlsx` w dokładnej kolejności kolumn wymaganej przez szablon importu Enova.
5. Wszystko, czego skrypt nie jest pewien, ląduje w arkuszu `KONFLIKTY` z priorytetem i linkiem z powrotem do konkretnej komórki w `ENOVA_IMPORT` – operator nic nie musi szukać ręcznie.

## 3. Kluczowe mechanizmy

- **Walidacja PESEL i NIP od zera** – pełny algorytm sumy kontrolnej dla obu numerów (wagi, modulo), nie tylko sprawdzenie długości.
- **Kaskadowe dopasowanie tekstowe (fuzzy matching)** – nazwy urzędów w PDF-ach rzadko pasują znak w znak do słownika (inna kolejność wyrazów, brak liczebnika porządkowego typu "Pierwszy/Drugi"). Dopasowanie: dokładne → zawieranie podciągu → `SequenceMatcher` z progiem podobieństwa, a przy remisie dodatkowe rozstrzygnięcie po kodzie pocztowym z tej samej linii PDF.
- **Wykrywanie duplikatów po PESEL** – jeśli ten sam PESEL pojawia się w kilku plikach, wiersze są podświetlane w arkuszu wynikowym, a skrypt sam sprawdza, czy dane w duplikatach są ze sobą zgodne, czy się rozjeżdżają (inny priorytet konfliktu w każdym przypadku).
- **Zasada "niepewne = konflikt, nie zgadywanie"** – np. pole "Poczta" bywa wypełniane przez ludzi czymkolwiek (ulicą, drugim kodem pocztowym, adresem e-mail); skrypt i tak przepisuje wartość, ale oznacza ją jako wymagającą sprawdzenia zamiast cicho ją "poprawiać".
- **Rozbicie numeru rachunku bankowego** na segmenty (cyfra kontrolna / kierunek / numer) zgodnie ze strukturą pól importu Enova, z zachowaniem wiodących zer (pola tekstowe, nie liczbowe).
- **Krytyczne błędy jako natywny popup Windows** (`MessageBoxW` przez `ctypes`), żeby ważny komunikat nie zniknął razem z zamknięciem konsoli.

## 4. Stack technologiczny

Python · `pypdf` (odszyfrowanie AES) · `openpyxl` (formatowanie, hiperlinki, auto-filtr, freeze panes) · `difflib` (dopasowanie przybliżone) · wyrażenia regularne · `unicodedata` (normalizacja polskich znaków do porównań).

## 5. Uwaga o danych

Skrypt operuje na realnych danych osobowych (PESEL, adresy, numery kont), dlatego w repozytorium **celowo nie ma** przykładowych PDF-ów, słowników ani pliku wynikowego – folder ma dołączony `.gitignore` blokujący te ścieżki. Hasło do odszyfrowania PDF-ów w kodzie jest placeholderem (`TWOJE_HASLO_TUTAJ`) – do realnego użycia podmień je na właściwe hasło lokalnie, nigdy w repo.

## 6. Rozwój z wykorzystaniem AI

Projekt rozwijany iteracyjnie z Claude jako wsparciem: analiza logiki dopasowania danych, projektowanie reguł walidacji i kaskady fuzzy matching, oraz debugowanie na rzeczywistych, niespójnych wariantach formularzy PDF.

## 7. Jak uruchomić

```powershell
pip install pypdf cryptography openpyxl
```

Struktura folderów obok skryptu:

```
PDF/                    <- zaszyfrowane PDF-y (czytane też z podfolderów)
Slowniki/               <- US.csv i NFZ.csv (UTF-16, tab-separated, kolumny Kod/Nazwa)
enova_import.xlsx       <- plik wynikowy (tworzony przez skrypt)
```

Uzupełnij stałą `HASLO` swoim hasłem, a następnie:

```powershell
python odszyfruj_i_zestaw_enova.py
```

---

**Uwaga:** nazwy części kolumn "zawsze pustych" (telefon, faks, skrzynka pocztowa, dokument tożsamości) to nazwy robocze wg konwencji Enova – przed pierwszym realnym importem warto porównać listę `ENOVA_COLUMNS` z prawdziwym szablonem importu.

**LinkedIn:** [Kamil Krzosek](https://www.linkedin.com/in/kamil-krzosek-b17921418/)
