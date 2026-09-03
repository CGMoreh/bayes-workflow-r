# Worked results sections, annotated

Three complete results sections, one per common design, matching the three methods sections in
`methods-templates.md`. Each is followed by a table saying which stage of the workflow every
sentence reports and where the evidence behind it lives. They are templates in the strict
sense: the bracketed slots are the only parts meant to change, and every sentence outside a
bracket is there because it does something the register requires – states the quantity on the
substantive scale, reads a check as the absence of a visible problem, joins a failed check to
the model that replaced it, or says beside a claim what would overturn it.

The register is the one described in `results-register.md`: the interpretive prose of the
workflow book's own case studies, written for a sociology journal. Numbers live in tables and
figures; the sentence beside a table gives the comparative and the reading, and where a number
does appear in prose it is a derived quantity a reader can picture, at a precision the
posterior supports. The habits to avoid while writing are in `prose-discipline.md`.

A results section in this register has four movements, in this order: the quantity the paper
is about, stated first with its uncertainty; the checks that licence it, read as what they
could and could not see; the model sequence that produced it, with the failures kept; and what
the analysis cannot settle, stated beside the claim rather than in a closing section.

---

## Template A: multilevel logistic model on a cross-sectional survey

> The predicted probability of [outcome] rises from [p_low] at [low value of the predictor]
> to [p_high] at [high value], averaging over the observed distribution of the other
> covariates within each posterior draw (Figure [n]; posterior median and 95% interval in
> Table [n]). That difference of [pp] percentage points is the quantity the argument depends
> on, and it is insensitive to power-scaling of the priors and sensitive to power-scaling of
> the likelihood, so the data rather than the prior specification are its source. The
> [k] region intercepts are partially pooled: the between-region standard deviation is
> [sd] on the log-odds scale, and the two regions with the fewest respondents, [names],
> are pulled [x] and [y] percentage points towards the overall rate from their raw
> proportions, which is the pooling doing what it is for rather than a defect. Posterior
> predictive checks on the proportion of [outcome] within each [group] show no visible
> discrepancy, and a leave-one-out check on the same proportions agrees, so the model
> reproduces the between-group structure it was built to describe; neither check can see
> misspecification within a group, and we do not claim it is absent. The coefficient on
> [contested predictor] is centred near [value] with an interval spanning [interval], and
> the likelihood sensitivity for it is low, so the data are weakly informative about it and
> we treat it as undetermined rather than as null. Two things the analysis cannot check:
> [unmeasured confounder] is not in the survey, and the [design feature] is not modelled,
> so the intervals are narrower than a design-based analysis would give.

| Sentence | Stage it reports | Evidence behind it |
|---|---|---|
| Predicted probabilities, averaged within draws | Estimand | `bayes-estimands-r`, `marginaleffects::avg_predictions()` |
| Insensitive to prior, sensitive to likelihood | Sensitivity of the estimand | `bw_sensitivity(fit, newdata = ...)` |
| Partial pooling, with the two smallest regions | Fit and its structure | `ranef()`, raw against fitted proportions |
| No visible discrepancy, and what the check cannot see | Predictive checks | `pp_check(type = "stat_grouped")`, `loo_pit_ecdf` |
| Undetermined rather than null | Reporting the posterior | `reference/sensitivity.md`, the weak-likelihood reading |
| Two things the analysis cannot check | Limits beside the claim | the workflow log |

```markdown
| Sentence                                          | Stage it reports          | Evidence behind it                                        |
|---------------------------------------------------|---------------------------|-----------------------------------------------------------|
| Predicted probabilities, averaged within draws     | Estimand                  | `bayes-estimands-r`, `marginaleffects::avg_predictions()` |
| Insensitive to prior, sensitive to likelihood      | Sensitivity of the estimand | `bw_sensitivity(fit, newdata = ...)`                    |
| Partial pooling, with the two smallest regions     | Fit and its structure     | `ranef()`, raw against fitted proportions                 |
| No visible discrepancy, and what the check cannot see | Predictive checks       | `pp_check(type = "stat_grouped")`, `loo_pit_ecdf`         |
| Undetermined rather than null                      | Reporting the posterior   | `reference/sensitivity.md`, the weak-likelihood reading   |
| Two things the analysis cannot check               | Limits beside the claim   | the workflow log                                          |

: Template A, sentence by stage.
```

