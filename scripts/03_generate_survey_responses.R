# ============================================================
# Employee Listening and Organizational Health Analytics
# Script: 03_generate_survey_responses.R
# Purpose: Generate synthetic item-level survey responses for 
#           employees who responded to each survey wave.
# ============================================================


# 1. Packages -------------------------------------------------

library(dplyr)
library(tidyr)
library(purrr)
library(lubridate)
library(readr)
library(readxl)

# 2. Reproducibility ------------------------------------------

set.seed(123)

# 3. Survey assumptions ---------------------------------------

likert_values = 1:5

likert_labels = c(
  "Strongly disagree",
  "Disagree",
  "Neither agree nor disagree",
  "Agree",
  "Strongly agree"
)

# 4. Load survey population -----------------------------------

survey_population = readxl::read_xlsx("data/processed/survey_population.xlsx")

# 5. Validate survey population -------------------------------

stopifnot(
  "Survey population should contain 7,200 employee-wave records." = 
    nrow(survey_population) == 7200,
  
  "Employee IDs should be unique within each survey wave." = 
    nrow(
      survey_population %>%
        distinct(employee_id, survey_wave)
    ) == nrow(survey_population),
  
  "Some records are marked as responded without being invited." = 
    !any(survey_population$responded == TRUE & survey_population$invited == FALSE)
)

# 6. Select survey respondents --------------------------------

survey_responses = survey_population %>%
  filter(responded == TRUE)

# 7. Define latent construct correlation structure ------------

construct_names = c(
  "engagement",
  "manager_effectiveness",
  "psychological_safety",
  "growth_development",
  "workload_sustainability",
  "belonging"
)

construct_correlations = matrix(
  c(
    1.00, 0.45, 0.40, 0.40, 0.35, 0.45,
    0.45, 1.00, 0.50, 0.40, 0.40, 0.45,
    0.40, 0.50, 1.00, 0.35, 0.40, 0.50,
    0.40, 0.40, 0.35, 1.00, 0.30, 0.40,
    0.35, 0.40, 0.40, 0.30, 1.00, 0.35,
    0.45, 0.45, 0.50, 0.40, 0.35, 1.00
  ),
  nrow = 6,
  ncol = 6,
  byrow = TRUE,
  dimnames = list(
    construct_names,
    construct_names
  )
)

# 8. Validate correlation structure ---------------------------

stopifnot(
  "The construct correlation matrix must be symmetric." = 
    isTRUE(all.equal(
      construct_correlations,
      t(construct_correlations)
    )),
  
  "The construct correlation matrix must have 1.00 on its diagonal." = 
    all(diag(construct_correlations) == 1),
  
  "The construct correlation matrix contains correlations outisde [-1, 1]." = 
    all(
      construct_correlations >= -1 & construct_correlations <= 1
    ),
  
  "The construct correlation matrix must contain six constructs." = 
    nrow(construct_correlations) == 6 & ncol(construct_correlations) == 6
)

# 9. Validate positive definiteness ----------------------------

# Is the corr matrix mathematically suitable for the simulation?
#
# A corr matrix needs to be positive definite before it can be used as
#   the covariance/correlation structure in a multivariate normal simulation.
#
# Positive definite: there must not be any mathematical contradiction in the 
#   relationships that have been specified. 
# a positive-definite corr matrix guarantees that the relationships can coexist
#   in a mathematically valid multivariate distribution. 
#
# For example:
#
# engagement <-> manager_effect = 0.90
# engagement <-> psych_safety = 0.90
# manager_effect <-> psych_safety = -0.90
#
# The relationships above are mathematically nonsensical when considered simultaneously
#   because if A is extremely similar to B & A is extremely similar to C,
#   then B and C can't, at the same time, be extremely opposite.
#
# Positive definiteness ensures that the full set of specified correlations can
#   exist together and that the resulting matrix defines a valid multivariate distribution.
#
# Otherwise, the algorithm can fail because there is no valid multivariate normal distribution
#   corresponding to the relationships specified in the covariance/corr matrix.
#
# Eigen values: tell you how a matrix behaves in a particular direction.
# If said matrix is positive definite (valid), all its eigenvalues > 0.
# 
# For this project, I used eigenvalues as a diagnostic to check if the correlation
#   matrix represents a mathematically valid set or relationships.
#   
#     all eigenvalues > 0 -> +ve definite -> suitable for simulation
#     any eigenvalue <= 0 -> not +ve definite -> matrix needs to be fixed


