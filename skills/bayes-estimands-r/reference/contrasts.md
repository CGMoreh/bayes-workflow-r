# Contrasts from a brms fit: the marginaleffects cookbook

Everything on this page turns posterior draws into a quantity a reader can evaluate: a
probability difference, a risk ratio, an expected-count change, a difference between
subgroup effects. The engine is `marginaleffects`, which understands `brmsfit` objects
natively and does its averaging inside each draw, so every number arrives with a correct
posterior interval and nothing has to be derived by hand.

Three functions cover nearly everything, and choosing between them is choosing the estimand:

| Function | Question it answers |
|---|---|
| `avg_predictions()` | What level does the outcome take, on average, here? |
| `avg_comparisons()` | How much does the outcome change when a variable changes? |
| `avg_slopes()` | What is the instantaneous rate of change? (continuous exposures) |

`avg_comparisons()` is the workhorse for anything treatment-shaped. `avg_slopes()` is its
derivative-based sibling and inherits everything below.

---

## 1. Two arguments decide what the number means, so set them deliberately

**`re_formula`** controls what happens to group-level effects, and the default is not the
population-level answer.

```r
avg_comparisons(fit, variables = "sex")                    # re_formula = NULL: keeps each
                                                           # unit's own group effects
avg_comparisons(fit, variables = "sex", re_formula = NA)   # population level: group
                                                           # effects set to zero
```

With `NULL` the contrast is averaged over the sample *including* each respondent's region
effect, which answers "what changes for these people, in their regions". With `NA` it
answers "what changes at the population level, for a region at the average". Papers usually
want the second; small-area work wants the first. The two can differ noticeably in
non-linear models, because group effects move units along a curved response scale. Say
which one you report.

**`type`** controls the scale. For a logistic model, `type = "response"` (the default for
`avg_comparisons` on a brmsfit) gives probability differences; `type = "link"` gives
log-odds differences, which are the coefficients' scale and almost never what a reader
wants. Report response-scale quantities and keep the link scale for internal checks.

## 2. The contrast itself: `variables`

```r
avg_comparisons(fit, variables = "treat")                       # 1 vs 0, or factor steps
avg_comparisons(fit, variables = list(age_z = 1))               # a one-unit change
avg_comparisons(fit, variables = list(age_z = "sd"))            # a one-SD change
avg_comparisons(fit, variables = list(age_z = "iqr"))           # 25th to 75th percentile
avg_comparisons(fit, variables = list(income = c(20, 60)))      # between two named values
avg_comparisons(fit, variables = list(educ = "pairwise"))       # all level pairs of a factor
```

The IQR form is often the most defensible for a skewed continuous exposure: "moving from
the 25th to the 75th percentile of income" is a change that actually occurs in the data,
where "a one-unit change" may not be.

## 3. Differences and ratios are different estimands

```r
avg_comparisons(fit, variables = "treat")                       # difference: p1 - p0
avg_comparisons(fit, variables = "treat", comparison = "ratio") # risk ratio: p1 / p0
```

For a rare outcome the ratio can be large while the difference is negligible, and the
reverse for a common one, so the choice is substantive rather than cosmetic. Report the
difference when the policy question is about absolute numbers of people; report the ratio
when comparing across outcomes with different base rates; never let the software's default
make the choice silently. Odds ratios – `exp()` of the link-scale contrast – are what the
coefficients give you, but risk differences and risk ratios are what readers can evaluate,
and with a fitted model there is no reason to settle for the odds ratio.

## 4. Effects within subgroups, and differences between them

```r
# the effect within each subgroup
avg_comparisons(fit, variables = "treat", by = "race")

# is the effect DIFFERENT between subgroups? A contrast of contrasts:
avg_comparisons(fit, variables = "treat", by = "race", hypothesis = ~ pairwise)

# or one named difference, by row position in the by-table
avg_comparisons(fit, variables = "treat", by = "race", hypothesis = "b2 - b1 = 0")
```

The second call is the answer to "does the effect differ by group", and it is not the same
question as "is the effect credible in one group and not the other". Two subgroup intervals,
one excluding zero and one not, do not establish a difference between the groups; the
pairwise contrast is the quantity that does, with its own interval. This is the
interaction-fallacy guard, and having it as one argument removes the last excuse for the
fallacy.

## 5. Levels, not only changes

```r
avg_predictions(fit, by = "education", re_formula = NA)      # P(outcome) per group
avg_predictions(fit, newdata = datagrid(age_z = c(-1, 0, 1)),
                re_formula = NA)                             # at set covariate values
```

A results section usually reads best with both: the levels ("entry rises from 0.22 to
0.38") and the contrast ("a difference of 16 percentage points, 89% interval …"). The
levels give the reader the base rate that makes the contrast interpretable.

## 6. Weights make it a population quantity

Averaging over the sample as observed answers a sample question. To answer a population
question, average over a poststratification frame with cell weights:

```r
avg_comparisons(fit, variables = "treat",
                newdata = ps_frame, wts = "n_pop", allow_new_levels = TRUE)
```

Omitting `wts` weights every row of `newdata` equally, which is a different estimand and
rarely the intended one. See `reference/poststratification.md` for building the frame.

## 7. Getting the draws out

Every function above returns a summary; the full posterior of the quantity is one call
away, and from there the tidybayes and ggdist toolchain applies:

```r
library(ggdist)

avg_comparisons(fit, variables = "treat", re_formula = NA) |>
  get_draws() |>
  ggplot(aes(x = draw)) +
  stat_halfeye(.width = c(0.66, 0.89)) +
  labs(x = "Average treatment effect (probability scale)", y = NULL)
```

`get_draws()` is also the bridge to everything else in this plugin that consumes draws:
power-scaling the estimand (`bayes-workflow-r/reference/sensitivity.md`), probability of
direction, and comparisons of magnitudes between two estimands computed within the same
draws.

## 8. The checks that go with a reported contrast

A contrast is a derived quantity of the model, so it inherits the model's obligations. The
three that bite in practice:

- **Its prior.** The implied prior on the contrast can be checked exactly as the implied
  prior on R² is: compute the contrast on a `sample_prior = "only"` fit and look at what
  the priors claim before the data speak.
- **Its sensitivity.** Power-scale the contrast, not the coefficients, when answering the
  priors-drove-it objection – the route is `predictions_as_draws()`, documented in the
  workflow skill.
- **Its positivity.** A contrast averaged over covariate values the data barely contain is
  extrapolation wearing an interval. Check the overlap before averaging over a frame very
  unlike the sample, and say so when the target population sits partly outside the
  sample's support.

---

Verified against marginaleffects 0.32.0 and brms 2.23.0; every call on this page was run
against fitted models before being written down. The estimand framing follows Gelman,
Vehtari, McElreath et al., *Bayesian Workflow* (CRC Press, 2026), chapter 7.
