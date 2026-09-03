################################################################################
# Title:      Dependency contract checks
# Purpose:    Assert every package behaviour the shipped scripts and reference
#             files depend on, so a dependency update that breaks one is caught
#             here rather than by a user mid-analysis
# Reads:      nothing; fits one small model if a Stan backend is available
# Writes:     nothing; exit status 0 if every contract holds, 1 otherwise
# Author:     Chris Moreh
# Last updated: 2026-08-27
################################################################################

# Run locally with:  Rscript tests/dependency-contracts.R
# CI runs it on a schedule against current CRAN versions.
#
# Each contract names the file that depends on it, so a failure points at what
# to fix rather than only at what broke. Contracts come in two tiers: SURFACE
# checks need no fitted model and always run; OBJECT checks reach into a fitted
# brmsfit and are skipped, loudly, where no Stan backend is available.

results <- list()

check <- function(label, depends_on, expr) {
  out <- tryCatch(isTRUE(expr), error = function(e) structure(FALSE, msg = conditionMessage(e)))
  results[[length(results) + 1L]] <<- list(
    label = label, depends_on = depends_on, ok = isTRUE(out),
    msg = if (!isTRUE(out)) attr(out, "msg") %||% "returned FALSE" else ""
  )
  invisible(out)
}

`%||%` <- function(x, y) if (is.null(x)) y else x
has_arg_of <- function(f, a) a %in% names(formals(f))

cat("=== package versions ===\n")
pkgs <- c("brms", "loo", "posterior", "priorsense", "marginaleffects",
          "bayesplot", "projpred", "jsonlite")
for (p in pkgs) {
  v <- tryCatch(as.character(packageVersion(p)), error = function(e) "MISSING")
  cat(sprintf("  %-16s %s\n", p, v))
}

suppressPackageStartupMessages({
  library(brms); library(loo); library(posterior)
})

## ---- surface contracts: no model fit required --------------------------------

check("brms exports R2D2() for the R-squared prior",
      "reference/priors.md",
      is.function(brms::R2D2) && has_arg_of(brms::R2D2, "mean_R2"))

check("brms exports horseshoe() with par_ratio",
      "reference/priors.md",
      is.function(brms::horseshoe) && has_arg_of(brms::horseshoe, "par_ratio"))

check("loo exports kfold_split_grouped() for leave-one-group-out",
      "scripts/bw_loo_report.R, reference/comparison.md",
      is.function(loo::kfold_split_grouped))

check("priorsense::powerscale() still defaults resample to FALSE",
      "reference/sensitivity.md (the warning about hand-rolled alpha loops)",
      {
        f <- formals(priorsense:::powerscale.default)
        "resample" %in% names(f) && isFALSE(eval(f$resample))
      })

check("priorsense exports predictions_as_draws() taking a predict_fn",
      "scripts/bw_sensitivity.R, reference/reviewer-responses.md",
      has_arg_of(priorsense::predictions_as_draws, "predict_fn"))

check("priorsense exports create_priorsense_data() taking a fit",
      "scripts/bw_sensitivity.R",
      has_arg_of(priorsense:::create_priorsense_data.default, "fit"))

check("powerscale_sensitivity() still defaults k_threshold to 0.5",
      "reference/sensitivity.md (quotes the 0.5 default)",
      isTRUE(all.equal(formals(priorsense:::powerscale_sensitivity.priorsense_data)$k_threshold, 0.5)))

check("brms family constructors used in families.md still build",
      "reference/families.md",
      all(vapply(list(brms::zero_inflated_negbinomial(), brms::hurdle_poisson(),
                      brms::zero_one_inflated_beta(), brms::cumulative("probit"),
                      brms::acat(), brms::lognormal()),
                 \(f) inherits(f, "brmsfamily") || inherits(f, "family"), logical(1))))

check("brms response terms cens/trunc/weights/trials still parse",
      "reference/families.md",
      all(vapply(list(bf(y | cens(c) ~ x), bf(y | trunc(lb = 0) ~ x),
                      bf(y | weights(w) ~ x), bf(y | trials(n) ~ x)),
                 \(f) inherits(f, "brmsformula"), logical(1))))

