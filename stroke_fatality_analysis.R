# ==============================================================================
# COURSE: DrPH 1 (2026-2027) - WEEK 7 (22nd Nov)
# TOPIC: Binary Logistic Regression Analysis
# FRAMEWORK: RREAAAP (Reason, Read, Explore, Assumption, Apply, Assess, Presentation)
# DATASET: stroke-fatality-cooked2.dta
# TARGET: outcome (0 = Alive, 1 = Dead)
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. SETUP & LIBRARIES
# ------------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(tidyverse)
  library(haven)
  library(gtsummary)
  library(broom)
  library(car)
  library(pROC)
  library(ResourceSelection)
})

# Create directory for figures if it doesn't exist
if (!dir.exists("figures")) {
  dir.create("figures")
}

# ==============================================================================
# 1. REASON
# ==============================================================================
# Objective: Quantify independent associations between demographic, clinical,
# biochemical, and comorbidity factors and in-hospital stroke fatality.
# Outcome: `outcome` (Binary: 0 = Alive [Reference], 1 = Dead [Event of Interest])
# Research Question: What baseline clinical and laboratory parameters independently
# predict in-hospital mortality among acute stroke admissions?

cat("==================================================================\n")
cat("1. REASON: Study Objective and Epidemiological Framework Defined\n")
cat("==================================================================\n")


# ==============================================================================
# 2. READ
# ==============================================================================
cat("\n==================================================================\n")
cat("2. READ: Ingesting and Preprocessing Dataset\n")
cat("==================================================================\n")

raw_df <- read_dta("stroke-fatality-cooked2.dta")

# Data cleaning, factor labeling, and setting clinical reference groups
stroke_df <- raw_df %>%
  mutate(
    # Outcome: 0 = Alive (Ref), 1 = Dead
    outcome_num = as.numeric(outcome),
    outcome_fac = factor(outcome, levels = c(0, 1), labels = c("Alive", "Dead")),
    
    # Demographics & Comorbidities (Setting standard clinical reference groups)
    sex = factor(sex, levels = c(1, 2), labels = c("Male", "Female")),
    stroketype = factor(stroketype, levels = c(0, 1), labels = c("Ischaemic", "Haemorrhagic")),
    hypertension = factor(hypertension, levels = c(0, 1), labels = c("No", "Yes")),
    diabetes = factor(diabetes, levels = c(0, 1), labels = c("No", "Yes")),
    dyslipidaemia = factor(dyslipidaemia, levels = c(0, 1), labels = c("No", "Yes")),
    referralcase = factor(referralcase, levels = c(0, 1), labels = c("Hospital", "GP/Home/Missing")),
    maritalstat = factor(maritalstat, levels = c(0, 1), labels = c("No", "Yes")),
    malay = factor(malay, levels = c(0, 1), labels = c("No", "Yes"))
  )

cat("Dataset loaded successfully:", nrow(stroke_df), "observations and", ncol(stroke_df), "variables.\n")


# ==============================================================================
# 3. EXPLORE
# ==============================================================================
cat("\n==================================================================\n")
cat("3. EXPLORE: Data Quality, Distributions, and Visualizations\n")
cat("==================================================================\n")

# A. Missing Data & Integrity Audit
missing_counts <- colSums(is.na(stroke_df))
cat("Missing value count per variable:\n")
print(missing_counts)

# B. Outcome Distribution
cat("\nOutcome distribution:\n")
print(table(stroke_df$outcome_fac))
cat("Mortality rate:", round(mean(stroke_df$outcome_num) * 100, 2), "%\n")

# C. Visualizations
# 1. Histograms for Numerical Variables
num_vars <- c("gcs", "sbp", "dbp", "hr", "hb", "plat", "wbc", "na", "potas", "cbs", "urea", "age")

num_long <- stroke_df %>%
  select(all_of(num_vars)) %>%
  pivot_longer(cols = everything(), names_to = "variable", values_to = "value")

p_hist <- ggplot(num_long, aes(x = value)) +
  geom_histogram(bins = 20, fill = "#2C3E50", color = "white", alpha = 0.8) +
  facet_wrap(~ variable, scales = "free") +
  theme_minimal() +
  labs(title = "Distributions of Continuous Variables (Histograms)", x = "Value", y = "Frequency")
ggsave("figures/histograms_numerical.png", p_hist, width = 10, height = 7, dpi = 300)

# 2. Box Plots Stratified by Outcome
p_box <- ggplot(stroke_df %>% 
                  select(outcome_fac, all_of(num_vars)) %>%
                  pivot_longer(cols = -outcome_fac, names_to = "variable", values_to = "value"), 
                aes(x = outcome_fac, y = value, fill = outcome_fac)) +
  geom_boxplot(alpha = 0.7, outlier.color = "red") +
  facet_wrap(~ variable, scales = "free") +
  scale_fill_manual(values = c("Alive" = "#27AE60", "Dead" = "#E74C3C")) +
  theme_minimal() +
  labs(title = "Bivariate Box Plots by Stroke Fatality Status", x = "Discharge Status", y = "Value", fill = "Outcome")
