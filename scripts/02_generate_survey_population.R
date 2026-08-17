# ============================================================
# Employee Listening and Organizational Health Analytics
# Script: 02_generate_survey_population.R
# Purpose: Define survey eligibility and participation for
#           each synthetic employee-listening survey wave.
# ============================================================

# 1. Packages ------------------------------------------------

library(dplyr)
library(tidyr)
library(purrr)
library(lubridate)
library(readr)

# 2. Reproducibility ------------------------------------------

set.seed(123)

# 3. Survey-wave assumptions ----------------------------------

wave_1_date = as.Date("2025-10-15")
wave_2_date = as.Date("2026-04-15")

survey_waves = tibble(
  survey_wave = c("Wave 1", "Wave 2"),
  survey_date = c(wave_1_date, wave_2_date)
)

# 4. Load employee population ---------------------------------

employee_population = readxl::read_xlsx("data/processed/employee_population.xlsx")

# 5. Validate employee population -----------------------------

stopifnot(
  nrow(employee_population) == 3600,
  n_distinct(employee_population$employee_id) == 3600,
  all(
    c(
      "employee_id",
      "business_unit",
      "department",
      "job_level",
      "manager_status",
      "work_arrangement",
      "location_region",
      "hire_date",
      "tenure_years",
      "tenure_group"
    ) %in%
      names(employee_population)
  )
)

# 6. Generate synthetic employee end dates -----------------
# a subset of employees is assigned a synthetic employment end date
#   to create realistic differences in survey eligibility between waves.
# These dates are used only to establish survey eligibility and are
#   not treated as the voluntary-turnover outcome for retention modeling.

# Implementing this gives us a legitimate survey eligibility 
#      denominator.
# This gives ~10% of employees an end date between Wave 1 
#       & 90 days after Wave 2

employee_population = employee_population %>%
  mutate(
    employment_end_date = case_when(
      runif(n()) < 0.10 ~
        wave_1_date + days(
          sample(
            1:((wave_2_date - wave_1_date) + 90),
            size = n(),
            replace = TRUE
          )
        ),
      TRUE ~ as.Date(NA)
    )
  )

# 7. Validate employment end date ----------------------------

stopifnot(
  "Employment end date must be after hire date" = all(
    is.na(employee_population$employment_end_date) | employee_population$employment_end_date > employee_population$hire_date
  ),
  "Employment end date must be within 90 days (after) Wave 2" = all(
    is.na(employee_population$employment_end_date) | employee_population$employment_end_date <= wave_2_date + days(90)
  )
)

# Summary/Inspect
employee_population %>%
  summarise(
    employees = n(),
    active_through_wave_2 = sum(is.na(employment_end_date)),
    with_end_date = sum(!is.na(employment_end_date))
  )

# 8. Define survey eligibility & create survey population ------
# translating the rules from Population_Spec into code
# an employee is eligible if they were hired on or before the 
#     survey launch date and are active when the survey launches and
#     have not left before the survey launches.

# creates 3600 * 2 = 7200 rows; each employee has one record 
#     for Wave 1 and one for Wave 2
survey_population = crossing(
  employee_population,
  survey_waves
) %>%
  mutate(
    eligible = hire_date <= survey_date &
      (
        is.na(employment_end_date) | employment_end_date >= survey_date
      )
  )

# 9. Validate survey eligibility -------------------------------

survey_population %>%
  count(survey_wave, eligible)

# 10. Generate survey invitations ------------------------------

survey_population = survey_population %>%
  mutate(
    invited = eligible
  )

# 11. Validate survey invitations ------------------------------

stopifnot(
  all(survey_population$invited == survey_population$eligible)
)

# 12. Define survey response assumptions ----------------------
# the synthetic survey program has an overall target rate of ~62%
#     this is a data-generation assumption, not a finding.

base_response_rate = 0.62

# 13. Define response-propensity adjustments ------------------
# so that response behavior varies somewhat across employee groups.
# essentially, there are small differences in participation by organizational context.
# the later analyses will determine whether those differences are meaningful or not.

department_response_adjustment = c(
  "Customer Support" = -0.06,
  "Implementation" = 0.02,
  "Service Delivery" = -0.03,
  "Engineering" = 0.04,
  "Data and Analytics" = 0.03,
  "Product" = 0.02,
  "Human Resources" = 0.05,
  "Finance" = 0.01,
  "Sales and Marketing" = -0.02
)

work_arrangement_response_adjustment = c(
  "On-site" = -0.03,
  "Hybrid" = 0.02,
  "Remote" = 0.00
)

tenure_response_adjustment = c(
  "Less than 1 year" = -0.04,
  "1-2 years" = 0.00,
  "3-5 years" = 0.02,
  "6-10 years" = 0.02,
  "11 or more years" = -0.01
)

# 14. Calculate response probability --------------------------
# calculate each employee's response probability

survey_population = survey_population %>%
  mutate(
    response_probability = case_when(
      invited == TRUE ~
        base_response_rate + department_response_adjustment[department] + work_arrangement_response_adjustment[work_arrangement] + tenure_response_adjustment[tenure_group],
      
      TRUE ~ 0
    )
  )

# constrain the probability to a reasonable range:
#     -> (min prob: 5%; max prob: 95%)

survey_population = survey_population %>%
  mutate(
    response_probability = pmin(
      pmax(response_probability, 0.05),
      0.95
    )
  )

# 15. Generate survey response indicator ------------------------
# uses the specified response probabilities to determine who responds.

survey_population = survey_population %>%
  mutate(
    responded = if_else(
      invited,
      rbinom( # each employee's survey participation is a binary outcome (they respond or they do not respond)
        # rbinom() generates a Bernoulli trial (binomial dist w/size = 1) for each employee using a specified p i.e. a specified probability.
        n = n(),
        size = 1,
        prob = response_probability
      ) == 1,
      FALSE
    )
  )

# 16. Validate the response rates ---------------------------------

# overall response rate
survey_population %>%
  group_by(survey_wave) %>%
  summarise(
    eligible = sum(eligible),
    invited = sum(invited),
    responses = sum(responded),
    response_rate = responses / invited
  )

# response rate by department
survey_population %>%
  group_by(survey_wave, department) %>%
  summarise(
    eligible = sum(eligible),
    responses = sum(responded),
    response_rate = responses / eligible,
    .groups = "drop"
  )

# response rate by tenure
survey_population %>%
  group_by(survey_wave, tenure_group) %>%
  summarise(
    eligible = sum(eligible),
    responses = sum(responded),
    response_rate = responses / eligible,
    .groups = "drop"
  )

# response rate by work arrangement
survey_population %>%
  group_by(survey_wave, work_arrangement) %>%
  summarise(
    eligible = sum(eligible),
    responses = sum(responded),
    response_rate = responses / eligible,
    .groups = "drop"
  )

# 17. Validate survey participation ---------------------------

stopifnot(
  "Some respondents are marked as responded without being invited." = 
  all(survey_population$responded <= survey_population$invited),
  
  "Some employees are marked as invited without being eligible." = 
  all(survey_population$invited <= survey_population$eligible),
  
  "Some response probabilities are below 0.05 or above 0.95." = 
  all(survey_population$response_probability >= 0.05 & survey_population$response_probability <= 0.95)
)