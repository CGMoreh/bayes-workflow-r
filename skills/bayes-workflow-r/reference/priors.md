# Priors, and checking what they imply

The habit this file exists to break: declaring `normal(0, 0.5)` on standardised slopes,
calling it weakly informative, and moving on. Whether a prior is weak is not a property of
the prior you wrote. It is a property of what that prior implies about the quantity you care
about, and the two can point in opposite directions.

---

## 0. First ask what scale the outcome is on

Before anything about the number of predictors, settle the units. A slope prior is read in
units of the *outcome*, so standardising the predictors fixes only the denominator of the
ratio. The same `normal(0, 0.5)` means three different things:

- **Outcome standardised, gaussian.** It puts 95% of its mass roughly between −1 and 1. A
  standardised slope near 1 is close to a perfect correlation, so per coefficient this rules
  out almost nothing. Weakly informative, and generous by the standards of observational
  social data, where partial standardised slopes above 0.3 are unusual.
- **Outcome on its raw scale.** If the outcome is annual income with a standard deviation
  near £20,000, the same prior says a one-standard-deviation move in a predictor shifts income
  by well under a pound. That is a hard pull towards zero which will overwhelm most likelihoods.
- **Logistic or another non-identity link.** Coefficients are log-odds, so the prior says a
  one-SD move multiplies the odds by something between about 0.4 and 2.7. A reasonable
  per-coefficient statement for observational data.

So if the outcome is unstandardised and continuous, rescale the prior before reading anything
below. Sections 1 to 3 assume the units are already sensible, and they are about a second
problem that survives even when they are.

## 1. Priors are joint, even when you write them one at a time

You specify priors coefficient by coefficient. The model uses them all at once. In a
regression with many predictors, independent priors that each look uninformative on their own
combine into a prior that is emphatically informative about how much variance the model
explains – and in the wrong direction, favouring near-perfect fit.

The mechanism is dimensionality. Each coefficient is free to be moderately large, the
predictors are several, and their contributions to the variance of the linear predictor add
up. A prior meant to say "we do not know" ends up saying "this model explains nearly
everything".

How badly, and from how few predictors, is worth stating in numbers. Standardised predictors,
`exponential(1)` on sigma, and the coefficient priors below give these prior distributions of
R²:

| Slope prior | 5 predictors | 20 predictors | 95th percentile at 20 |
|---|---:|---:|---:|
| `normal(0, 1)` | 0.90 | 0.97 | 1.00 |
| `normal(0, 0.5)`, halved arbitrarily | 0.71 | 0.91 | 1.00 |
| `normal(0, sqrt(0.3/k)·sd(y))`, scaled to a target | 0.37 | 0.37 | 0.99 |
| `R2D2(mean_R2 = 0.25)` | 0.12 | 0.14 | 0.46 |

Prior median R², with the upper tail in the last column. With `normal(0, 1)` slopes and 20
predictors the 5th percentile is 0.66, so the model is a priori almost certain to explain most
of the variance before it has seen anything.

Three things follow. This is not a many-predictor corner case – it is already severe at five
predictors, which is a modest regression by any standard.

**Arbitrary rescaling does not help.** Halving `normal(0, 1)` to `normal(0, 0.5)` at 20
predictors moves the median from 0.97 to 0.91, which is not a different claim in any way that
matters, and leaves the upper tail at 1.00.

**Scaling to a target does help, and is a legitimate option.** Setting the slope scale to
sqrt(target R² / k) · sd(y) – the standard construction, and the one Gelman et al. use in
their student-grades case study – brings the median to 0.37 for a target of 0.3, and holds it
there as predictors are added: 0.37 at five predictors and 0.37 at twenty. If you want a
normal prior and have a defensible target, this is how to set it, and the arithmetic is one
line. What it does not control is the upper tail, which stays at 0.99: the prior still admits
a model that explains everything. R2D2 controls the whole distribution rather than its centre,
which is why it is the recommendation below, but the gap between the two is narrower than the
gap between either and an unscaled prior.

