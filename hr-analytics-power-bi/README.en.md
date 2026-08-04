*[Czytaj po polsku](README.md)*

# HR Analytics: Employee Attrition Analysis (Power BI)

An interactive Power BI report analyzing employee attrition using the IBM HR Analytics Employee Attrition dataset (1,470 employees). The project doesn't stop at building charts. Its core is a documented investigative process: hypothesis, verification, rejection, next hypothesis, until landing on a precisely defined high-risk employee segment.

**Project file:** [`Port_1_HR_Insights.pbix`](Port_1_HR_Insights.pbix) (a single file, open it directly in Power BI Desktop)

---

## Report preview

| Overview | Dimension analysis |
|---|---|
| ![Overview](screenshots/01_przeglad.png) | ![Dimension analysis](screenshots/02_analiza_wymiarow.png) |

| Anomaly analysis | AI visuals |
|---|---|
| ![Anomaly analysis](screenshots/03_analiza_anomalii.png) | ![AI visuals](screenshots/04_wizualizacje_ai.png) |

**Conclusions**
![Conclusions](screenshots/05_wnioski.png)

---

## 1. Business question

Where in the organization is attrition highest, which factors are associated with it, and can we identify a specific, precisely defined high-risk employee segment rather than just general correlations.

## 2. Data

- **Source:** [IBM HR Analytics Employee Attrition & Performance](data/HR_Analytics.csv) (a well-known, publicly available demo dataset, included in this repo under [`data/`](data/)).
- **Raw data:** 1,480 employee rows.
- **Cleaning (Power Query):**
  - removed 7 fully duplicated rows (`Table.Distinct` on the whole row),
  - removed 3 additional rows with a repeated `EmpID` where other columns differed (`Table.Distinct` on `EmpID`),
  - **result: 1,470 unique employees** (verified directly against the source file and consistent with the `Employee count` measure in the report),
  - removed columns with zero variance: `EmployeeCount`, `StandardHours`, `Over18`,
  - added a helper column `SalarySlab Key` (custom column, if/then logic), because the text-based salary bracket categories (e.g. "Upto 5k") sorted alphabetically rather than logically.

## 3. Data model

A star schema instead of one flat table:

```
dim_Department ──┐
                  ├──► fact_HR ──► _Measures (DAX measures table)
dim_JobRole ──────┘
```

- `Department Key` / `JobRole Key` were built manually in Power Query: reference the fact table → distinct values → `Remove Duplicates` → `Add Index Column` → merge back into `fact_HR`. Keys are numeric surrogate keys, not text.
- 1-to-many relationships, single-direction filtering.
- **Deliberately did not build a `dim_Employee` table**: the relationship would be 1:1 with `fact_HR`, giving no star-schema benefit (just an artificial split of one table into two).
- Dynamic dimension switching on page 2 is implemented via a **field parameter** (`Dim Selector`), not a plain slicer (see section 5).
- The measures table is named `_Measures` (with a leading underscore).

## 4. DAX measures (selected)

| Measure | Definition | Result (total) |
|---|---|---|
| `Attrition Rate` | `DIVIDE(CALCULATE(COUNTROWS(fact_HR), fact_HR[Attrition]="Yes"), COUNTROWS(fact_HR), 0)` | 16.12% |
| `Avg Salary` | `AVERAGE(fact_HR[MonthlyIncome])` | 6,503 PLN |
| `Avg OverTime` | `DIVIDE(CALCULATE(COUNTROWS(fact_HR), fact_HR[OverTime]="Yes"), COUNTROWS(fact_HR), 0)` | 28.30% |
| `Employee count` | `COUNTROWS(fact_HR)` | 1,470 |
| `Avg Job Satisfaction` | `AVERAGE(fact_HR[JobSatisfaction])` | 2.73 |

`DIVIDE(...,...,0)` is used consistently instead of the `/` operator, to avoid divide-by-zero errors in heavily filtered views.

## 5. Report structure

