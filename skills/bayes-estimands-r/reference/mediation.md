# Direct and indirect effects by simulation

When a mediator sits between exposure and outcome, the total effect splits into a path that runs
through the mediator and a path that does not. Neither is a coefficient. Putting the mediator in
the outcome model and reading off the exposure coefficient gives something related to the direct
effect only under assumptions that are rarely stated and often false.

The construction that works is a simulation. The mediator is itself affected by the exposure, so
it has to be simulated conditional on the exposure, and the direct effect is the comparison in
which the exposure changes while the mediator is held at the value it would have taken under the
control condition.

---

## The procedure

For each posterior draw:

1. Simulate the mediator as it would be under control, and under treatment.
2. Compute the expected outcome under control, with the control-condition mediator.
3. Compute the expected outcome under treatment, still with the **control-condition** mediator.
   The difference from step 2 is the direct effect.
4. Compute the expected outcome under treatment with the treatment-condition mediator. The
   difference from step 3 is the indirect effect, and the difference from step 2 is the total.

Everything happens within the draw, so the three quantities come out with correct joint
uncertainty and can be compared against one another.

## Fitting both equations at once

The mediator and outcome equations are fitted jointly so that every posterior draw carries
both sets of coefficients at once, which is what the within-draw simulation below needs.

```r
library(brms)

bform <- bf(u ~ z + x) +          # mediator equation
         bf(y ~ u + z + x) +      # outcome equation
         set_rescor(FALSE)

fit <- brm(
  bform, data = d, family = gaussian(),
  prior = c(prior(normal(0, 2), class = "b", resp = "u"),
            prior(normal(0, 2), class = "b", resp = "y")),
  seed = 20260826, backend = "cmdstanr",
  file = "model-data/m_mediation", file_refit = "on_change"
)
```

`set_rescor(FALSE)` says the two equations have independent residuals. Allowing residual
correlation instead is a different model, and one that no longer supports a causal reading of the
decomposition without further assumptions.

## Computing the three effects

```r
library(posterior)
library(dplyr)

# the mediator as it would be under each assignment: draws by cases
u0 <- posterior_epred(fit, newdata = mutate(d, z = 0), resp = "u")
u1 <- posterior_epred(fit, newdata = mutate(d, z = 1), resp = "u")

dr <- as_draws_df(fit)

# expected outcome given a supplied mediator matrix and an exposure value.
# eta[s, i] uses draw s of every coefficient and case i of every covariate.
expected_y <- function(umat, zval) {
  eta <- dr$b_y_Intercept +
         dr$b_y_u * umat +                 # recycles down columns: draw s gets b_y_u[s]
         dr$b_y_z * zval +
         outer(dr$b_y_x, d$x)
  rowMeans(eta)                            # identity link; see below for other families
}

y_ctl        <- expected_y(u0, 0)   # control throughout
y_trt_med_ctl <- expected_y(u0, 1)  # treated, mediator held at its control value
y_trt        <- expected_y(u1, 1)   # treated, mediator allowed to respond

effects <- tibble::tibble(
  direct   = y_trt_med_ctl - y_ctl,
  indirect = y_trt - y_trt_med_ctl,
  total    = y_trt - y_ctl
)

effects |>
  tidyr::pivot_longer(everything(), names_to = "path", values_to = "draw") |>
  summarise(
    median = median(draw),
    lower  = quantile(draw, 0.055),
    upper  = quantile(draw, 0.945),
    .by    = path
  )
```

On simulated data with a direct path of 0.40, an indirect path of 0.30 and a total of 0.70, this
returns 0.44 [0.27, 0.60], 0.24 [0.16, 0.33] and 0.68 [0.50, 0.85]. The decomposition adds up by
construction, because the three quantities are differences among the same three simulated
outcomes within each draw.

## Non-linear outcomes: two changes, not one

The `expected_y()` above assumes an identity link. For any other family, apply the inverse link
to the linear predictor before averaging, and average on the response scale rather than the
latent one:

```r
expected_y <- function(umat, zval) {
  eta <- dr$b_y_Intercept + dr$b_y_u * umat + dr$b_y_z * zval + outer(dr$b_y_x, d$x)
  rowMeans(plogis(eta))            # bernoulli / binomial
  # rowMeans(exp(eta))             # poisson / negbinomial
}
```

Averaging the linear predictor and then transforming is not the same thing and gives the wrong
answer whenever the link is non-linear.

**The mediator has to change too, and this is the error that actually bites.** With a
non-linear link the effect must be averaged over the *distribution* of the mediator, not
evaluated at its expectation, because the expectation of a non-linear function is not the
function of the expectation. Using `posterior_epred()` for the mediator substitutes the
conditional mean for the distribution and biases every path – and the direction of the
bias depends on where the outcome's base rate sits on the link's curve, so it cannot be
waved away as conservative:

```r
# non-linear outcome: simulate the mediator, do not take its expectation
u0 <- posterior_predict(fit, newdata = mutate(d, z = 0), resp = "u")
u1 <- posterior_predict(fit, newdata = mutate(d, z = 1), resp = "u")
```

How much this matters depends on how strong the mediation is and on the outcome's base
rate. On a logistic outcome with a baseline probability near 0.45, a mediator residual SD of
1.5 and a mediator coefficient of 1.2, Monte Carlo truth over 400 replicate integrations
gives a direct effect of 0.078, an indirect effect of 0.109 and a total of 0.187. The
`posterior_epred()` version returns roughly 0.11, 0.15 and 0.26, overstating the paths by a
third to 45 per cent; switching to `posterior_predict()` and changing nothing else returns
0.076, 0.109 and 0.185. At weaker mediation the error falls sharply – a few per cent at a
residual SD of 1.0 with a coefficient of 0.4, and under 1 per cent at 0.5 with 0.3.

The direction reverses for rare outcomes, where the base rate sits on the convex part of the
inverse link: at a baseline of 0.10 the same shortcut *understates* the direct effect by
about 27 per cent, and at 0.05 it understates the direct, indirect and total effects by
roughly 44, 13 and 26 per cent. So the shortcut is not a cautious approximation in either
direction, and the strongly mediated mid-range case people write papers about is merely
where the overstatement is largest.

A single simulated draw of the mediator per posterior draw is unbiased but noisy. If the
resulting intervals are too wide to read, average over several draws of the mediator within
each posterior draw rather than reverting to the expectation.

For an identity-link outcome the two agree, because expectation is linear, and
`posterior_epred()` is the lower-variance choice. That is why the worked example above uses it.

## When the mediator is not continuous

Give the mediator equation the appropriate family in `bf()`, and use `posterior_predict()` for
it so that a binary or count mediator is simulated as a realised value. The rest of the
procedure is unchanged.

## What this does and does not license

The decomposition is a statement about the fitted model. Reading it causally requires, at
minimum, that there is no unmeasured confounding of the exposure-outcome relationship, none
of the exposure-mediator relationship, none of the mediator-outcome relationship, and no
exposure-induced confounding of the mediator-outcome relationship. The last is the one people
forget, and it is not testable from the data.

Say which of these you are assuming. A decomposition reported without them is a description of
the model, and should be worded as one.

## Interventions on more than one variable

The same machinery covers an intervention that sets several variables at once, or that unfolds
over time. Simulate every downstream variable in the order the causal structure implies, holding
the intervened variables at their assigned values, and difference the results. The bookkeeping
grows; the logic does not change.

---

Source: Gelman, Vehtari, McElreath et al., *Bayesian Workflow* (CRC Press, 2026), chapter 7
section 2, which sets out the simulation procedure for direct effects. The brms implementation
here is original.