eigenvalues = eigen(
  construct_correlations,
  symmetric = TRUE,
  only.values = TRUE
)$values

stopifnot(
  "The construct correlation matrix must be positive definite." = 
    all(eigenvalues > 0)
)

eigenvalues

# 10. Generate correlated latent constructs -------------------
# 
# MASS::mvrnorm() generates one multivariate-normal observation per employee.
# Each latent construct is centered at 0, & the relationships between constructs
#   are defined by the construct correlation matrix.
#   
# These latent scores are not survey responses yet. They represent underlying
#   employee-experience traits (e.g., engagement, manager effectiveness, etc.)
#   that will later be used to generate individual Likert-scale survey items.
#   
# empirical = FALSE means the simulated sample is a random draw from the specified
#   distribution; the sample means/correlations will, as a result, be close to, but
#   not necessarily exactly equal to, the specified parameters.

latent_constructs = MASS::mvrnorm(
  n = nrow(survey_responses),
  mu = rep(0, length(construct_names)), # give every latent construct a mean of 0.
  Sigma = construct_correlations,
  empirical = FALSE # don't force the generated sample to have exactly the requested means & corrs.
)

latent_constructs = as.data.frame(latent_constructs)

names(latent_constructs) = construct_names

# 11. Attach latent constructs to respondent_level data & Inspect the simulated latent correlations ---------------
# essentially, give each employee a latent construct score.

survey_responses = bind_cols(
  survey_responses, latent_constructs
)

survey_responses %>%
  select(all_of(construct_names)) %>%
  cor() %>%
  round(2)

# 12. Validate latent constructs -------------------------------

stopifnot(
  "The number of generated latent construct scores does not match the number of respondents." =
    nrow(latent_constructs) == nrow(survey_responses),
  
  "The generated latent construct scores contain missing values." = 
    !any(is.na(latent_constructs)),
  
  "The generated latent construct set does not contain all six expected constructs." = 
    all(construct_names %in% names(latent_constructs))
)

# 13. Define item-to-construct mapping -------------------------

item_construct_map = c(
  eng_01 = "engagement",
  eng_02 = "engagement",
  eng_03 = "engagement",
  eng_04 = "engagement",
  
  mgr_01 = "manager_effectiveness",
  mgr_02 = "manager_effectiveness",
  mgr_03 = "manager_effectiveness",
  mgr_04 = "manager_effectiveness",
  
  psy_01 = "psychological_safety",
  psy_02 = "psychological_safety",
  psy_03 = "psychological_safety",
  psy_04 = "psychological_safety",
  
  grw_01 = "growth_development",
  grw_02 = "growth_development",
  grw_03 = "growth_development",
  grw_04 = "growth_development",
  
  wrk_01 = "workload_sustainability",
  wrk_02 = "workload_sustainability",
  wrk_03 = "workload_sustainability",
  wrk_04 = "workload_sustainability",
  
  blg_01 = "belonging",
  blg_02 = "belonging",
  blg_03 = "belonging",
  blg_04 = "belonging"
)

# 14. Define item loadings -------------------------------------
# Give each item a reasonably strong yet imperfect relationship 
#   with its underlying construct.
# These values are simulation parameters, not empirical estimates.

item_loadings = c(
  eng_01 = 0.75,
  eng_02 = 0.70,
  eng_03 = 0.72,
  eng_04 = 0.68,
  
  mgr_01 = 0.75,
  mgr_02 = 0.72,
  mgr_03 = 0.70,
  mgr_04 = 0.68,
  
  psy_01 = 0.74,
  psy_02 = 0.70,
  psy_03 = 0.72,
  psy_04 = 0.68,
  
  grw_01 = 0.75,
  grw_02 = 0.69,
  grw_03 = 0.71,
  grw_04 = 0.73,
  
  wrk_01 = 0.73,
  wrk_02 = 0.70,
  wrk_03 = 0.67,
  wrk_04 = 0.71,
  
  blg_01 = 0.74,
  blg_02 = 0.72,
  blg_03 = 0.69,
  blg_04 = 0.71
)