**It is not only about coefficients.** Anything that contributes to the variance of the linear
predictor contributes here, and in a multilevel model the varying effects usually contribute
more than the slopes do. Fitting the sleep-deprivation study with a single population-level
slope, varying intercepts and slopes by participant, and `exponential(0.02)` priors on the
group-level standard deviations – a prior with a mean of 50 on a scale where the outcome
itself has a standard deviation of about 56 – gives an implied prior median R² of 0.83. The
same priors admit negative reaction times. One slope, and the prior is already claiming the
model explains most of the variance.

So when the implied R² comes out high, look at the variance-component priors before the slope
priors. In a multilevel model the quantity computed here is a conditional R², because the
varying effects are part of the linear predictor.

**And on real data, with real predictors.** Predicting final grades for 649 secondary students
from the thirty background variables in the dataset – thirty-nine columns once the categorical
ones are dummy-coded – the implied prior median R² is 0.83 under `normal(0, 1)` slopes and 0.61
under `normal(0, 0.5)`. Under `R2D2(mean_R2 = 0.3)` it is 0.15. The fitted model's posterior R²
is 0.356 [0.311, 0.399].

Read that comparison carefully. The prior most people would describe as weakly informative
asserts, before seeing anything, that the model explains more than twice the variance it turns
out to explain. The R2D2 prior set at a plausible 0.3 sits below the eventual answer and leaves
room for it, which is what a prior is supposed to do.

## 2. The check: the prior distribution of R²

Fit the model with the likelihood switched off, then form R² from the prior draws.

**`bayes_R2()` cannot be used for this, and the failure is silent.** It forms residuals against
the *observed* outcome, so on a prior-only fit the fitted values are enormous relative to the
data, the residual variance tracks them almost exactly, and the ratio is pulled towards 0.5. On the
20-predictor model above it reports a prior median R² of 0.49 with a 90% interval of 0.46 to
0.51 – a reassuring and entirely artefactual answer.

The pull towards 0.5 needs its condition stated, because the number it returns is not always
near 0.5 and a reader who sees 0.04 should not conclude the artefact is absent. It happens when
the prior-implied fitted values are large relative to the observed outcome, which is exactly the
case you are worried about. Under `normal(0, 0.05)` slopes the same call returns 0.02 to 0.07,
while the variance-component computation for that same fit gives a median of 0.08 with a 95th
percentile of 0.93.
The two disagree in both directions, so the instruction is unconditional even though the
symptom is not: compute the ratio from the model's own variance components instead.

```r
library(brms)
library(posterior)

priors_wide <- c(
  prior(normal(0, 1), class = "Intercept"),
  prior(normal(0, 1), class = "b"),
  prior(exponential(1), class = "sigma")
)

# sample_prior = "only" ignores the likelihood; the fit is the prior, expressed as a model
fit_prior <- brm(
  outcome ~ x1 + x2 + x3 + x4 + x5,
  data = d, family = gaussian(), prior = priors_wide,
  sample_prior = "only", chains = 2, iter = 2000,
  seed = 20260826, backend = "cmdstanr", refresh = 0
)

# variance of the linear predictor across cases, per draw, against the residual variance
mu_prior  <- posterior_epred(fit_prior)
sigma_pr  <- as_draws_df(fit_prior)$sigma
var_mu    <- apply(mu_prior, 1, var)
r2_prior  <- var_mu / (var_mu + sigma_pr^2)

quantile(r2_prior, c(0.05, 0.5, 0.95))
```

Read the median and the lower tail. If the prior median sits at 0.9 in a literature where
published models reach 0.2, the priors are making a claim nobody would defend out loud. Set
the prior on R² directly (section 3) rather than searching for a coefficient scale that
happens to work, because the scale that works depends on how many predictors you have and will
stop working the moment you add one.

The same check works for any derived quantity, and for a quantity of interest it is more
informative than R²:

```r
# prior-implied distribution of a predicted probability at a set covariate profile
newd <- datagrid(model = fit_prior, x1 = 0, x2 = c(-1, 1))
posterior_epred(fit_prior, newdata = newd) |> apply(2, quantile, c(0.05, 0.5, 0.95))
```

