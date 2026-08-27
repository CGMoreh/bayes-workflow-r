# When the sampler complains, it is usually telling you about the model

The organising idea, which Gelman calls the folk theorem of statistical computing: when
sampling is slow, divergent or badly mixed, the cause is more often a problem with the model
than a problem with the sampler. Prior-data conflict, non-identifiability, awkward posterior
geometry and unscaled predictors all show up first as computational symptoms. Treating those
symptoms as noise to be suppressed – raising `adapt_delta` until the warnings stop – discards
the most useful diagnostic information the fit produces.

That does not mean tuning is never the answer. It means tuning is the second thing to try.

---

## Read the diagnostics first

```r
summary(fit)                                        # Rhat, Bulk_ESS, Tail_ESS per parameter
bayesplot::mcmc_rank_ecdf(fit)                      # sharper than trace plots for mixing
bayesplot::mcmc_pairs(fit, np = brms::nuts_params(fit))   # divergences drawn in red
```

brms stores an rstan S4 `stanfit` in `fit$fit` whatever the backend, so the cmdstanr
object's own `$diagnostic_summary()` is not reachable there. The equivalent one-liner is:

```r
rstan::check_hmc_diagnostics(fit$fit)   # divergences, treedepth, E-BFMI, in one call
```

It also prints the configured treedepth limit, which is the number saturation has to be
judged against.

**Thresholds.** R-hat below 1.01. Bulk-ESS and Tail-ESS each above 400 for any parameter you
intend to report. Zero divergent transitions is the target.

Divergences need a judgement rather than a threshold, so `scripts/bw_diagnose.R` grades them:
at or below 0.5% of post-warmup draws it reports a warning and lets the gate pass, above that
it fails. The warning is not a dismissal. A handful scattered across the posterior is usually
tolerable; the same handful concentrated in one region is not, because that region is
precisely where the sampler could not go, and it is often where the interesting parameter
values are. Draw the pairs plot before accepting any of them:

```r
bayesplot::mcmc_pairs(fit, np = brms::nuts_params(fit))
```

Adjust the tolerance with `div_tol` if your situation warrants it, but adjust it before you
see the result, not after.

## Symptom, cause, remedy

| Symptom | Most likely cause | What to do |
|---|---|---|
| Chains never leave their initial values; log probability evaluates to log(0) | Improper or absent prior on some coefficient, or a parameter the data cannot identify | Put a proper, weakly informative prior on every coefficient; remove redundant predictors |
| R-hat far above 1.01 with very low ESS | Chains exploring different regions: multimodality, or a flat ridge in the posterior | Run more chains to find the modes; check identifiability; tighten or rescale priors; add an ordering or sign constraint if the modes are label-switching |
| Divergent transitions, few and scattered | Step size slightly too large for the local curvature | Raise `adapt_delta`: 0.95, then 0.99 |
| Divergences that survive `adapt_delta = 0.999` | Geometry, typically a funnel where a group-level scale approaches zero | Reparameterise. brms already uses the non-centred form for group-level terms, so the funnel is usually elsewhere: tighten the prior on the group-level SD, or ask whether the grouping factor has enough levels to support a variance at all |
| Transitions exceeded maximum treedepth | Strong posterior correlation forcing long trajectories | An efficiency warning, not a validity warning. Raise `max_treedepth` to 12 or 15, but the real fix is to decorrelate: centre and scale the predictors |
| Slow, thick-tailed, wandering chains | Heavy-tailed priors such as Cauchy, or predictors on wildly different scales | Replace Cauchy with normal or student_t(3, 0, s); standardise predictors |
| Bimodal posterior for a variance or a mixture weight | Genuine multimodality, or an unidentified sign or label | Add a constraint that identifies the parameterisation; reconsider the model |

## The levers, and what each one costs

```r
brm(
  formula, data = d, family = gaussian(), prior = priors,
  control    = list(adapt_delta = 0.99, max_treedepth = 12),
  chains     = 4,
  iter       = 4000, warmup = 1000,
  init       = 0,                    # tame wild starting values in hierarchical models
  seed       = 20260826,
  backend    = "cmdstanr",
  file       = "model-data/m3",      # cache the compiled model and the draws
  file_refit = "on_change"
)
```

`adapt_delta` closer to one means a smaller step size: fewer divergences, slower sampling.
`max_treedepth` allows longer trajectories, which removes the warning without removing the
correlation that caused it. Standardising predictors is the cheapest and most effective single
intervention available, because it decorrelates the posterior, makes default priors meaningful,
and often resolves treedepth warnings on its own.

## A grouping factor with few levels

A varying intercept over a factor with three or four levels is a variance estimated from three
or four numbers. It produces funnel geometry, divergences, and a posterior for the group-level
SD with most of its mass near zero and a long right tail. Options, in order of preference: put
an informative prior on the SD; treat the factor as a population-level effect with a few dummy
terms instead; or keep the partial pooling and state plainly in the write-up that the variance
component is weakly identified.

## What goes in the log

Record the warning, what you concluded it meant, and what you changed in response. A methods
section that says "four chains of 2000 iterations, all R-hat below 1.01" and stops there
discards the evidence that the computation was interrogated rather than merely run.

---

Source: Gelman, Vehtari, McElreath et al., *Bayesian Workflow* (CRC Press, 2026), chapters 11
and 12, and the case study on diagnosing and fixing problems with fitting. See
`reference/book-map.md` for the pointers.
