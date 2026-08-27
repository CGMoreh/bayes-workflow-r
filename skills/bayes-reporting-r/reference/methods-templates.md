# Worked methods sections, annotated

Three complete methods sections, one per common design, each followed by a table saying
which workflow stage every sentence reports and where the supporting evidence lives. They
are templates in the strict sense: the bracketed slots are the only parts meant to change,
and every sentence outside a bracket is there because it answers an objection a reviewer
actually raises.

The register is a sociology journal. Terms a methods reviewer in the discipline knows –
partial pooling, posterior, credible interval, marginal effect – are used plainly; terms
that need one-time definitions get them in the template where they first appear.

---

## Template A: multilevel logistic model on a cross-sectional survey

> We model [outcome] with a Bayesian logistic regression fitted in brms [CITE brms], with
> population-level terms for [predictors] and a varying intercept for [grouping], so that
> [group]-level baselines are partially pooled towards their common mean rather than
> estimated separately in each of the [J] groups. The estimation sample is [N] respondents.
> The estimates below are the product of an iterative workflow of prior checking, fitting,
> computational diagnosis and model checking [CITE workflow], rather than of a single
> regression, and we report each stage at the point where it bears on a claim.
>
> Priors were set on the logit scale and checked before the outcome was used: [prior spec]
> on standardised slopes and [prior spec] on the intercept. Simulating from these priors
> alone implies outcome rates between [q05] and [q95], with [x]% of prior mass on rates
> below 0.02 or above 0.98, so the priors stabilise estimation in sparse cells without
> asserting a near-certain outcome in either direction. The [grouping]-level standard
> deviation received a [prior spec] prior, which bounds between-group spread away from
> implausibly large values while leaving the observed spread well inside its support.
>
> We ran [k] chains of [n] iterations with the [backend] backend. All R-hat values were
> below 1.01, bulk and tail effective sample sizes exceeded [min ESS] for every reported
> parameter, and no transitions diverged. A posterior predictive check on the
> [group]-level outcome rates showed the fitted model reproducing the observed
> between-group spread; the check on [feature] initially failed under a model without
> [term], which is why [term] is in the specification reported here.
>
> We report average marginal effects on the probability scale rather than log-odds
> coefficients, computed by averaging each contrast within every posterior draw over the
> sample's covariate distribution. Because posterior conclusions could in principle depend
> on the priors, we ran a power-scaling sensitivity analysis [CITE priorsense], which
> perturbs the prior and the likelihood and measures how far the posterior moves: the
> reported marginal effect of [key predictor] is insensitive to perturbation of the prior
> and sensitive to perturbation of the likelihood, indicating an estimate driven by the
> data rather than by the prior specification. Intervals are [width]% highest-density
> posterior intervals throughout.

| Sentence | Stage it reports | Evidence behind it |
|---|---|---|
| Model, terms, partial pooling, J and N | Specification | the model object |
| "product of an iterative workflow" | Framing | the workflow log |
| Priors with implied outcome rates | Prior predictive check | `bw_prior_check()` output |
| Group-level SD prior sentence | Priors on variance components | `reference/priors.md` argument |
| R-hat, ESS, divergences with values | Computational diagnosis | `bw_diagnose()` output |
| PPC that failed and changed the model | Posterior predictive check | the log entry for that model |
| Marginal effects on the probability scale | Estimand | `bayes-estimands-r` |
| Power-scaling sentence | Sensitivity | `bw_sensitivity()` with the AME predict-function wrapper in `reviewer-responses.md` |
| Interval-width declaration | Reporting convention | – |

The load-bearing habits: diagnostics appear as values, never as verdicts; the one check
that changed the model is named in the text, because it is the justification for the
specification; and the sensitivity sentence names its method and states its conclusion in
a clause of its own.

---

## Template B: small sample, repeated measures