The first sentence is the whole result, on the probability scale, before any diagnostic is
mentioned. The pooling sentence names the two regions the reader would otherwise suspect,
because a reviewer's first question about a multilevel model is what it did to the small
groups. The predictive-check sentence says what the check saw and, in the same sentence, what
it could not, which is how the case studies read every passed check.

---

## Template B: small sample, repeated measures

> Over the [k] days of [treatment or exposure], [outcome] rose by [slope] [units] per day on
> average, with a 95% interval of [lower, upper] (Figure [n]), and the rate differed
> between participants far more than that interval suggests: the between-participant
> standard deviation of the slope is [sd] [units] per day, so a participant one standard
> deviation above the mean rate deteriorates at roughly [slope + sd] per day and one below at
> roughly [slope − sd]. Both quantities come from the model with a participant-level slope;
> the model with only a participant-level intercept gives the same average with an interval
> [x]% as wide, which understates the uncertainty because it treats every participant as
> sharing one rate. A leave-one-out predictive check on the gaussian version showed [m]
> observations, all from [participants], falling outside their predictive intervals, which
> the Student-t version accommodates: cross-validation prefers it by [elpd_diff] in
> expected log predictive density (standard error [se_diff]), the Pareto k diagnostics are
> acceptable for both after refitting the [m] flagged folds, and the interval for the average
> slope widens from [w1] to [w2] under the heavier tail, which is the estimate we report.
> The reported slope moves by less than [x] [units] per day when the prior on it is
> power-scaled by a factor of two in either direction. With [n] participants the design
> recovers a between-participant standard deviation of the size estimated in [x]% of simulated
> replications and overstates it by a factor of [f] when it does, so the spread is the less
> secure of the two findings and we say so. The study does not record [what is missing], and
> the [k]-day window cannot separate a linear decline from one that levels off after day
> [d]; nothing here bears on either.

| Sentence | Stage it reports | Evidence behind it |
|---|---|---|
| Average slope and its interval, on the outcome scale | Estimand | `fixef()`, or `posterior_epred()` by day |
| Between-participant spread, translated into rates | Estimand, second quantity | `VarCorr()`, the `sd_` posterior |
| The intercept-only model and its narrower interval | Comparison judged on the estimand | `reference/comparison.md` |
| LOO check, outliers, Student-t, Pareto k after reloo | Predictive checks and comparison | `pp_check(type = "loo_intervals")`, `bw_loo_report()` |
| Moves by less than [x] under power-scaling | Sensitivity of the estimand | `bw_sensitivity(fit, newdata = ...)` |
| Recovery rate and inflation at n | Design calibration | `bw_recovery()` |
| What is missing, and what the window cannot separate | Limits beside the claim | the workflow log |

```markdown
| Sentence                                              | Stage it reports                    | Evidence behind it                                     |
|-------------------------------------------------------|-------------------------------------|--------------------------------------------------------|
| Average slope and its interval, on the outcome scale   | Estimand                            | `fixef()`, or `posterior_epred()` by day               |
| Between-participant spread, translated into rates      | Estimand, second quantity           | `VarCorr()`, the `sd_` posterior                       |
| The intercept-only model and its narrower interval     | Comparison judged on the estimand   | `reference/comparison.md`                              |
| LOO check, outliers, Student-t, Pareto k after reloo   | Predictive checks and comparison    | `pp_check(type = "loo_intervals")`, `bw_loo_report()`  |
| Moves by less than [x] under power-scaling             | Sensitivity of the estimand         | `bw_sensitivity(fit, newdata = ...)`                   |
| Recovery rate and inflation at n                       | Design calibration                  | `bw_recovery()`                                        |
| What is missing, and what the window cannot separate   | Limits beside the claim             | the workflow log                                       |

: Template B, sentence by stage.
```

Two quantities, both on the outcome scale, and the second is translated into what it means for
a participant one standard deviation from the mean, because a standard deviation of a slope is
not a number a reader can picture. The model comparison is reported through its effect on the
estimate – the interval widens – rather than as a verdict about the models. The calibration
sentence grades the two findings against each other and says which is less secure.

---

## Template C: overdispersed counts

