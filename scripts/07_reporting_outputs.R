# ============================================================
# Employee Listening and Organizational Health Analytics
# Script: 07_reporting_outputs.R
# 
# Purpose:
# Generate final report-ready visualizations and analytical
# tables from the validated survey analysis.
# 
# This script converts selected findings from the preceding 
# analytical scripts into reproducible reporting outputs.
# 
# Key outputs:
# - Final report figures
# - Final analytical tables
# - Saved reporting artifacts
# 
# Input:
#   Validated survey and analytical results from preceding scripts.
#   
# Output:
#   figures/
#   outputs/
#   
# Notes:
#   Only selected final-report outputs are saved. Intermediate
#   exploratory results remain reproducible through the analytical
#   scripts rather than being exported individually.
# ============================================================

# 1. Load packages ------------------------------------------------

library(tidyverse)
library(readxl)

# 2. Create reporting output directories --------------------------

dir.create(
  "figures",
  showWarnings = FALSE,
  recursive = TRUE
)

dir.create(
  "outputs",
  showWarnings = FALSE,
  recursive = TRUE
)

dir.exists("figures")
dir.exists("outputs")


# 3. Load validated survey data ----------------------------------

survey_responses = read_xlsx(
  "data/processed/survey_responses.xlsx"
)

dim(survey_responses)

# 4. Define reporting variables ----------------------------------

construct_names = c(
  "engagement",
  "manager_effectiveness",
  "psychological_safety",
  "growth_development",
  "workload_sustainability",
  "belonging"
)

stopifnot(
  "One or more reporting constructs are missing." =
    all(
      construct_names %in% names(survey_responses)
    ),
  
  "Intent-to-stay outcome is missing." =
    "intent_to_stay" %in% names(survey_responses)
)

# 5. Define report population ------------------------------------

report_data = survey_responses %>%
  filter(
    usable_response == TRUE
  )

dim(report_data)

# Verify

stopifnot(
  "Report data contains unusable responses." =
    all(
      report_data$usable_response == TRUE
    )
)

# 6. Overall construct summary -----------------------------------

overall_construct_summary = report_data %>%
  summarise(
    across(
      all_of(construct_names),
      list(
        mean = ~ mean(.x, na.rm = TRUE),
        sd = ~ sd(.x, na.rm = TRUE)
      ),
      .names = "{.col}_{.fn}"
    )
  )

overall_construct_summary

# 7. Format overall construct summary ----------------------------

overall_construct_report = overall_construct_summary %>%
  pivot_longer(
    cols = everything(),
    names_to = c("construct", ".value"),
    names_pattern = "(.+)_(mean|sd)"
  ) %>%
  mutate(
    construct = str_replace_all(
      construct,
      "_",
      " "
    ),
    construct = str_to_title(construct)
  ) %>%
  arrange(
    desc(mean)
  )

overall_construct_report

# 8. Overall employee-experience scores --------------------------

overall_construct_plot = overall_construct_report %>%
  ggplot(
    aes(
      x = reorder(construct, mean),
      y = mean
    )
  ) +
  geom_col() +
  geom_errorbar(
    aes(
      ymin = mean - sd,
      ymax = mean + sd
    ),
    width = 0.2
  ) +
  coord_flip() +
  scale_y_continuous(
    limits = c(0, 5)
  ) +
  labs(
    title = "Overall employee-experience scores",
    x = NULL,
    y = "Mean score"
  ) +
  theme_minimal()

overall_construct_plot

# 9. Save overall construct summary & figure  -----------------------

write_csv(
  overall_construct_report, 
  "outputs/overall_construct_summary.csv"
)

# Verify the file exists

stopifnot(
  "Overall construct summary was not saved." =
    file.exists(
      "outputs/overall_construct_summary.csv"
    )
)

ggsave(
  "figures/overall_employee_experience_scores.png",
  plot = overall_construct_plot,
  width = 10,
  height = 7,
  dpi = 300
)

# Verify

stopifnot(
  "Overall construct figure was not saved." =
    file.exists(
      "figures/overall_employee_experience_scores.png"
    )
)

# 10. Business-unit construct summary ----------------------------

business_unit_report = report_data %>%
  group_by(business_unit) %>%
  summarise(
    across(
      all_of(construct_names),
      ~ mean(.x, na.rm = TRUE)
    ),
    usable_responses = n(),
    .groups = "drop"
  ) %>%
  relocate(
    usable_responses,
    .after = business_unit
  )

business_unit_report

# 11. Save business-unit summary ---------------------------------

write_csv(
  business_unit_report,
  "outputs/business_unit_summary.csv"
)

stopifnot(
  "Business-unit summary was not saved." =
    file.exists(
      "outputs/business_unit_summary.csv"
    )
)

# 12. Business-unit construct visualization ----------------------

business_unit_plot_data = business_unit_report %>%
  pivot_longer(
    cols = all_of(construct_names),
    names_to = "construct",
    values_to = "mean_score"
  ) %>%
  mutate(
    construct = str_replace_all(
      construct,
      "_",
      " "
    ),
    construct = str_to_title(construct)
  )

business_unit_plot = business_unit_plot_data %>%
  ggplot(
    aes(
      x = business_unit,
      y = mean_score,
      fill = construct
    )
  ) +
  geom_col(
    position = "dodge"
  ) +
  scale_y_continuous(
    limits = c(0, 5)
  ) +
  labs(
    title = "Employee-experience scores by business unit",
    x = NULL,
    y = "Mean score",
    fill = "Construct"
  ) +
  theme_minimal()

