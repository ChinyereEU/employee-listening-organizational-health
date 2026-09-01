# ============================================================
# Employee Listening and Organizational Health Analytics
# Script: 05_organizational_analytics.R
# 
# Purpose: 
# Analyze employee-experience scores across organizational
# groups and identify patterns relevant to organizational health.
# 
# This script uses the validated survey response dataset produced
# in Script 04
# 
# Key analyses:
# - Organizational-level construct summaries
# - Construct comparisons across business units and departments
# - Group-level response counts and reporting eligibility
# - Privacy-conscious organizational reporting
# - Identification of areas with comparatively lower experience scores
# 
# Input:
#   data/processed/survey-responses.xlsx
#   
# Output:
#   Analytical objects and model results used for downstream reporting.
#   
# Notes:
#   Survey responses are synthetic and do not represent real
#   employees or organizations.
# ============================================================

# 1. Load packages ------------------------------------------------

library(tidyverse)
library(readxl)

# 2. Load validated survey response ------------------------------

survey_responses = read_xlsx("data/processed/survey_responses.xlsx")

# 3. Inspect ------------------------------------------------------

dim(survey_responses)

names(survey_responses)

# 4. Define organizational and analysis variables ----------------

organizational_groups = c(
  "business_unit",
  "department"
)

construct_names = c(
  "engagement",
  "manager_effectiveness",
  "psychological_safety",
  "growth_development",
  "workload_sustainability",
  "belonging"
)

outcome_names = c(
  "intent_to_stay",
  "ovl_01"
)

# Check that everything exists

stopifnot(
  "Some organizational grouping variables are missing." = 
    all(
      organizational_groups %in%
        names(survey_responses)
    ),
  
  "Some employee-experience constructs are missing." = 
    all(
      construct_names %in%
        names(survey_responses)
    ),
  
  "Some outcome variables are missing." = 
    all(
      outcome_names %in%
        names(survey_responses)
    )
)

# 5. Define the analysis population --------------------------------
# Use the `usable response` flag to define eligible responses.

analysis_data = survey_responses %>%
  filter(
    usable_response == TRUE
  )

# Inspect
dim(analysis_data)

analysis_data %>%
  count(survey_wave)

# Verify the analysis population
stopifnot(
  "Organizational analysis dataset contains unusable responses." = 
    all(
      analysis_data$usable_response == TRUE
    )
)

# 6. Define minimum reporting threshold ---------------------------
# Use the established threshold of 10 usable responses.

minimum_reporting_n = 10

# Validate minimum reporting parameter
stopifnot(
  "Minimum reporting threshold must be at least 10." = 
    minimum_reporting_n >= 10
)

# 7. Calculate group-level response counts ------------------------
# Number of usable survey responses within each business unit & department.

business_unit_counts = analysis_data %>%
  count(
    business_unit,
    name = "usable_responses"
  )

department_counts = analysis_data %>%
  count(
    business_unit,
    department,
    name = "usable_responses"
  )

business_unit_counts

department_counts

# Reportability flag

business_unit_counts = business_unit_counts %>%
  mutate(
    reporting_status = if_else(
      usable_responses >= minimum_reporting_n,
      "Reportable",
      "Suppressed"
    )
  )

department_counts = department_counts %>%
  mutate(
    reporting_status = if_else(
      usable_responses >= minimum_reporting_n,
      "Reportable",
      "Suppressed"
    )
  )

business_unit_counts

department_counts

# 8. Business-unit construct summaries ----------------------------
# Mean, SD for each employee-experience construct by business unit & department.

business_unit_summary = analysis_data %>%
  group_by(business_unit) %>%
  summarise(
    across(
      all_of(construct_names),
      list(
        mean = ~ mean(.x, na.rm = TRUE),
        sd = ~ sd(.x, na.rm = TRUE)
      ),
      .names = "{.col}_{.fn}"
    ),
    .groups = "drop"
  )

business_unit_summary

# Department-level construct summaries ----------------------------

department_summary = analysis_data %>%
  group_by(
    business_unit,
    department
  ) %>%
  summarise(
    across(
      all_of(construct_names),
      list(
        mean = ~ mean(.x, na.rm = TRUE),
        sd = ~ sd(.x, na.rm = TRUE)
      ),
      .names = "{.col}_{.fn}"
    ),
    .groups = "drop"
  )

