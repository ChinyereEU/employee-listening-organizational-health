# ============================================================
# Employee Listening and Organizational Health Analytics
# Script: 04_validate_survey_data.R
# Purpose: Validate the synthetic survey dataset and evaluate
#          the measurement properties of the survey instrument.
# ============================================================


# 1. Packages -------------------------------------------------

library(dplyr)
library(tidyr)
library(readxl)
library(psych)

# 2. Reproducibility ------------------------------------------

set.seed(123)

# 3. Load survey responses ------------------------------------

survey_responses = read_xlsx("data/processed/survey_responses.xlsx")

# 4. Define survey items --------------------------------------

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
  blg_04 = "belonging",
  
  its_01 = "intent_to_stay",
  its_02 = "intent_to_stay",
  
  ovl_01 = "overall_experience"
)

likert_items = names(item_construct_map)

# 5. Validate survey-response dataset -------------------------

stopifnot(
  "The survey-response dataset should contain 4,344 respondents." = 
    nrow(survey_responses) == 4344,
  
  "Employee IDs should be unique within each survey wave." = 
    nrow(
      survey_responses %>%
        distinct(employee_id, survey_wave)
    ) == nrow(survey_responses),
  
  "Some expected survey items are missing." = 
    all(
      likert_items %in% names(survey_responses)
    )
)

# 6. Validate Likert response values ---------------------------

stopifnot(
  "Some survey items contain values outside the five-point Likert scale." = 
    all(
      unlist(
        survey_responses[likert_items]
      ) %in% c(1:5, NA)
    )
)

# 7. Inspect respondents by survey wave ------------------------

survey_responses %>%
  count(survey_wave)

# 8. Inspect item-level missingness ----------------------------

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

# Inspect the range of missingness
range(item_missingness$missing_rate)

# 9. Inspect Likert item distributions for (1) ------------------

item_distributions = survey_responses %>%
  summarise(
    across(
      all_of(likert_items),
      ~ mean(. == 1, na.rm = TRUE)
    )
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = "item",
    values_to = "pct_strongly_disagree"
  )

item_distributions

# 10. Inspect full Likert distributions -----------------------

likert_distribution = survey_responses %>%
  select(all_of(likert_items)) %>%
  pivot_longer(
    cols = everything(),
    names_to = "item",
    values_to = "response"
  ) %>%
  filter(!is.na(response)) %>%
  count(item, response) %>%
  group_by(item) %>%
  mutate(
    pct = round(n / sum(n) * 100, 1)
  ) %>%
  ungroup()

likert_distribution

# Inspect the distribution of all items at once
likert_distribution %>%
  print(n = Inf)

# 11. Item correlation matrix ---------------------------------
# Are items intended to measure the same construct actually behaving
#   as related items in the generated data?

item_correlations = survey_responses %>%
  select(all_of(likert_items)) %>%
  cor(use = "pairwise.complete.obs") %>%
  round(2)

item_correlations

# 12. Within-construct item correlations ----------------------
# Specifically inspect the four items within each construct.
# 
# Are the four items within each construct correlated with each other?

construct_item_correlations = list(
  Engagement = c("eng_01", "eng_02", "eng_03", "eng_04"),
  Manager_effectiveness = c("mgr_01", "mgr_02", "mgr_03", "mgr_04"),
  Psychological_safety = c("psy_01", "psy_02", "psy_03", "psy_04"),
  Growth_development = c("grw_01", "grw_02", "grw_03", "grw_04"),
  Workload_sustainability = c("wrk_01", "wrk_02", "wrk_03", "wrk_04"),
  Belonging = c("blg_01", "blg_02", "blg_03", "blg_04")
)

within_construct_correlations = map(
  construct_item_correlations,
  ~ survey_responses %>%
    select(all_of(.x)) %>%
    cor(use = "pairwise.complete.obs") %>%
    round(2)
)

within_construct_correlations