## 3. Setting the prior on R² instead

`brms` implements the R2D2 prior, which puts a beta prior on R² and derives the joint prior on
the coefficients from it, distributing the implied variance across predictors. It solves the
problem in section 1 at its source rather than by trial and error on individual scales.

```r
priors_r2d2 <- c(
  prior(R2D2(mean_R2 = 0.25, prec_R2 = 2), class = "b"),
  prior(normal(0, 1), class = "Intercept"),
  prior(exponential(1), class = "sigma")
)
```

`mean_R2` is where you expect the proportion of explained variance to sit, and `prec_R2`
governs how tightly. Both are quantities an applied reader can argue with, which is the point:
a reviewer can dispute "we expected this model to explain about a quarter of the variance" in
a way they cannot dispute `normal(0, 0.5)`.

For genuinely sparse problems – many candidate predictors, few expected to matter – the
regularised horseshoe is the alternative, `prior(horseshoe(df = 1, par_ratio = 0.1), class = "b")`.
Set `par_ratio` to the fraction of coefficients you expect to be non-negligible.

## 4. Prior predictive simulation

Simulating outcomes from the prior asks a blunter question than R² does: are the outcomes this
model considers possible actually possible?

```r
pp_check(fit_prior, ndraws = 100)                    # continuous outcome
pp_check(fit_prior, type = "bars", ndraws = 100)     # discrete or binary
pp_check(fit_prior, type = "stat", stat = "sd")      # is the implied spread plausible?
```

For a logistic model, check on the probability scale rather than the log-odds scale. A
`normal(0, 10)` prior on log-odds is not vague: it puts most of its mass within a hair of 0 and
1, which is a strong claim that the outcome is nearly deterministic.

```r
posterior_epred(fit_prior) |> as.vector() |> hist(breaks = 50)
```

## 5. When to run the prior predictive check

Not always first. If the sample is large and the likelihood dominates, an implausible prior
predictive distribution may have no consequence for the posterior at all, and time spent
tuning it is time wasted.

The ordering that makes sense in practice:

- **Before data collection, or when designing the model** – prior predictive simulation is the
  right tool, because there is no likelihood to defer to and the prior is the whole model.
- **With data in hand and a large sample** – run the power-scaling sensitivity analysis first
  (`reference/sensitivity.md`). If the posterior is insensitive to the prior, the prior
  predictive distribution is a curiosity rather than a problem.
- **With data in hand and a small sample, or parameters the data barely inform** – run both.
  This is the case where the prior does real work and the objection that the prior drove the
  result is the one a reviewer will actually raise.

## 6. Scale parameters, and one reparameterisation trap

Half-normal, exponential or `student_t(3, 0, s)` for standard deviations and for `sigma`.
`brms` constrains them to be positive, so the prior is automatically truncated.

The trap: when expanding a normal likelihood to a Student t likelihood for outlier
robustness, the prior on `sigma` no longer means what it meant. For a t distribution with
ν degrees of freedom the variance is ν/(ν − 2) times σ², so with small ν the parameter σ is
no longer close to the residual standard deviation. A prior carried over unchanged from the
normal model is tighter, or looser, than intended. Re-examine it whenever the family changes.

## 7. Recording the decision

Whatever you settle on, the workflow log entry needs the reasoning, not the syntax. "Slope
priors `normal(0, 0.5)`; implied prior median R² 0.31, 95th percentile 0.68, which brackets
the 0.2 to 0.4 range reported in this literature" is a sentence that survives peer review.
"Weakly informative priors were used" is not.

---

Source for the underlying argument: Gelman, Vehtari, McElreath et al., *Bayesian Workflow*
(CRC Press, 2026), chapter 5 on building models and chapter 8 section 5 on the influence of
likelihood and prior information. The R2D2 prior is due to Zhang and colleagues and to
Aguilar and Bürkner; see `reference/book-map.md` for the pointers.
