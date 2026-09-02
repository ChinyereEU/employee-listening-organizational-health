# ============================================================
# Employee Listening and Organizational Health Analytics
# Script: 06_predictive_modeling.R
# 
# Purpose:
# Develop and evaluate predictive models of employee intent to
# stay using validated employee-experience measures and relevant
# organizational characteristics.
# 
# This script uses the validated survey response dataset produced
# in Script 04 and analytical measures examined in Scripts 04 and 05.
# 
# Key analyses:
# - Predictive modeling of intent to stay
# - Model performance evaluation
# - Prediction diagnostics
# - Interpretation of important predictors
# 
# Input:
#   data/processed/survey_responses.xlsx
#   
# Output:
#   Predictive modeling objects and results used for downstream
#   reporting.
#   
# Notes:
#   Survey responses are synthetic and do not represent real
#   employees or organizations.
# ============================================================

# 1. Load packages ------------------------------------------------

library(tidyverse)
library(readxl)

# 2. Load validated survey response data --------------------------

survey_responses = read_xlsx("data/processed/survey_responses.xlsx")

# 3. Inspect ------------------------------------------------------

dim(survey_responses)

names(survey_responses)

# 4. Define modeling variables -----------------------------------

construct_names = c(
  "engagement",
  "manager_effectiveness",
  "psychological_safety",
  "growth_development",
  "workload_sustainability",
  "belonging"
)

outcome_name = "intent_to_stay"

organizational_predictors = c(
  "business_unit",
  "department",
  "job_level",
  "manager_status",
  "work_arrangement",
  "tenure_years"
)

stopifnot(
  "Outcome variable is missing." = 
    outcome_name %in% names(survey_responses),
  
  "Some employee-experience predictors are missing." = 
    all(
      construct_names %in% names(survey_responses)
    ),
  
  "Some organizational predictors are missing." = 
    all(
      organizational_predictors %in% names(survey_responses)
    )
)

# 5. Define the modeling population --------------------------------

modeling_data = survey_responses %>%
  filter(
    usable_response == TRUE,
    !is.na(intent_to_stay)
  )

# Inspect the modeling population

dim(modeling_data)

modeling_data %>%
  summarise(
    modeling_n = n(),
    mean_intent_to_stay = mean(
      intent_to_stay,
      na.rm = TRUE
    ),
    sd_intent_to_stay = sd(
      intent_to_stay,
      na.rm = TRUE
    )
  )

# Verify the population definition

stopifnot(
  "Modeling dataset contains unusable survey responses." = 
    all(
      modeling_data$usable_response == TRUE
    ),
  
  "Modeling dataset contains missing intent-to-stay outcomes." = 
    all(
      !is.na(modeling_data$intent_to_stay)
    )
)

# 6. Create reproducible train-test split -------------------------
# 80/20 train-test split

set.seed(123)

train_indices = sample(
  seq_len(nrow(modeling_data)),
  size = floor(0.80 * nrow(modeling_data))
)

training_data = modeling_data[train_indices,]

testing_data = modeling_data[-train_indices,]

dim(training_data)

dim(testing_data)

# Verify the split

stopifnot(
  "Training and testing datasets overlap." = 
    length(
      intersect(
        train_indices,
        setdiff(seq_len(nrow(modeling_data)), train_indices)
      )
    ) == 0,
  
  "Training and testing datasets do not contain all modeling observations." = 
    nrow(training_data) + nrow(testing_data) == nrow(modeling_data)
)

# 7. Fit baseline intent-to-stay model ----------------------------
# Fit predictive model using the six employee-experience constructs only.

baseline_model = lm(
  intent_to_stay ~
    engagement +
    manager_effectiveness +
    psychological_safety +
    growth_development +
    workload_sustainability +
    belonging,
  data = training_data
)

summary(baseline_model)

# 8. Generate test-set predictions -------------------------------
# Predict on the held-out test set (the 20%)