# 13. Reliability analysis -------------------------------------
# Test whether the four items within each construct show adequate
#   internal consistency, i.e. do they behave consistently enough
#   that it makes sense to combine them into one score?
#   
# Internal consistency means that the questions that are supposed
#   to measure the same thing tend to move together.
#   
# Taken together, the items should form a sufficiently consistent scale.
# 
# Cronbach's alpha estimates how consistently a group of items 
#   measures the same underlying construct. Essentially, a measure
#   of scale consistency:
#   higher values generally indicate that the items are more strongly 
#   related and may be suitable for combining into a single scale score.
#   
#   Alpha summarizes the overall consistency w/a single summary statistic.
#   
#   Roughly: 
#   
#     |   Alpha | General interpretation |
#     | ------: | ---------------------- |
#     |   < .60 | Poor                   |
#     | .60–.69 | Questionable           |
#     | .70–.79 | Acceptable             |
#     | .80–.89 | Good                   |
#     |    .90+ | Very high              |
#     
#     raw_alpha: calculates alpha using actual item variances.
#     std_alpha: calculates alpha after standardizing the items, so
#       differences in their variances don't affect the calculation 
#       in the same way.
#   
# Reliability is not evidence that a scale measures the "correct" construct;
#   it only indicates that the items behave consistently with one another.
# 

reliability_results = map(
  construct_item_correlations,
  ~ psych::alpha(
    survey_responses %>%
      select(all_of(.x))
  )
)

reliability_summary = map_dfr(
  reliability_results,
  ~ tibble(
    raw_alpha = .x$total$raw_alpha,
    std_alpha = .x$total$std.alpha
  ),
  .id = "construct"
)

reliability_summary

# Inspect item-level reliability statistics
reliability_results$Engagement
reliability_results$Psychological_safety
reliability_results$Growth_development
reliability_results$Workload_sustainability
reliability_results$Belonging

# Reliability interpretation:
# All six multi-item constructs demonstrate acceptable internal consistency,
#   with Cronbach's alpha ranging from 0.754 to 0.780. Item-level diagnostics
#   do not indicate that removing any individual item would improve reliability.
#   
# These results support combining the items within each construct into
#   composite scale scores for subsequent analysis.

# 14. Validate reliability results -----------------------------

stopifnot(
  "Some constructs have a reliability estimate below the minimum threshold." = 
    all(
      reliability_summary$raw_alpha >= 0.70
    )
)

# 15. Prepare employee-experience items for factor analysis ----

experience_items = survey_responses %>%
  select(
    eng_01, eng_02, eng_03, eng_04,
    mgr_01, mgr_02, mgr_03, mgr_04,
    psy_01, psy_02, psy_03, psy_04,
    grw_01, grw_02, grw_03, grw_04,
    wrk_01, wrk_02, wrk_03, wrk_04,
    blg_01, blg_02, blg_03, blg_04
  )

# 16. Assess factorability ------------------------------------
# Is the correlation matrix suitable for factor analysis?
# 
# Before performing exploratory factor analysis (EFA), first determine whether
#   the survey items have enough shared correlation for factor analysis to be
#   meaningful.
# 
# EFA looks for underlying latent factors that explain patterns of correlation
#   among observed survey items. In this project, the 24 employee-experience
#   items were designed to reflect six latent constructs:
#   
#     Engagement, Manager effectiveness, Psychological safety, Growth & development,
#     Workload sustainability, Belonging
#     
# EFA asks whether the response patterns in the generated data actually support a 
#   structure resembling these underlying constructs, rather than simply assuming 
#   that the structure we designed is present.
#   
# Factorability means that the observed items share enough common information for
#   underlying factors to be identified. If the items were almost entirely unrelated,
#   factor analysis would not be appropriate.
#   
# Two diagnostics are used to assess factorability:
# 
# 16.1. KMO (Kaiser-Meyer-Olkin) ----------------------------------
# 
# KMO evaluates whether the items share enough common variance to justify
#   factor analysis. It compares the correlations among items with their
#   partial correlations.
#   
# Higher KMO values indicate that the correlation patterns are more suitable
#   for identifying common underlying factors.
#   
# Rough guidelines:
#   < 0.50       = unacceptable
#   0.50–0.59    = poor
#   0.60–0.69    = mediocre
#   0.70–0.79    = good
#   0.80–0.89    = very good
#   0.90+        = excellent
#   
# The overall KMO is the primary value of interest in this case. Individual item-level
#   KMO values can also be inspected if a particular item appears problematic.
#   
# 16.2. Bartlett's test of sphericity -----------------------------
# 
# Bartlett's test evaluates whether the correlation matrix contains meaningful
#   relationships among the items.
#   
# The null hypothesis is that the correlation matrix is an identity matrix,
#   meaning that the items are essentially uncorrelated with one another.
#   
# We generally want a statistically significant result (p < 0.05), which
#   provides evidence that the correlation matrix contains relationships that
#   make factor analysis appropriate.
#   
# KMO and Bartlett's test answer related but different questions:
# 
#   KMO -> Do the items share enough common information? i.e.
#          Are they related in a way that suggests they share 
#          underlying/common factors?
#   Bartlett  -> Are there meaningful correlations among the items? i.e. 
#                Are the items related at all? Does the correlation matrix 
#                differ from an identity matrix?
#   
# If the KMO is adequate and Bartlett's test is significant, the correlation
#   matrix is considered suitable for proceeding with EFA.
#   
# In this synthetic project, EFA provides an additional validation step:
#   the data were intentionally generated from six latent constructs, so we
#   expect the factor analysis to recover a structure broadly consistent with
#   those six constructs.
#   
# Important distinction:
#   Reliability asks whether items within a construct behave consistently.
#   EFA asks whether the broader pattern of relationships among items supports 
#   the presence of underlying factors.
#   
# EFA therefore does not simply confirm that the six constructs were specified
#   in advance; it explores whether the generated response data exhibit a
#   corresponding underlying structure.

