# Prior and likelihood sensitivity by power-scaling

The question a reviewer asks about any small-sample Bayesian result is whether the priors
produced it. Power-scaling answers that cheaply and without refitting: the prior, or the
likelihood, is raised to a power alpha, the existing draws are reweighted by Pareto-smoothed
importance sampling, and the movement in the posterior is measured.

Two questions come out of it, and the second is at least as useful as the first:

1. Is the posterior sensitive to the prior? If so, the prior is doing work the data are not.
2. Is the posterior sensitive to the likelihood? If it is *not*, the data are not informing
   that parameter at all, whatever the posterior interval looks like.

---

## The basic pass

```r
library(priorsense)

powerscale_sensitivity(fit)
powerscale_sensitivity(fit, variable = c("b_x1", "b_x2", "sigma"))

powerscale_plot_dens(fit, variable = "b_x1")        # how the density moves with alpha
powerscale_plot_quantities(fit, variable = "b_x1")  # summaries against alpha
```

The table gives, per variable, a `prior` and a `likelihood` sensitivity magnitude and a
`diagnosis` string. Larger means more sensitive; the default threshold is 0.05.

| `prior` | `likelihood` | Diagnosis string emitted | What it means |
|---|---|---|---|
| high | high | `potential prior-data conflict` | Prior and data disagree. Sometimes the prior is wrong; sometimes the data are genuinely surprising. Either way it needs thought, not a wider prior |
| high | low | `potential strong prior / weak likelihood` | The posterior is essentially the prior. The data do not inform this parameter |
| low | low | `-` | Insensitive to reasonable perturbation of either |

By default the table covers every parameter in the model, including one group-level
deviation per group per term. On a model with eighteen participants and varying slopes that
is forty-five rows, and on a country-level model it is hundreds. Restrict it with
`variable =`, or use `scripts/bw_sensitivity.R`, which reports population-level parameters
and variance components and leaves the per-group deviations out unless asked.

A worked instance of the conflict flag: fitting the sleep-deprivation study with an
`lkj(2)` prior on the intercept-slope correlation flags
`cor_Subject__Intercept__Days_z` as a prior-data conflict. The data carry a strong positive
correlation between baseline reaction time and the effect of sleep loss, and `lkj(2)` mildly
favours weaker correlations. That is worth a sentence in the paper, not a change of prior.

**The flag has a large-sample form too, and it means something different.** On a
verbal-aggression study with 7584 responses, `normal(0, 1)` priors on the coefficients flag a
conflict for the behaviour-type contrasts. Nothing is wrong with the data; the effects are
simply large, and a prior that was weakly informative at n = 200 is a real constraint at
n = 7584. Sensitivity is relative to the amount of information in the likelihood, so the same
prior moves from harmless to binding as the sample grows. The response is to widen the prior
for those coefficients on the grounds that the effects genuinely can be large, and to say so –
which is the one case where reacting to the flag by changing the prior is the right move,
because the reasoning is about the effect and not about the diagnostic.

A parameter that is insensitive to the prior *and* sensitive to the likelihood is the case you
want: the data are doing the work. priorsense also polices its own importance-sampling
reliability: there is no Pareto k column in the output, but the procedure warns when k
exceeds its threshold (0.5 by default). Treat that warning as disqualifying, and confirm the
result by actually refitting under an alternative prior rather than trusting the reweighting.

## The rule that stops this becoming a ritual

**Do not adjust priors until the diagnostic messages go away.** A conflict flag is information
about the model, and tuning until it disappears destroys the information without fixing
anything. The right response to a conflict is to work out which of the prior and the data is
telling you something you did not expect.

## Sensitivity of the estimand, not of the coefficients

This is the refinement that matters most in practice, and the one almost nobody runs.

When parameters are correlated in the posterior – spline coefficients, dummy-coded factor
levels, anything where a function of several parameters is identified but the individual
parameters are not – the marginal posterior of any one of them is not interpretable on its own,
so neither is its sensitivity. A model can show alarming sensitivity in its marginal
coefficients while the quantity actually reported is perfectly stable, and the reverse.

Carry the derived quantity through with `predictions_as_draws()` and power-scale that:

```r
library(priorsense)

nd <- data.frame(x = c(-1, 0, 1))

pred_draws <- predictions_as_draws(
  fit, posterior_epred, newdata = nd,
  prediction_names = c("epred_lo", "epred_mid", "epred_hi")
)

psd <- create_priorsense_data(pred_draws, fit = fit)
powerscale_sensitivity(psd)
```

which returns the same diagnosis table, one row per derived quantity:

```
  variable prior likelihood diagnosis
  epred_lo 0.020      0.108         -
 epred_mid 0.003      0.094         -
  epred_hi 0.030      0.100         -
```

Any function of the parameters can go through the same route by supplying a different
`predict_fn`: `posterior_linpred` for the linear predictor, `posterior_predict` for the
predictive distribution, or a custom function returning a draws-by-cases matrix.

**Report the sensitivity of the number the paper claims.** If the abstract states an average
marginal effect, that is the quantity that has to be shown insensitive to the prior. A table of
coefficient sensitivities does not answer the question that was asked.

## Static sensitivity analysis, without any refitting

A different and cheaper move, useful when power-scaling is unavailable or has warned that
its importance sampling is untrustworthy. Plot the quantity of interest against a parameter, across posterior draws.
The plot reads two ways:

- **Directly**: how strongly the quantity of interest depends on that parameter in the
  posterior. A flat cloud means the quantity is insensitive to it; a tight relationship means
  it is largely determined by it.
- **Indirectly, as prior sensitivity**: changing the prior on the parameter on the horizontal
  axis is equivalent to reweighting the points by the ratio of the new prior to the old one. A
  tilted cloud means a shifted prior on that parameter would move the estimand; a flat cloud
  means it would not.

```r
library(tidybayes)
library(ggplot2)

fit |>
  spread_draws(b_x1, sigma) |>
  mutate(estimand = b_x1 / sigma) |>          # whatever the reported quantity is
  ggplot(aes(x = sigma, y = estimand)) +
  geom_point(alpha = 0.1) +
  labs(x = "sigma", y = "Quantity of interest")
```

No refit, no importance sampling, and no diagnostic to distrust.

## What to report

One sentence per claim. "The average marginal effect of parental education is insensitive to
power-scaling of the prior and sensitive to power-scaling of the likelihood, indicating an
estimate driven by the data rather than by the prior specification" is a defensible sentence. A
table of sensitivity diagnoses in an appendix, with nothing said about it in the text, is not.

---

Source: Gelman, Vehtari, McElreath et al., *Bayesian Workflow* (CRC Press, 2026), chapter 8
section 5. The power-scaling method and the `priorsense` package are due to Kallioinen,
Paananen, Bürkner and Vehtari. See `reference/book-map.md`.
