# Reporting and Privacy Rules

## Purpose

These rules define how employee survey results will be analyzed, displayed, and interpreted in the Employee Listening and Organizational Health Analytics project.

They are intended to protect employee confidentiality, reduce the risk of overinterpreting small groups, and ensure that reporting decisions are applied consistently across the analysis, dashboard, and executive report.

## Minimum Reporting Threshold

Employee survey results will only be displayed for organizational groups with at least 10 usable survey responses.

A usable response is a survey submission that meets the project's response-quality requirements and contains sufficient information to calculate the relevant measure.

Reporting status will be assigned as follows:

* Fewer than 10 respondents: Suppressed
* 10–19 respondents: Reportable with caution
* 20 or more respondents: Fully reportable

Results for groups below the minimum threshold will not display scores, favorable-response percentages, confidence intervals, trends, or open-ended comment themes.

## Survey Participation Reporting

Response rates may be reported using the full eligible survey population.

Response-rate calculations will use:

* Response rate = Number of usable survey responses ÷ Number of eligible invited employees

Participation counts may be displayed for organizational units even when survey scores are suppressed, provided that the counts do not create an unnecessary risk of identifying individual employees.

## Organizational Group Reporting

Results may be examined by:

* Business unit
* Department
* Job level
* Manager status
* Tenure group
* Work arrangement
* Survey wave

Results will not be displayed for any subgroup that falls below the minimum reporting threshold.

When multiple filters are applied, the reporting threshold will be reassessed using the number of respondents remaining after all filters have been applied.

## Trend Reporting

Wave-over-wave changes will only be reported when the organizational group meets the minimum reporting threshold in both survey waves.

When a group is reportable in one wave but not the other, the trend will be labeled unavailable.

Trend results will include both the direction and magnitude of change. Small differences will not automatically be described as meaningful.

## Small-Group Caution

Groups with 10–19 respondents may be displayed but will receive a caution indicator.

Results for these groups will be interpreted carefully because estimates based on smaller samples have greater uncertainty and may be affected more strongly by individual responses.

## Employee Identifiers

Employee identifiers will not be included in public-facing datasets, Tableau Public files, dashboard downloads, screenshots, or reports.

Employee IDs may be used temporarily during private data preparation to connect population, survey, and outcome records. They will be removed from public reporting tables.

## Individual-Level Reporting

The project will not display:

* Individual survey responses
* Individual scale scores
* Individual intent-to-stay scores
* Individual turnover probabilities
* Lists of employees classified as high risk
* Individual manager rankings

The purpose of the project is organizational learning and group-level analysis, not employee surveillance or individual performance evaluation.

## Manager-Level Reporting

Manager-level results will only be displayed when the manager's reporting group meets the minimum reporting threshold.

Managers with fewer than 10 usable responses will not receive an individual score or appear in comparative rankings.

Results will not be used to label individual managers as effective or ineffective based solely on survey responses.

## Open-Ended Comments

All open-ended comments in the portfolio project will be synthetic.

Comments will only be reported through aggregated themes or carefully selected examples. Comments will not be connected to employee identifiers or displayed for groups below the minimum reporting threshold.

Comments containing highly specific personal, location, role, or incident details will be excluded from public reporting even when they are synthetic.

## Public Dashboard Data

The Tableau Public dashboard will use aggregated reporting tables rather than unrestricted employee-level survey data.

Before publication, the dataset will:

* Remove employee identifiers
* Apply suppression rules
* Exclude individual response records where possible
* Exclude individual retention-risk predictions
* Exclude identifiable comment text
* Limit fields to those needed for dashboard reporting

## Statistical Interpretation

Statistical relationships will be described as associations rather than causal effects.

Acceptable language includes:

* `Associated with intent to stay`
* `Potential driver for further investigation`
* `Meaningful experience difference`
* `Priority area for follow-up`
* `The results suggest`
* `Employees in this group reported`

The following claims will be avoided:

* `This factor caused employees to stay`
* `This department has bad managers`
* `These employees will leave`
* `Improving this score will definitely reduce turnover`
* `The analysis proves that one experience caused another`

Statistical significance will not be interpreted without considering the size, uncertainty, and practical importance of the difference.

## Retention Analysis

Any voluntary-turnover analysis will be treated as a secondary component of the project.

The retention model will not be used to make employment decisions or identify individual employees for intervention.

Model results will be evaluated at the aggregate level and will include:

* Calibration
* Precision and recall
* Time-based validation
* Subgroup performance
* Limitations
* Potential sources of bias

Individual retention-risk scores will not appear in the public dashboard.

## Consistent Application

These reporting and privacy rules will be applied consistently across:

* Data-preparation scripts
* Statistical analysis notebooks
* SQL reporting tables
* Tableau dashboard views
* Executive reports
* README documentation
* Dashboard screenshots

Any exception to these rules will be documented and justified.