experience_correlations = cor(
  experience_items,
  use = "pairwise.complete.obs"
)

experience_correlations

kmo_results = psych::KMO(experience_correlations)

bartlett_results = psych::cortest.bartlett(
  experience_correlations,
  n = nrow(experience_items)
)

kmo_results
bartlett_results

# Factorability interpretation:
# The 24 employee-experience items demonstrate excellent factorability.
# Overall KMO = 0.90, indicating that the items share sufficient common
# variance for factor analysis. Bartlett's test of sphericity is highly 
#   significant (chi-square = 29,381.6, df = 276, p < .001), indicating
#   that the correlation matrix differs substantially from an identity 
#   matrix.
#   
# Together, these results support proceeding with EFA to investigate whether
#   the generated response data recover the six underlying employee-experience
#   constructs specified during simulation.

# 17. Determine number of factors ------------------------------
# Parallel analysis compares the eigenvalues from our actual survey data
#   with eigenvalues expected from random data.
#   
# Factors are retained when the actual-data eigenvalue exceeds the
#   corresponding random-data benchmark.
#   
# Parallel analysis recommends retaining 6 factors. This matches the six 
#   latent employee-experience constructs specified during data generation:
#   Engagement, Manager Effectiveness, Psychological Safety, Growth &
#   Development, Workload Sustainability, and Belonging.
#   
# This provides evidence that the generated data contain the intended
#   six-factor structure rather than an arbitrary number of factors.

parallel_analysis = psych::fa.parallel(
  experience_items,
  fa = "fa",
  fm = "minres",
  cor = "poly"
)

# 18. Exploratory factor analysis ------------------------------
# Which items load on which factors?
# Examine whether the 24 employee-experience items recover the six latent
#   constructs specified during data generation.
#   
# Minimum residual factor analysis is used because the goal is to identify
#   underlying latent factors rather than reduce the data into components.
# Oblique rotation (oblimin) is used because the employee-experience
#   constructs are expected to be correlated.
#   
# Parallel analysis previously indicated that six factors should be retained.
# The EFA results show a clean six-factor structure: items designed for each
#   construct load strongly on the same factor with minimal cross-loadings.
#   
# This supports the intended measurement structure of the simulated survey.
# So no changes to the survey instrument are warranted from the EFA.

efa_6factor = psych::fa(
  experience_items,
  nfactors = 6,
  fm = "minres",
  rotate = "oblimin",
  cor = "poly"
)

efa_6factor

# 19. Inspect factor loadings ---------------------------------

print(
  efa_6factor$loadings,
  cutoff = 0.30,
  sort = TRUE
)

# 20. Validate EFA loading structure ---------------------------

loading_matrix = as.matrix(efa_6factor$loadings)

