# Worked methods sections, annotated

Three complete methods sections, one per common design, each followed by a table saying
which workflow stage every sentence reports and where the supporting evidence lives. They
are templates in the strict sense: the bracketed slots are the only parts meant to change,
and every sentence outside a bracket is there because it answers an objection that reviewers
actually raise.

The templates follow the rule under "Article sections" in SKILL.md. The methods say what was done and how each check was read, including the model sequence and the comparison that chose the final model, while the matching sections in `results-templates.md` say what the checks of the final model showed, and each number that the analysis produced appears in one of the two sections only. The annotation tables describe the templates and stay out of the write-up.

The register is a sociology journal. Terms a methods reviewer in the discipline knows –
partial pooling, posterior, credible interval, marginal effect – are used plainly; terms
that need one-time definitions get them in the template where they first appear.

---

## Template A: multilevel logistic model on a cross-sectional survey

> We model [outcome] with a Bayesian logistic regression fitted in brms [CITE brms], with population-level terms for [predictors] and a varying intercept for [grouping], so that [group]-level baselines are partially pooled towards their common mean rather than estimated separately in each of the [J] groups. The estimation sample is [N] respondents. The estimates below are the product of an iterative workflow of prior checking, fitting, computational diagnosis and model checking [CITE workflow], rather than of a single regression, and we report each stage at the point where it bears on a claim; [Appendix S1] records every model in the sequence.
>
> Priors were set on the logit scale and checked before the outcome was used: [prior spec] on standardised slopes and [prior spec] on the intercept. Simulating from these priors alone implies outcome rates between [q05] and [q95] (the 5th and 95th percentiles), with [mass_extreme]% of prior mass on rates below 0.02 or above 0.98, so the priors stabilise estimation in sparse cells without asserting a near-certain outcome in either direction. The [grouping]-level standard deviation received a [prior spec] prior, which bounds between-group spread away from implausibly large values while leaving the observed spread well inside its support. We ran [n_chains] chains of [n_iter] iterations with the [backend] backend. All R-hat values were below 1.01, bulk and tail effective sample sizes exceeded [min_ess] for every reported parameter, and no transitions diverged.
>
> A model without [term] failed a posterior predictive check on [feature]: the observed [statistic] was [obs_stat], outside its predictive interval of [pi_low] to [pi_high], and [term] is in the specification reported here for that reason. Leave-one-out cross-validation, which scores a model by how well it predicts each observation when that observation is left out of the fit, prefers the model with [term] by [elpd_diff] in expected log predictive density (standard error [se_diff]). The final model was checked on [a statistic that the [group] intercepts do not fit directly, such as the rate of [outcome] within cells defined by [covariate] in each [group]] and on the calibration of its predicted probabilities. We report average marginal effects on the probability scale rather than log-odds coefficients, computed by averaging each contrast within every posterior draw over the covariate distribution of the sample. Because posterior conclusions could depend on the priors, we power-scaled the reported marginal effect [CITE priorsense]. The method raises the prior, and separately the likelihood, to a power close to one and measures how far the posterior of the effect moves, and a sensitivity above 0.05, the default threshold of the method, marks the prior or the likelihood as shaping the estimate. As the method registers only small changes around the specified priors, we also refitted the model under [alternative prior]. Intervals are central [width]% posterior intervals throughout.

| Sentence | Stage it reports | Evidence behind it |
|---|---|---|
| Model, terms, partial pooling, J and N | Specification | the model object |
| "product of an iterative workflow", and the pointer to the appendix | Framing | the workflow log, the appendix |
| Priors with implied outcome rates | Prior predictive check | `bw_prior_check()` output |
| Group-level SD prior sentence | Priors on variance components | `bayes-workflow-r/reference/priors.md` argument |
| Chains, iterations, R-hat, ESS, divergences with values | Computational diagnosis | `bw_diagnose()` output |
| The failed check and the comparison that put [term] in the model | Model sequence | the log entry for that model, `bw_loo_report()` |
| The checks run on the final model | Posterior predictive checks, as procedure | the workflow log; what the checks showed goes in the results |
| Marginal effects on the probability scale | Estimand | `bayes-estimands-r` |
| Power-scaling and the refit, as procedure | Sensitivity | `bw_sensitivity()` with the AME predict-function wrapper in `reviewer-responses.md`; the result goes in the results |
| Interval declaration | Reporting convention | – |

