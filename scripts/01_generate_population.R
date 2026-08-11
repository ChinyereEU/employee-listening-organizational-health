# ============================================================
# Employee Listening and Organizational Health Analytics
# Script: 01_generate_population.R
# Purpose: Generate the synthetic employee population used
#           for survey participation and employee-experience analysis.
# ============================================================

# 1. Packages ------------------------------------------------

library(dplyr)
library(tidyr)
library(purrr)
library(lubridate)
library(readr)
library(writexl)

# 2. Reproducibility ------------------------------------------

set.seed(123) #so this script produces the same synthetic 
#   population each time it is run

# 3. Core project assumptions ---------------------------------

n_employees = 3600
wave_1_date = as.Date("2025-10-15") #first & second wave are 6-months apart
wave_2_date = as.Date("2026-04-15")

min_hire_date = as.Date("2005-01-01")

# 4. Department structure -------------------------------------

department_spec = tibble( #translate the Excel assumptions into
#               a machine-readable R table
    business_unit = c(
        "Client Operations",
        "Client Operations",
        "Client Operations",
        "Technology and Product",
        "Technology and Product",
        "Technology and Product",
        "Corporate Services",
        "Corporate Services",
        "Corporate Services"
    ),

    department = c(
        "Customer Support",
        "Implementation",
        "Service Delivery",
        "Engineering",
        "Data and Analytics",
        "Product",
        "Human Resources",
        "Finance",
        "Sales and Marketing"
    ),

    target_headcount = c(
        700,
        450,
        470,
        600,
        270,
        390,
        180,
        180,
        360
    )
)

# 5. Validate department totals -----------------------------------------

sum(department_spec$target_headcount)

#department headcount must always equal the total employee 
#           population specified above
stopifnot(sum(department_spec$target_headcount) == n_employees)

# 6. Create base employee population -------------------------------------

employee_population = department_spec %>%
    tidyr::uncount(weights = target_headcount) %>%     # expands each dept according to its target_headcount
    mutate(
        employee_id = sprintf("EMP%04d", row_number()) # creates IDs like EMP0001, EMP0002... that match the Excel Data_Dictionary
    ) %>%
    select(employee_id,
           business_unit,
           department
    )

# 7. Validate base populations

stopifnot(
    nrow(employee_population) == n_employees, # exactly 3600 rows exist
    n_distinct(employee_population$employee_id) == n_employees, # all 3600 employee IDs are unique
    !any(is.na(employee_population$business_unit)), # no employee is missing a business unit
    !any(is.na(employee_population$department)) # no employee is missing a department
)

# 8. Define tenure group probabilities -------------------------------------
# Logic: nobody can have a hire date after the survey date.
# Since the base employee population is being created before the
#       survey-wave expansion, I'm using Wave 1 as the reference 
#       point for initial hire-date generation.
# Later, when I build both waves, tenure will be recalculated for each wave.

tenure_groups = c(
    "Less than 1 year",
    "1-2 years",
    "3-5 years",
    "6-10 years",
    "11 or more years"
)

tenure_group_probs = c(
    0.15, 0.25, 0.30, 0.20, 0.10
)

# 9. Assign target tenure bands -------------------------------------

employee_population = employee_population %>%
    mutate(
        tenure_target_group = sample(
            tenure_groups,
            size = n(),
            replace = TRUE,
            prob = tenure_group_probs
        )
    )


# 10. Generate hire dates within tenure bands -------------------------------------

employee_population = employee_population %>%
    mutate(
        days_since_hire = map_int(
            tenure_target_group,
            ~ case_when(
                .x == "Less than 1 year" ~ sample(0:364, 1),
                .x == "1-2 years" ~ sample(365:1095, 1),
                .x == "3-5 years" ~ sample(1096:2191, 1),
                .x == "6-10 years" ~ sample(2192:4017, 1),
                .x == "11 or more years" ~ sample(4018:7592, 1)
            )
        ),
        hire_date = wave_1_date - days_since_hire
    )
# 11. Derive tenure years -------------------------------------

employee_population = employee_population %>%
    mutate(
        tenure_years = round(
            as.numeric(
                difftime(
                    wave_1_date,
                    hire_date,
                    units = "days"
                )
            ) / 365.25,
            2
        )
    )

