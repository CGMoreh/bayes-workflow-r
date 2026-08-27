# Choosing the family: matching the model to how the outcome was generated

`fitting.md` states the principle – match the family to the generating process, not to how
the data look – and this file is the casebook. Each entry names the outcome type, the brms
call, the specific way the obvious simpler choice fails, and the check that would catch the
failure. Read the entry for your outcome, not the file.

Throughout: a family choice is a modelling claim, so it is testable, and the posterior
predictive check is where it is tested. The recurring pattern is that the wrong family
passes checks on the features it models and fails on the ones it cannot express, so the
check must target the feature at risk.

---

## Counts

```r
family = poisson()                     # variance equals the mean, by assumption
family = negbinomial()                 # variance = mu + mu^2/shape; shape is estimated
```

Start Poisson only as a deliberate first rung: real counts are almost always overdispersed,
and the Poisson absorbs the excess into spuriously tight intervals. The check that catches
it is dispersion – `pp_check(fit, type = "stat", stat = "sd")` – with the caveat documented
in `predictive-checks.md`: varying intercepts can absorb the overdispersion at the group
level and let the marginal check pass, so compare by LOO as well.

**Exposure.** Counts collected over unequal windows or populations need an offset,
`y ~ x + offset(log(exposure))`, so the model describes rates. Omitting it turns
differences in observation time into fake differences in incidence.

**Many zeros** are two different problems, and the choice between the fixes is
substantive, not statistical:

```r
family = hurdle_poisson()              # zeros come from a separate process entirely
family = zero_inflated_negbinomial()   # SOME zeros are structural, the rest are ordinary
```

A hurdle says every zero is a "never" – non-smokers smoke zero cigarettes. Zero inflation
says zeros are a mixture – some respondents could never experience the event, others could
and did not this period. Both accept their own formula for the extra component
(`bf(y ~ x, hu ~ z)` or `bf(y ~ x, zi ~ z)`), which turns "who are the structural zeros"
into an estimated equation rather than an assumption. The check: `pp_check(type = "bars")`
on the low counts, and a posterior predictive on the zero proportion specifically.

## Ordered categories

```r
family = cumulative("logit")           # the default ordinal model
family = acat()                        # adjacent categories, when steps are the estimand
```

The temptation is to treat a 5-point agreement scale as metric. The cumulative model
declines the assumption the metric treatment imposes – equal spacing between categories –
and estimates the thresholds instead. Where predictors plausibly act differently on
different transitions ("strongly disagree" against "disagree" responding to different
things), free that predictor with `cs()` under `acat()` or `sratio()`: `y ~ x + cs(z)` gives
`z` one coefficient per transition, and comparing against the constrained model by LOO tests
the parallel-effects assumption instead of asserting it. Under `cumulative()` brms flags
`cs()` as experimental, because category-specific effects can make the thresholds cross and
imply negative category probabilities; use one of the other two ordinal families for this
check.

The check that condemns the metric treatment: fit both and compare predicted category
frequencies – `pp_check(type = "bars")` on the ordinal fit, and for the metric fit round its
continuous draws first (bayesplot's bars check refuses a continuous `yrep`) or use a density
overlay. The metric model routinely predicts mass outside the scale and misplaces the modal
category.

## Bounded proportions

```r
family = Beta()                        # strictly inside (0, 1)
family = zero_one_inflated_beta()      # with observations AT 0 and/or 1
```

Shares, rates and sliders with responses piled at the endpoints are the canonical case: a
gaussian on the logit of the share must either drop or fudge the exact 0s and 1s, and both
moves change the estimand. The zero-one-inflated beta models the boundary mass as its own
process. For ordered-categorical readings of slider data there is also the ordered beta
model (Kubinec 2023), available through the `ordbetareg` package built on brms, which
treats the endpoints as the extreme categories of an ordered response; prefer it when the
endpoints are meaningfully "none" and "all" rather than censoring.

## Heavy tails and skew

```r
family = student()                     # gaussian with tail-thickness nu estimated
family = lognormal()                   # positive, multiplicative errors
family = Gamma(link = "log")           # positive, variance grows with the mean
```

`student()` is the cheap robustness move: it downweights outliers by letting `nu` be
small, and if the data are actually near-gaussian the posterior for `nu` says so. The trap
is documented in `priors.md` section 6 – the prior on `sigma` does not mean the same thing
after the switch, because the t's variance is `nu/(nu-2)` times `sigma^2`.

For durations, incomes and expenditures, lognormal and Gamma differ mainly in their
variance structure; fit both and let LOO and the tail-focused predictive check
(`stat = "max"`, `stat = function(y) quantile(y, .99)`) arbitrate. Reporting then happens
on the original scale via `avg_comparisons(..., type = "response")`, not by
back-transforming coefficients.

## Censoring, truncation, weights

Three response-side annotations that change the likelihood, not the family:

```r
bf(y | cens(cen_ind) ~ x)        # censored: top-coded income, right-censored durations
bf(y | trunc(lb = 0) ~ x)        # truncated: values outside the bounds cannot be observed
bf(y | weights(w) ~ x)           # weighted likelihood contributions
```

Censoring and truncation are different claims: a censored value exists but is recorded at
the bound; a truncated value never enters the sample. Top-coded income is censored;
a sample that only includes firms above a size threshold is truncated. Modelling one as
the other biases the scale parameters.

On `weights()`: it multiplies log-likelihood contributions, which reproduces
design-weighted point estimates but does not deliver design-based uncertainty, and it
interacts awkwardly with LOO (the pointwise contributions are reweighted too). For survey
representation, the model-based route in `bayes-estimands-r/reference/poststratification.md`
– model the selection variables, poststratify the draws – is the coherent Bayesian
treatment; reserve `weights()` for frequency weights, where a row genuinely stands for w
identical observations.

## When one linear predictor is not enough

```r
bf(y ~ x + (1 | g), sigma ~ x)         # the SPREAD depends on x too
```

Distributional models give model parameters beyond the mean their own formulas. The
canonical use is heteroscedasticity as a finding rather than a nuisance – inequality
research where the dispersion of outcomes, not their level, is the estimand. Two cautions:
`sigma` gets a log link by default, so its coefficients are multiplicative; and the prior
predictive check becomes doubly important, because priors on the sigma-equation compound
with priors on the mean-equation in what they imply about the outcome's range.

---

Everything above was checked to construct against brms 2.23.0. Source for the
principle: Gelman, Vehtari, McElreath et al., *Bayesian Workflow* (CRC Press, 2026),
chapters 5 and 8; the ordinal argument follows Liddell and Kruschke (2018); ordered beta is
Kubinec (2023).
