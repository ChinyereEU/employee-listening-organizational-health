# Project Foundation

## Employee Listening and Organizational Health Analytics

## Fictional Organization

**Company:** Meridian Workforce Solutions
**Industry:** Business services and technology-enabled operations
**Employees:** Approximately 3,600
**Locations:** Multiple U.S. offices plus remote employees
**Survey cadence:** Two survey waves conducted six months apart
**Work arrangements:** On-site, hybrid, and remote
**Minimum reporting threshold:** 10 usable survey responses

## Organizational Structure

| Business unit          | Departments                                        |
| ---------------------- | -------------------------------------------------- |
| Client Operations      | Customer Support, Implementation, Service Delivery |
| Technology and Product | Engineering, Data and Analytics, Product           |
| Corporate Services     | Human Resources, Finance, Sales and Marketing      |

## Job Levels

1. Entry Level
2. Professional
3. Senior Professional
4. Manager
5. Director and Above

## Project Overview

Meridian Workforce Solutions is a fictional business services and technology organization with approximately 3,600 employees across client operations, technology, product, and corporate functions. Employees work through on-site, hybrid, and remote arrangements across multiple U.S. locations.

The organization conducts a recurring employee-listening survey to understand employee experiences, monitor organizational health, and identify areas that may require additional investigation or leadership support.

This project analyzes two employee survey waves conducted six months apart. It evaluates survey participation, validates employee-experience measures, examines differences across organizational groups, and identifies experience dimensions associated with employees' intent to stay.

The project uses entirely synthetic data and does not contain information from real employees or organizations.

## Business Need

Leadership wants a more complete understanding of employee experience than can be obtained from a single overall satisfaction score. The organization needs to know:

* Which dimensions of the employee experience are most strongly associated with intent to stay
* Whether employee experiences are improving or declining across survey waves
* Which organizational groups show meaningful experience differences
* Where additional qualitative investigation or leadership follow-up may be warranted
* Whether survey results can be reported while protecting employee confidentiality

The analysis is intended to support organizational learning and follow-up. It will not be used to identify individual employees, assign individual retention-risk scores, or evaluate individual managers.

## Primary Business Questions

1. Which employee-experience dimensions are most strongly associated with employees' intent to stay?
2. Which departments, job levels, tenure groups, and work arrangements show meaningful differences in employee experience?
3. Which organizational health measures improved or declined between the two survey waves?
4. Which groups may require additional investigation or organizational support?
5. Are survey participation patterns sufficiently representative across organizational groups?

## Survey Population

The survey population includes active employees who meet the organization's eligibility requirements on the date each survey wave is launched.

Employees will be excluded when they:

* Are inactive before the survey launch date
* Are temporary workers who do not meet the program's eligibility rules
* Join after the survey population is finalized
* Leave the organization before receiving the invitation
* Have invalid or unavailable survey contact information

The synthetic population will include invited respondents and invited nonrespondents so that response rates can be calculated using the full eligible population.

## Employee-Experience Framework

The survey will measure six primary employee-experience dimensions:

* Engagement
* Manager effectiveness
* Psychological safety
* Growth and development
* Workload sustainability
* Belonging

Detailed construct definitions, item counts, and survey response scales are documented in [`survey_constructs.md`](survey_constructs.md).

## Primary Outcome

The primary outcome will be intent to stay, measured through multiple survey items rather than a single question.

Intent to stay will be treated as an employee attitude measured at the time of the survey. Associations between employee-experience dimensions and intent to stay will not be presented as proof that one experience dimension causes employees to remain with the organization.

## Optional Secondary Outcome

A later version of the project may connect survey responses to voluntary turnover during a defined period following the survey.

The turnover model will be secondary to the employee-listening analysis. It will be evaluated using time-based validation, calibration, precision, recall, subgroup performance, and clearly stated limitations.

Individual turnover-risk scores will not appear in the public dashboard.

## Reporting and Confidentiality

Results will only be displayed for groups that satisfy the project's minimum reporting requirements. Employee identifiers will be excluded from public-facing datasets, reports, and Tableau Public files.

Detailed privacy, suppression, small-group reporting, and interpretation standards are documented in [`reporting_privacy_rules.md`](reporting_privacy_rules.md).

## Analytical Scope

This project will include:

* Survey population definition
* Response-rate calculation
* Participation monitoring by organizational group
* Assessment of potential nonresponse patterns
* Missing-data analysis
* Survey item distributions
* Reliability analysis
* Exploratory factor analysis
* Scale construction
* Employee-experience comparisons
* Survey-wave trends
* Confidence intervals
* Practical significance and effect sizes
* Key-driver analysis
* Privacy-conscious dashboard reporting

The project will not claim that statistical associations prove causal relationships.

## Intended Audience

The primary audience includes:

* People Analytics leaders
* Human Resources leaders
* Employee Experience teams
* Department and business-unit leaders
* Organizational development professionals

The final materials will translate statistical findings into practical questions and areas for follow-up while maintaining appropriate methodological and privacy limitations.
