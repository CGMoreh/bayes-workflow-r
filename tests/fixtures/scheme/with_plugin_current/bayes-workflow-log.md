# Bayesian workflow log – pest-control trial

## 2026-09-02 – Before any fit: the estimand, the structure, the abandonment rule

**The question.** Did the treatment reduce the number of pests caught, and by how much?

**The estimand, in the four terms `bayes-estimands-r` asks for.**

1. *Contrast.* Treated (`treated = 1`) against untreated (`treated = 0`), the same apartments
   counterfactually assigned to each arm.
2. *Population.* The 262 apartments in the trial, as observed – a sample average treatment
   effect. There is no external target population described anywhere in the brief or the
   codebook, so nothing supports poststratifying to one.
3. *Scale.* Two quantities, both on the response scale, both over the standard trapping
   window (`trap_period = 1`): the ratio of expected counts (treated / untreated), and the
   difference in expected counts. The ratio is the transportable summary; the difference is
   what a building manager counts. The log-link coefficient on `treated` is neither of these
   once the outcome is averaged over a skewed covariate, so it is not reported as the answer.
4. *Total or direct.* Total. `baseline` and `senior_only` are both pre-treatment, so
   conditioning on them cannot block any part of the effect. `trap_period` is a design
   variable – how long the traps were out – and enters as an offset, not as a covariate,
   because differences in observation time are not differences in incidence.

**Structure and sample size.** 262 independent apartments, one row each, no clustering
variable in the file. n = 262 is not small for a four-parameter regression, so the priors are
not expected to be load-bearing; that expectation is tested by power-scaling rather than
assumed.

**Design.** Treated and untreated arms are balanced on the pre-treatment infestation measure
(standardised difference 0.036 on the raw scale, 0.084 on the log scale) and mildly unbalanced
on building type (34% senior-only among treated, 26% among untreated). That pattern is what
random assignment to unequal arm sizes looks like. Covariate adjustment is therefore for
precision, not for identification, and the answer should not move much when the covariates are
dropped. That is a check to run, not an assumption.

**What would make me abandon the model.** (a) A posterior predictive check on the proportion of
zeros or on dispersion that the model cannot reproduce; (b) `p_loo` far above the parameter
count, which for counts means the family is wrong; (c) power-scaling showing the treatment
contrast moves with the prior; (d) the answer changing materially between the adjusted and
unadjusted specifications, which would mean the covariates are doing identification work that
randomisation was supposed to do.

## 2026-09-02 – Data description
`caught`: mean 25.7, variance 2585, variance-to-mean ratio 101. 94 of 262 apartments (35.9%)
caught nothing. A Poisson is ruled out on inspection, but it is fitted anyway as the first rung
so that the failure is measured rather than asserted.

`baseline` is heavily skewed (mean 42.2, median 7.0). On the log scale it correlates 0.65 with
the log outcome rate against 0.54 on the raw scale, so it enters as `log(1 + baseline)`,
standardised.

Crude, unadjusted, ignoring the exposure window: treated apartments caught 20.1 pests per
standard window on average against 36.0 untreated, a rate ratio of 0.56.

## 2026-09-02 – Priors, chosen by what they imply
Three prior sets simulated with `sample_prior = "only"` and compared on the observable
scale. The wide set (`normal(0, 10)` intercept, `normal(0, 5)` slopes, the brms default
`gamma(0.01, 0.01)` on shape) put its median replicate at zero pests in every apartment and
its 95th percentile of the maximum at 22 million, and only 37% of its mass on treatment rate
ratios between 0.1 and 10. It is not weakly informative; it is absurd, and it is what the
defaults give.

Carried forward: `normal(1, 2.5)` on the intercept, `normal(0, 1)` on slopes,
`exponential(0.5)` on the negative binomial shape, `beta(1, 1)` or `normal(0, 1.5)` on the
zero component. Implied prior median replicate count 2 against 3 observed, implied median
proportion of zeros 0.32 against 0.359 observed, implied maximum 96 with a 5th-to-95th range
of 2 to 8,670 against 357 observed, and 98% of the prior mass on rate ratios between 0.1 and
10. The prior brackets the data without asserting the answer.

## 2026-09-02 – m1 Poisson: the failure that names the next model
`p_loo` 264.1 against four parameters. Predicted proportion of zeros 0.015 against 0.359
observed, posterior predictive p-value 0.000; the same for the standard deviation and the
maximum. Every replicate the Poisson generates is less dispersed than the data. Next:
negative binomial.

