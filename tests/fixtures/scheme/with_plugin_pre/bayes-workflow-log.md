# Workflow log – pest-control trial

## 2026-09-02 – the estimand, written before any model is fitted

**What contrast?** Treated against untreated, for the same apartment: what would be caught
if this apartment received the treatment, against what would be caught if it did not.

**Over what population?** The 262 apartments as observed. This is a sample average treatment
effect. Nothing in the file describes a wider population of apartments, so there is no frame
to poststratify to and no defensible way to reweight; any generalisation beyond these
buildings is a substantive judgement rather than a quantity this analysis can estimate.

**On what scale?** Two numbers, both on the response scale and both per standard trapping
window (`trap_period = 1`):

1. the rate ratio, expected count under treatment divided by expected count under no
   treatment, which is the scale a log-link count model reports naturally and the scale on
   which a proportional reduction is stated;
2. the absolute difference in expected counts, which is the number of pests, because a
   proportional reduction on a base of two pests and the same reduction on a base of two
   hundred are different facts for anyone deciding whether to pay for the treatment.

**Total or direct?** Total. `baseline` is measured before the trial began and `senior_only`
is a fixed property of the building, so both are pre-treatment and neither can be a mediator.
They enter the model to absorb variation in the outcome and so sharpen the contrast, not to
block a path.

**What would make me abandon a model?** A predictive check on dispersion or on the share of
zeros that the model cannot reproduce; divergent transitions that survive reparameterisation;
or a rate ratio whose posterior moves materially when the prior is power-scaled, which would
mean the data are not the source of the answer.

**Design note.** The two arms are closely balanced on everything measured before treatment –
the standardised difference in log baseline count is 0.084, senior-only buildings are 26% of
the untreated arm and 34% of the treated arm, and the trapping windows have almost identical
means. That balance is what a randomised assignment produces, and it is why the covariates
are here for precision rather than for identification. It is not proof of randomisation, and
the report says so.

## 2026-09-02 – priors, checked before the data were used

`normal(2, 1.5)` on the intercept, `normal(0, 1)` on the slopes, `exponential(1)` on the
negative binomial shape. Simulating 262 apartments from the prior alone gives a median count
of 2 against an observed median of 3, a 90th percentile of 88 against an observed 77, and
1.9% of apartments catching more than a thousand pests, which is generous rather than
absurd. The prior on the treatment rate ratio runs from 0.15 to 6.3 at 95%. Widening the
slope prior to `normal(0, 5)` puts the 90th percentile of the prior predictive at 293,697
pests in a single apartment and 23% of apartments above a thousand, so it is not a
defensible alternative even though it is the more conventional "vague" choice.
Output: `output/02_prior_predictive.txt`.

## 2026-09-02 – m1: Poisson. Fails on every summary that can fail

Variance-to-mean ratio in the data is 100.8; the Poisson asserts 1. Predicted standard
deviation, share of zeros, 90th percentile, maximum and share above 100 all have posterior
predictive p-values of 0.000. Only 1 of 10 baseline-quintile-by-arm cells falls inside its
95% predictive interval. LOO puts it 4232.7 behind the best model with a standard error of
705.8. Kept in the report only as the rung that fails.

## 2026-09-02 – m2 to m10: overdispersion, zeros, functional form, exposure

m2 (negative binomial) fixes the dispersion. Its remaining misfit is in the other direction:
the predicted maximum has p = 0.976 and the predicted standard deviation p = 0.951, so the
tail is now too heavy. One grouped cell still fails, the lowest baseline quintile among
treated apartments, where the observed mean is 0.65 against a predicted 1.68 [0.68, 3.71].
Two responses to that cell fit the data: a hurdle, which lets treatment act on whether any
pest is caught at all (m6), and an interaction, which lets the proportional effect weaken as
the baseline count rises (m8). Both are credible on their own, and they imply different
answers – rate ratio 0.42 against 0.69. m3 (baseline entered raw rather than logged) is 21
elpd worse than the spline and is dropped. m10 estimates the coefficient on
log(trap_period) instead of fixing it at 1 and returns 0.97 [−0.11, 2.05], so the offset
stands. Outputs: `output/03_fit_models.txt`, `output/04_diagnostics_ppc.txt`,
`output/05_comparison.txt`.

## 2026-09-02 – m11 and m12: the two explanations are not rivals

Fitting both mechanisms together settles it. The count-part interaction shrinks from 0.43
[0.19, 0.67] in m8 to 0.26 [0.01, 0.50] in m11 and 0.23 [−0.02, 0.48] in m12 once a hurdle
is present, so part of what m8 read as a weakening proportional effect was the excess of
zeros among lightly infested treated apartments. Part of it is real: the observed
apartment-level rate ratio falls monotonically across baseline quintiles, 0.096, 0.257,
0.430, 0.471, 0.684, with no model involved.

With Pareto k repaired by moment matching, LOO orders the models m12, m11 (−1.0, se 3.1),
m6 (−2.5, se 4.7), m8 (−13.1, se 7.5), m9 (−16.7, se 7.8), m2 (−18.9, se 9.2). The three
hurdle models are indistinguishable from each other and all beat the plain negative
binomials. m12 is carried forward because it is the only one that asserts neither
interaction away, and because its fitted arm means reproduce the observed ones (34.55 and
21.58 against 34.68 and 19.70) where m2's do not (51.55 against 34.68).
Output: `output/08_expand.txt`.

## 2026-09-02 – the estimand, checked against a model-free anchor

A Bayesian bootstrap over apartments, which assumes only that the 262 apartments are
exchangeable, gives a rate ratio of 0.568 [0.355, 0.909]. m12 gives 0.554 [0.320, 0.947].
m2 gives 0.304 [0.189, 0.479] and does not contain the bootstrap estimate. A posterior
predictive check aimed at the observed rate ratio confirms the direction of the failure:
p = 0.587 for m12 and 0.130 for m2. Output: `output/10_design_based.txt`,
`output/11_primary.txt`.

## 2026-09-02 – sensitivity

Power-scaling the prior on m12 between alpha 0.5 and 2 moves the reported rate ratio from
0.539 to 0.582, and priorsense raises no diagnosis flag (prior 0.032, likelihood 0.129).
Refitting under `normal(0, 5)` slopes gives 0.526 against the reported 0.554; refitting
under `normal(0, 0.35)` gives 0.679, which is the one prior that moves the answer, and it
is a prior that constrains the interactions as well as the main effect to lie within a rate
ratio of about [0.5, 2]. Output: `output/11_primary.txt`, `output/07_sensitivity.txt`.
