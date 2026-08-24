# Synthetic Data Generation Assumptions

## Purpose

This document defines the assumptions used to generate the synthetic employee survey data for the Employee Listening and Organizational Health Analytics portfolio project.

The assumptions are simulation parameters rather than empirical estimates. They are used to create a realistic analytical environment in which the project's survey validation, organizational analysis, and intent-to-stay analyses can be demonstrated.

The resulting findings should therefore be interpreted as patterns within the simulated data-generating process rather than evidence about real employees or organizations.

## Latent Employee-Experience Constructs

The simulation will generate six correlated latent employee-experience constructs:

- Engagement
- Manager effectiveness
- Psychological safety
- Growth and development
- Workload sustainability
- Belonging

Each construct will serve as the underlying dimension for four observed survey items defined in the [`survey_instrument.md`](survey_instrument.md).

## Correlation Structure

The latent constructs will be simulated with the following correlation structure:

| | Engagement | Manager effectiveness | Psychological safety | Growth and development | Workload sustainability | Belonging |
|---|---:|---:|---:|---:|---:|---:|
| Engagement | 1.00 | 0.45 | 0.40 | 0.40 | 0.35 | 0.45 |
| Manager effectiveness | 0.45 | 1.00 | 0.50 | 0.40 | 0.40 | 0.45 |
| Psychological safety | 0.40 | 0.50 | 1.00 | 0.35 | 0.40 | 0.50 |
| Growth and development | 0.40 | 0.40 | 0.35 | 1.00 | 0.30 | 0.40 |
| Workload sustainability | 0.35 | 0.40 | 0.40 | 0.30 | 1.00 | 0.35 |
| Belonging | 0.45 | 0.45 | 0.50 | 0.40 | 0.35 | 1.00 |

These correlations are intentional simulation parameters. They do not represent estimates from real employee data.

## Intent-to-Stay Relationship

Intent to stay will be simulated as a separate outcome that is moderately associated with the employee-experience constructs.

The intended relationships are:

| Employee-experience construct | Intended association with intent to stay |
|---|---:|
| Engagement | 0.45 |
| Manager effectiveness | 0.40 |
| Psychological safety | 0.35 |
| Growth and development | 0.35 |
| Workload sustainability | 0.30 |
| Belonging | 0.40 |

These values are simulation assumptions and will not be presented as empirical findings.

The subsequent analysis will determine which associations are recovered from the simulated sample and how strongly they appear after accounting for other dimensions.

## Item Generation

Each employee-experience construct will generate four observed survey items.

The observed items will be imperfect indicators of their underlying latent construct. Item responses will therefore include measurement error and will not be identical within a construct.

The item structure follows the survey instrument:

- Engagement: `eng_01`–`eng_04`
- Manager effectiveness: `mgr_01`–`mgr_04`
- Psychological safety: `psy_01`–`psy_04`
- Growth and development: `grw_01`–`grw_04`
- Workload sustainability: `wrk_01`–`wrk_04`
- Belonging: `blg_01`–`blg_04`
- Intent to stay: `its_01`–`its_02`

## Likert Response Generation

Observed item responses will be represented using a five-point agreement scale:

1. Strongly disagree
2. Disagree
3. Neither agree nor disagree
4. Agree
5. Strongly agree

Underlying continuous responses will be converted to the five-point ordinal response scale.

## Measurement Error

Measurement error will be incorporated into item generation so that observed responses are related to, but not perfectly determined by, the underlying latent construct.

This is intended to create realistic item-level variation and allow subsequent reliability and factor analyses to evaluate the proposed measurement structure.

## Missing Responses

A small amount of item-level missingness will be introduced into the synthetic survey responses.

The initial simulation assumption is approximately 3% missingness at the item level.

Missingness will be evaluated during the subsequent data-quality analysis rather than automatically treated as evidence of a particular real-world missing-data mechanism.

## Survey-Wave Differences

The two survey waves will be generated from related but not identical distributions.

The initial simulation will use small wave-to-wave changes rather than large shifts in employee experience.

This allows the analysis to evaluate whether observed changes are distinguishable from sampling variability without making the simulated waves artificially different.

## Interpretation

The parameters documented here define the synthetic data-generating process.

They should not be interpreted as:

- empirical estimates;
- validated population parameters;
- causal effects;
- evidence about employee behavior;
- evidence about real organizations.

The purpose of the simulation is to create a controlled environment for demonstrating survey analytics, measurement validation, organizational comparison, privacy-conscious reporting, and statistical modeling.

## Relationship to Analysis

The analytical workflow will not assume that the intended structure is automatically recovered.

The project will evaluate the generated data using:

- Item distributions
- Missing-data assessment
- Item-total relationships
- Reliability analysis
- Exploratory factor analysis
- Scale construction
- Group comparisons
- Intent-to-stay modeling

Where the simulated structure is not fully recovered, the analysis will report that result rather than treating the intended simulation parameters as confirmed findings.