# Implementation Plan: Binary Logistic Regression using the RREAAAP Framework

## Project Information
- **Course**: DrPH 1 (2026–2027) - Week 7 (22nd Nov)
- **Topic**: Binary Logistic Regression (In-hospital Stroke Fatality)
- **Dataset**: `stroke-fatality-cooked2.dta` (N = 226, 22 variables)
- **Target Outcome**: `outcome` (0 = Alive, 1 = Dead)
- **Deliverable Format**: Quarto (`.qmd`) / R Markdown (`.Rmd`) rendered to an interactive HTML report
- **Execution Status**: **CONFIRMED & READY FOR EXECUTION UPON USER COMMAND**

---

## 1. REASON
* **Core Objective**: Model in-hospital stroke fatality (`outcome`: 0 = alive, 1 = dead) and quantify its associations with clinical, demographic, biochemical, and comorbidity independent variables.
* **Research Question**: What demographic, clinical presentation, and biochemical markers are independent risk factors for in-hospital mortality among stroke patients?
* **Outcome Variable**: `outcome` (Binary: 0 = Alive [Reference], 1 = Dead [Event of Interest]).
* **Independent Variables**:
  - *Demographics*: `age`, `sex`, `maritalstat`, `malay`
  - *Clinical presentation*: `gcs` (Glasgow Coma Scale), `sbp` (Systolic BP), `dbp` (Diastolic BP), `hr` (Heart Rate), `referralcase`, `stroketype` (Ischaemic vs. Haemorrhagic)
  - *Comorbidities*: `hypertension`, `diabetes`, `dyslipidaemia`
  - *Biochemical / Laboratory*: `hb` (Hemoglobin), `plat` (Platelets), `wbc` (White Blood Cell Count), `na` (Sodium), `potas` (Potassium), `cbs` (Capillary Blood Sugar), `urea`

---