## 2026-09-02 – m2 negative binomial: dispersion fixed, the contrast wrong
The zero proportion and the dispersion now pass. But the check on the summary the answer is
a statement about – the ratio of mean catch rates between arms – gives a fitted 0.328 against
0.559 observed. The model reproduces the outcome's shape and misses the treatment contrast
that the raw data show, which is the only check here that bears directly on the question.
Two candidate causes, and both were fitted: the 36% zeros are not being generated by the
right process, and the effect may not be constant across levels of infestation.

## 2026-09-02 – m3 to m6: separating the two candidate repairs
m3 (zero-inflated, constant zi) estimates zi at 0.05 and is indistinguishable from m2. m4
(hurdle, constant hu) fits the zero proportion exactly but loses 44.1 elpd. m5 (zero
inflation with predictors) and m6 (treatment by baseline interaction) each gain: m5 by 17.9
elpd over m2, m6 by 6.5. So both repairs are real and neither excludes the other.

## 2026-09-02 – m9 to m13: the combinations, and the checks the interaction has to survive
m9 (zero inflation with predictors AND the interaction) is the best model by ten-fold
cross-validation, with m11 (its hurdle twin) 1.5 elpd behind on a standard error of 2.4 –
indistinguishable. m12 replaces the interaction with a free smooth of baseline in each arm
and reproduces the same divergence between arms, so the interaction is not an artefact of
forcing baseline in as a straight line on the log scale. m13 frees the exposure coefficient
that the offset fixes at 1 and puts it at 0.60 [-0.45, 1.70], which contains 1, and leaves
the treatment coefficient at -1.20 against -1.21; the offset stands.

Under m9 the fitted arm-mean ratio is 0.622 and under m11 0.598, against 0.559 observed. The
models without the interaction sit at 0.46, and m2 at 0.33. The interaction is what
reconciles the model with the contrast the randomisation delivers.

## 2026-09-02 – Sensitivity
Power-scaling the reported quantity rather than the coefficients: prior sensitivity 0.017
under m9 and 0.020 under m11, both well under the 0.05 threshold, against likelihood
sensitivity 0.135 and 0.118. The answer is the data's. Refitting confirms it: the
sample-average ratio is 0.585 under the reported priors, 0.627 under the tighter set that
the prior predictive check endorsed, and 0.568 under the absurd wide set.

The zero-inflation parameters of m9 do flag prior-data conflict (0.198 on zi_Intercept). The
zero-inflation probability trades off against the negative binomial's own capacity to
generate zeros, so it is weakly identified and its prior binds; under the wide prior
zi_Intercept moves from -2.5 to -4.3. The reported quantity does not move with it, which is
the reason for power-scaling the quantity rather than the parameters.

## 2026-09-02 – Design calibration
One hundred trials simulated at n = 262 with the covariate mix, arm sizes and trapping windows
resampled from the trial. A true halving of the catch rate is recovered 94% of the time, with
89% intervals covering 89% of the time, no sign errors and no exaggeration (0.96x). A true 15%
reduction is recovered 24% of the time, with a 28% sign-error rate and a 2.90x exaggeration
among detections. Under no effect at all, 6% of runs return an interval excluding zero.

The estimated effect sits in the range this design recovers reliably; the upper end of its
interval sits in the range it does not, which is why that interval reaches almost to 1.

## 2026-09-02 – m14: the building-type question, tested rather than argued
Writing up the subgroup results showed that the averaged effect ratio in senior-only buildings
(0.53) differs from the ratio elsewhere (0.60) with a ratio of ratios of 0.87 [0.79, 0.95],
even though the model carries no treatment-by-building-type term. Two possible causes:
composition, or a real difference the model is not allowed to express. m14 adds the term. It
buys nothing predictively – 0.5 elpd behind m9 on a standard error of 3.1 – and the term is
-0.76 [-1.64, 0.11]. Senior-only apartments have a median pre-trial count of 2 against 13
elsewhere, and the effect is proportionally larger where infestation was lower, so the
composition explanation is sufficient. The first draft of the report said there was "no
evidence that the treatment works differently in the two settings", which was wrong on its own
numbers; this entry records the correction.

## 2026-09-02 – The report, and the check on it
`br_check_numbers()` traced all 333 numbers in REPORT.md to a value in output/. Three failed on
the first pass: two were thousands separators the matcher could not read, and one was a
scientific-notation prior quantile computed on a 500-draw subsample, whose Monte Carlo error on
that heavy a tail was larger than the figure being quoted. `12_report_numbers.R` recomputes the
prior-predictive summaries on all 2,000 draws, and the report now quotes those.

Reading the number-free quantified claims against the tables behind them is what caught the
building-type error above. That is the pass which is worth its cost.