# 12. Derive tenure groups --------------------------------

employee_population = employee_population %>%
    mutate(
        tenure_group = case_when(
            tenure_years < 1 ~ "Less than 1 year",
            tenure_years < 3 ~ "1-2 years",
            tenure_years < 6 ~ "3-5 years",
            tenure_years < 11 ~ "6-10 years",
            tenure_years >= 11 ~ "11 or more years"
        )
    )

# 13. Validate tenure -------------------------------------

stopifnot(
    !any(is.na(employee_population$hire_date)),
    !any(is.na(employee_population$tenure_years)),
    !any(is.na(employee_population$tenure_group)),
    all(employee_population$hire_date <= wave_1_date),
    all(employee_population$hire_date >= min_hire_date),
    all(employee_population$tenure_years >= 0),
    all(employee_population$tenure_group %in% tenure_groups)
)

# 14. Define job-level probabilities -------------------------------------

job_levels = c(
    "Entry Level",
    "Professional",
    "Senior Professional",
    "Manager",
    "Director and Above"
)

job_level_probs = list(
    customer_service = c(
        0.30, 0.40, 0.18, 0.09, 0.03
    ),
    
    implementation = c(
        0.15, 0.45, 0.25, 0.11, 0.04
    ),
    
    tech_product = c(
        0.08, 0.42, 0.32, 0.13, 0.05
    ),
    
    corporate = c(
        0.10, 0.45, 0.28, 0.12, 0.05
    ),
    
    sales_marketing = c(
        0.15, 0.40, 0.25, 0.14, 0.06
    )
)

# 15. Assign department job-level groups -------------------------------------
# define which probability set belongs to each department

employee_population = employee_population %>%
    mutate(
        job_level_group = case_when(
            department %in% c(
                "Customer Support",
                "Service Delivery"
            ) ~ "customer_service",
            
            department == "Implementation" ~ "implementation",
            
            department %in% c(
                "Engineering",
                "Data and Analytics",
                "Product"
            ) ~ "tech_product",
            
            department %in% c(
                "Human Resources",
                "Finance"
            ) ~ "corporate",
            
            department == "Sales and Marketing" ~ "sales_marketing"
        )
    )

# 16. Adjust job-level probabilities based on tenure -------------------------------------

adjust_job_level_probs = function(base_probs, tenure_group){
    adjusted = case_when(
        tenure_group == "Less than 1 year" ~
            base_probs * c(1.5, 1.1, 0.5, 0.4, 0.3),
        
        tenure_group == "1-2 years" ~
            base_probs * c(1.2, 1.1, 0.8, 0.6, 0.5),
        
        tenure_group == "3-5 years" ~
            base_probs * c(0.8, 1.1, 1.2, 0.9, 0.7),
        
        tenure_group == "6-10 years" ~
            base_probs * c(0.5, 1.0, 1.3, 1.2, 1.0),
        
        tenure_group == "11 or more years" ~
            base_probs * c(0.3, 0.9, 1.4, 1.4, 1.2)
    )
    
    adjusted / sum(adjusted)
}

# 17. Generate job levels  -------------------------------------
# assign the actual job level using the Excel probabilities 
#       (won't be exact, sampling probabilistically) to 
#       create as close to a realistic workforce as possible

employee_population = employee_population %>%
    mutate(
        job_level = map2_chr(
            job_level_group,
            tenure_group,
            ~ sample(
                job_levels,
                size = 1,
                prob = adjust_job_level_probs(
                    job_level_probs[[.x]],
                    .y
                )
            )
        )
    )

# 18. Validate job levels -------------------------------------

stopifnot(
    !any(is.na(employee_population$job_level_group)), # each employee must have a job_level_group (corporate, tech_product, etc)
    !any(is.na(employee_population$job_level)), # each employee must have a job_level assigned (entry level, professional, etc.)
    all(employee_population$job_level %in% job_levels) # each employee job_level must exist in the defined job_levels
)

# 19. Define people manager-status probabilities -------------------------------------
# this status is not random, it depends on job_level as defined in Excel Population_Spec

manager_probs = c(
    "Entry Level" = 0.00,
    "Professional" = 0.02,
    "Senior Professional" = 0.08,
    "Manager" = 0.80,
    "Director and Above" = 0.90
)