## 2. READ
* **Data Source**: [stroke-fatality-cooked2.dta](file:///g:/My%20Drive/Desktop/DrPH1%202026-2027/01.%20CURRENT%20TEACHINGS/07.%20WEEK%207,%2022nd%20NOV/01.%20KIM%20-%20LOGISTIC%20REGRESSION/stroke-fatality-cooked2.dta)
* **Ingestion Tool**: `haven::read_dta()` to retain Stata variable labels and value attributes.
* **Variable Standardisation & Type Casting**:
  - Verify and clean column names to tidy snake_case.
  - Set explicit factor levels and clinical reference groups:
    - `outcome`: Factor (`"Alive"` [0, ref], `"Dead"` [1])
    - `sex`: Factor (`"Male"` [1, ref], `"Female"` [2])
    - `stroketype`: Factor (`"Ischaemic"` [0, ref], `"Haemorrhagic"` [1])
    - `hypertension`, `diabetes`, `dyslipidaemia`: Factors (`"No"` [0, ref], `"Yes"` [1])
    - `maritalstat`, `malay`: Factors (`"No"` [0, ref], `"Yes"` [1])
    - `referralcase`: Factor (`"Hospital"` [0, ref], `"GP/Home/Missing"` [1])
  - Preserve `rn` (registration number) as unique ID (excluded from regression modeling).

---

## 3. EXPLORE
* **Data Quality & Integrity Checks**:
  - Check dataset dimensions, structure, and missing value counts/percentages per variable.
  - Screen for data entry errors or physiologically implausible values (e.g. GCS outside 3–15, extreme BP, negative laboratory values).
* **Univariate & Bivariate Exploratory Visualizations**:
  - **Numerical Variables** (`age`, `gcs`, `sbp`, `dbp`, `hr`, `hb`, `plat`, `wbc`, `na`, `potas`, `cbs`, `urea`):
    - Histograms with density overlays using `ggplot2` to examine distribution normality and skewness.
    - Box plots grouped by `outcome` (Alive vs. Dead) to inspect medians, IQRs, and outliers.
  - **Categorical Variables** (`sex`, `stroketype`, `hypertension`, `diabetes`, `dyslipidaemia`, `referralcase`, `maritalstat`, `malay`):
    - Bar charts showing proportions and counts across survival outcomes.
* **Descriptive Baseline Characteristics Table (Table 1)**:
  - Formatted using `gtsummary::tbl_summary(by = outcome)` with `add_p()` and `add_overall()`.
  - Continuous variables reported as mean (SD) or median (IQR); categorical variables reported as n (%).

---

## 4. ASSUMPTION
* **Binomial Distribution**: Verified through binary status of `outcome`.
* **Independence of Observations**: Verified through independent acute stroke admissions.
* **Linearity in the Logit**:
  - Assessed for all continuous variables (`age`, `gcs`, `sbp`, `dbp`, `hr`, `cbs`, `urea`, `wbc`, `hb`, `na`, `potas`, `plat`).
  - Tested using the **Box-Tidwell test** ($X \times \ln(X)$ interaction terms with outcome).
  - Supported by empirical logit plots to verify functional form.
* **Multicollinearity Assessment**:
  - Evaluated using Variance Inflation Factors (VIF / GVIF) via `car::vif()` on the multivariable model (confirming VIF < 5 to rule out collinearity, e.g., between SBP and DBP).
* **Model Specification**: Confirmed by ensuring relevant clinical confounders are retained and functional forms are verified.

---

## 5. APPLY
* **Univariable Logistic Regression (Screening Stage)**:
  - Fit simple binary logistic regression for each candidate independent variable using `glm(outcome ~ X, family = binomial)`.
  - Extract estimates with `broom::tidy()`:
    - Log-odds coefficient ($\beta$)
    - Standard error (SE)
    - Crude Odds Ratio ($\text{cOR} = e^\beta$)
    - 95% Confidence Intervals
    - Wald test statistic and p-value
  - **Screening Rule**: Variables with **$p < 0.25$** in univariable regression (or strong clinical plausibility) are shortlisted for initial multivariable modeling.
* **Multivariable Logistic Regression (Purposeful Selection)**:
  - Fit initial multivariable model with all shortlisted variables.
  - **No interaction terms** (strictly per study specification).
  - Execute backward elimination:
    - Sequentially remove non-significant variables ($p \ge 0.05$).
    - Check for confounding after each deletion: if removing a variable causes any remaining $\beta$ coefficient to change by $> 20\%$ ($\Delta\hat{\beta} > 20\%$), the variable is retained as an essential confounder.
  - Finalize parsimonious multivariable model.

---

## 6. ASSESS
* **Overall Model Fitness & Discrimination**:
  - **ROC Curve & AUC**:
    - Generate empirical ROC curve using `pROC::roc()`.
    - Calculate Area Under the Curve (AUC / c-statistic) with 95% DeLong confidence intervals.
    - Identify optimal cutoff probability via Youden's Index ($J = \text{Sensitivity} + \text{Specificity} - 1$).
    - Compute classification metrics: Sensitivity, Specificity, PPV, NPV, and classification accuracy.
  - **Goodness-of-Fit / Calibration**:
    - Perform Hosmer-Lemeshow goodness-of-fit test (`ResourceSelection::hoslem.test(g = 10)`). A $p > 0.05$ indicates acceptable calibration.
    - Report model deviance, AIC, and BIC.
* **Diagnostic Stability via `broom::augment()`**:
  - Calculate Pearson residuals, deviance residuals, leverage values ($h_i$), and Cook's distance ($D_i$).
  - Plot diagnostic index plots to inspect:
    - Residuals vs. predicted probabilities.
    - Leverage vs. deviance residuals (identifying high-leverage outliers).
    - Cook's distance plot (identifying influential cases).
  - Evaluate whether influential cases distort parameter estimates.

---

## 7. PRESENTATION
* **Table 1**: Baseline patient characteristics stratified by stroke outcome (`tbl_summary`).
* **Table 2**: Univariable logistic regression results ($\beta$, SE, crude OR, 95% CI, p-value).
* **Table 3**: Final multivariable logistic regression model ($\hat{\beta}$, SE, adjusted aOR, 95% CI, p-value) using `gtsummary::tbl_regression()`.
* **Table 4**: Combined Model Comparison Table (`tbl_merge`) showing side-by-side Crude OR vs. Adjusted OR with 95% CIs and p-values to demonstrate confounding adjustments.
* **Visual Plots**:
  - Publication-ready ROC curve with annotated AUC (95% CI).
  - Exploratory histograms, bar charts, and box plots.
  - Regression diagnostic plots.
* **Teaching Annotations**: Explanations of statistical concepts (odds vs. probability, logit interpretation, Wald test, Hosmer-Lemeshow, ROC-AUC) tailored for DrPH students.

---

## Confirmed Deliverable
- Interactive Quarto document (`stroke_fatality_analysis.qmd`) rendered to HTML, along with self-contained R code.
