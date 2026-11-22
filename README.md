# In-Hospital Stroke Fatality Analysis: Binary Logistic Regression

[![R](https://img.shields.io/badge/R-%3E%3D%204.6.0-blue.svg)](https://www.r-project.org/)
[![Framework](https://img.shields.io/badge/Framework-RREAAAP-brightgreen.svg)]()
[![Method](https://img.shields.io/badge/Model-Binary%20Logistic%20Regression-orange.svg)]()
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)]()

> **Course**: DrPH 1 (2026–2027) — Biostatistics & Epidemiological Methods (Week 7)  
> **Topic**: Binary Logistic Regression (In-Hospital Stroke Fatality)  
> **Dataset**: `stroke-fatality-cooked2.dta` ($N = 226$, 22 variables)  
> **Outcome**: `outcome` ($0 = \text{Alive}$, $1 = \text{Dead}$)  

---

## Overview

This repository implements a rigorous, reproducible epidemiological investigation of in-hospital stroke mortality following the **RREAAAP** framework:

* **REASON**: Formulate study questions, define binary outcome (`outcome`), and hypothesize relationships with clinical, demographic, biochemical, and comorbidity variables.
* **READ**: Ingest data using `haven::read_dta()`, clean and standardize variable names, and set explicit factor levels and reference categories.
* **EXPLORE**: Data integrity audits (missing data, entry errors, physiological boundaries); distributions via histograms, bar charts, and box plots; baseline Table 1 via `gtsummary::tbl_summary()`.
* **ASSUMPTION**: Check binomial link, evaluate linearity in the logit using the Box-Tidwell test ($X \ln X$), and test for multicollinearity (VIF).
* **APPLY**: Univariable logistic regression screening ($p < 0.25$), initial multivariable model fitting, and purposeful backward elimination with confounding checks ($\Delta\hat{\beta} > 20\%$) — strictly **without interaction terms**.
* **ASSESS**: Calibration via Hosmer-Lemeshow goodness-of-fit, discrimination via empirical ROC-AUC (95% CI) and Youden's J cutoff, and diagnostic stability using `broom::augment()` (deviance/Pearson residuals, leverage, Cook's distance).
* **PRESENTATION**: Publication-grade tables comparing crude and adjusted odds ratios (aOR), 95% CIs, and p-values using `gtsummary`.

---

## Key Epidemiological Findings

### Final Multivariable Model (`outcome ~ sex + gcs`)

| Characteristic | Crude OR (95% CI) | Crude p-value | Adjusted aOR (95% CI) | Adjusted p-value |
|:---|:---:|:---:|:---:|:---:|
| **Glasgow Coma Scale (GCS)** | 0.53 (0.44, 0.61) | < 0.001 | **0.49 (0.39, 0.58)** | **< 0.001** |
| **Sex** | | | | |
| — Male | 1.00 (Reference) | — | 1.00 (Reference) | — |
| — Female | 1.53 (0.84, 2.84) | 0.166 | **0.33 (0.10, 0.93)** | **0.044** |

### Core Pedagogical Takeaways
1. **Glasgow Coma Scale (GCS)**:
   * Each 1-point increase in admission GCS (higher level of consciousness) is associated with a **51% reduction** in the odds of in-hospital death ($\text{aOR} = 0.49, 95\% \text{ CI: } 0.39 - 0.58$), holding sex constant.
   * Conversely, each 1-point drop in GCS increases the odds of in-hospital death by a factor of $2.05$ (**105% increase in death odds per point lost**).
2. **Sex as a Negative Confounder**:
   * In unadjusted analysis, female sex appeared to have higher mortality ($\text{cOR} = 1.53, p = 0.166$).
   * After adjusting for baseline consciousness level (GCS), female sex demonstrated a significant **67% reduction in mortality odds** ($\text{aOR} = 0.33, p = 0.044$). This highlights classic **negative confounding** in acute hospital epidemiology, as female patients presented with more severe neurological compromise.

### Model Performance & Diagnostics
* **Discrimination (ROC-AUC)**: **0.9434** ($95\% \text{ CI: } 0.9099 - 0.9769$) — *Outstanding discriminatory performance*.
* **Calibration (Hosmer-Lemeshow GOF)**: $\chi^2 = 7.803, df = 4, p = 0.099 > 0.05$ (Good calibration).
* **Classification at Youden's J (Cutoff = 0.229)**: Sensitivity: **91.9%**, Specificity: **86.0%**, PPV: **71.3%**, NPV: **96.6%**, Accuracy: **87.6%**.
* **Diagnostic Stability**: Maximum Cook's distance is $0.112$ (well below the disruptive cutoff of 1.0), confirming no single influential point distorted model coefficients.

---

## Repository Structure

```
├── README.md                          # Project documentation and summary
├── AGENTS.md                          # Agent roles and operating principles
├── implementations.md                 # Step-by-step implementation plan
├── stroke_fatality_analysis.R         # Complete, modular R analysis script
├── stroke_fatality_analysis.Rmd       # R Markdown source for interactive report
├── stroke_fatality_analysis.html      # Rendered interactive HTML report
├── stroke-fatality-cooked2.dta        # Original Stata dataset
├── figures/                           # High-resolution publication plots
│   ├── histograms_numerical.png       # Distributions of continuous variables
│   ├── boxplots_by_outcome.png        # Biomarkers stratified by fatality status
│   ├── barcharts_categorical.png      # Mortality proportions across categorical factors
│   ├── roc_curve.png                  # Empirical ROC curve and AUC (95% CI)
│   └── regression_diagnostics.png     # Residuals, leverage, and Cook's distance
└── .gitignore                         # Ignored temporary files
```

---

## Getting Started & Reproducibility

### Prerequisites
* R (>= 4.5.0)
* R Packages:
  ```r
  install.packages(c("tidyverse", "haven", "gtsummary", "broom", "car", "pROC", "ResourceSelection", "rmarkdown", "knitr"))
  ```

### Running the Analysis
1. Execute the full script from the terminal:
   ```bash
   Rscript stroke_fatality_analysis.R
   ```
2. Render the interactive HTML report:
   ```r
   rmarkdown::render("stroke_fatality_analysis.Rmd")
   ```