department_summary

# 9. Validate organizational summaries ----------------------------
# Verify that the reported means and SDs are based on the intended 
# analysis population and that no construct produces an invalid summary.

stopifnot(
  "Business-unit summary contains unexpected rows." = 
    nrow(business_unit_summary) == 
    n_distinct(analysis_data$business_unit),
  
  "Department summary contains unexpected rows." = 
    nrow(department_summary) ==
    n_distinct(
      analysis_data %>%
        distinct(business_unit, department)
    )
)

stopifnot(
  
  "Business-unit construct means fall outside the expected 1-5 range." = 
    all(
      unlist(
        business_unit_summary %>%
          select(ends_with("_mean")) 
      ) >= 1 &
        unlist(
          business_unit_summary %>%
            select(ends_with("_mean"))
        ) <= 5
    ),
  
  "Department construct means fall outside the expected 1-5 range." = 
    all(
      unlist(
        department_summary %>%
          select(ends_with("_mean"))
      ) >= 1 &
        unlist(
          department_summary %>%
            select(ends_with("_mean"))
        ) <= 5
    )
) 

# 10. Business-unit construct comparison --------------------------
# Long-format comparison table showing each business unit's mean score
# for each employee-experience construct.

business_unit_comparison = analysis_data %>%
  group_by(business_unit) %>%
  summarise(
    across(
      all_of(construct_names),
      ~ mean(.x, na.rm = TRUE),
      .names = "{.col}"
    ),
    .groups = "drop"
  ) %>%
  pivot_longer(
    cols = all_of(construct_names),
    names_to = "construct",
    values_to = "mean_score"
  ) %>%
  arrange(
    construct,
    desc(mean_score)
  )

business_unit_comparison

# Check the mean range

stopifnot(
  "Business-unit construct means fall outside the expected 1-5 range." = 
    all(business_unit_comparison$mean_score >= 1 &
          business_unit_comparison$mean_score <= 5)
)

# 11. Rank business-unit construct results -----------------------
# Calculate each construct's highest and lowest scoring business unit
# and the difference between them.

business_unit_ranges = business_unit_comparison %>%
  group_by(construct) %>%
  summarise(
    highest_score = max(mean_score),
    lowest_score = min(mean_score),
    score_range = highest_score - lowest_score,
    highest_business_unit = business_unit[which.max(mean_score)],
    lowest_business_unit = business_unit[which.min(mean_score)],
    .groups = "drop"
  )

business_unit_ranges

# Validate

stopifnot(
  "Business-unit score ranges contain negative values." = 
    all(
      business_unit_ranges$score_range >= 0
      ),
  
  "Business-unit score range exceed the possible 1-5 scale." = 
    all(
      business_unit_ranges$score_range >= 0 &
        business_unit_ranges$score_range <= 4
    )
)

# 12. Department-level construct comparison ----------------------

department_comparison = analysis_data %>%
  group_by(
    business_unit,
    department
  ) %>%
  summarise(
    across(
      all_of(construct_names),
      ~ mean(.x, na.rm = TRUE),
      .names = "{.col}"
    ),
    .groups = "drop"
  ) %>%
  pivot_longer(
    cols = all_of(construct_names),
    names_to = "construct",
    values_to = "mean_score"
  ) %>%
  arrange(
    construct,
    desc(mean_score)
  )

department_comparison

# Validate

stopifnot(
  "Department construct means fall outside the expected 1-5 range." =
    all(
      department_comparison$mean_score >= 1 &
        department_comparison$mean_score <= 5
    )
)

# 13. Rank department-level construct results --------------------

department_ranges = department_comparison %>%
  group_by(construct) %>%
  summarise(
    highest_score = max(mean_score),
    lowest_score = min(mean_score),
    score_range = highest_score - lowest_score,
    highest_department = department[
      which.max(mean_score)
    ],
    lowest_department = department[
      which.min(mean_score)
    ],
    .groups = "drop"
  )

department_ranges

# Validate

stopifnot(
  "Department score ranges contain invalid values." =
    all(
      department_ranges$score_range >= 0 &
        department_ranges$score_range <= 4
    )
)