# Identify the strongest factor loading for each item

efa_loading_check = tibble(
  item = rownames(loading_matrix),
  primary_loading = apply(
    abs(loading_matrix),
    1,
    max
  )
)

efa_loading_check

# Check for substantial cross-loadings i.e. how many factors does
#   each item load meaningfully (>= 0.30) on?
#   
# In this case, all 24 items had a score of 1. Conceptually, this 
#   suggests that each survey question is clearly associated with 
#   its intended underlying construct rather than simultaneously 
#   measuring multiple constructs.

cross_loading_check = apply(
  abs(loading_matrix),
  1,
  function(x) sum(x >= 0.30)
)

cross_loading_check

# Validate that every item has a primary loading of at least 0.50
 stopifnot(
   "Some employee-experience items have a primary factor loading below 0.50." =
     all(
       efa_loading_check$primary_loading >= 0.50
     )
 )
 
# Validate that each construct's items load on the same factor

 expected_factor_items = list(
   Engagement = c("eng_01", "eng_02", "eng_03", "eng_04"),
   Manager_effectiveness = c("mgr_01", "mgr_02", "mgr_03", "mgr_04"),
   Psychological_safety = c("psy_01", "psy_02", "psy_03", "psy_04"),
   Growth_development = c("grw_01", "grw_02", "grw_03", "grw_04"),
   Workload_sustainability = c("wrk_01", "wrk_02", "wrk_03", "wrk_04"),
   Belonging = c("blg_01", "blg_02", "blg_03", "blg_04")
 )

# 21. Construct the Likert scale scores for the six constructs ---------
# Using the 24 experience items only <- excluding its_01, its_02, ovl_01,
#   create the construct scores.
#
# In the syntax, we use na.rm = TRUE because the data has item-level missingness.
# Since we previously established that a response is usable at 75% completion,
#   na.rm = TRUE is needed to prevent a missing item from making the entire
#   construct score missing.

construct_names = c(
   "engagement",
   "manager_effectiveness",
   "psychological_safety",
   "growth_development",
   "workload_sustainability",
   "belonging"
 )
 
survey_responses = survey_responses %>%
   mutate(
     engagement = rowMeans(
       select(., eng_01, eng_02, eng_03, eng_04),
       na.rm = TRUE
     ),
     manager_effectiveness = rowMeans(
       select(., mgr_01, mgr_02, mgr_03, mgr_04),
       na.rm = TRUE
     ),
     psychological_safety = rowMeans(
       select(., psy_01, psy_02, psy_03, psy_04),
       na.rm = TRUE
     ),
     growth_development = rowMeans(
       select(., grw_01, grw_02, grw_03, grw_04),
       na.rm = TRUE
     ),
     workload_sustainability = rowMeans(
       select(., wrk_01, wrk_02, wrk_03, wrk_04),
       na.rm = TRUE
     ),
     belonging = rowMeans(
       select(., blg_01, blg_02, blg_03, blg_04),
       na.rm = TRUE
     )
   )
 
# Inspect the Likert score (1 to 5) distribution for each construct;
# What do the six constructed employee-experience scores look like?
 
summary(
 survey_responses %>%
   select(
     engagement,
     manager_effectiveness,
     psychological_safety,
     growth_development,
     workload_sustainability,
     belonging
   )
)
 
# 22. Validate construct scale scores --------------------------

stopifnot(
  "Engagement scale contains values outside the valid 1 to 5 range." = 
    all(
      survey_responses$engagement >= 1 &
        survey_responses$engagement <= 5
    ),
  
  "Manager effectiveness scale contains values outside the valid 1 to 5 range." =
    all(
      survey_responses$manager_effectiveness >= 1 &
        survey_responses$manager_effectiveness <= 5
    ),
  
  "Psychological safety scale contains values outside the valid 1 to 5 range." =
    all(
      survey_responses$psychological_safety >= 1 &
        survey_responses$psychological_safety <= 5
    ),
  
  "Growth and development scale contains values outside the valid 1 to 5 range." =
    all(
      survey_responses$growth_development >= 1 &
        survey_responses$growth_development <= 5
    ),
  
  "Workload sustainability scale contains values outside the valid 1 to 5 range." =
    all(
      survey_responses$workload_sustainability >= 1 &
        survey_responses$workload_sustainability <= 5
    ),
  
  "Belonging scale contains values outside the valid 1 to 5 range." =
    all(
      survey_responses$belonging >= 1 &
        survey_responses$belonging <= 5
    )
)