business_unit_plot

# 13. Department construct summary -------------------------------

department_report = report_data %>%
  group_by(
    business_unit,
    department
  ) %>%
  summarise(
    across(
      all_of(construct_names),
      ~ mean(.x, na.rm = TRUE)
    ),
    usable_responses = n(),
    .groups = "drop"
  ) %>%
  relocate(
    usable_responses,
    .after = department
  )

department_report

# 14. Save department summary ------------------------------------

write_csv(
  department_report,
  "outputs/department_summary.csv"
)

stopifnot(
  "Department summary was not saved." = 
    file.exists("outputs/department_summary.csv")
)

# 15. Department score ranges ------------------------------------

department_range_report = department_report %>%
  pivot_longer(
    cols = all_of(construct_names),
    names_to = "construct",
    values_to = "mean_score"
  ) %>%
  group_by(construct) %>%
  summarise(
    highest_score = max(mean_score, na.rm = TRUE),
    lowest_score = min(mean_score, na.rm = TRUE),
    score_range = highest_score - lowest_score,
    highest_department = department[
      which.max(mean_score)
    ],
    lowest_department = department[
      which.min(mean_score)
    ],
    .groups = "drop"
  ) %>%
  arrange(
    desc(score_range)
  )

department_range_report

# 16. Save department score ranges -------------------------------

write_csv(
  department_range_report,
  "outputs/department_score_ranges.csv"
)

stopifnot(
  "Department score-range report was not saved." =
    file.exists(
      "outputs/department_score_ranges.csv"
    )
)

# 17. Overall intent-to-stay summary ------------------------------

intent_to_stay_report = report_data %>%
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
    )
  )

intent_to_stay_report

# 18. Save intent-to-stay summary --------------------------------

write_csv(
  intent_to_stay_report,
  "outputs/intent_to_stay_summary.csv"
)

stopifnot(
  "Intent-to-stay summary was not saved." =
    file.exists(
      "outputs/intent_to_stay_summary.csv"
    )
)

# 19. Intent-to-stay associations --------------------------------

intent_association_report = map_dfr(
  construct_names,
  ~ tibble(
    construct = .x,
    correlation = cor(
      report_data[[.x]],
      report_data$intent_to_stay,
      use = "complete.obs"
    )
  )
) %>%
  arrange(
    desc(correlation)
  )

intent_association_report

# 20. Save intent-to-stay associations ----------------------------

write_csv(
  intent_association_report,
  "outputs/intent_to_stay_associations.csv"
)

stopifnot(
  "Intent-to-stay association report was not saved." =
    file.exists(
      "outputs/intent_to_stay_associations.csv"
    )
)

# 21. Load final predictive-model results -------------------------

final_model_coefficients_ci = read_csv(
  "outputs/final_model_coefficients_raw.csv",
  show_col_types = FALSE
)

final_model_summary = read_csv(
  "outputs/final_model_summary.csv",
  show_col_types = FALSE
)

# 22. Format final predictive-model results ----------------------

final_model_report = final_model_coefficients_ci %>%
  filter(
    term != "(Intercept)"
  ) %>%
  mutate(
    construct = str_replace_all(
      term,
      "_",
      " "
    ),
    construct = str_to_title(construct)
  ) %>%
  select(
    construct,
    estimate,
    conf.low,
    conf.high,
    p.value
  ) %>%
  arrange(
    desc(estimate)
  )

final_model_report

# 23. Save final predictive-model results -------------------------

write_csv(
  final_model_report,
  "outputs/final_model_coefficients_report.csv"
)

stopifnot(
  "Final model coefficient table was not saved." =
    file.exists(
      "outputs/final_model_coefficients_report.csv"
    )
)

# 24. Load final test-set predictions -----------------------------

final_test_predictions = read_csv(
  "outputs/final_test_predictions.csv",
  show_col_types = FALSE
)

# 25. Observed versus predicted intent-to-stay figure ------------

final_prediction_plot = final_test_predictions %>%
  ggplot(
    aes(
      x = intent_to_stay,
      y = final_predicted_intent_to_stay
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

final_prediction_plot

# 26. Save observed versus predicted figure ----------------------

ggsave(
  "figures/observed_vs_predicted_intent_to_stay.png",
  plot = final_prediction_plot,
  width = 10,
  height = 7,
  dpi = 300
)

stopifnot(
  "Observed-versus-predicted figure was not saved." =
    file.exists(
      "figures/observed_vs_predicted_intent_to_stay.png"
    )
)

# 27. Final reporting-output validation ---------------------------

required_outputs = c(
  "outputs/overall_construct_summary.csv",
  "outputs/business_unit_summary.csv",
  "outputs/department_summary.csv",
  "outputs/department_score_ranges.csv",
  "outputs/intent_to_stay_summary.csv",
  "outputs/intent_to_stay_associations.csv",
  "outputs/final_model_coefficients_raw.csv",
  "outputs/final_model_coefficients_report.csv",
  "outputs/final_model_summary.csv",
  "outputs/final_test_predictions.csv",
  "figures/overall_employee_experience_scores.png",
  "figures/observed_vs_predicted_intent_to_stay.png"
)

stopifnot(
  "One or more final reporting outputs are missing." =
    all(file.exists(required_outputs))
)