The load-bearing habits: diagnostics appear as values, never as verdicts; the one check that changed the model is named in the text with its values, because it is the justification for the specification; and the sensitivity analysis is described by what was power-scaled and how its readings are interpreted, with the result left to the results section. Central intervals are declared because the marginal effects move every quantity from the logit to the probability scale, and a central interval stays central under that move, which a highest-density interval does not.

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
> At this sample size the analytical choices carry real weight, so we treat the analysis explicitly as a workflow [CITE workflow] and report its checks in the main text. Priors were [prior spec] on standardised slopes and [prior spec] on the participant-level standard deviations; simulating from the priors alone implies outcomes spanning [range_prior], and the implied share of variance explained covers [r2_q05] to [r2_q95], wide enough to let the data decide. Computation passed its gates ([diagnostics with values]).
>
> A model with participant-level intercepts only gives the same average slope with an interval [width_ratio]% as wide as that of the model with a participant-level slope, because it treats every participant as sharing one rate, so it understates the uncertainty of the average and we report the model with the slope. Under a gaussian likelihood, [n_out] observations fell outside their [width_pi]% leave-one-out predictive intervals, the intervals predicted for each observation by the model fitted without it, against about [n_expected] that a well-calibrated model leaves outside, so the count by itself says little. The failure lies in the distance: [n_far] of those observations, all from [participants], lie more than [distance] predictive standard deviations from the value predicted for each, and the same observations carry the largest pointwise differences in expected log predictive density, a measure of out-of-sample predictive accuracy, between the gaussian and Student-t versions. Cross-validation prefers the Student-t version by [elpd_diff] (standard error [se_diff]), and the Pareto k diagnostics, which check for each observation whether the leave-one-out approximation can be trusted, are acceptable for both versions once the [n_reloo] observations flagged by the diagnostics are refitted exactly. Under the heavier tail the interval for the average slope changes from [w_gauss] to [w_t] [units] per day, and the Student-t version is the one reported.
>
> Because an interval excluding zero says little by itself when [N] is small, we calibrated the design by simulation before interpreting the estimates. We generated data at our exact sample size and structure, with an average slope of [slope_assumed] and a between-participant standard deviation of [sd_assumed], values taken from [a source outside these data], and refitted the model [S] times with the same priors and [width]% intervals. For the average slope we count the runs in which the interval excludes zero, the runs in which it covers the assumed value and the runs that get the sign wrong, and among the runs whose interval excludes zero we compare the size of the estimate with the assumed value. A standard deviation is positive in every draw, so its interval excludes zero in every run, and for the between-participant standard deviation we count only the runs whose interval covers the assumed value and compare the posterior median with that value. The reported within-person effect was also power-scaled for sensitivity to the prior and to the likelihood [CITE priorsense], and the power-scaling addresses the concern that priors rather than data drive results at this sample size. The results section reports the findings of both analyses, each beside the estimate that it qualifies.

| Sentence | Stage it reports | Evidence behind it |
|---|---|---|
| Person-mean and deviation decomposition | Specification | `bayes-workflow-r/reference/fitting.md` |
| "treat the analysis explicitly as a workflow" | Framing | the workflow log |
| Priors with implied variance-explained interval | Prior predictive check | `bw_prior_check()` |
| Diagnostics with values | Computational diagnosis | `bw_diagnose()` |
| The intercept-only model and its narrower interval | Model sequence, judged on the estimand | `bayes-workflow-r/reference/comparison.md` |
| Outlying observations located by distance, Student-t, Pareto k after exact refits | Model sequence and comparison | `pp_check(type = "loo_intervals")`, `loo::E_loo()` for the predictive means and standard deviations, `bw_loo_report()` |
| How the design was simulated, and what each rate counts | Design calibration, as procedure | `bw_recovery(width = [width])`, one call per parameter; the rates go in the results |
| Power-scaling, as procedure | Sensitivity | `bw_sensitivity()`; the result goes in the results |