# 14. Add department sample sizes --------------------------------
# We want the final organizational results to carry the number of 
# usable responses (n) for each department.
# 
# This way, the reporting threshold is transparent & context is
# given to the means.

department_summary_with_n = analysis_data %>%
  group_by(
    business_unit,
    department
  ) %>%
  summarise(
    usable_responses = n(),
    across(
      all_of(construct_names),
      ~ mean(.x, na.rm = TRUE),
      .names = "{.col}_mean"
    ),
    .groups = "drop"
  )

department_summary_with_n

# Verify the privacy rule

stopifnot(
  "A department falls below the minimum reporting threshold." = 
    all(
      department_summary_with_n$usable_responses >= minimum_reporting_n
    )
)

# 15. Department-level intent-to-stay analysis --------------------
# Calculate the mean `intent_to_stay` score by department, while keeping
# the usable response count visible.

department_intent = analysis_data %>%
  group_by(
    business_unit,
    department
  ) %>%
  summarise(
    usable_responses = n(),
    
    intent_to_stay_n = sum(
      !is.na(intent_to_stay)
      ),
    intent_to_stay_mean = mean(
      intent_to_stay,
      na.rm = TRUE
    ),
    intent_to_stay_sd = sd(
      intent_to_stay,
      na.rm = TRUE
    ),
    .groups = "drop"
  )

department_intent

# Validate scores

stopifnot(
  "Intent-to-stay response counts exceed usable response counts." =
    all(
      department_intent$intent_to_stay_n <=
        department_intent$usable_responses
    ),
  
  "Department intent-to-stay means fall outside the expected 1-5 range." =
    all(
      department_intent$intent_to_stay_mean >= 1 &
        department_intent$intent_to_stay_mean <= 5
    ),
  
  "Department intent-to-stay SDs are invalid." =
    all(
      department_intent$intent_to_stay_sd >= 0
    )
)

# 16. Business-unit intent-to-stay analysis --------------------
# Calculate the mean `intent_to_stay` score by business-unit, while keeping
# the usable response count visible.

business_unit_intent = analysis_data %>%
  group_by(
    business_unit
  ) %>%
  summarise(
    usable_responses = n(),
    
    intent_to_stay_n = sum(
      !is.na(intent_to_stay)
    ),
    intent_to_stay_mean = mean(
      intent_to_stay,
      na.rm = TRUE
    ),
    intent_to_stay_sd = sd(
      intent_to_stay,
      na.rm = TRUE
    ),
    .groups = "drop"
  )

business_unit_intent

# Validate scores

stopifnot(
  "Business-unit intent-to-stay means fall outside the expected 1-5 range." =
    all(
      business_unit_intent$intent_to_stay_mean >= 1 &
        business_unit_intent$intent_to_stay_mean <= 5
    ),
  
  "Business-unit intent-to-stay response counts exceed usable response counts." =
    all(
      business_unit_intent$intent_to_stay_n <=
        business_unit_intent$usable_responses
    ),
  
  "Business-unit intent-to-stay SDs are invalid." =
    all(
      business_unit_intent$intent_to_stay_sd >= 0
    ),
  
  "A business unit falls below the minimum reporting threshold." =
    all(
      business_unit_intent$usable_responses >=
        minimum_reporting_n
    )
)

# 17. Identify lowest-scoring departments -------------------------
# Identify the lowest-scoring department for each construct.

department_lowest_scores = department_comparison %>%
  group_by(construct) %>%
  slice_min(
    order_by = mean_score,
    n = 1,
    with_ties = TRUE
  ) %>%
  ungroup() %>%
  arrange(
    mean_score,
    construct
  )

department_lowest_scores

# Validate score range

stopifnot(
  "Department lowest-score table contains scores outside the expected 1-5 range." = 
    all(
      department_lowest_scores$mean_score >= 1 &
        department_lowest_scores$mean_score <= 5
    )
)

# 18. Identify highest-scoring departments ------------------------

department_highest_scores = department_comparison %>%
  group_by(construct) %>%
  slice_max(
    order_by = mean_score,
    n = 1,
    with_ties = TRUE
  ) %>%
  ungroup() %>%
  arrange(
    desc(mean_score),
    construct
  )

