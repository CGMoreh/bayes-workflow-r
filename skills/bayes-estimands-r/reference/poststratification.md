# Poststratification: from the sample you have to the population you mean

Poststratification reweights model-based predictions to the composition of a target population.
It is what makes an estimate from an unrepresentative sample say something about a population,
and it is the mechanism behind multilevel regression and poststratification.

The Bayesian version has one property that the classical version does not: because the
reweighting happens inside each posterior draw, the uncertainty comes out correctly without any
extra work. There is no variance formula to look up.

---

## The procedure

1. Fit a model predicting the outcome from the variables that define the cells.
2. Build a frame with one row per cell, carrying the population size of that cell.
3. Predict into the frame, keeping the draws rather than summarising.
4. Within each draw, average the cell predictions weighted by cell size.
5. Summarise the resulting distribution.

```r
library(brms)
library(tidybayes)
library(dplyr)

# 1. model: partial pooling over cells, so sparse cells borrow strength
fit <- brm(
  y ~ (1 | age_group) + (1 | education) + (1 | region) + sex,
  data = d, family = bernoulli(),
  prior = c(prior(normal(0, 1), class = "Intercept"),
            prior(normal(0, 1), class = "b"),
            prior(exponential(2), class = "sd")),
  seed = 20260826, backend = "cmdstanr",
  file = "model-data/m_mrp", file_refit = "on_change"
)

# 2. BUILD the poststratification frame: one row per cell, with its population
#    count. Census extracts usually arrive as person- or household-level counts;
#    aggregate them to the cells the model uses.
ps_frame <- census_counts |>
  count(age_group, education, region, sex, wt = n, name = "n_pop")

# where the model's factor levels must all be present even if a cell is empty,
# build the full cross and join the counts onto it
ps_frame <- expand_grid(
  age_group = levels(d$age_group), education = levels(d$education),
  region    = levels(d$region),    sex       = levels(d$sex)
) |>
  left_join(census_counts, by = c("age_group", "education", "region", "sex")) |>
  mutate(n_pop = coalesce(n_pop, 0))

# 3-5. predict into the cells, then average within draw, weighted by cell size
pop_estimate <- fit |>
  add_epred_draws(newdata = ps_frame, allow_new_levels = TRUE) |>
  group_by(.draw) |>
  summarise(estimate = weighted.mean(.epred, n_pop), .groups = "drop")

pop_estimate |>
  summarise(
    median = median(estimate),
    lower  = quantile(estimate, 0.055),
    upper  = quantile(estimate, 0.945)
  )
```

`allow_new_levels = TRUE` matters: the frame will usually contain cells that appear in the
population but not in the sample, and the model supplies predictions for them from the
group-level distribution.

One constraint on the construction itself: poststratification needs the JOINT cell counts,
and a census that publishes only the margins – age by itself, education by itself – does
not determine them. Where only margins exist, the joint table has to be estimated (raking to
the margins, or a synthetic joint from a larger survey), and that estimation is part of the
method to be reported, not plumbing to be hidden.

## What it fixes, and what it cannot

The procedure can be checked against ground truth, because California publishes academic
performance scores for its whole population of schools. Two runs, same recipe.

**Selection on a variable that is adjusted for.** Drawing a sample that oversamples schools
with high free-meal eligibility, a variable strongly related to the outcome, gives a sample
mean 68.09 points below the population mean of 664.80. Poststratifying on school type and
meal category returns 665.09, with an 89% interval of 657.75 to 672.26. The error falls from
68.09 to 0.29 and the interval covers the truth.

**Selection on something else.** The published two-stage cluster sample of the same
population has a mean 45.70 points above the truth, because whole school districts were
sampled and districts differ. Poststratifying on the same school type and size cells moves
that error from 45.70 to 45.49. It does essentially nothing.

Both results are the method working correctly. Poststratification removes bias that runs
through the cell variables and is blind to bias that does not. The second case is the more
common one in practice, and no amount of weighting will rescue it – the remedy there is to
model the level at which selection actually happened, which for a cluster sample means a
varying intercept for the cluster and a population frame that includes clusters.

The practical test before running any of this: can you tell a story in which being in the
sample depends on the cell variables? If not, expect the first decimal place to move and
nothing else.

## Subgroup estimates come free

Once the draws are in the frame, any subpopulation is a different weighted average of the same
draws. Nothing needs refitting.

```r
subgroup_estimates <- fit |>
  add_epred_draws(newdata = ps_frame, allow_new_levels = TRUE) |>
  group_by(.draw, region) |>
  summarise(estimate = weighted.mean(.epred, n_pop), .groups = "drop_last") |>
  group_by(region) |>
  summarise(
    median = median(estimate),
    lower  = quantile(estimate, 0.055),
    upper  = quantile(estimate, 0.945)
  )
```

This is where the approach earns its cost. Small-area estimates that no direct calculation could
support come out of the same fit, with intervals that widen appropriately where the sample is
thin.

## Which variables belong in the cells

Not every predictor of the outcome. The variables that need to be in the poststratification are
those related both to the outcome *and* to the probability of being in the sample, whether
through the sampling design or through non-response. A strong predictor of the outcome that is
unrelated to selection does not need to be adjusted for, and adding it enlarges the frame for
nothing.

The practical constraint is usually the other way round: you can only poststratify on variables
for which population counts exist. Where a selection-related variable has no population margin,
say so as a limitation rather than quietly dropping the issue.

## Partial pooling is what makes the sparse cells work

A cell containing four respondents produces a hopeless direct estimate. Modelling the cell
effects as drawn from a common distribution shrinks those estimates toward the overall mean by
an amount the data determine, which is why the multilevel part of multilevel regression and
poststratification is not optional.

The cost is dependence on the model. Shrinkage is an assumption about how cells relate to one
another, and if that assumption is wrong the small-cell estimates are wrong in a way the
intervals will not reveal. Two mitigations, both worth reporting:

- Posterior predictive checks by cell, particularly for cells that were not used in fitting.
- Comparison against a simpler estimate where the sample supports one, for instance direct
  estimates in the largest cells. Agreement there is weak evidence, but disagreement is strong
  evidence of a problem.

## Effects, not just levels

Everything above estimates a population *level*. For a population average treatment effect, the
same frame is used but the prediction is a contrast rather than a level:

```r
library(marginaleffects)

avg_comparisons(
  fit, variables = "treatment",
  newdata = ps_frame, wts = "n_pop",
  allow_new_levels = TRUE          # the frame carries cells the sample never saw
)
```

The `wts` argument weights the averaging by cell size, which is what makes it a population
quantity rather than a cell-average quantity. Omitting it silently gives every cell equal
weight, which is a different estimand and rarely the one intended.

## Reporting

State the target population explicitly, name the variables poststratified on, name their source,
and say which selection-related variables you could not adjust for. "Estimates are
poststratified to the 2021 Census population by age group, education, region and sex" is a
sentence a reader can evaluate. "Weighted estimates are reported" is not.

---

Source: Gelman, Vehtari, McElreath et al., *Bayesian Workflow* (CRC Press, 2026), chapter 7
section 1. The R implementation here is original.