# 15. Generate continuous item responses ----------------------
# Each latent construct represents an employee's underlying level of a trait
#   (e.g, Engagement), while the individual survey items are observable 
#   measures used to capture that underlying trait.
#   
# For each item, we generate a continuous response using:
# 
#   item response = (loading * latent construct score) + random error
#   
# The loading controls how strongly the item reflects its underlying construct.
# A higher loading means the item is more strongly related to the construct,
#   while the random error represents other factors that can affect how
#   an employee responds to a particular question.
#   
# For example, an employee with a high latent Engagement score will generally
#   have higher Engagement item responses, but the responses will not be 
#   identical because each item contains some random variation.
#   
# The result is a set of continuous item responses that reflect the intended
#   latent constructs while allowing realistic variation between items.

for (item in names(item_construct_map)) {
  construct = item_construct_map[[item]]
  loading = item_loadings[[item]]
  
  survey_responses[[paste0(item, "_continuous")]] = 
    loading * survey_responses[[construct]] +
    rnorm(
      n = nrow(survey_responses),
      mean = 0,
      sd = sqrt(1 - loading^2)
    )
}

# 16. Convert continuous responses to five-point Likert scale --
# Strongly disagree, disagree, neither agree nor disagree...

continuous_items = paste0(
  names(item_construct_map),
  "_continuous"
)

for (item in names(item_construct_map)) {
  
  continuous_item = paste0(item, "_continuous")
  
  survey_responses[[item]] = cut(
    survey_responses[[continuous_item]],
    breaks = c(
      -Inf,
      -0.85,
      -0.20,
      0.20,
      0.85,
      Inf
    ),
    labels = likert_values,
    include.lowest = TRUE
  ) |>
    as.integer()
}

# 17. Validate employee-experience items ----------------------

stopifnot(
  "Generated survey items contain values outside the five-point Likert scale." = 
    all(
      unlist(
        survey_responses[names(item_construct_map)]
      ) %in% likert_values
    ),
  
  "Generated survey items contain missing values before missigness is introduced." = 
    !any(
      is.na(
        unlist(
          survey_responses[names(item_construct_map)]
        )
      )
    )
)

# Inspect one construct
survey_responses %>%
  select(eng_01, eng_02, eng_03, eng_04) %>%
  summary()

# Check its correlations:
survey_responses %>%
  select(eng_01, eng_02, eng_03, eng_04) %>%
  cor() %>%
  round(2)

# 18. Define intent-to-stay relationships ---------------------
# 
# Define simulation weights that control how strongly each 
#   employee-experience construct contributes to the underlying
#   intent-to-stay signal.
#   
# Higher weight = stronger influence on the simulated intent-to-stay signal.
# 
# These weights are simulation parameters chosen to create a plausible
#   relationship between employee experience and intent to stay. They are
#   NOT empirical estimates, regression coefficients, or findings from
#   actual employee data.
#   
# For example, Engagement has a weight of 0.45, meaning it is assigned a
#   relatively stronger influence on the simulated intent-to-stay signal
#   than Workload Sustainability, which has a weight of 0.30.

intent_to_stay_weights = c(
  engagement = 0.45,
  manager_effectiveness = 0.40,
  psychological_safety = 0.35,
  growth_development = 0.35,
  workload_sustainability = 0.30,
  belonging = 0.40
)

# 19. Generate latent intent to stay --------------------------
# intent_to_stay_signal represents an employee's underlying continuous 
#   tendency to remain with Meridian before converting it into
#   the final survey response.
#   
# First, we select the employee-experience construct scores corresponding
#   to the weights defined above & convert them to a matrix.
#   
# Then calculate a weighted sum for each employee using matrix multiplication:
# 
# intent_to_stay signal = 
#   (Engagement * weight) +
#   (Manager Effectiveness * weight) +
#   (Psychological Safety * weight) +
#   (Growth & Development * weight) +
#   (Workload Sustainability * weight) +
#   (Belonging * weight)
# 
# A higher signal indicates a more favorable simulated employee experience
#   and therefore a stronger underlying tendency to stay. A lower signal
#   indicates a weaker tendency to stay.
#   
# Lastly, I use scale() to standardize the signal to approximately mean = 0
#   and standard deviation = 1. This creates a standardized continuous latent 
#   variable that can be used to generate the final intent-to-stay responses.

