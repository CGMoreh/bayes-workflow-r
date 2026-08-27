# Fitting: the decisions, not the syntax

brms formula syntax is documented thoroughly in `?brmsformula` and in the package vignettes, and
repeating it here would add nothing. This file covers the decisions that the documentation does
not make for you, and that change what the model means.

---

## Standardise, and know what it costs

Centring and scaling continuous predictors decorrelates the posterior, makes a prior such as
`normal(0, 0.5)` interpretable as "a one standard deviation change moves the outcome by at most
about one", and usually resolves treedepth warnings. It is the cheapest intervention available.

The cost is interpretability of the coefficients, which now speak in standard deviations of a
particular sample. Two consequences worth planning for. Coefficients are no longer comparable
across samples with different spreads, which matters if the paper compares countries or waves.
And any predicted quantity has to be transformed back before it is reported, which is a reason
to report marginal effects on the response scale rather than coefficients.

Scale by one standard deviation, not two, unless you have a specific reason: the two-SD
convention exists to make continuous and binary predictors comparable, and if you are not making
that comparison it just adds a factor to explain.

Never standardise the outcome in a model where the outcome scale carries meaning, and never
standardise a binary or count outcome at all.

## Repeated measures: separate the two effects you have conflated

With several observations per person, a predictor that varies within person carries two
different pieces of information, and a single coefficient averages them into something that
answers no question. People who are more X than other people may differ in the outcome for
reasons that have nothing to do with what happens when a given person becomes more X than usual.

Split them explicitly:

```r
library(dplyr)

d_model <- d |>
  mutate(
    x_person = mean(x, na.rm = TRUE),           # the person's own level, a between-person trait
    x_dev    = x - x_person,                    # departure from it, a within-person change
    .by = participant_id
  ) |>
  mutate(across(c(x_person, x_dev), \(v) as.numeric(scale(v)), .names = "{.col}_z"))

fit <- brm(
  y ~ x_person_z + x_dev_z + (1 | participant_id),
  data = d_model, family = gaussian(), prior = priors,
  seed = 20260826, backend = "cmdstanr",
  file = "model-data/m_within", file_refit = "on_change"
)
```

`b_x_person_z` is now a between-person comparison and `b_x_dev_z` a within-person one, and the
paper can say which it is claiming. Whether they differ is itself a substantive finding, and it
is a straightforward posterior computation:

```r
library(tidybayes)
fit |>
  spread_draws(b_x_person_z, b_x_dev_z) |>
  summarise(prob_within_larger = mean(abs(b_x_dev_z) > abs(b_x_person_z)))
```

## Temporal order

A predictor and an outcome measured at the same occasion show co-occurrence. If the claim is
that one precedes the other, the predictor has to come from the earlier occasion:

```r
d_model <- d |>
  arrange(participant_id, time) |>
  mutate(x_dev_lag = lag(x_dev), .by = participant_id)
```

This costs one occasion per participant, which at small sample sizes is a real loss and worth
weighing against what the lag buys. Lagging does not establish causation; it removes one
specific alternative explanation, and the write-up should claim exactly that much.

## Varying slopes, and when to stop

A varying intercept says groups differ in level. A varying slope says the effect itself differs
between groups, which is usually a more interesting claim and always a more expensive one: it
adds a variance and a correlation to estimate. Fit the varying slope when the question is about
heterogeneity in the effect, and expect divergences if the number of groups is small.

The correlation between varying intercepts and slopes needs its own prior. `lkj(2)` mildly
favours weaker correlations and is a sensible default; `lkj(1)` is uniform over correlation
matrices, which in higher dimensions is not as uninformative as it sounds.

## Caching, seeds and reproducibility

```r
dir.create("model-data", showWarnings = FALSE)   # brms errors if the directory is absent

brm(..., seed = 20260826, file = "model-data/m3", file_refit = "on_change")
```

`file` caches both the compiled model and the draws, and `file_refit = "on_change"` refits only
when the formula, data or priors change. Keep fits in `model-data/` rather than in the output
directory, so that they are not confused with rendered artefacts and are easy to exclude from
version control.

Set the seed explicitly on every fit and every simulation. A Bayesian analysis whose numbers
move between runs cannot be checked by anyone, including you.

## Choosing the family

Match it to how the outcome was generated, not to how it looks. Bounded proportions with mass at
the boundaries want an ordered beta or zero-one-inflated beta rather than a gaussian on a
transformed scale. Ordinal responses want a cumulative model rather than a metric one, because
treating ordered categories as equally spaced numbers imposes an assumption the data can
contradict. Counts with more variance than the mean want negative binomial. Bounded outcomes
treated as gaussian will predict impossible values, and the posterior predictive check will show
you that if you ask it for the range.

---

Source: Gelman, Vehtari, McElreath et al., *Bayesian Workflow* (CRC Press, 2026), chapters 5 and
11. brms itself is due to Bürkner. See `reference/book-map.md`.
