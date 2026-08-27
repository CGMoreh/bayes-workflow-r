# Calibrating the design by simulation

Two different questions, both answered by simulating data from a model you control and refitting.

**Design calibration** asks whether this design, at this sample size, can recover an effect of
the size you expect. It is the Bayesian analogue of a power calculation, and it is the check
that converts "the credible interval excludes zero" into a statement about what the design was
capable of detecting in the first place.

**Simulation-based calibration** asks whether the inference machinery is correct: whether the
posterior, averaged over data simulated from the prior, reproduces the prior. It tests the model
and the sampler rather than the design.

---

## Design calibration: can this study recover this effect?

Simulate at the sample size and structure you actually have, with an effect of the size the
literature or theory suggests, refit, and count how often the analysis recovers it.

```r
library(brms)
library(purrr)
library(dplyr)

set.seed(20260826)

simulate_once <- function(i, n = 32, beta = 0.5, fit_template) {
  d_sim <- tibble(
    x = rnorm(n),
    y = rbinom(n, 1, plogis(-0.2 + beta * x))
  )
  fit_sim <- update(fit_template, newdata = d_sim, refresh = 0, silent = 2)
  draws <- as_draws_df(fit_sim)$b_x
  tibble(
    iteration = i,
    median    = median(draws),
    lower     = quantile(draws, 0.055),
    upper     = quantile(draws, 0.945),
    pd        = mean(draws > 0),
    covers    = lower <= beta & beta <= upper,
    excludes0 = lower > 0 | upper < 0
  )
}

results <- map(1:200, simulate_once, fit_template = fit_template) |> list_rbind()

results |>
  summarise(
    recovery_rate = mean(excludes0),          # how often the design detects the effect
    coverage      = mean(covers),             # does the interval cover the truth as advertised
    median_bias   = mean(median) - 0.5,     # subtract the beta simulated above
    type_s        = mean(median < 0)        # sign errors; truth is positive here
  )
```

Read three numbers, and the last two matter more than the first.

- **Recovery rate.** If simulating the effect you expect recovers it 30% of the time, a null
  result in the real data says almost nothing, and the paper should say so.
- **Coverage.** Should be close to the nominal level. Systematic under-coverage points at a
  model or prior problem.
- **Sign error rate.** At small samples, conditioning on having found a detectable effect can
  produce estimates that are exaggerated and sometimes of the wrong sign. Reporting how often
  the simulation gets the sign wrong is more informative than any power figure.

Use the same priors as the real analysis. Simulating with flat priors and fitting the real model
answers a question nobody asked.

`update()` with `newdata` reuses the compiled Stan model, which is what makes a few hundred
refits feasible. Compile once and pass the fitted template in.

## Simulation-based calibration

Draw parameters from the prior, simulate data from them, fit, and record where the true value
falls in the posterior. Over many replications the ranks should be uniform. Departures diagnose
a mis-specified model, a bug in the likelihood, or a sampler failing on this geometry.

`SBC_backend_brms_from_generator()` requires a generator built by `SBC_generator_brms()`, which
takes the formula, a template dataset and the priors, and generates by sampling the model with
`sample_prior = "only"` internally. Passing it a generator built from a plain simulation
function fails its `stopifnot`, because the two are different classes.

```r
# remotes::install_github("hyunjimoon/SBC") - optional, not a dependency of this skill
library(SBC)

# d_template supplies the predictors and the data shape; its outcome column is ignored
gen <- SBC_generator_brms(
  y ~ x + (1 | g), data = d_template, family = gaussian(),
  prior = priors,
  thin = 50, warmup = 10000, refresh = 2000
)

ds  <- generate_datasets(gen, n_sims = 200)
bck <- SBC_backend_brms_from_generator(gen, chains = 2, iter = 2000, warmup = 1000)
res <- compute_SBC(ds, bck)

plot_rank_hist(res)
plot_ecdf_diff(res)
```

The `thin` and `warmup` arguments to the generator matter: the prior draws it produces must be
close to independent, or the rank statistics are not uniform even when the model is correct.

**This block is written against the package source rather than run.** `SBC` is not installed as
a dependency of this plugin and this path is not exercised by its eval suite, unlike every other
piece of code here. Check it against the package's own vignettes before relying on it.

Non-uniform ranks with a characteristic shape are informative: a U shape means the posterior is
too narrow, a hump in the middle that it is too wide, and a slope that the posterior is biased.

SBC is worth the cost for a model class you will reuse – a measurement model, a custom
likelihood, a structure you plan to apply across several papers. For a single one-off regression
it is usually not.

## Where these fit in the workflow

Design calibration belongs early, before the real analysis if possible, because it can tell you
the study cannot answer the question and that is better learned before the analysis than after.
It belongs in the methods section, not the appendix, whenever the sample is small.

Simulation-based calibration belongs to model development, and its natural home is a supplement.

---

Source: Gelman, Vehtari, McElreath et al., *Bayesian Workflow* (CRC Press, 2026), chapters 6 and
14, and the case studies on coding a series of models and on simulation-based calibration
checking. See `reference/book-map.md`.