department_highest_scores

# 19. Department-level score spread -------------------------------
# Rank the constructs by their department-level spread.

department_range_rank = department_ranges %>%
  arrange(desc(score_range))

department_range_rank

# 20. Business-unit score spread -------------------------------

business_unit_ranges = business_unit_comparison %>%
  group_by(construct) %>%
  summarise(
    highest_score = max(mean_score),
    lowest_score = min(mean_score),
    score_range = highest_score - lowest_score,
    highest_business_unit = business_unit[
      which.max(mean_score)
    ],
    lowest_business_unit = business_unit[
      which.min(mean_score)
    ],
    .groups = "drop"
  ) %>%
  arrange(desc(score_range))

business_unit_ranges

# 21. Employee-experience associations with intent to stay --------
# Which aspects of employee experience have the strongest observed 
# relationship w/intent to stay?

intent_association = analysis_data %>%
  select(
    all_of(construct_names),
    intent_to_stay
  ) %>%
  cor(
    use = "pairwise.complete.obs"
  ) %>%
  as.data.frame() %>%
  select(intent_to_stay) %>%
  tibble::rownames_to_column("construct") %>%
  filter(
    construct != "intent_to_stay"
  ) %>%
  rename(
    correlation = intent_to_stay
  ) %>%
  arrange(
    desc(correlation)
  )

intent_association
 
# 22. Multiple regression of intent to stay ------------------------
# Do these relationships remain meaningful when the six constructs 
# are considered simultaneously?
# 
# Which employee-experience dimensions are uniquely associated with 
# intent to stay after accounting for the other dimensions?
# 
# MR w/intent_to_stay as the outcome and the six employee-experience
# constructs as predictors.

intent_model = lm(
  intent_to_stay ~
    engagement +
    manager_effectiveness +
    psychological_safety +
    growth_development +
    workload_sustainability +
    belonging,
  data = analysis_data
)

summary(intent_model)

# 23. Standardized coefficients for intent-to-stay model ----------
# So we can compare the relative strength of the six predictors on 
# appx. the same standardized scale rather than treating the raw 
# coefficients as though they were directly comparable.

intent_model_standardized = lm(
  scale(intent_to_stay) ~
    scale(engagement) +
    scale(manager_effectiveness) +
    scale(psychological_safety) +
    scale(growth_development) +
    scale(workload_sustainability) +
    scale(belonging),
  data = analysis_data
)

summary(intent_model_standardized)

# 23a. Save standardized model coefficients ----------------------

standardized_model_coefficients = broom::tidy(
  intent_model_standardized
) %>%
  filter(
    term != "(Intercept)"
  )

write_csv(
  standardized_model_coefficients,
  "outputs/standardized_model_coefficients.csv"
)

# 24. Multicollinearity diagnostics -------------------------------
# Because the six predictors are correlated with one another, we must
# check whether they are sufficiently distinct for the regression 
# coefficients to be interpreted sensibly.
# 
# Are the predictors so strongly related to one another that they make
# it difficult for the regression model to estimate their individual
# associations with intent to stay.
# 
# Variance Inflation Factor (VIF) measures how much the uncertainty of
# each coefficient is inflated because of overlap with other predictors.
# 
# `How well can I predict a given predictor using all the other predictors?`
# Suppose those other predictors could explain 80% of the given predictor's
# variation; then the given predictor is highly redundant with the other
# predictors.
# 
# VIF = 1 indicates no multicollinearity; larger values indicate greater
# redundancy among predictors.
# 
# Roughly:
#   | VIF | Interpretation                   |
#   | --- | -------------------------------- |
#   |  ~1 | Essentially no multicollinearity |
#   | 1–5 | Generally acceptable             |
#   |  >5 | Potential concern                |
#   | >10 | Serious concern                  |
#   
# All VIF values are close to 1 (1.18-1.34), indicating very low 
# multicollinearity. The predictors therefore provide sufficiently distinct
# information for their individual regression coefficients to be interpreted
# as unique associations with intent to stay.
# 
# Multicollineariy is about how the predictors relate to each other, not
# about whether they relate to the outcome.
# 
# Estimating each predictor's individual contribution.

vif_results = car::vif(intent_model)

vif_results