> Our panel comprises [N] participants observed at [T] occasions ([N x T] observations).
> We model [outcome] with a Bayesian multilevel regression with varying intercepts and
> [where used] varying slopes by participant, separating within-person change from
> between-person differences: each time-varying predictor enters as a person mean and a
> within-person deviation from it, so that the coefficient on the deviation is a
> within-person comparison and cannot be confounded by stable differences between
> participants.
>
> At this sample size the analytical choices carry real weight, so we treat the analysis
> explicitly as a workflow [CITE workflow] and report its checks in the main text. Priors
> were [prior spec] on standardised slopes and [prior spec] on the participant-level
> standard deviations; simulating from the priors alone implies outcomes spanning [range],
> and the implied share of variance explained covers [q05] to [q95], wide enough to let the
> data decide. Computation passed its gates ([diagnostics with values]).
>
> Because an interval excluding zero says little by itself when [N] is small, we calibrated
> the design by simulation before interpreting the estimates: generating data at our exact
> sample size and structure with an effect of [size], the size this literature reports, and
> refitting [S] times, the design recovers the effect in [x]% of runs with [y]% interval
> coverage and a sign-error rate of [z]%; estimates that cleared the threshold overstated
> the true effect by a factor of [m] on average. We therefore report magnitudes with that
> calibration alongside them, and we treat the estimate's direction as better supported
> than its size. The reported within-person effect is insensitive to power-scaling of the
> prior [CITE priorsense], which addresses the concern that priors rather than data drive
> results at this sample size.

| Sentence | Stage it reports | Evidence behind it |
|---|---|---|
| Person-mean and deviation decomposition | Specification | `reference/fitting.md` |
| "treat the analysis explicitly as a workflow" | Framing | the workflow log |
| Priors with implied variance-explained interval | Prior predictive check | `bw_prior_check()` |
| Diagnostics with values | Computational diagnosis | `bw_diagnose()` |
| Recovery, coverage, sign error, exaggeration | Design calibration | `bw_recovery()` |
| "direction better supported than size" | Interpretation discipline | the calibration output |
| Power-scaling sentence | Sensitivity | `bw_sensitivity()` |

The design-calibration sentence is the paragraph's centre of gravity. It converts "small
sample, interpret cautiously" from a ritual disclaimer into four numbers, and it answers a
question most small-N papers never ask: what could this design have detected at all?

---

## Template C: overdispersed counts

> The outcome is a count of [events] per [unit-period], modelled with a negative binomial
> regression with a varying intercept for [unit]. We began from a Poisson specification;
> its posterior predictive distribution reproduced the mean structure but under-predicted
> the dispersion and the frequency of high-count [units], and leave-one-out cross-validation
> preferred the negative binomial by [elpd_diff] in expected log predictive density
> (standard error [se_diff]). That difference is concentrated: [k] of [n] observations
> contribute [x]% of the total disagreement between the models, all of them [description of
> those cases], so the negative binomial's advantage lies in describing [that tail] rather
> than in a uniform improvement, and we say so rather than reporting the comparison as a
> global verdict. Priors, diagnostics and sensitivity follow the same protocol as
> [cross-reference or repeat the Template A sentences], and we report incidence-rate
> contrasts on the count scale, averaged within posterior draws over the observed covariate
> distribution.

| Sentence | Stage it reports | Evidence behind it |
|---|---|---|
| Poisson to negative binomial, with the failed check | Model expansion | the workflow log |
| elpd_diff against its standard error | Comparison | `bw_loo_report()` |
| Concentration of the disagreement | Pointwise attribution | `bw_loo_report()` |
| "rather than a global verdict" | Interpretation discipline | `reference/comparison.md` |
| Incidence-rate contrasts | Estimand | `bayes-estimands-r/reference/contrasts.md` |

This template exists because the sequence Poisson-fails-then-negative-binomial is the most
common model expansion in applied count work, and papers usually report only its endpoint.
Reporting the failed check and the concentration turns a bare model choice into an
argument.

---

## Adapting a template

Change brackets, not sentences, until a sentence is false for your analysis – then replace
it with one that is true, at the same level of specificity. The failure mode to avoid is
deleting a sentence because its check was not run: the template is also a checklist, and a
sentence you cannot fill is a stage you have skipped. The one legitimate deletion is design
calibration when adapting Template B to a large sample, where it answers a question nobody
is asking.