# Check construct-score completeness; is any missing?

survey_responses %>%
 summarise(
   across(
     all_of(construct_names),
     ~ sum(is.na(.))
   )
 )

# 23. Inspect construct scale correlations ---------------------
# How are the six constructed scales related to one another?
# 
# Validate the relationship between the constructed scales and the
#   original item-level data.
#   
# This is to verify that the six constructed scales (eng, mgr, etc.) retain the 
#   expected positive relationships among the employee-experience
#   dimensions.

construct_correlations = survey_responses %>%
  select(all_of(construct_names)) %>%
  cor(use = "pairwise.complete.obs") %>%
  round(2)

construct_correlations
 
# 24. Construct correlations with intent to stay ----------------
# What is the relationship between the six construct scores &
#   intent to stay.
# 
# Verifies if the constructed scale scores shown the expected
#   positive association with the two intent-to-stay items.

intent_correlations = survey_responses %>%
  select(
    all_of(construct_names),
    its_01,
    its_02
  ) %>%
  cor(use = "pairwise.complete.obs") %>%
  round(2)

intent_correlations

# 25. Construct correlations with overall employee experience ----

overall_correlations = survey_responses %>%
  select(
    all_of(construct_names),
    ovl_01
  ) %>%
  cor(use = "pairwise.complete.obs") %>%
  round(2)

overall_correlations

# 26. Intent-to-stay reliability -------------------------------
# its_01 & its_02 explicitly intended to form a two-item outcome, 
#   let's confirm that.

intent_reliability = psych::alpha(
  survey_responses %>%
    select(its_01, its_02)
)

intent_reliability

# Intent-to-Stay reliability:
# The two-item scale shows moderate internal consistency (alpha = 0.63).
# Because removing either item lowers reliability, both items are retained.
# The relatively low alpha is partly attributable to the scale containing
#   only two items; the inter-item correlation should also be considered.

# 27. Construct intent-to-stay composite score -------------------
# Since missingness is already handled at the response level and both
#   items have similar behavior, we use the mean of the two items.

survey_responses = survey_responses %>%
  mutate(
    intent_to_stay = if_else(
      !is.na(its_01) & !is.na(its_02),
      rowMeans(
        select(
          .,
          its_01,
          its_02
        ),
        na.rm = FALSE
      ),
      NA_real_ #return a numeric NA when either its_01 or its_02 is missing so it doesn't return an error due to NaN when validating.
    )
  )

# Check the resulting composite score

summary(
  survey_responses %>%
    select(intent_to_stay)
)

# Validate intent-to-stay score range

stopifnot(
  "Non-missing intent-to-stay scores fall outside the expected 1-5 range." = 
    all(
      survey_responses$intent_to_stay[
        !is.na(survey_responses$intent_to_stay)
      ] >= 1 &
      survey_responses$intent_to_stay[
        !is.na(survey_responses$intent_to_stay)
      ] <= 5
    )
)

# 28. Final dataset structure validation ------------------------
# Make sure there aren't any accidentally retained simulation-only 
#   variables & that the expected analytical variables are present.

required_variables = c(
  "employee_id",
  "business_unit",
  "department",
  "job_level",
  "manager_status",
  "work_arrangement",
  "location_region",
  "hire_date",
  "tenure_years",
  "tenure_group",
  "survey_wave",
  "survey_date",
  "eng_01",
  "eng_02",
  "eng_03",
  "eng_04",
  "mgr_01",
  "mgr_02",
  "mgr_03",
  "mgr_04",
  "psy_01",
  "psy_02",
  "psy_03",
  "psy_04",
  "grw_01",
  "grw_02",
  "grw_03",
  "grw_04",
  "wrk_01",
  "wrk_02",
  "wrk_03",
  "wrk_04",
  "blg_01",
  "blg_02",
  "blg_03",
  "blg_04",
  "its_01",
  "its_02",
  "ovl_01",
  "intent_to_stay",
  "comment_01"
)