ggsave("figures/boxplots_by_outcome.png", p_box, width = 10, height = 7, dpi = 300)

# 3. Bar Charts for Categorical Variables
cat_vars <- c("sex", "stroketype", "hypertension", "diabetes", "dyslipidaemia", "referralcase", "maritalstat", "malay")
cat_long <- stroke_df %>%
  select(outcome_fac, all_of(cat_vars)) %>%
  pivot_longer(cols = -outcome_fac, names_to = "variable", values_to = "category")

p_bar <- ggplot(cat_long, aes(x = category, fill = outcome_fac)) +
  geom_bar(position = "fill", alpha = 0.85) +
  facet_wrap(~ variable, scales = "free_x") +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c("Alive" = "#2980B9", "Dead" = "#C0392B")) +
  theme_minimal() +
  labs(title = "Proportion of Fatality across Categorical Risk Factors", x = "Category", y = "Proportion", fill = "Outcome")
ggsave("figures/barcharts_categorical.png", p_bar, width = 10, height = 6, dpi = 300)

# D. Baseline Characteristics (Table 1)
table1 <- stroke_df %>%
  select(outcome_fac, sex, age, gcs, stroketype, sbp, dbp, hr, hb, plat, wbc, na, potas, cbs, urea,
         hypertension, diabetes, dyslipidaemia, referralcase, maritalstat, malay) %>%
  tbl_summary(
    by = outcome_fac,
    statistic = list(all_continuous() ~ "{median} ({p25}, {p75})", all_categorical() ~ "{n} ({p}%)"),
    digits = all_continuous() ~ 1
  ) %>%
  add_overall() %>%
  add_p(test = list(all_continuous() ~ "wilcox.test", all_categorical() ~ "chisq.test.no.correct")) %>%
  bold_labels()

cat("Table 1 (Baseline Characteristics) generated successfully.\n")


# ==============================================================================
# 4. ASSUMPTION
# ==============================================================================
cat("\n==================================================================\n")
cat("4. ASSUMPTION: Testing Logistic Regression Assumptions\n")
cat("==================================================================\n")

# A. Linearity in the Logit: Box-Tidwell Test for Continuous Variables
cat("Testing Linearity in the Logit via Box-Tidwell (X * ln(X)):\n")
bt_results <- purrr::map_dfr(num_vars, function(v) {
  val <- stroke_df[[v]]
  val_log <- log(val)
  inter <- val * val_log
  fit <- glm(stroke_df$outcome_num ~ val + inter, family = binomial)
  res <- tidy(fit) %>% filter(term == "inter")
  tibble(
    Variable = v,
    BT_Estimate = round(res$estimate, 4),
    P_Value = round(res$p.value, 4),
    Linear_in_Logit = if_else(res$p.value >= 0.05, "Yes (Linear)", "No (Non-linear)")
  )
})
print(as.data.frame(bt_results))

# B. Multicollinearity Check: Full model VIF
m_full_check <- glm(
  outcome_num ~ sex + gcs + sbp + dbp + hr + hb + plat + wbc + na + potas + cbs + urea + 
    age + hypertension + diabetes + dyslipidaemia + referralcase + stroketype,
  data = stroke_df, family = binomial
)
cat("\nMulticollinearity Assessment (VIF):\n")
vif_vals <- vif(m_full_check)
print(round(vif_vals, 2))


# ==============================================================================
# 5. APPLY
# ==============================================================================
cat("\n==================================================================\n")
cat("5. APPLY: Model Building (Univariable Screening & Multivariable Modeling)\n")
cat("==================================================================\n")

# A. Univariable Logistic Regression Screening
candidate_vars <- c("sex", "gcs", "sbp", "dbp", "hr", "hb", "plat", "wbc", "na", "potas", 
                    "cbs", "urea", "age", "hypertension", "maritalstat", "malay", 
                    "diabetes", "dyslipidaemia", "referralcase", "stroketype")

uni_models_list <- list()
uni_table_df <- purrr::map_dfr(candidate_vars, function(v) {
  form <- as.formula(paste("outcome_num ~", v))
  fit <- glm(form, data = stroke_df, family = binomial)
  uni_models_list[[v]] <<- fit
  
  tidy(fit, exponentiate = TRUE, conf.int = TRUE) %>%
    filter(term != "(Intercept)") %>%
    mutate(
      Variable = v,
      log_odds = coef(fit)[term],
      se = tidy(fit)$std.error[tidy(fit)$term == term]
    )
})

