# Maintenance

What can break these skills, how you find out, and what to do about it.

## Tested against

| Package | Version | Source |
|---|---|---|
| R | 4.6.0 | |
| brms | 2.23.0 | CRAN |
| cmdstanr | 0.9.0 | stan-dev.r-universe.dev |
| rstan | 2.32.7 | CRAN |
| loo | 2.9.0 | CRAN |
| posterior | 1.7.1 | CRAN |
| priorsense | 1.2.0 | CRAN |
| projpred | 2.10.0 | CRAN |
| bayesplot | 1.15.0 | CRAN |
| marginaleffects | 0.32.0 | CRAN |
| tidybayes | 3.0.7 | CRAN |
| jsonlite | 2.0.0 | CRAN |

```markdown
| Package         | Version | Source                  |
|-----------------|---------|-------------------------|
| R               | 4.6.0   |                         |
| brms            | 2.23.0  | CRAN                    |
| cmdstanr        | 0.9.0   | stan-dev.r-universe.dev |
| rstan           | 2.32.7  | CRAN                    |
| loo             | 2.9.0   | CRAN                    |
| posterior       | 1.7.1   | CRAN                    |
| priorsense      | 1.2.0   | CRAN                    |
| projpred        | 2.10.0  | CRAN                    |
| bayesplot       | 1.15.0  | CRAN                    |
| marginaleffects | 0.32.0  | CRAN                    |
| tidybayes       | 3.0.7   | CRAN                    |
| jsonlite        | 2.0.0   | CRAN                    |

: Versions the contract checks last passed against. Update after a green run on newer ones.
```

These are the versions the contract checks last passed against, not a floor and not a
ceiling. Nothing here pins a user's library, and nothing should: the skills run inside
someone else's analysis project, against whatever they already have installed, and a plugin
that demanded particular versions of brms would be unusable for the person whose paper
depends on a newer one.

## How breakage is detected

`tests/dependency-contracts.R` asserts every package behaviour the skills depend on, and
names the file that depends on each one. Run it any time:

```bash
Rscript tests/dependency-contracts.R
```

It has two tiers. Surface contracts check that functions exist with the arguments the
reference files use, and need no model. Object contracts fit one small model and reach into
it, checking the structures the scripts read. With no Stan backend available the object tier
is skipped loudly rather than counted as passing.

`.github/workflows/dependency-contracts.yml` runs the same file against current CRAN on the
first of each month, on any push that touches a script or the contracts themselves, and on
demand. A scheduled failure opens an issue labelled `dependencies` naming the failing
contract. Monthly is deliberate: these packages move on a scale of months, and a nightly job
would mostly spend minutes confirming silence.

## What is most likely to break, and why

The scripts reach into package internals in a few places. These are the fragile points, in
rough order of risk:

- **`fit$fit@stan_args[[1]]$control`** in `bw_diagnose.R`, for `adapt_delta` and
  `max_treedepth`. An rstan S4 slot that brms populates whatever the backend, and an internal
  structure rather than a documented interface. Already guarded: `bw_stan_control()` catches
  a read failure, says which setting it could not read and under which brms version, assumes
  the Stan default, and carries on. A layout change costs one line of context, not the
  diagnosis.
- **`priorsense::predictions_as_draws()` and `create_priorsense_data()`** in
  `bw_sensitivity.R`. priorsense is the youngest dependency here and the most likely to
  change signatures.
- **`attr(loo_object, "yhash")`** in `bw_loo_report.R`, the second layer of the
  same-observations guard. An undocumented attribute; if it disappears the row-name check
  still stands and only the equal-size-different-rows case reopens.
- **`fit$ranef$group`, `fit$family$family`, `rownames(fit$data)`, `fit$criteria$loo`** across
  the scripts. Stable across recent brms versions, but all internal.
- **`marginaleffects` `hypothesis` syntax** in `reference/contrasts.md`. This interface has
  changed before, and the contrast-of-contrasts recipe depends on it.

- **`loo_R2()` collapsing onto a bound** on an overdispersed count, which `bw_loo_report.R`
  now refuses rather than reads as an optimism gap. The refusal depends on that collapse
  being detectable as a pile-up of draws at one value; a future brms that clamps or warns
  differently would change what the guard sees. Contract: "loo_R2() can collapse onto a
  single bound on an overdispersed count".
- **`priorsense::powerscale(resample = FALSE)` as the default**, which `reference/sensitivity.md`
  warns about for hand-written alpha loops. If priorsense changes the default the warning
  becomes wrong rather than the code. Contract: "powerscale() still defaults resample to FALSE".
- **`brms::standata(fit)$Y`** in `bw_prior_check.R`, for the observed outcome the prior
  predictive is read against. Stan data is an internal layout. Contract: "standata()$Y returns
  the outcome of a univariate fit".
- **`se_diff` being `sqrt(n) * sd(pointwise difference)`**, which the leave-out probability
  check in `bw_loo_report.R` recomputes for itself. Contract: "loo_compare()'s se_diff is sqrt(n)
  times the sd of the pointwise differences".
- **`brms::variables()` naming** – `lp__`, `lprior`, `z_`, `L_`, the centred `Intercept` – which
  `bw_n_parameters()` filters to count parameters. A renamed internal would miscount. Contract:
  "brms::variables() counts parameters the way bw_n_parameters() assumes".
- **`sigma` on the log scale for a lognormal fit**, which is why `bw_prior_check.R` forms its
  residual from the predictive draws for every family without an identity link. Contract: "on a
  lognormal fit, sigma is the spread of log(y), not of y".

## What silent drift looks like

Code breaking is the easy case: it errors, and the contracts catch it. The harder failure is
a reference file quietly becoming wrong while every script still runs, because an agent will
read it and tell a user something that used to be true.

Several contracts exist for that reason rather than for the code: that `bayes_R2()` on a
prior-only fit really is contaminated, that `loo_compare()` really does error on differing
observation counts, that `ppc_bars()` really does refuse continuous draws, that
`powerscale_sensitivity()` really does default its Pareto k threshold to 0.5, and that brms's
default prior on `class = "b"` really is improper. Each of those is a claim a reference file
makes in prose. If one starts failing, the fix is a sentence, not a line of code.

## When a contract fails

1. Read the failure: it names the contract and the file that depends on it.
2. Fix that file. A signature change usually means new code; a behaviour change usually means
   revised prose.
3. Re-run the contracts locally until green.
4. Update the version table above, and add a contract for whatever the change taught you.

## What is deliberately not here

**No renv lockfile, and no pinned versions.** renv isolates one project's library, which is
exactly right for an analysis and exactly wrong for a plugin that runs inside somebody else's
analysis. The version table records what was tested; the contracts tell you when that record
has gone stale; the guards keep a script useful in between. That is the whole mechanism, and
it is the most a tool in this position can offer without claiming a stability it does not
have.

**No test of the skills' own quality here.** That lives in `evals/`, which measures whether
the instructions produce good work rather than whether the code still runs. The two answer
different questions and are worth keeping apart.
