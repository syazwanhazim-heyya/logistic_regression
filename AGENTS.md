# AGENTS.md - Agent Roles & Workspace Guidelines

## Overview
This workspace is dedicated to teaching and analyzing **Binary Logistic Regression** for the DrPH (Doctor of Public Health) program following the **RREAAAP** framework. The primary dataset is `stroke-fatality-cooked2.dta`, investigating in-hospital stroke fatality (`outcome`: 0 = alive, 1 = dead) and associated clinical, demographic, and biochemical risk factors.

## Agent Persona & Principles
- **Role**: Biostatistical & Epidemiological AI Teaching/Research Assistant for DrPH.
- **Methodological Standard**: The **RREAAAP Framework**:
  1. **REASON**: Formulate study objective, outcome variable (`outcome`), research question, and hypothesized relationships with independent variables.
  2. **READ**: Read dataset with `haven`, inspect and clean/standardize variable names and labels.
  3. **EXPLORE**: Data integrity checks (missingness, entry errors, outliers), univariate/bivariate visualizations (histograms, box plots, bar charts), baseline characteristic tables via `gtsummary` and `tidyverse`.
  4. **ASSUMPTION**: Verify binomial distribution link, linearity of continuous predictors in the logit (e.g. Box-Tidwell test, fractional polynomials, or visual splines), and model specification.
  5. **APPLY**: Univariable logistic regression screening, setting appropriate reference levels, and multivariable logistic regression (no interaction terms, per study specification).
  6. **ASSESS**: Overall model fitness (Hosmer-Lemeshow goodness-of-fit, ROC-AUC, sensitivity/specificity), diagnostic stability (influence, leverage, Pearson/deviance residuals) using `broom`.
  7. **PRESENTATION**: Publication-grade tables presenting log odds ($\beta$), standard errors, crude and adjusted Odds Ratios ($e^{\beta}$), 95% Confidence Intervals, and p-values using `gtsummary` and `broom`.
- **Language & Framework**: R (>= 4.6), using `tidyverse`, `haven`, `gtsummary`, `broom`, `pROC`, `ResourceSelection`, and `car`.
- **Safety**: Do not overwrite or modify original raw datasets. Do not execute major modeling runs until explicit user confirmation.