The calibration paragraph says how the design was simulated and what each rate counts, and the rates themselves go in the results, where the rates grade the claims. In `bw_recovery()` a run 'recovers' the effect when its interval excludes zero, the event that this skill tells the writer not to treat as a finding, so the template says what is counted rather than using the word, and for a standard deviation it counts only what the function can compute for one. The assumed values come from outside these data, because an estimate used as the truth carries its own exaggeration into the calibration: either a range of plausible values, with one run of the calibration for each, or a published estimate discounted for the selection that inflates published effects. The paragraph answers a question that most small-N papers never ask, which is what this design could have detected at all. The outlier sentence locates the failure by distance rather than by count, because a count of observations outside the intervals means something only beside the count that a well-calibrated model leaves there, about one in twenty for 95% intervals.

---

## Template C: overdispersed counts

> The outcome is a count of [events] per [unit-period], modelled with a negative binomial regression with a varying intercept for [unit] and the treatment effect allowed to vary with [baseline]. We began from a Poisson specification. Its posterior predictive distribution reproduced the mean structure but under-predicted the dispersion and the frequency of high-count [units], and leave-one-out cross-validation put its effective number of parameters at [p_loo_pois] against [k_pois] actual ones. An effective number far above the actual count indicates a misspecified model rather than a flexible one. A negative binomial with a constant treatment effect reproduces the marginal shape of the outcome but misses the contrast that the analysis is for: it puts the expected count in the untreated arm at [fitted_const] against an observed mean of [observed_arm], which is why the effect is allowed to vary with [baseline].
>
> Leave-one-out cross-validation prefers the interaction model to the constant-effect one by [elpd_diff] in expected log predictive density, a measure of out-of-sample predictive accuracy (standard error [se_diff]), once moment matching has brought the [n_high_k] observations with unreliable leave-one-out estimates below 0.7 on the Pareto k diagnostic, which checks for each observation whether the approximation holds. That difference is concentrated: [k_top] of [n_units] observations contribute [share_top]% of the total disagreement between the models, all of those observations [description of those cases], and dropping the three most influential moves the implied probability that the constant-effect model predicts worse from [p_full] to [p_drop]. We therefore report the difference and its standard error and not the probability, and we read the advantage of the interaction model as lying in [that tail] rather than in a uniform improvement. [n_models] further specifications, [list], cannot be separated from the interaction model by cross-validation, and the results report the estimate under each. Priors, diagnostics and the sensitivity analysis follow the same protocol as [cross-reference or repeat the Template A sentences]. The treatment effect is reported as [the average across [units] of the [unit]-level ratio of the expected count under treatment to the expected count without it / the ratio of the average expected counts], computed within each posterior draw over the observed covariate distribution.

| Sentence | Stage it reports | Evidence behind it |
|---|---|---|
| Poisson, p_loo against the parameter count | Model sequence, diagnosed | `bw_loo_report()`, effective parameters |
| The constant-effect model misses the contrast | Model sequence: a failed check on the summary of the estimand | `pp_check(type = "stat_grouped", stat = "mean", group = "[treatment]")` |
| elpd_diff against its standard error, after moment matching | Comparison | `bw_loo_report()` |
| Concentration of the disagreement, and the probability withdrawn | Pointwise attribution | `bw_loo_report()`, the leave-out probability check in `bayes-workflow-r/reference/comparison.md` |
| Specifications that cannot be separated | Comparison | `bw_loo_report()`; the estimates under each go in the results |
| The estimand named | Estimand | `bayes-estimands-r/reference/contrasts.md` |

This template exists because the sequence Poisson-fails-then-negative-binomial is the most
common model expansion in applied count work, and papers usually report only its endpoint.
Reporting the failed checks and the concentration turns a bare model choice into an
argument.

The last sentence names the estimand because the two ratios differ whenever the effect varies with [baseline]. The average of the [unit]-level ratios weights every [unit] equally, while the ratio of the average expected counts is dominated by the [units] with the highest counts. With marginaleffects 0.32.0, `avg_comparisons(fit, variables = "[treatment]", comparison = "ratio")` returns the ratio of the averages, and `comparison = function(hi, lo) mean(hi / lo)` returns the average of the ratios.

---

## Adapting a template

Change brackets, not sentences, until a sentence is false for your analysis, and then replace it with one that is true, at the same level of specificity. Do not delete a sentence because its check was not run. For a finished analysis, the sentence becomes one clause stating that the stage was not run, with the reason where the log gives one. A bracket is filled only from the log or the saved output, never from invention, and a value that neither of them holds stays a bracket and is listed in the reply. The one legitimate deletion is design calibration when adapting Template B to a large sample, where it answers a question that nobody is asking.
