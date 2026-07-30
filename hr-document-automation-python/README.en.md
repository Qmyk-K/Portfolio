*[Czytaj po polsku](README.md)*

# HR Document Processing Automation (Python)

A Python script that decrypts and parses "Contractor Statement" PDF forms, extracts personal, address, and tax data, validates it, and assembles it into a file ready to import into the Enova365 ERP system. Instead of manually retyping dozens of fields per form, the operator gets one `enova_import.xlsx` sheet plus a separate `KONFLIKTY` (conflicts) sheet listing everything that needs a manual check.

**Project file:** [`odszyfruj_i_zestaw_enova.py`](odszyfruj_i_zestaw_enova.py)

---

## 1. Business problem

Contractor data arrived as encrypted PDFs with an inconsistent structure (multiple form variants, different label layouts), while the target HR system (Enova365) requires a fixed column layout for import. Manually retyping roughly 50 fields per person is slow and error-prone, and a mistake in a national ID number or bank account has real consequences.

## 2. How it works

1. The script reads every PDF from the `PDF/` folder (including subfolders), decrypts it with a password, and saves a plaintext copy into a separate, date-stamped folder.
2. From each PDF's text it extracts: personal data, three address blocks (registered / residential / correspondence), email, bank account number, tax office, and health-insurance branch.
3. Tax office and health-insurance branch names are matched to codes from lookup tables (`Slowniki/US.csv`, `Slowniki/NFZ.csv`) through a cascade: exact match, then substring match, then approximate (fuzzy) matching via `difflib`, with ties broken using the postal code found in the same PDF line.
4. Every field goes through validation (see below), and the result is written to `enova_import.xlsx` in the exact column order required by Enova's import template.
5. Anything the script isn't confident about lands in a `KONFLIKTY` sheet with a priority level and a hyperlink back to the exact cell in `ENOVA_IMPORT`, so the operator never has to go hunting manually.

## 3. Key mechanisms

- **National ID and tax ID validation built from scratch** – full checksum algorithms (weighted digits, modulo) for both identifiers, not just a length check.
- **Cascading fuzzy text matching** – office names in the PDFs rarely match the lookup table character-for-character (different word order, missing ordinal like "First/Second"). Matching cascade: exact, then substring containment, then `SequenceMatcher` similarity above a threshold, with ties resolved using the postal code from the same PDF line.
- **Duplicate detection by national ID** – if the same ID appears across multiple files, the rows are highlighted in the output sheet, and the script checks whether the duplicate records actually agree or diverge (different conflict priority for each case).
- **"Uncertain means flagged, not guessed" principle** – e.g. the postal-town field is sometimes filled in by people with anything (a street, a second postal code, an email address); the script still copies the value through but marks it for review instead of silently "correcting" it.
- **Bank account number splitting** into the check-digit / sort-code / account-number segments required by Enova's field structure, preserving leading zeros (these are text fields, not numeric).
- **Critical errors surfaced as a native Windows popup** (`MessageBoxW` via `ctypes`), so an important message doesn't disappear along with the console window.

## 4. Tech stack

Python · `pypdf` (AES decryption) · `openpyxl` (formatting, hyperlinks, auto-filter, freeze panes) · `difflib` (fuzzy matching) · regular expressions · `unicodedata` (normalizing Polish characters for comparison).

## 5. A note on data

The script processes real personal data (national ID numbers, addresses, bank accounts), so this repository **deliberately does not include** any sample PDFs, lookup tables, or output files – the folder ships with a `.gitignore` blocking those paths. The PDF decryption password in the code is a placeholder (`TWOJE_HASLO_TUTAJ`); for real use, replace it locally with the actual password, never in the repository.

## 6. Built with AI assistance

Developed iteratively with Claude as a support tool: analyzing matching logic, designing validation rules and the fuzzy-matching cascade, and debugging against real, inconsistent PDF form variants.

## 7. How to run

```powershell
pip install pypdf cryptography openpyxl
```

Folder structure next to the script:

```
PDF/                    <- encrypted PDFs (also read from subfolders)
Slowniki/               <- US.csv and NFZ.csv (UTF-16, tab-separated, Kod/Nazwa columns)
enova_import.xlsx       <- output file (created by the script)
```

Fill in the `HASLO` constant with your password, then:

```powershell
python odszyfruj_i_zestaw_enova.py
```

---

**Note:** the names of a few "always empty" columns (phone, fax, PO box, ID document) follow Enova's naming convention as working assumptions – before a real import, compare the `ENOVA_COLUMNS` list against the actual import template.