| Page | Content | Key design decision |
|---|---|---|
| **1. Overview** | KPI cards (Employee Count, Attrition Rate, Avg Salary, Avg Job Satisfaction) + Attrition Rate by age group | The Attrition Rate card is deliberately highlighted in color as the report's central metric |
| **2. Dimension analysis** | One chart (Attrition Rate + Employee Count), switchable between Department / JobRole / JobLevel | **Field parameter** instead of a slicer (see below) |
| **3. Anomaly analysis** | 4 charts investigating the JobLevel 3 anomaly (WorkLifeBalance, OverTime, YearsSinceLastPromotion, WorkingYear+CompaniesWorked) | Chart type chosen to match the nature of the data: bars for comparisons with no trend, lines for trend along an ordered scale |
| **4. AI visuals** | Key Influencers, Top Segments, Decomposition Tree | Explicit use of Power BI's built-in AI tools, clearly distinguished from manual DAX analysis |
| **5. Conclusions** | Written summary: context, key figures, main insight, limitations | Honestly stating the boundaries of the analysis, not just the "wins" |

**Field parameter instead of a slicer (page 2):** a regular slicer *filters rows*. A field parameter *changes which column the visual displays at all* (via the `NAMEOF` + `SELECTEDVALUE` mechanism). This lets one chart serve three different dimensions without duplicating visuals, with the chart title updating dynamically. The slicer is set to single-select: the default multi-select setting produced nonsensical results when several dimensions were selected at once.

```dax
Dim Selector =
{
    ("Department", NAMEOF('dim_Department'[Department]), 0),
    ("JobRole",    NAMEOF('dim_JobRole'[JobRole]),        1),
    ("JobLevel",   NAMEOF('fact_HR'[JobLevel]),           2)
}
```

## 6. The investigation: the most important part of this project

### Step 1. First lead: JobRole

`Sales Representative` has the highest Attrition Rate (39.76%) and the lowest average salary (2,626 PLN) of any role. At first glance: lower pay → higher attrition, and the relationship looks linear.

### Step 2. Checking against JobLevel (the hypothesis breaks down)

| JobLevel | Attrition Rate | Headcount | Avg. Salary |
|---|---|---|---|
| 1 | 26.34% | 543 | 2,786 PLN |
| 2 | 9.74% | 534 | 5,502 PLN |
| **3** | **14.68%** ⚠️ | 218 | 9,817 PLN |
| 4 | 4.72% | 106 | 15,503 PLN |
| 5 | 7.25% | 69 | 19,191 PLN |

Level 3 **breaks the pattern**: its attrition rate is higher than both neighboring levels (2 and 4), even though salary rises monotonically. So the salary/attrition relationship isn't as linear as JobRole alone suggested.

### Step 3. Systematically ruling out hypotheses for the JobLevel 3 anomaly

Checked and **rejected** as explanations:

- `WorkLifeBalance`: flat at 2.71–2.84 across all levels, no difference,
- `OverTime`: flat at 26–31% across all levels, no difference,
- `YearsSinceLastPromotion`: rises linearly with JobLevel (1.19 → 4.84), level 3 doesn't stand out, and the direction is opposite to the hypothesis anyway,
- `TotalWorkingYears` and `NumCompaniesWorked`: also rise linearly with JobLevel, level 3 doesn't stand out.

**Honest conclusion:** the group size (218 people, 32 departures) is large enough to rule out statistical noise. This isn't chance. But with the variables available, **the cause could not be conclusively determined**. A combination of factors outside this dataset is possible. Rather than forcing an explanation, the report states plainly "cause unknown."

### Step 4. Key Influencers across the whole population (not just JobLevel 3)

| Factor | Increased likelihood of attrition |
|---|---|
| `TotalWorkingYears` ≤ 2 | **3.23×** |
| `OverTime` = Yes | 2.93× |
| `JobRole` = Sales Representative | 2.70× |
| `YearsAtCompany` ≤ 1 | 2.70× |

**Methodological observation:** `OverTime` did not differentiate JobLevel 3 from its neighbors in the manual cross-sectional analysis (flat at 26–31%), yet it's one of the strongest predictors in the population-wide model. No difference *between specific groups* doesn't mean a variable isn't important *overall*: those are two different questions.

