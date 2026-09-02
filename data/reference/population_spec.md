# Population Specification

This document summarizes the synthetic employee-population specifications used to generate the Meridian Workforce Solutions survey population.

**Source:** `survey_item_map.xlsx` — `Population_Spec` sheet.

**Note:** All population specifications are synthetic and are used solely for demonstration purposes.

## Survey Waves

| Parameter | Wave 1 | Wave 2 |
|---|---|---|
| Survey wave | Wave 1 | Wave 2 |
| Survey launch date | October 15, 2025 | April 15, 2026 |
| Approximate workforce size | 3,600 | 3,600 |
| Time between waves | — | 6 months |

## Organizational Structure

| Business unit | Department | Target headcount | % of workforce |
|---|---|---:|---:|
| Client Operations | Customer Support | 700 | 19.4% |
| Client Operations | Implementation | 450 | 12.5% |
| Client Operations | Service Delivery | 470 | 13.1% |
| Technology & Product | Engineering | 600 | 16.7% |
| Technology & Product | Data & Analytics | 270 | 7.5% |
| Technology & Product | Product | 390 | 10.8% |
| Corporate Services | Human Resources | 180 | 5.0% |
| Corporate Services | Finance | 180 | 5.0% |
| Corporate Services | Sales & Marketing | 360 | 10.0% |
| **Total** | | **3,600** | **100.0%** |

## Job-Level Distribution

| Job level | Target % | Approximate headcount |
|---|---:|---:|
| Entry Level | 18.0% | 648 |
| Professional | 40.0% | 1,440 |
| Senior Professional | 25.0% | 900 |
| Manager | 12.0% | 432 |
| Director and Above | 5.0% | 180 |
| **Total** | **100.0%** | **3,600** |

## Tenure Targets

| Tenure group | Target % | Approximate headcount |
|---|---:|---:|
| Less than 1 year | 15.0% | 540 |
| 1–2 years | 25.0% | 900 |
| 3–5 years | 30.0% | 1,080 |
| 6–10 years | 20.0% | 720 |
| 11 or more years | 10.0% | 360 |
| **Total** | **100.0%** | **3,600** |

## Work Arrangements

| Work arrangement | Target % | Approximate headcount |
|---|---:|---:|
| On-site | 35.0% | 1,260 |
| Hybrid | 40.0% | 1,440 |
| Remote | 25.0% | 900 |
| **Total** | **100.0%** | **3,600** |

## Location Region

| Region | Target % | Approximate headcount |
|---|---:|---:|
| Northeast | 28.0% | 1,008 |
| South | 27.0% | 972 |
| Midwest | 25.0% | 900 |
| West | 20.0% | 720 |
| **Total** | **100.0%** | **3,600** |

## Manager Status Logic

| Job level | Approximate probability of being a People Manager |
|---|---:|
| Entry Level | 0% |
| Professional | 2% |
| Senior Professional | 8% |
| Manager | 80% |
| Director and Above | 90% |

## Generation Rules and Dependencies

| Variable | Depends on | Rule |
|---|---|---|
| department | business_unit | Department must belong to its assigned business unit. |
| job_level | department, tenure_group | Job-level probabilities vary by department and are adjusted by tenure group; longer-tenured employees have a lower probability of entry-level classification. |
| manager_status | job_level | Probability of being a people manager increases at higher job levels; Entry Level employees cannot be People Managers. |
| work_arrangement | department | Work arrangement probabilities vary by department. |
| hire_date | Survey date | Hire date must occur on or before the relevant survey date. |
| tenure_years | hire_date, survey_date | Derived from the difference between hire date and survey date. |
| tenure_group | tenure_years | Derived from tenure-year boundaries. |
| eligible | Employment status and dates | Eligibility determined by the survey population rules. |
| invited | eligible | Eligible employees are normally invited. |
| responded | Department, tenure, work arrangement | Response probability may vary moderately across groups. |
| usable_response | responded, survey completion | Only submitted responses can be classified as usable. |
| response_status | eligible, invited, responded, usable_response | Derived from eligibility and survey participation fields. |

## Department-Specific Work Arrangement Assumptions

| Department | On-site | Hybrid | Remote | Total |
|---|---:|---:|---:|---:|
| Customer Support | 60% | 25% | 15% | 100% |
| Implementation | 30% | 45% | 25% | 100% |
| Service Delivery | 55% | 30% | 15% | 100% |
| Engineering | 15% | 55% | 30% | 100% |
| Data & Analytics | 10% | 55% | 35% | 100% |
| Product | 10% | 60% | 30% | 100% |
| Human Resources | 20% | 60% | 20% | 100% |
| Finance | 25% | 60% | 15% | 100% |
| Sales & Marketing | 10% | 45% | 45% | 100% |

## Job-Level Mix by Department Type

| Department type | Entry | Professional | Senior Professional | Manager | Director+ | Total |
|---|---:|---:|---:|---:|---:|---:|
| Customer Support / Service Delivery | 30% | 40% | 18% | 9% | 3% | 100% |
| Implementation | 15% | 45% | 25% | 11% | 4% | 100% |
| Engineering / Data & Analytics / Product | 8% | 42% | 32% | 13% | 5% | 100% |
| HR / Finance | 10% | 45% | 28% | 12% | 5% | 100% |
| Sales & Marketing | 15% | 40% | 25% | 14% | 6% | 100% |