# 25. Regression residual diagnostics-----------------------------
# Do the model's residuals behave reasonably?

intent_residuals = residuals(intent_model)

summary(intent_residuals)

hist(
  intent_residuals,
  breaks = 30,
  main = "Distribution of Intent-to-Stay Model Residuals",
  xlab = "Residual"
)

# 26. Residuals versus fitted values ------------------------------
# Is the residual variance reasonably constant across the range of
# predicted intent-to-stay scores?

plot(
  fitted(intent_model),
  residuals(intent_model),
  xlab = "Fitted Intent-to-Stay",
  ylab = "Residual",
  main = "Residuals vs Fitted Values"
)

abline(
  h = 0,
  lty = 2
)

# Residuals Interpretation =========================================
# Residuals are centered approximately around zero with no obvious
# funnel-shaped increase in variance. The diagonal banding reflects 
# the discrete 1-5 nature of the intent-to-stay outcome rather than
# a continuous outcome.
# 
# Since intent_to_stay is a 1-5 ordinal composite, linear regression
# is being used here as a practical approximation for the project
# demonstration, not because the outcome is truly continuous.

# 27. Intent-to-stay model performance ---------------------------
# Quantify how well the model predicts the observed intent-to-stay
# scores.
# 
# RMSE & MAE

intent_predictions = predict(intent_model)

intent_actual = analysis_data$intent_to_stay[
  !is.na(analysis_data$intent_to_stay)
]

intent_rmse = sqrt(
  mean(
    (intent_actual - intent_predictions)^2
  )
)

intent_mae = mean(
  abs(
    intent_actual - intent_predictions
  )
)

intent_model_performance = tibble(
  metric = c(
    "R-squared",
    "RMSE",
    "MAE"
  ),
  value = c(
    summary(intent_model)$r.squared,
    intent_rmse,
    intent_mae
  )
)

intent_model_performance

# 28. Consolidate Script 05 analytical outputs -------------------

script05_outputs = list(
  business_unit_summary = business_unit_summary,
  department_summary = department_summary,
  department_intent = department_intent,
  business_unit_intent = business_unit_intent,
  department_lowest_scores = department_lowest_scores,
  department_highest_scores = department_highest_scores,
  department_range_rank = department_range_rank,
  intent_association = intent_association,
  intent_model = intent_model,
  intent_model_standardized = intent_model_standardized,
  vif_results = vif_results,
  intent_model_performance = intent_model_performance
)

names(script05_outputs)

# 29. Final Script 05 output validation --------------------------

stopifnot(
  "Business-unit summary is missing." =
    exists("business_unit_summary"),
  
  "Department summary is missing." =
    exists("department_summary"),
  
  "Business-unit intent analysis is missing." =
    exists("business_unit_intent"),
  
  "Department intent analysis is missing." =
    exists("department_intent"),
  
  "Intent association analysis is missing." =
    exists("intent_association"),
  
  "Intent-to-stay regression model is missing." =
    exists("intent_model"),
  
  "VIF results are missing." =
    exists("vif_results"),
  
  "Model performance results are missing." =
    exists("intent_model_performance")
)

# Check the core model outputs

stopifnot(
  "Intent-to-stay model R-squared is outside the valid 0-1 range." =
    summary(intent_model)$r.squared >= 0 &
    summary(intent_model)$r.squared <= 1,
  
  "Intent-to-stay model performance R-squared does not match the model." =
    isTRUE(
      all.equal(
        intent_model_performance$value[
          intent_model_performance$metric == "R-squared"
        ],
        summary(intent_model)$r.squared
      )
    )
)

# 30. Script 05 completion note -----------------------------------
# 
# Script 05 completed the organizational-level employee-experience
# analysis using responses meeting the defined usability criteria.
# 
# Analyses included:
# - Business-unit and department-level construct summaries
# - Department-level highest and lowest construct scores
# - Intent-to-stay summaries by business unit and department
# - Correlations between employee-experience constructs and intent to stay
# - Multiple regression predicting intent to stay
# - Standardized regression coefficients
# - Multicollinearity diagnostics using VIF
# - Regression residual diagnostics
# - Model performance metrics
# 
# All findings are descriptive/associational and reflect the synthetic
# data-generating process documented in the project assumptions.