check("brms distributional and category-specific syntax still parse",
      "reference/families.md",
      inherits(bf(y ~ x, sigma ~ x), "brmsformula") &&
      inherits(bf(y ~ x + cs(z)), "brmsformula"))

check("marginaleffects accepts hypothesis = ~pairwise",
      "reference/contrasts.md",
      has_arg_of(marginaleffects::avg_comparisons, "hypothesis"))

check("marginaleffects exports get_draws()",
      "reference/contrasts.md, reference/reviewer-responses.md",
      is.function(marginaleffects::get_draws))

check("projpred cv_varsel() still takes validate_search, nterms_max and nloo",
      "reference/comparison.md (the two-pass projpred recipe)",
      all(vapply(c("validate_search", "nterms_max", "nloo"), \(a)
                 has_arg_of(projpred:::cv_varsel.refmodel, a), logical(1))))

check("projpred cv_varsel() still defaults validate_search to TRUE",
      "reference/comparison.md, which tells the reader the default is the one to keep",
      isTRUE(formals(projpred:::cv_varsel.refmodel)$validate_search))

check("projpred ranking() takes nterms_max, and cv_proportions() exists",
      "reference/comparison.md (the fold-stability table)",
      has_arg_of(projpred:::ranking.vsel, "nterms_max") &&
        is.function(projpred::cv_proportions))

check("bayesplot ppc_bars() still refuses continuous yrep",
      "reference/families.md (the rounding caveat)",
      inherits(tryCatch(bayesplot::ppc_bars(c(1, 2, 3), matrix(rnorm(9), 3)),
                        error = function(e) e), "error"))

## ---- object contracts: need one fitted model ---------------------------------

backend <- if (requireNamespace("cmdstanr", quietly = TRUE) &&
               !is.null(tryCatch(cmdstanr::cmdstan_version(), error = function(e) NULL))) {
  "cmdstanr"
} else if (requireNamespace("rstan", quietly = TRUE)) "rstan" else NA_character_