experience_matrix = survey_responses %>%
  select(all_of(names(intent_to_stay_weights))) %>%
  as.matrix()

intent_to_stay_signal = as.numeric(
  experience_matrix %*% intent_to_stay_weights
)

intent_to_stay_signal = as.numeric(
  scale(intent_to_stay_signal)
)

# 20. Generate intent-to-stay items ---------------------------
# 0.75 & 0.70 are the loadings of the items on the latent 
#   intent-to stay construct.

survey_responses = survey_responses %>%
  mutate(
    its_01_continuous =
      0.75 * intent_to_stay_signal +
      rnorm(
        n = n(),
        mean = 0,
        sd = sqrt(1 - 0.75^2)
      ),
    
    its_02_continuous = 
      0.70 * intent_to_stay_signal +
      rnorm(
        n = n(),
        mean = 0,
        sd = sqrt(1 - 0.70^2)
      )
  )

# Convert the intent-to-stay items to the same five-point scale

for (item in c("its_01", "its_02")) {
  continuous_item = paste0(item, "_continuous")
  
  survey_responses[[item]] = cut(
    survey_responses[[continuous_item]],
    breaks = c(
      -Inf,
      -0.85,
      -0.20,
      0.20,
      0.85,
      Inf
    ),
    labels = likert_values,
    include.lowest = TRUE
  ) |>
  as.integer()
}

# 21. Validate intent-to-stay items ---------------------------

stopifnot(
  "Intent-to-stay items contain values outside the five-point Likert scale." = 
    all(
      unlist(
        survey_responses[c("its_01", "its_02")]
      ) %in% likert_values
    ),
  
  "Intent-to_stay items contain missing values before missingness is introduced." = 
    !any(
      is.na(
        unlist(
          survey_responses[c("its_01", "its_02")]
        )
      )
    )
)

# check (should be +ve corr between its_01 & its_02)
survey_responses %>%
  select(its_01, its_02) %>%
  cor() %>%
  round(2)

# the experience constructs should show +ve associations w/intent to stay
survey_responses %>%
  select(
    engagement,
    manager_effectiveness,
    psychological_safety,
    growth_development,
    workload_sustainability,
    belonging,
    its_01,
    its_02
  ) %>%
  cor() %>%
  round(2)

# 22. Generate overall employee_experience item ----------------
# It reflects the overall employee experience by drawing on all six
#   latent constructs, with some additional noise.
#   
# Calculate each employee's overall experience by taking the mean of their
#   six employee-experience construct scores. This creates a single signal
#   representing the employee's general experience across the organization.
#   
# Next, the signal is standardized so employees can be compared relative to
#   the overall disribution (appx. mean = 0, SD = 1).
#   
# Lastly, generate a continuous overall-experience survey item using the same
#   latent-variable approach used for the individual construct items:
#   
#     item response = (loading * overall experience) + random error
#     
# A loading of 0.75 creates a reasonably strong but imperfect relationship
#   between the overall-experience item and the underlying experience signal.
# The random error allows employees with similar underlying experiences
#   to give relatively different responses to the individual question.

# overall_experience_signal is the latent score for each respondent.
overall_experience_signal = rowMeans(
  survey_responses %>%
    select(all_of(construct_names))
)

overall_experience_signal = as.numeric(
  scale(overall_experience_signal)
)

# 0.75 is the loading i.e. how strongly ovl_01 reflects the latent signal.
survey_responses = survey_responses %>%
  mutate(
    ovl_01_continuous = 
      0.75 * overall_experience_signal +
      rnorm(
        n = n(),
        mean = 0,
        sd = sqrt(1 - 0.75^2)
      )
  )

# 23. Convert overall employee-experience item to Likert scale ----

survey_responses = survey_responses %>%
  mutate(
    ovl_01 = cut(
      ovl_01_continuous,
      breaks = c(
        -Inf,
        -0.85,
        -0.20,
        0.20,
        0.85,
        Inf
      ),
      labels = likert_values,
      include.lowest = TRUE
    ) |>
      as.integer()
  )

# 24. Validate overall employee-experience item ---------------