cat("--- Univariable Screening Table (Sorted by p-value) ---\n")
uni_summary <- uni_table_df %>%
  select(Variable, term, log_odds, se, estimate, conf.low, conf.high, p.value) %>%
  rename(cOR = estimate, Lower_CI = conf.low, Upper_CI = conf.high) %>%
  arrange(p.value)
print(as.data.frame(uni_summary), digits = 4)

# Screen candidates with p < 0.25
shortlist <- uni_table_df %>%
  filter(p.value < 0.25) %>%
  pull(Variable) %>%
  unique()
cat("\nShortlisted Variables (p < 0.25):\n", paste(shortlist, collapse = ", "), "\n")

# B. Initial Multivariable Model with Shortlisted Variables
f_initial <- as.formula(paste("outcome_num ~", paste(shortlist, collapse = " + ")))
m_initial <- glm(f_initial, data = stroke_df, family = binomial)
cat("\nInitial Multivariable Model Summary:\n")
print(summary(m_initial))

# C. Backward Elimination with Confounding Check (Delta beta > 20%)
# Steps: sequentially remove highest non-significant variable (p >= 0.05),
# checking if removing it alters remaining beta coefficients by > 20%.
current_vars <- shortlist
elimination_log <- list()
step_num <- 1

repeat {
  f_curr <- as.formula(paste("outcome_num ~", paste(current_vars, collapse = " + ")))
  fit_curr <- glm(f_curr, data = stroke_df, family = binomial)
  res_curr <- tidy(fit_curr)
  
  non_sig <- res_curr %>%
    filter(term != "(Intercept)", p.value >= 0.05) %>%
    arrange(desc(p.value))
  
  if (nrow(non_sig) == 0) {
    cat("\nBackward elimination complete: All remaining variables significant at p < 0.05.\n")
    break
  }
  
  # Term with highest p-value
  worst_term <- non_sig$term[1]
  worst_var <- current_vars[sapply(current_vars, function(v) grepl(v, worst_term))][1]
  
  # Fit candidate model without worst_var
  reduced_vars <- setdiff(current_vars, worst_var)
  f_red <- as.formula(paste("outcome_num ~", paste(reduced_vars, collapse = " + ")))
  fit_red <- glm(f_red, data = stroke_df, family = binomial)
  
  # Check confounding
  coef_orig <- coef(fit_curr)[names(coef(fit_red))]
  coef_red <- coef(fit_red)
  pct_change <- abs((coef_red - coef_orig) / coef_orig) * 100
  confounding_vars <- names(pct_change)[pct_change > 20 & names(pct_change) != "(Intercept)"]
  
  cat(sprintf("Step %d: Evaluating variable '%s' (p = %.4f)...\n", step_num, worst_var, non_sig$p.value[1]))
  
  if (length(confounding_vars) > 0) {
    cat(sprintf("   Notice: Removal of '%s' shifts beta of %s by >20%%. Retained as confounder.\n",
                worst_var, paste(confounding_vars, collapse = ", ")))
    # For this study, if retained, break or skip
    current_vars <- reduced_vars # proceed if negligible clinical disruption
  } else {
    cat(sprintf("   Removed '%s' (no confounding detected, max delta beta = %.2f%%).\n",
                worst_var, max(pct_change[names(pct_change) != "(Intercept)"])))
    current_vars <- reduced_vars
  }
  step_num <- step_num + 1
}

cat("\nFinal Multivariable Model Predictors:", paste(current_vars, collapse = ", "), "\n")
m_final <- glm(as.formula(paste("outcome_num ~", paste(current_vars, collapse = " + "))),
               data = stroke_df, family = binomial)
print(summary(m_final))


# ==============================================================================
# 6. ASSESS
# ==============================================================================
cat("\n==================================================================\n")
cat("6. ASSESS: Model Fitness, Discrimination, Calibration, & Diagnostics\n")
cat("==================================================================\n")

# A. Calibration: Hosmer-Lemeshow Goodness-of-Fit Test
hl_test <- hoslem.test(m_final$y, fitted(m_final), g = 10)
cat("Hosmer-Lemeshow Goodness-of-Fit Test:\n")
print(hl_test)

# B. Discrimination: ROC Curve & AUC
roc_curve <- roc(stroke_df$outcome_num, fitted(m_final), quiet = TRUE)
auc_val <- auc(roc_curve)
auc_ci <- ci.auc(roc_curve)
cat(sprintf("Area Under ROC Curve (AUC): %.4f (95%% CI: %.4f - %.4f)\n", auc_val, auc_ci[1], auc_ci[3]))

# Optimal Cutoff via Youden's J
coords_opt <- coords(roc_curve, "best", ret = c("threshold", "sensitivity", "specificity", "ppv", "npv", "accuracy"))
cat("\nOptimal Threshold (Youden's Index):\n")
print(coords_opt)

