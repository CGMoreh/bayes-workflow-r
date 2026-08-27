# Posterior predictive checking, and interrogating the joint posterior

A posterior predictive check simulates data from the fitted model and compares the simulations
with what was observed. Its value depends entirely on choosing a summary that *could* fail. A
check on the mean of a model with an intercept will always pass, and passing tells you nothing.

---

## Checks that can fail

```r
pp_check(fit, ndraws = 100)                                  # overall distribution
pp_check(fit, type = "bars", ndraws = 100)                   # discrete or binary outcomes
pp_check(fit, type = "stat", stat = "sd")                    # dispersion
pp_check(fit, type = "stat_2d", stat = c("mean", "sd"))
pp_check(fit, type = "stat_grouped", stat = "mean", group = "region")
pp_check(fit, type = "intervals", x = "time")                # fit across a predictor
```

### A check can pass on a model that is badly wrong

Worth seeing before choosing any of them. Fitting seizure counts with a Poisson model and a
varying intercept per patient, then checking the predicted standard deviation against the
observed one, gives an observed value of 12.35 against a predictive median of 11.65 with an
interval of 10.42 to 12.99. The posterior probability of a replicate at least as dispersed
as the data is 0.139 – not a pass anyone would celebrate, but not a failure either.

The same model loses to a negative binomial by 55.1 in expected log predictive density.

The marginal check cannot see the problem because the varying intercepts absorb the
dispersion at the patient level: each patient gets their own rate, so the pooled spread comes
out about right while the within-patient predictions are badly calibrated. The check that
does see it is either cross-validated, or a check on dispersion *within* patients rather than
across the whole sample.

The lesson is not that dispersion checks are useless. It is that a summary has to be able to
fail before its passing means anything, and a summary computed over a grouping the model
already absorbs usually cannot.

### Three families of summary worth the effort

- **Features the model does not explicitly fit.** Dispersion, skew, the proportion of zeros,
  the maximum. These are where misfit shows.
- **Groupings the model does not include.** If the model has no term for region and the
  region-level means fall outside their predictive intervals, that is the model asking for a
  region term. This is the single most productive check in applied work.
- **Whatever the substantive claim depends on.** If the paper is about between-group variation,
  check the between-group variance.

## A failed check names the next model

The point of the exercise is not reassurance. Read each failure as a specification:

| What fails | What the model is missing |
|---|---|
| Dispersion is under-predicted for counts | Overdispersion: negative binomial rather than Poisson, or an observation-level term |
| Too few zeros predicted | A zero-inflation or hurdle component |
| Group means outside their intervals | A varying intercept for that grouping |
| Tails under-predicted | A heavier-tailed family: student_t rather than gaussian |
| Fit degrades across a predictor | Non-linearity: a spline or polynomial in that predictor |
| Bimodality in the observed data, unimodal predictions | An unmodelled subgroup, or a mixture |

Record the failure and the response in the workflow log. The sequence of models, each motivated
by the check that failed on the previous one, is the actual argument of the methods section.

## Interrogating the joint posterior

Marginal checks pass on models whose joint behaviour is nonsense. The move that catches this is
to condition on something and ask what else the model then implies, particularly in the tails
where little of the probability mass lives and nobody looks.

The general procedure: take the predictive draws, condition on an event of interest, and
examine the conditional distribution of some other quantity. If the implied conditional
relationship contradicts what you know about the world, the model has a problem that no
marginal check would have revealed.

```r
library(posterior)

yrep <- posterior_predict(fit)             # draws x cases

# implied correlation structure between two cases or units
cor(yrep[, unit_a], yrep[, unit_b])

# conditional behaviour: given an unusual outcome for unit A, what does the model say about B?
unusual <- yrep[, unit_a] > quantile(yrep[, unit_a], 0.95)
mean(yrep[unusual, unit_b] > threshold)
mean(yrep[, unit_b] > threshold)           # compare with the unconditional rate
```

Two questions to ask of the answer. Does the sign of the implied dependence make sense? And is
the dependence of a plausible magnitude, or does the model treat units as more independent than
they could possibly be? Models built from independent error terms often imply near-zero
correlation between units that any substantive account says should move together, and this
shows up only when you go looking in the tails.

For a multilevel model the equivalent check is on the implied intraclass correlation and on
whether the model's group-level predictions are as variable as the observed groups.

## Cross-validated checks

An in-sample posterior predictive check is optimistic, because the observation being checked
helped fit the model. The leave-one-out version removes that:

```r
library(bayesplot)

loo1 <- loo(fit, save_psis = TRUE)
psis <- loo1$psis_object

ppc_loo_pit_overlay(y = d$outcome, yrep = posterior_predict(fit), lw = weights(psis))
```

The LOO probability integral transform values should be approximately uniform. Systematic
departure from uniformity indicates miscalibration: a U shape means the predictive distribution
is too narrow, an inverted U that it is too wide.

For binary outcomes, calibration is better read from a reliability diagram than from a PIT plot:
bin the predicted probabilities and check that the observed frequency in each bin matches.

## What to report

Put the checks that changed the model in the main text, at the point where the model choice is
justified, and the rest in a supplementary appendix. A check that changed nothing is still worth
reporting if a reader would otherwise wonder whether it was run, but it belongs in the appendix.

---

Source: Gelman, Vehtari, McElreath et al., *Bayesian Workflow* (CRC Press, 2026), chapter 8
sections 1 to 3, and the case study on posterior predictive checking. See
`reference/book-map.md`.