testing_data = testing_data %>%
  mutate(
    predicted_intent_to_stay = predict(
      baseline_model,
      newdata = testing_data
    )
  )

head(
  testing_data %>%
    select(
      intent_to_stay,
      predicted_intent_to_stay
    )
)

# 9. Evaluate baseline model on the test set ----------------------
# RMSE, MAE, test-set R^2 using only the held-out data

test_actual = testing_data$intent_to_stay
test_predicted = testing_data$predicted_intent_to_stay

test_rmse = sqrt(
  mean(
    (test_actual - test_predicted)^2
  )
)

test_mae = mean(
  abs(
    test_actual - test_predicted
  )
)

test_r_squared = 1 - 
  sum(
    (test_actual - test_predicted)^2
  ) / 
  sum(
    (test_actual - mean(test_actual))^2
  )

baseline_test_performance = tibble(
  metric = c(
    "R-squared",
    "RMSE",
    "MAE"
  ),
  value = c(
    test_r_squared,
    test_rmse,
    test_mae
  )
)

baseline_test_performance

# 10. Compare training and test performance ----------------------

training_predictions = predict(
  baseline_model,
  newdata = training_data
)

training_rmse = sqrt(
  mean(
    (training_data$intent_to_stay - training_predictions)^2
  )
)

training_mae = mean(
  abs(
    training_data$intent_to_stay - training_predictions
  )
)

training_r_squared = summary(
  baseline_model
)$r.squared

baseline_performance_comparison = tibble(
  dataset = c(
    "Training",
    "Testing"
  ),
  r_squared = c(
    training_r_squared,
    test_r_squared
  ),
  rmse = c(
    training_rmse,
    test_rmse
  ),
  mae = c(
    training_mae,
    test_mae
  )
)

baseline_performance_comparison

# 11. Observed versus predicted intent to stay -------------------
# Do higher observed intent-to-stay scores generally correspond to
# higher predicted scores.

ggplot(
  testing_data,
  aes(
    x = intent_to_stay,
    y = predicted_intent_to_stay
  )
) +
  geom_jitter(
    width = 0.08,
    height = 0.08,
    alpha = 0.25
  ) +
  geom_smooth(
    method = "lm",
    se = FALSE
  ) +
  labs(
    title = "Observed versus predicted intent to stay",
    x = "Observed intent to stay",
    y = "Predicted intent to stay"
  ) +
  theme_minimal()

# 12. Prediction error by observed intent-to-stay scores -----------
# Does the model systematically under- or over-predict at different
# levels of intent to stay?

prediction_error = testing_data %>%
  mutate(
    prediction_error = 
      predicted_intent_to_stay - intent_to_stay
  ) %>%
  group_by(
    intent_to_stay
  ) %>%
  summarise(
    n = n(),
    mean_prediction_error = mean(
      prediction_error
    ),
    mean_absolute_error = mean(
      abs(prediction_error)
    ),
    .groups = "drop"
  )

prediction_error

# 13. Expanded intent-to-stay model -------------------------------
# Does adding employee characteristics: job level, manager status, 
# work arrangement, and tenure provide additional predictive information?

expanded_model = lm(
  intent_to_stay ~
    engagement +
    manager_effectiveness +
    psychological_safety +
    growth_development +
    workload_sustainability +
    belonging +
    job_level +
    manager_status +
    work_arrangement +
    tenure_years,
  data = training_data
)

summary(expanded_model)

# 14. Test incremental contribution of organizational characteristics
# Does adding the four variables as a group produce a statistically 
# significant improvement in model fit?

model_comparison = anova(
  baseline_model,
  expanded_model
)

model_comparison
 
# 15. Select final predictive model -------------------------------

final_intent_model = baseline_model

final_intent_model_performance = baseline_test_performance

summary(final_intent_model)

# 16. Generate final model predictions ----------------------------