# 20. Generate manager status -------------------------------------

employee_population = employee_population %>%
    mutate(
        manager_status = map_chr(
            job_level,
            ~sample(
                c("Individual Contributor", "People Manager"),
                size = 1,
                prob = c( 
                    # probs for someone at the `manager` job level: IC = 20%; People Manager = 80%
                    # probs for someone at the `senior professional` job level: IC = 92%; People Manager = 8%
                    1 - manager_probs[[.x]],
                    manager_probs[[.x]]
                )
            )
        )
    )

# 21. Validate manager status -------------------------------------

stopifnot(
    !any(is.na(employee_population$manager_status)),
    all(
        # only IC & PM are assignable manager_statuses
        employee_population$manager_status %in%
            c("Individual Contributor", "People Manager")
    ),
    !any( # entry level cannot be people manager
        employee_population$job_level == "Entry Level" & 
            employee_population$manager_status == "People Manager"
    )
)

# 22. Define work-arrangement probabilities -------------------------------------
# assign work arrangement by department

work_arrangements = c(
    "On-site",
    "Hybrid",
    "Remote"
)

work_arrangement_probs = list(
    "Customer Support" = c(0.60, 0.25, 0.15),
    "Implementation" = c(0.30, 0.45, 0.25),
    "Service Delivery" = c(0.55, 0.30, 0.15),
    "Engineering" = c(0.15, 0.55, 0.30),
    "Data and Analytics" = c(0.10, 0.55, 0.35),
    "Product" = c(0.10, 0.60, 0.30),
    "Human Resources" = c(0.20, 0.60, 0.20),
    "Finance" = c(0.25, 0.60, 0.15),
    "Sales and Marketing" = c(0.10, 0.45, 0.45)
)

# 23. Generate work arrangement -------------------------------------

employee_population = employee_population %>%
    mutate(
        work_arrangement = map_chr(
            department,
            ~ sample(
                work_arrangements,
                size = 1,
                prob = work_arrangement_probs[[.x]]
            )
        )
    )

# 24. Validate work arrangement -------------------------------------

stopifnot(
    !any(is.na(employee_population$work_arrangement)),
    all(
        employee_population$work_arrangement %in%
            work_arrangements
    )
)

# check to make sure each department has a probability vector

stopifnot(
    all(
        unique(employee_population$department) %in%
            names(work_arrangement_probs)
    )
)

# 25. Define location-region probabilities -------------------------------------

location_regions = c(
    "Northeast",
    "South",
    "Midwest",
    "West"
)

location_region_probs = c(
    0.28,
    0.27,
    0.25,
    0.20
)

# 26. Generate location region -------------------------------------

employee_population = employee_population %>%
    mutate(
        location_region = sample(
            location_regions,
            size = n(),
            replace = TRUE,
            prob = location_region_probs
        )
    )

# 27. Validate location region -------------------------------------

stopifnot(
    !any(is.na(employee_population$location_region)),
    all(
        employee_population$location_region %in%
            location_regions
    )
)

# 28. Remove the generation-only helper variables -------------------

employee_population = employee_population %>%
    select(
        employee_id,
        business_unit,
        department,
        job_level,
        manager_status,
        work_arrangement,
        location_region,
        hire_date,
        tenure_years,
        tenure_group
    )

# 29. Validate the final employee population --------------------------

stopifnot(
    nrow(employee_population) == 3600,
    n_distinct(employee_population$employee_id) == 3600,
    !anyNA(employee_population$employee_id),
    !anyNA(employee_population$business_unit),
    !anyNA(employee_population$department),
    !anyNA(employee_population$job_level),
    !anyNA(employee_population$manager_status),
    !anyNA(employee_population$work_arrangement),
    !anyNA(employee_population$location_region),
    !anyNA(employee_population$hire_date),
    !anyNA(employee_population$tenure_years),
    !anyNA(employee_population$tenure_group)
)

# inspect the final structure --------------------------------------

glimpse(employee_population)

summary(employee_population)

# 30. Save the employee population ---------------------------------

writexl::write_xlsx(employee_population, "data/processed/employee_population.xlsx")