stopifnot(
  "The overall employee-experience item contains values outside the five-point Likert scale." = 
    all(
      survey_responses$ovl_01 %in% likert_values
    ),
  
  "The overall employee-experience item contains missing values before missigness is introduced." = 
    !any(
      is.na(survey_responses$ovl_01)
    )
)

# check
survey_responses %>%
  count(ovl_01) %>%
  mutate(
    pct = round(n / sum(n) * 100, 1)
  )

# check its relationship w/the six constructs
survey_responses %>%
  select(
    all_of(construct_names),
    ovl_01
  ) %>%
  cor() %>%
  round(2)

# 25. Introduce item-level missingness -------------------------
# 
# Real survey respondents may skip individual questions, so introduce
#   a small amount of randomly distributed item-level missingness into
#   the synthetic survey responses.
#   
# A 3% missingness rate means that each survey item has approximately a 3%
#   probability of being unanswered for any given employee.
#   
# For each Likert item:
#   1. Generate a random value between 0 & 1 for every employee.
#   2. If the value is below the missingness rate, mark that response as NA.
#   3. Else, retain the employee's original response.
# 
# This is to create realistic incomplete survey data rather than assuming
#   every employee answered every question.

likert_items = c(
  names(item_construct_map),
  "its_01",
  "its_02",
  "ovl_01"
)

missingness_rate = 0.03

for (item in likert_items) {
  # generate random numbers between 0 & 1, then check if it's < 0.03
  missing = runif(nrow(survey_responses)) < missingness_rate
  
  # if TRUE (< 0.03), mark as missing by replacing the employee's
  #   survey responses with NA_integer_ (integer valued variable)  
  survey_responses[[item]][missing] = NA_integer_
}

# 26. Validate item-level missingness --------------------------

item_missingness = survey_responses %>%
  summarise(
    across(
      all_of(likert_items),
      ~ mean(is.na(.))
    )
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = "item",
    values_to = "missing_rate"
  )

item_missingness

# Check the overall rate of missingness
mean(
  is.na(
    survey_responses %>%
      select(all_of(likert_items)) %>%
      unlist()
  )
)

# 27. Define usable-response threshold ------------------------
# Since we introduced ~3% item-level missingness, some respondents 
#   will have incomplete surveys.
# 
# There needs to be a rule that determines whether a response is 
#   sufficiently complete for analysis.
#   
# A response is usable if at least 80% of the 27 Likert items have 
#   valid responses, i.e. a respondent can have up to 5 missing 
#   Likert items & still be considered a usable response:
#     
#     27 * 0.80 = 21.6
#     
# So they need at least 22 valid responses.

minimum_item_completion = 0.80

minimum_valid_items = ceiling(
  length(likert_items) * minimum_item_completion
)

#check; should return 22
minimum_valid_items

# 28. Calculate item completion --------------------------------

 survey_responses = survey_responses %>%
  mutate(
    valid_likert_items = rowSums(
      !is.na(
        across(all_of(likert_items))
      )
    ),
    
    item_completion_rate = valid_likert_items / length(likert_items)
  )

# 29. Determine usable responses -------------------------------

survey_responses = survey_responses %>%
  mutate(
    usable_response = #returns a bool
      valid_likert_items >= minimum_valid_items
  )

# 30. Validate the usable response rule ------------------------

stopifnot(
  "Some usable responses have fewer than the required number of valid items." = 
    all(
      survey_responses$valid_likert_items >= minimum_valid_items |
        survey_responses$usable_response == FALSE
    ),
  
  "Some responses meet the minimum item requirement but are marked unusable." = 
    all(
      survey_responses$valid_likert_items < minimum_valid_items |
        survey_responses$usable_response == TRUE
    )
)

# Inspect
survey_responses %>%
  count(survey_wave, usable_response) %>%
  group_by(survey_wave) %>%
  mutate(
    pct = round(n / sum(n) * 100, 1)
  ) %>%
  ungroup()

survey_responses %>%
  group_by(survey_wave) %>%
  summarise(
    respondents = n(),
    usable_responses = sum(usable_response),
    usable_rate = round(
      usable_responses / respondents,
      3
    )
  )

# 31. Validate item completion -------------------------------
# Is the completion rate itself behaving correctly?

