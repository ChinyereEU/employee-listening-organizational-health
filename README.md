# Employee Listening and Organizational Health Analytics

A synthetic employee-listening analytics project examining employee experience, organizational differences, survey measurement quality, and associations with intent to stay.

## Project Status

**Complete**

This project demonstrates an end-to-end employee-listening and organizational-health analytics workflow, from synthetic data generation and survey validation through organizational analysis, predictive modeling, privacy-conscious reporting, and stakeholder communication.

## Project Overview

This project simulates an internal employee-listening program for Meridian Workforce Solutions, a fictional workforce and people-analytics consulting organization with approximately 3,600 employees.

The analysis uses synthetic employee and survey data representing two survey waves conducted six months apart. The project demonstrates how an internal people analytics team could assess employee experience, evaluate survey measurement quality, identify organizational differences, and examine factors associated with employees' intent to stay.

All data used in this project are synthetic and were created for demonstration purposes. No real employee or organizational data are used.

## Business Question

> What aspects of the employee experience at Meridian are most strongly associated with intent to stay, and which organizational groups may need additional support?

### Objectives

1. Assess employee experience across six core constructs.
2. Identify differences across business units and departments.
3. Examine associations between employee experience and intent to stay.
4. Develop and evaluate a predictive model of intent to stay.
5. Determine whether basic employee characteristics provide additional predictive information beyond employee-experience measures.

## Employee-Experience Dimensions

The survey measures six employee-experience constructs:

- Engagement
- Manager Effectiveness
- Psychological Safety
- Growth & Development
- Workload Sustainability
- Belonging

The survey also includes **Intent to Stay** as the primary outcome for the predictive analysis.

Each employee-experience construct is measured using multiple survey items rather than a single overall satisfaction question.

## Analytical Approach

The project includes:

- Synthetic employee population and survey-data generation
- Survey population and participation processing
- Survey-response validation
- Missing-data assessment
- Likert-scale validation
- Internal consistency assessment using Cronbach's alpha
- Factorability diagnostics
- Exploratory factor analysis
- Composite scale construction
- Organization- and business-unit-level comparisons
- Department-level analysis
- Correlation analysis
- Multiple linear regression
- Train/test model evaluation
- Multicollinearity diagnostics
- Comparison of employee-experience measures with basic employee characteristics
- Privacy-conscious organizational reporting
- Report-ready analytical outputs and visualizations

Statistical relationships are described as associations rather than causal effects.

## Key Results

The final analytical dataset contains **4,344 usable survey responses**, with **4,071 valid Intent to Stay observations**.

Key findings include:

- Overall employee-experience scores were tightly clustered around the midpoint of the five-point scale.
- Growth & Development had the highest overall mean score (3.02), while Belonging had the lowest (2.98).
- Business-unit differences were generally modest.
- Department-level analysis showed greater variation in selected areas, particularly Growth & Development and Manager Effectiveness.
- All six employee-experience constructs were positively associated with Intent to Stay.
- Engagement showed the strongest observed correlation with Intent to Stay (`r = .529`), followed by Manager Effectiveness (`r = .524`) and Belonging (`r = .503`).
- The final predictive model achieved an R² of **.582** on the held-out test set, with RMSE of **.794** and MAE of **.640**.
- Adding job level, manager status, work arrangement, and tenure did not significantly improve model fit (`p = .700`).

Because the data are synthetic, these findings describe patterns within the simulated dataset and should not be interpreted as evidence about real employees or organizations.

## Measurement and Reporting Safeguards

The survey measurement framework was evaluated before substantive analysis.

- Cronbach's alpha values across the six constructs ranged from **0.754 to 0.780**.
- Overall KMO was **0.90**.
- Bartlett's test of sphericity was significant (`χ² = 29,381.6`, `df = 276`, `p < .001`).
- Parallel analysis supported a six-factor structure.
- Exploratory factor analysis supported the intended six-construct measurement structure.

Survey reporting uses a minimum threshold of **10 usable responses** for organizational groups. Groups below the threshold would be suppressed rather than reported.

The threshold is a basic reporting safeguard; real employee-listening programs would require additional protections when examining small demographic or organizational intersections.

## How to Interpret the Results

This is a simulation-based portfolio project, not an empirical study of real employees.

The employee population, survey responses, organizational characteristics, and analytical findings were synthetically generated for demonstration purposes. The results therefore describe relationships within the simulated data-generating process rather than real-world workforce behavior.

The analysis distinguishes between:

- Patterns represented in the synthetic data-generating process
- Relationships recovered through statistical analysis
- Findings that remain uncertain or are not supported by the simulated data

The project does not claim that synthetic findings generalize to real organizations or establish causal relationships.

## Tools

- R
- Excel
- Git and GitHub

## Repository Structure

```text
employee-listening-organizational-health/
├── README.md
├── assets/
├── data/
│   ├── processed/
│   ├── raw/
│   └── reference/
├── docs/
├── figures/
├── outputs/
├── reports/
└── scripts/
    ├── 01_generate_population.R
    ├── 02_generate_survey_population.R
    ├── 03_generate_survey_responses.R
    ├── 04_validate_survey_data.R
    ├── 05_organizational_analysis.R
    ├── 06_predictive_modeling.R
    └── 07_reporting_outputs.R