### Step 5. Top Segments: the project's strongest insight

> **Segment: `OverTime = Yes` AND `JobLevel ≤ 1`**
> **156 people** (10.6% of the whole company) → **52.6% attrition**, 36 percentage points above the company average (16.1%).

This is the two strongest individual factors from Key Influencers combined: together they produce a bigger effect than either alone. **Manual analysis by JobLevel alone never caught this**, because it looked at the variable in isolation. Only intersecting two dimensions at once (OverTime × JobLevel) reveals a genuinely high-risk group. This is the kind of finding that translates directly into an HR recommendation (e.g. reducing overtime assignment at the lowest job levels).

### Step 6. Decomposition Tree: two different paths, two different questions

- **Rate-based path (Attrition Rate):** Department = Sales (20.63%) → JobRole = Sales Representative (39.76%) → OverTime (Yes: 66.67% / No: 28.81%). Confirms the Step 1 lead.
- **Count-based path (Attrition Count, drilled to 6 levels):** JobLevel = 1 → Department = Research & Development → OverTime = Yes → WorkLifeBalance = 3 → JobRole = Research Scientist → MaritalStatus = Single (14 people at the leaf node).

These two paths **aren't contradictory: they answer different questions**. Research & Development simply has more employees than Sales, so it dominates in absolute numbers despite a lower percentage rate. Practical implication for HR: *rate* shows where things are proportionally worst (Sales Representative), *count* shows where the company is losing the most people in absolute terms (JobLevel 1 / R&D). These are two different, complementary business decisions, not one "correct" answer.

**Small-sample caveat:** drilling to 6 levels leads to very small groups (14 people). The Decomposition Tree is well suited to exploration, but conclusions at this depth lose statistical reliability and shouldn't drive decisions without further verification.

## 7. Visual design

Beyond the analytical layer, the report went through a separate visual design pass, including:

- fixed a bug in the theme's color palette: pure white as one of the data colors made the 4th category in charts (e.g. JobLevel) **invisible** against the white card background,
- added consistent rounded corners, a subtle shadow, and borders on visuals (depth instead of a flat look),
- fixed one KPI card's formatting, which was inconsistent with the other three,
- added spacing between visuals that previously touched edge-to-edge,
- the bar-vs-line chart type choice on page 3 is a deliberate decision communicating the nature of the data, not an accident.

## 8. Limitations

- The analysis is correlational, not causal: the data can show associations, not prove a causal mechanism.
- The JobLevel 3 anomaly remains unexplained with the available variables, deliberately reported as an open question rather than forced into a tidy explanation.
- Low-headcount categories (e.g. JobRole = Human Resources, Manager, Research Director) show extreme Attrition Rate values and need cautious interpretation.
- Unexplored follow-up: `MaritalStatus` (within the high-risk segment, "Single" accounts for 37.8% and, per the AI tool, "most affects the distribution"), a potential third dimension for this segment worth investigating further.

## 9. Skills demonstrated

Power Query (data cleaning, surrogate key building, custom columns) · star-schema modeling · DAX (`CALCULATE`, `DIVIDE`, `AVERAGE`, `COUNTROWS`) · field parameters · Key Influencers and Decomposition Tree (AI visuals) · deliberate chart-type selection · report styling (JSON theme, visual consistency) · data model naming hygiene.

## 10. How to open

1. Requires Power BI Desktop.
2. Open `Port_1_HR_Insights.pbix`: a single, self-contained file with the data already loaded, so it opens immediately with no extra setup.
3. The raw source data (`data/HR_Analytics.csv`) is included separately in this repo for transparency. If you want to refresh the data after cloning this repo somewhere else, update the path in Power Query (Transform Data → `HR_Analytics` query → `Source` step).

---

**Data source:** IBM HR Analytics Employee Attrition & Performance (publicly available demo dataset).

**LinkedIn:** [Kamil Krzosek](https://www.linkedin.com/in/kamil-krzosek-b17921418/)