stopifnot(
  "Some item completion rates are outside the valid range of 0 to 1." = 
    all(
      survey_responses$item_completion_rate >= 0 &
        survey_responses$item_completion_rate <= 1
    ),
  
  "Some usable responses have completion rates below the minimum threshold." = 
    !any(
      survey_responses$usable_response == TRUE &
        survey_responses$item_completion_rate < minimum_item_completion
    )
)

# Inspect
survey_responses %>%
  group_by(survey_wave) %>%
  summarise(
    min_completion = min(item_completion_rate),
    median_completion = median(item_completion_rate),
    mean_completion = mean(item_completion_rate),
    max_completion = max(item_completion_rate)
  )

# 32. Generate synthetic open-ended comments ------------------
# comment_01 is an open-text field, not a Likert item.
# It is also optional, so we're simulating an 75% comment-response rate.

comment_templates = c(
  "More opportunities for professional development would improve my experience.",
  "Clearer communication about organizational priorities would be helpful.",
  "I would appreciate more support with workload and competing priorities.",
  "More opportunities to collaborate across teams would improve my experiences.",
  "I would like clearer information about career growth opportunities.",
  "More consistent feedback from managers would be helpful.",
  "I would like more recognition for good work.",
  "No major changes are needed at this time."
)

comment_response_rate = 0.75

survey_responses = survey_responses %>%
  mutate(
    comment_01 = if_else(
      runif(n()) < comment_response_rate,
      sample(
      comment_templates,
      size = n(),
      replace = TRUE
    ),
    NA_character_
    )
  )

# 33. Validate synthetic comments ------------------------------

stopifnot(
  "The open-ended comment field is missing from the survey response data." = 
    "comment_01" %in% names(survey_responses),
  
  "The open-ended comment field contains unexpected values." = 
    all(
      is.na(survey_responses$comment_01) |
      survey_responses$comment_01 %in% comment_templates
    )
)

# 34. Remove simulation-only columns ---------------------------
# engagement, manager_effectiveness, psychological_safety, growth_development
#   workload_sustainability, belonging, every column ending in `_continuous`.
# 
# These are latent/helper variables used to generate the observed survey data
#   & should not appear in the final survey_response dataset.

survey_responses = survey_responses %>%
  select(
    -all_of(construct_names),
    -ends_with("_continuous")
  )

# check
names(survey_responses)

# 35. Validate final survey_response structure ----------------

expected_likert_items = c(
  names(item_construct_map),
  "its_01",
  "its_02",
  "ovl_01"
)

stopifnot(
  "Some expected Likert survey items are missing from the final dataset." = 
    all(
      expected_likert_items %in%
        names(survey_responses)
    ),
  
  "Simulation-only latent construct columns remain in the final dataset." = 
    !any(
      grepl(
        "_continuous$",
        names(survey_responses)
      )
    )
)

# check
nrow(survey_responses)

# 36. Final survey-response validation -------------------------

stopifnot(
  "The final survey-response dataset should contain 4,344 respondents." = 
    nrow(survey_responses) == 4344,
  
  "Employee IDs should be unique within each survey wave." = 
    nrow(
      survey_responses %>%
        distinct(employee_id, survey_wave)
    ) == nrow(survey_responses),
  
  "All final survey respondents should have responded = TRUE." = 
    all(survey_responses$responded == TRUE),
  
  "Some expected Likert items are missing from the final dataset." = 
    all(
      expected_likert_items %in%
        names(survey_responses)
    ),
  
  "Some survey responses have invalid Likert values." = 
    all(
      unlist(
        survey_responses[expected_likert_items]
      ) %in% c(1:5, NA)
    )
)

# 37. Save synthetic survey responses -------------------------

writexl::write_xlsx(survey_responses, "data/processed/survey_responses.xlsx")

# verify the file was written and saved
file.exists("data/processed/survey_responses.xlsx")

# inspect the saved survey_responses dataset
read_xlsx("data/processed/survey_responses.xlsx") %>%
  glimpse()

# summary
survey_responses %>%
  group_by(survey_wave) %>%
  summarise(
    respondents = n(),
    usable_responses = sum(usable_response),
    usable_rate = round(usable_responses / respondents, 3),
    comment_responses = sum(!is.na(comment_01)),
    comment_response_rate = round(
      comment_responses / respondents,
      3
    )
  )