> Under [treatment], the expected number of [events] per [unit-period] falls to [ratio] of its
> untreated level, with a 95% interval of [lower, upper], averaged over the observed
> distribution of [covariates] within each draw (Figure [n]). That average conceals the
> finding that matters for anyone deciding whether to [act]: the proportional reduction is
> [r_low] [interval] among [units] with the lowest [baseline] and [r_high] [interval] among
> those with the highest, where the interval spans one, so the treatment does most where there
> was least to begin with (Figure [n+1]). The model is a negative binomial with the treatment
> effect allowed to vary with [baseline]. The constant-effect negative binomial reproduces the
> marginal shape of the outcome and every conventional check on it, and misses the contrast
> the analysis is for: it puts the untreated arm's expected count at [fitted] against an
> observed [observed], and the interaction model at [fitted2]. The Poisson we began from
> under-predicted the dispersion and the frequency of high counts, and cross-validation put its
> effective number of parameters at [p_loo] against [k] actual ones, which reads as
> misspecification rather than flexibility. Cross-validation prefers the interaction model to
> the constant-effect one by [elpd_diff] in expected log predictive density (standard error
> [se_diff]); the pointwise differences are heavy-tailed and dropping the three most
> influential [units] moves the implied probability from [p1] to [p2], so we report the
> difference and its standard error and do not report the probability. Four models that
> cross-validation cannot separate give ratios between [r_min] and [r_max], and that range,
> rather than any one interval, is the uncertainty a reader should carry. The data carry no
> [cluster identifier], so [units] in the same [cluster] are treated as independent and the
> intervals are narrower than they should be; nothing in the file lets that be checked.

| Sentence | Stage it reports | Evidence behind it |
|---|---|---|
| The ratio, averaged within draws | Estimand | `bayes-estimands-r/reference/contrasts.md`, `posterior_epred()` under both assignments |
| Heterogeneity by baseline, with the interval spanning one | Estimand by subgroup | `posterior_epred()` by quintile of baseline |
| The constant-effect model misses the contrast | Predictive check on the estimand's own summary | `pp_check(type = "stat_grouped", stat = "mean", group = treatment)` |
| Poisson, p_loo against the parameter count | Model expansion, diagnosed | `bw_loo_report()`, effective parameters |
| elpd_diff, heavy tails, probability withdrawn | Comparison | `bw_loo_report()`, the leave-out probability check |
| The range across indistinguishable models | Sensitivity to model choice | `reference/comparison.md` |
| No cluster identifier | Limits beside the claim | the workflow log |

```markdown
| Sentence                                              | Stage it reports                              | Evidence behind it                                                    |
|-------------------------------------------------------|-----------------------------------------------|-----------------------------------------------------------------------|
| The ratio, averaged within draws                       | Estimand                                      | `bayes-estimands-r/reference/contrasts.md`, `posterior_epred()`       |
| Heterogeneity by baseline, interval spanning one       | Estimand by subgroup                          | `posterior_epred()` by quintile of baseline                           |
| The constant-effect model misses the contrast          | Predictive check on the estimand's own summary | `pp_check(type = "stat_grouped", stat = "mean", group = treatment)`  |
| Poisson, p_loo against the parameter count             | Model expansion, diagnosed                    | `bw_loo_report()`, effective parameters                               |
| elpd_diff, heavy tails, probability withdrawn          | Comparison                                    | `bw_loo_report()`, the leave-out probability check                    |
| The range across indistinguishable models              | Sensitivity to model choice                   | `reference/comparison.md`                                             |
| No cluster identifier                                  | Limits beside the claim                       | the workflow log                                                      |

: Template C, sentence by stage.
```

The second sentence is the one a reader of this template is most likely to delete, and it is
the one the case studies would keep: an average that conceals a gradient is reported with the
gradient. The comparison sentence performs the register's characteristic withdrawal – a
probability is computed, its sensitivity to three observations is measured, and it is then not
reported – and the sentence after it treats the spread across models as the uncertainty rather
than choosing one.

---

## Adapting a template

Change brackets, not sentences, until a sentence is false for your analysis; then replace it
with one that is true at the same level of specificity. The sentences that carry the register
and should survive any adaptation are the first, which states the quantity before any
diagnostic; the one that reads a passed check as what it could and could not see; the one that
joins a failure to the model that replaced it; and the last, which puts the limit beside the
claim. A results section that has lost all four has left the register whatever else it keeps.

Numbers in these templates are slots because the register puts them in tables and figures and
lets the sentence carry the reading. Where a number does belong in the prose – the quantity
the paper is about, a ratio a reader can picture – give it at a precision the posterior
supports, which for most social-science estimands is two significant figures, and give a
posterior probability as a rounded bound rather than to three decimals. `scripts/br_check_numbers.R`
will then confirm that each one traces to the output behind it.