stopifnot(
  "Required variables are missing from the final datset." = 
    all(required_variables %in% names(survey_responses)),
  
  "Simulation-only continuous item variables remain in the final dataset." = 
    !any(grepl("_continuous$", names(survey_responses)))
)

# Check
setdiff(required_variables, names(survey_responses))

# 29. Final dataset size and survey-wave validation -------------

stopifnot(
  "The final dataset contains no rows." = 
    nrow(survey_responses) > 0,
  
  "The final dataset contains unexpected survey waves." = 
    all(
      survey_responses$survey_wave %in% c("Wave 1", "Wave 2")
    )
)

survey_responses %>%
  count(survey_wave)

# 30. Validate employee-wave uniqueness -------------------------

duplicate_employee_waves = survey_responses %>%
  count(
    employee_id,
    survey_wave
  ) %>%
  filter(n > 1)

duplicate_employee_waves

stopifnot(
  "Employees have duplicate records within the same survey wave." = 
    nrow(duplicate_employee_waves) == 0
)

# 31. Validate categorical variables ----------------------------

stopifnot(
  "Unexpected survey-wave values found." = 
    all(
      survey_responses$survey_wave %in%
        c("Wave 1", "Wave 2")
    ),
  
  "Unexpected manager-status values found." = 
    all(
      survey_responses$manager_status %in%
        c("People Manager", "Individual Contributor")
    ),
  
  "Unexpected work-arrangement values found." = 
    all(
      survey_responses$work_arrangement %in%
        c("Remote", "Hybrid", "On-site")
    )
)

# 32. Final response usability validation ----------------------

expected_usable_response = survey_responses$item_completion_rate >= 0.75

stopifnot(
  "Usable response flag does not match the 75% completion rule." = 
    all(
      survey_responses$usable_response == expected_usable_response
    )
)

survey_responses %>%
  count(survey_wave, usable_response) %>%
  group_by(survey_wave) %>%
  mutate(
    pct = round(n / sum(n) * 100, 1)
  ) %>%
  ungroup()

# 33. Validate construct-score ranges --------------------------
# Do all six constructed employee-experience scores remain on the 
#   intended 1-5 scale?

stopifnot(
  "Construct scores fall outside the expected the 1-5 range." =
    all(
      unlist(
        survey_responses %>%
          select(all_of(construct_names))
      ) >= 1 &
        unlist(
          survey_responses %>%
            select(all_of(construct_names))
        ) <= 5,
      na.rm = TRUE
    )
)

summary(
  survey_responses %>%
    select(all_of(construct_names))
)

# 34. Final analytical variable type validation ----------------
# Verify the analytical variables are numeric

stopifnot(
  "Construct scores are not numeric." = 
    all(
      sapply(
        survey_responses %>%
          select(all_of(construct_names)),
        is.numeric
      )
    ),
  
  "Intent-to-stay score is not numeric." = 
    is.numeric(survey_responses$intent_to_stay),
  
  "Likert survey items are not numeric." = 
    all(
      sapply(
        survey_responses %>%
          select(all_of(likert_items)),
        is.numeric
      )
    )
)

# 35. Final dataset sanity check -------------------------------

# Remove accidental column created during intent-to-stay constructions.

# survey_responses = survey_responses %>%
#   select(-`NA_real_`)

stopifnot(
  "Final dataset contains unexpected zero rows." = 
    nrow(survey_responses) > 0,
  
  "Employee IDs are missing." = 
    all(!is.na(survey_responses$employee_id)),
  
  "Survey dates are missing." = 
    all(!is.na(survey_responses$survey_date)),
  
  "Accidental NA_real_ column remains in the final dataset." = 
    !"NA_real_" %in% names(survey_responses)
)

dim(survey_responses)

names(survey_responses)

# 36. Save final validated survey dataset ----------------------

writexl::write_xlsx(survey_responses, "data/processed/survey_responses.xlsx")

file.exists("data/processed/survey_responses.xlsx")

# Verify saved dataset ------------------------------------------

saved_survey_responses = read_xlsx(
  "data/processed/survey_responses.xlsx"
)

dim(saved_survey_responses)