if (is.na(backend)) {
  cat("\n!! no Stan backend available: object contracts SKIPPED, not passed\n")
} else {
  cat(sprintf("\n=== fitting one small model (%s backend) ===\n", backend))
  set.seed(1)
  d <- data.frame(y = rnorm(40), x = rnorm(40), g = rep(letters[1:4], each = 10))
  fit <- brm(y ~ x + (1 | g), data = d, chains = 2, iter = 600, refresh = 0,
             silent = 2, backend = backend,
             control = list(adapt_delta = 0.9, max_treedepth = 11))
  # explicit priors: brms's default on class "b" is improper, so a prior-only
  # refit of a default-prior model is refused - a fact reference/priors.md relies on
  pr2 <- c(prior(normal(0, 1), class = "b"),
           prior(normal(0, 1), class = "Intercept"),
           prior(exponential(1), class = "sigma"))
  fit2 <- brm(y ~ x, data = d, prior = pr2, chains = 2, iter = 600, refresh = 0,
              silent = 2, backend = backend)

  check("fit$fit carries S4 stan_args with the control list",
        "scripts/bw_diagnose.R (adapt_delta and max_treedepth readers)",
        {
          ctl <- fit$fit@stan_args[[1]]$control
          isTRUE(ctl$adapt_delta == 0.9) && isTRUE(ctl$max_treedepth == 11)
        })

  check("brms::nuts_params() returns divergent__ and treedepth__",
        "scripts/bw_diagnose.R",
        all(c("divergent__", "treedepth__") %in% unique(brms::nuts_params(fit)$Parameter)))

  check("fit$ranef$group identifies grouping terms",
        "scripts/bw_prior_check.R",
        length(fit$ranef$group) > 0 && length(fit2$ranef$group) == 0)

  check("fit$family$family is a single string for a univariate fit",
        "scripts/bw_prior_check.R (multivariate detection)",
        length(fit$family$family) == 1L)

  check("rownames(fit$data) preserves the source row labels",
        "scripts/bw_loo_report.R (same-observations guard)",
        identical(rownames(fit$data), rownames(d)))

  check("add_criterion() stores the criterion at fit$criteria$loo",
        "scripts/bw_loo_report.R",
        !is.null(brms::add_criterion(fit, "loo")$criteria$loo))

  check("standata()$Y agrees across families fitted to the same rows where yhash does not",
        "scripts/bw_loo_report.R (the same-observations guard compares Y, not loo's yhash)",
        {
          # the behaviour the guard depends on: a gaussian and a beta-binomial fit of
          # the same counts carry the same Y and different yhashes, so the hash would
          # refuse a legitimate comparison and Y does not
          set.seed(41)
          dk <- data.frame(y = rbinom(60, 20, 0.3), n = 20, x = rnorm(60))
          fg <- brm(y ~ x, data = dk, chains = 1, iter = 400, refresh = 0,
                    silent = 2, backend = backend)
          fb <- brm(y | trials(n) ~ x, data = dk, family = beta_binomial(), chains = 1,
                    iter = 400, refresh = 0, silent = 2, backend = backend)
          same_y <- isTRUE(all.equal(as.numeric(brms::standata(fg)$Y),
                                     as.numeric(brms::standata(fb)$Y)))
          hg <- attr(loo(fg), "yhash"); hb <- attr(loo(fb), "yhash")
          same_y && !identical(hg, hb)
        })

  check("loo_compare() errors on differing observation counts",
        "reference/comparison.md (the guard table)",
        {
          small <- brm(y ~ x, data = d[1:30, ], prior = pr2, chains = 1, iter = 400,
                       refresh = 0, silent = 2, backend = backend)
          inherits(tryCatch(loo_compare(loo(fit2), loo(small)),
                            error = function(e) e), "error")
        })

  check("bayes_R2() on a prior-only fit is contaminated, not the prior R2",
        "reference/priors.md (the central warning and its numbers)",
        {
          # the documented case: several predictors under a wide prior, where the
          # prior-implied fitted values dominate the observed outcome
          set.seed(2); k <- 8
          X  <- matrix(rnorm(40 * k), 40, k, dimnames = list(NULL, paste0("x", 1:k)))
          dk <- data.frame(y = rnorm(40), X)
          fk <- as.formula(paste("y ~", paste(paste0("x", 1:k), collapse = " + ")))
          prk <- c(prior(normal(0, 1), class = "b"),
                   prior(normal(0, 1), class = "Intercept"),
                   prior(exponential(1), class = "sigma"))
          fp <- brm(fk, data = dk, prior = prk, sample_prior = "only", chains = 1,
                    iter = 600, refresh = 0, silent = 2, backend = backend)
          br <- median(brms::bayes_R2(fp, summary = FALSE)[, 1])
          mu <- brms::posterior_epred(fp); sg <- as_draws_df(fp)$sigma
          vm <- apply(mu, 1, var)
          true_r2 <- median(vm / (vm + sg^2))
          # the artefact: bayes_R2 sits near 0.5 while the prior actually claims far more
          abs(br - 0.5) < 0.15 && true_r2 > br + 0.3
        })

  check("standata()$prior_only still marks a prior-only fit",
        "scripts/bw_loo_report.R (bw_is_prior_only, which refuses the optimism check)",
        {
          set.seed(3)
          dk <- data.frame(y = rnorm(30), x = rnorm(30))
          prk <- c(prior(normal(0, 1), class = "b"), prior(normal(0, 1), class = "Intercept"),
                   prior(exponential(1), class = "sigma"))
          fp <- brm(y ~ x, data = dk, prior = prk, sample_prior = "only", chains = 1,
                    iter = 400, refresh = 0, silent = 2, backend = backend)
          fq <- brm(y ~ x, data = dk, prior = prk, chains = 1, iter = 400,
                    refresh = 0, silent = 2, backend = backend)
          as.integer(brms::standata(fp)$prior_only) == 1L &&
            as.integer(brms::standata(fq)$prior_only) == 0L
        })

  check("bayes_R2() stays on the response scale for a non-identity family",
        "scripts/bw_loo_report.R (the optimism section, which must not mix scales)",
        {
          # var(mu)/(var(mu) + sigma^2) is only the response-scale R2 when sigma
          # is stored on the response scale. For lognormal it is not, and the
          # ratio runs far above the true figure - the bug this contract guards.
          set.seed(4)
          dk <- data.frame(x = rnorm(120))
          dk$y <- rlnorm(120, meanlog = 1 + 0.3 * dk$x, sdlog = 0.5)
          fl <- brm(y ~ x, data = dk, family = lognormal(), chains = 1, iter = 800,
                    refresh = 0, silent = 2, backend = backend)
          br <- median(brms::bayes_R2(fl, summary = FALSE)[, 1])
          lr <- median(brms::loo_R2(fl, summary = FALSE)[, 1])
          mu <- brms::posterior_epred(fl); sg <- as_draws_df(fl)$sigma
          vm <- apply(mu, 1, var)
          mixed <- median(vm / (vm + sg^2))
          # bayes_R2 tracks loo_R2; the scale-mixing ratio does not
          abs(br - lr) < 0.15 && mixed > br + 0.3
        })

  check("brms default prior on class b is improper (blocks sample_prior = only)",
        "reference/priors.md, tests/dependency-contracts.R fixtures",
        inherits(tryCatch(update(brm(y ~ x, data = d, chains = 1, iter = 200,
                                     refresh = 0, silent = 2, backend = backend),
                                 sample_prior = "only", chains = 1, iter = 200,
                                 refresh = 0, silent = 2),
                          error = function(e) e), "error"))

  check("loo_compare()'s se_diff is sqrt(n) times the sd of the pointwise differences",
        "scripts/bw_loo_report.R and reference/comparison.md (the leave-out probability check)",
        {
          set.seed(21)
          dk <- data.frame(x = rnorm(80), z = rnorm(80))
          dk$y <- rnorm(80, 0.5 * dk$x)
          f1 <- brm(y ~ x, data = dk, chains = 1, iter = 800, refresh = 0,
                    silent = 2, backend = backend)
          f2 <- brm(y ~ x + z, data = dk, chains = 1, iter = 800, refresh = 0,
                    silent = 2, backend = backend)
          l1 <- loo(f1); l2 <- loo(f2)
          cp <- loo::loo_compare(list(a = l1, b = l2))
          pw <- l1$pointwise[, "elpd_loo"] - l2$pointwise[, "elpd_loo"]
          abs(cp[2, "se_diff"] - sqrt(length(pw)) * sd(pw)) < 1e-6
        })

  check("on a lognormal fit, sigma is the spread of log(y), not of y",
        "scripts/bw_prior_check.R (the residual-scale branch of the implied R2)",
        {
          # the behaviour the branch depends on: sigma tracks the per-draw SD of
          # log(yrep) and sits nowhere near the SD of yrep itself, so using it as a
          # response-scale residual sends the R2 to 1.00 regardless of the prior
          set.seed(31)
          dk <- data.frame(x = rnorm(100))
          dk$y <- rlnorm(100, meanlog = 5 + 0.2 * dk$x, sdlog = 0.3)
          fl <- brm(y ~ x, data = dk, family = lognormal(), chains = 1, iter = 800,
                    refresh = 0, silent = 2, backend = backend)
          sg <- median(as_draws_df(fl)$sigma)
          yr <- brms::posterior_predict(fl, ndraws = 200)
          sd_log <- median(apply(log(yr), 1, sd))
          sd_raw <- median(apply(yr, 1, sd))
          abs(sg - sd_log) / sd_log < 0.25 && sd_raw / sg > 20
        })

  check("standata()$Y returns the outcome of a univariate fit",
        "scripts/bw_prior_check.R (the outcome-scale check against observed data)",
        {
          set.seed(32)
          dk <- data.frame(y = rnorm(40, 10), x = rnorm(40))
          fy <- brm(y ~ x, data = dk, chains = 1, iter = 400, refresh = 0,
                    silent = 2, backend = backend)
          Y <- brms::standata(fy)$Y
          length(Y) == 40L && isTRUE(all.equal(as.numeric(Y), dk$y))
        })

  check("a loo object carries p_loo in $estimates and one pareto_k per observation",
        "scripts/bw_loo_report.R (the effective-parameters section and the k counts)",
        {
          set.seed(11)
          dk <- data.frame(x = rnorm(60))
          dk$y <- rpois(60, exp(0.5 + 0.3 * dk$x))
          fk <- brm(y ~ x, data = dk, family = poisson(), chains = 1, iter = 600,
                    refresh = 0, silent = 2, backend = backend)
          lk <- loo(fk)
          "p_loo" %in% rownames(lk$estimates) &&
            "Estimate" %in% colnames(lk$estimates) &&
            length(lk$diagnostics$pareto_k) == nrow(dk)
        })

  check("brms::variables() counts parameters the way bw_n_parameters() assumes",
        "scripts/bw_loo_report.R (bw_n_parameters, which p_loo is read against)",
        {
          # the filter drops lp__, lprior, the centred Intercept and the raw z_/L_
          # group effects; what is left is the count a chapter would quote - here
          # an intercept, one slope and one varying intercept per group
          set.seed(12)
          dk <- data.frame(g = factor(rep(1:8, each = 5)), x = rnorm(40))
          dk$y <- rnorm(40, 0.4 * dk$x)
          fv <- brm(y ~ x + (1 | g), data = dk, chains = 1, iter = 600,
                    refresh = 0, silent = 2, backend = backend)
          v <- brms::variables(fv)
          n <- length(v[!grepl("^(lp__|lprior|z_|L_|Lrescor|Intercept)", v)])
          # b_Intercept, b_x, sd_g__Intercept, sigma, 8 x r_g
          n == 12L
        })

  check("loo_R2() can collapse onto a single bound on an overdispersed count",
        "scripts/bw_loo_report.R (the optimism section, which must refuse it)",
        {
          # the behaviour the refusal guards: where the leave-one-out residual
          # variance exceeds the variance of the outcome, the draws pile up on a
          # bound and the median is not a value to subtract anything from
          set.seed(13)
          dk <- data.frame(x = rnorm(80))
          dk$y <- rnbinom(80, mu = exp(1 + 0.2 * dk$x), size = 0.15)
          fo <- brm(y ~ x, data = dk, family = negbinomial(), chains = 1,
                    iter = 800, refresh = 0, silent = 2, backend = backend)
          rr <- suppressWarnings(brms::loo_R2(fo, summary = FALSE)[, 1])
          is.numeric(rr) && length(rr) > 100 &&
            (mean(rr <= min(rr) + 1e-9) > 0.5 || median(rr) <= 0)
        })

  check("posterior_linpred(transform = TRUE) gives the probability scale",
        "scripts/bw_prior_check.R (binomial event rate)",
        {
          db <- data.frame(k = rbinom(40, 10, 0.4), n = 10, x = rnorm(40))
          fb <- brm(k | trials(n) ~ x, data = db, family = binomial(),
                    chains = 1, iter = 400, refresh = 0, silent = 2, backend = backend)
          p <- brms::posterior_linpred(fb, transform = TRUE)
          e <- brms::posterior_epred(fb)
          all(p >= 0 & p <= 1) && max(e) > 1
        })
}

## ---- report ------------------------------------------------------------------

cat("\n=== contracts ===\n")
failed <- Filter(\(r) !r$ok, results)
for (r in results) {
  cat(sprintf("  %-4s %s\n", if (r$ok) "OK" else "FAIL", r$label))
  if (!r$ok) cat(sprintf("       depends on: %s\n       %s\n", r$depends_on, r$msg))
}
cat(sprintf("\n%d of %d contracts hold\n", length(results) - length(failed), length(results)))

if (length(failed)) {
  cat("\nA failing contract means a dependency changed under the plugin. Fix the file\n")
  cat("named beside it, then update the version note in MAINTENANCE.md.\n")
  quit(status = 1L)
}