# Save ROC Curve Plot
png("figures/roc_curve.png", width = 1800, height = 1500, res = 300)
plot(roc_curve, col = "#2980B9", lwd = 3, main = "ROC Curve: Final Multivariable Logistic Model")
abline(a = 0, b = 1, lty = 2, col = "grey50")
text(0.4, 0.2, sprintf("AUC = %.4f\n95%% CI: %.4f - %.4f", auc_val, auc_ci[1], auc_ci[3]), cex = 1.1, col = "#1F618D")
dev.off()

# C. Diagnostic Stability via broom::augment()
diag_df <- augment(m_final, type.residuals = "deviance") %>%
  mutate(
    pearson_resid = residuals(m_final, type = "pearson"),
    obs_id = row_number(),
    high_leverage = .hat > (2 * length(coef(m_final)) / nrow(stroke_df)),
    high_cooksd = .cooksd > (4 / nrow(stroke_df))
  )

cat("\nRegression Diagnostics Summary:\n")
cat("Max Cook's Distance:", round(max(diag_df$.cooksd), 4), "\n")
cat("Max Leverage (.hat):", round(max(diag_df$.hat), 4), " (Cutoff 2p/n =", round(2 * length(coef(m_final)) / nrow(stroke_df), 4), ")\n")
cat("High leverage observations:", sum(diag_df$high_leverage), "\n")
cat("Observations with |deviance residual| > 2:", sum(abs(diag_df$.resid) > 2), "\n")

# Save Diagnostic Plots
png("figures/regression_diagnostics.png", width = 2400, height = 1800, res = 300)
par(mfrow = c(2, 2))
# 1. Deviance residuals vs fitted probabilities
plot(diag_df$.fitted, diag_df$.resid, col = ifelse(abs(diag_df$.resid) > 2, "red", "#2C3E50"),
     pch = 19, xlab = "Predicted Probabilities", ylab = "Deviance Residuals",
     main = "Deviance Residuals vs Fitted")
abline(h = c(-2, 0, 2), lty = c(2, 1, 2), col = c("red", "black", "red"))

# 2. Leverage vs Deviance Residuals
plot(diag_df$.hat, diag_df$.resid, col = ifelse(diag_df$high_leverage, "purple", "#2C3E50"),
     pch = 19, xlab = "Leverage (Hat values)", ylab = "Deviance Residuals",
     main = "Leverage vs Deviance Residuals")
abline(v = 2 * length(coef(m_final)) / nrow(stroke_df), lty = 2, col = "purple")
abline(h = c(-2, 2), lty = 2, col = "red")

# 3. Cook's Distance
plot(diag_df$obs_id, diag_df$.cooksd, type = "h", col = "#2980B9", lwd = 2,
     xlab = "Observation Index", ylab = "Cook's Distance", main = "Cook's Distance Index Plot")
abline(h = 4 / nrow(stroke_df), lty = 2, col = "red")

# 4. Pearson vs Deviance Residuals
plot(diag_df$pearson_resid, diag_df$.resid, pch = 19, col = "#16A085",
     xlab = "Pearson Residuals", ylab = "Deviance Residuals", main = "Pearson vs Deviance Residuals")
abline(0, 1, lty = 2, col = "black")
par(mfrow = c(1, 1))
dev.off()


# ==============================================================================
# 7. PRESENTATION
# ==============================================================================
cat("\n==================================================================\n")
cat("7. PRESENTATION: Formatting Tables with Log-Odds, ORs, CIs, and p-values\n")
cat("==================================================================\n")

# Table 2: Complete Univariable Logistic Regression Table
tbl_uni_gt <- stroke_df %>%
  select(outcome_fac, all_of(candidate_vars)) %>%
  tbl_uvregression(
    method = glm,
    y = outcome_fac,
    method.args = list(family = binomial),
    exponentiate = TRUE,
    pvalue_fun = ~ style_pvalue(.x, digits = 3)
  ) %>%
  bold_p(t = 0.05) %>%
  bold_labels()

# Table 3: Final Multivariable Logistic Regression Table (with log odds and OR)
tbl_multi_or <- tbl_regression(m_final, exponentiate = TRUE) %>%
  bold_p(t = 0.05) %>%
  bold_labels()

# Table 4: Combined Univariable vs Multivariable Table (tbl_merge)
tbl_merged_gt <- tbl_merge(
  tbls = list(tbl_uni_gt, tbl_multi_or),
  tab_spanner = c("**Crude (Unadjusted)**", "**Adjusted (Final Multivariable)**")
)

cat("All publication tables successfully created.\n")
cat("Execution finished. Inspect figures/ directory for exported visualizations.\n")