testing_data = testing_data %>%
  mutate(
    final_predicted_intent_to_stay = predict(
      final_intent_model,
      newdata = testing_data
    )
  )

# Verify that predictions were generated for every test observation

stopifnot(
  "Final model did not generate predictions for all test observations." = 
    nrow(testing_data) == 
    sum(!is.na(testing_data$final_predicted_intent_to_stay))
)

# 17. Final model coefficients -----------------------------------

final_model_coefficients = broom::tidy(
  final_intent_model
) %>%
  select(
    term,
    estimate,
    std.error,
    statistic,
    p.value
  )

final_model_coefficients

# 18. Confidence intervals for final model coefficients -----------

final_model_coefficients_ci = broom::tidy(
  final_intent_model,
  conf.int = TRUE
) %>%
  select(
    term,
    estimate,
    conf.low,
    conf.high,
    std.error,
    p.value
  )

final_model_coefficients_ci

# 19. Final predictive model summary ------------------------------

final_model_summary = tibble(
  metric = c(
    "Training R-squared",
    "Testing R-squared",
    "Testing RMSE",
    "Testing MAE"
  ),
  value = c(
    summary(final_intent_model)$r.squared,
    final_intent_model_performance$value[
      final_intent_model_performance$metric == "R-squared"
    ],
    final_intent_model_performance$value[
      final_intent_model_performance$metric == "RMSE"
    ],
    final_intent_model_performance$value[
      final_intent_model_performance$metric == "MAE"
    ]
  )
)

final_model_summary

# 20. Save final model results ------------------------------------

write_csv(
  final_model_coefficients_ci,
  "outputs/final_model_coefficients_raw.csv"
)

write_csv(
  final_model_summary,
  "outputs/final_model_summary.csv"
)

stopifnot(
  # "Final model coefficients were not saved." =
  #   file.exists(
  #     "outputs/final_model_coefficients.csv"
  #   ),
  
  "Final model summary was not saved." =
    file.exists(
      "outputs/final_model_summary.csv"
    )
)

# Save final test-set predictions --------------------------------

final_test_predictions = testing_data %>%
  select(
    employee_id,
    intent_to_stay,
    final_predicted_intent_to_stay
  )

write_csv(
  final_test_predictions,
  "outputs/final_test_predictions.csv"
)

# 21. Final Script 06 validation ---------------------------------

stopifnot(
  "Final model is missing." =
    exists("final_intent_model"),
  
  "Final model coefficient table is missing." =
    exists("final_model_coefficients_ci"),
  
  "Final model summary is missing." =
    exists("final_model_summary"),
  
  "Final test R-squared is outside the valid range." =
    final_model_summary$value[
      final_model_summary$metric == "Testing R-squared"
    ] >= 0 &
    final_model_summary$value[
      final_model_summary$metric == "Testing R-squared"
    ] <= 1,
  
  "Final test RMSE is negative." =
    final_model_summary$value[
      final_model_summary$metric == "Testing RMSE"
    ] >= 0,
  
  "Final test MAE is negative." =
    final_model_summary$value[
      final_model_summary$metric == "Testing MAE"
    ] >= 0
)

# 22. Script 06 completion note -----------------------------------
# 
# Script 06 developed and evaluated a predicitve model of
# employee intent to stay.
# 
# The analysis included:
# - Reproducible training/testing split
# - Baseline employee-experience model
# - Held-out test-set evaluation
# - Prediction-error assessment
# - Expanded model including organizational characteristics
# - Nested model comparison
# - Selection of the final predictive model
# - Final model coefficients and confidence intervals
# 
# The final model uses the six employee-experience constructs.
# Adding job level, manager status, work arrangement, and tenure
# did not significantly improve model fit.
# 
# Results are based on synthetic survey data and should be
# interpreted as associations and predictive performance within
# the simulated dataset, not as causal evidence or estimates
# of real employee behavior.