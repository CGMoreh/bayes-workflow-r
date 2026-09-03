################################################################################
# Title:      Prior predictive checking, including what the priors imply about
#             explained variance
# Purpose:    Refit a model with the likelihood switched off and report what the
#             priors claim before any data are used
# Sourced by: bayes-workflow-r skill; call bw_prior_check(fit)
# Author:     Chris Moreh
# Last updated: 2026-08-27
################################################################################

# bayes_R2() cannot be used on a prior-only fit: it forms residuals against the
# observed outcome, so the quantity is contaminated by data the prior never saw.
# Where the prior-implied fitted values are large relative to the outcome it is
# pulled towards 0.5; where they are small it is pulled low. Either way it is not
# the prior R-squared. That is formed from the model's own variance components.
#
# The residual term comes from sigma where the family has one, and otherwise from
# the spread of the predictive draws around their expectation, which generalises
# the quantity to binary, count and other families rather than skipping them.
#
# For a model with group-level terms this is a CONDITIONAL R-squared: the varying
# effects are part of the linear predictor. A high conditional median can be
# perfectly correct - on a repeated-measures design where subjects differ a lot,
# the posterior conditional R-squared may itself be near 0.8 - so the median alone
# is not a fault. What cannot be defended is an upper tail at 1.00, which says the
# model might explain everything, and usually traces to a prior on a variance
# component that admits a residual standard deviation no real measurement has.

bw_prior_check <- function(fit, newdata = NULL, chains = 2, iter = 2000,
                           seed = 20260826, tail_max = 0.95, median_max = 0.7, ...) {

  stopifnot(inherits(fit, "brmsfit"))
  requireNamespace("posterior", quietly = TRUE)

  fam <- bw_family_name(fit)
  if (is.na(fam)) {
    stop("this fit has more than one response family (a multivariate model). ",
         "Run bw_prior_check() on each response separately, or check the priors ",
         "with pp_check(..., resp = ) per response.", call. = FALSE)
  }

  fit_prior <- stats::update(
    fit, sample_prior = "only", chains = chains, iter = iter,
    seed = seed, refresh = 0, silent = 2
  )

  mu    <- brms::posterior_epred(fit_prior, newdata = newdata, ...)
  draws <- posterior::as_draws_df(fit_prior)
  has_re <- length(fit$ranef$group) > 0

  cat("\n=== Prior predictive check ===\n")
  cat(sprintf("family: %s%s\n", fam, if (has_re) ", with group-level terms" else ""))

  # posterior_epred() returns draws x observations x category for ordinal,
  # categorical and multinomial fits. A single R-squared is not defined there, and
  # the matrix arithmetic below would either fail or recycle silently.
  if (length(dim(mu)) > 2) {
    cat("implied prior R2                 not defined for this family: posterior_epred()\n")
    cat("  returns one column per category, so there is no single expected value to take\n")
    cat("  the variance of. Check the priors with the implied category probabilities:\n")
    cat("  apply(posterior_epred(fit_prior), 3, mean)  and  pp_check(fit_prior, type = 'bars')\n")
    return(invisible(list(fit_prior = fit_prior, r2 = NULL, epred = mu)))
  }

  yrep <- brms::posterior_predict(fit_prior, newdata = newdata, ...)

  # --- are the priors on the outcome's scale at all?
  # Read before anything else. A prior whose predictive median sits a hundred
  # times beyond the largest observed value, or a hundredth of the smallest, is
  # almost always a prior chosen on one scale and applied on another: normal(250,
  # 100) on an intercept is a reaction time in milliseconds on an identity link
  # and e^250 on a log link. The book's sleep-study case does exactly this on
  # purpose, and the R2 below cannot see it, so this check has to come first.
  qy <- stats::quantile(as.vector(yrep), c(0.01, 0.5, 0.99), na.rm = TRUE)
  y  <- tryCatch(as.numeric(brms::standata(fit)$Y), error = function(e) NULL)
  off_scale <- FALSE
  scale_ratio <- NA_real_
  if (!is.null(y) && all(is.finite(y)) && is.finite(qy[2]) && max(abs(y)) > 0) {
    scale_ratio <- qy[2] / max(abs(y))
    off_scale   <- is.finite(scale_ratio) && (scale_ratio > 100 || scale_ratio < 0.01)
  }

  # --- implied prior on explained variance
  if (off_scale) {
    r2 <- NULL
    cat(sprintf("%-32s not read: the priors sit off the outcome's scale, see below\n",
                "implied prior R2"))
  } else {
  # sigma is the response-scale residual SD only under an identity link. On a
  # lognormal fit it is the SD of log(y) set against a response-scale mu, and the
  # ratio runs to 1.00 whatever the prior says: on the book's sleep-study case
  # it returned 1.00 for an absurd prior and for the sensible replacement alike.
  # Every other family forms its residual on the response scale from the
  # predictive draws, which is what explained variance means there.
  identity_sigma <- fam %in% c("gaussian", "student") &&
    "sigma" %in% posterior::variables(draws)
  if (identity_sigma) {
    var_res <- draws$sigma^2
    basis   <- "residual scale"
  } else {
    var_res <- apply(yrep - mu, 1, stats::var)
    basis   <- "predictive spread, response scale"
  }
  var_mu <- apply(mu, 1, stats::var)
  r2     <- var_mu / (var_mu + var_res)
  q      <- stats::quantile(r2, c(0.05, 0.5, 0.95), na.rm = TRUE)

  label <- if (has_re) "implied prior R2 (conditional)" else "implied prior R2"
  cat(sprintf("%-32s q05 %.2f | median %.2f | q95 %.2f   [%s]\n",
              label, q[1], q[2], q[3], basis))

  if (q[3] > tail_max) {
    cat("  -> the upper tail admits a model that explains essentially everything.\n",
        "     Find the component that allows it: usually a prior on a scale parameter\n",
        "     with mass near zero, admitting a residual SD the measurement cannot have.\n",
        sep = "")
  }
  if (q[2] > median_max) {
    if (has_re) {
      cat("  -> a high conditional median may be correct where groups genuinely differ,\n",
          "     so compare it against the conditional R2 you expect rather than against\n",
          "     a fixed threshold. Check the group-level SD priors before the slopes.\n",
          sep = "")
    } else {
      cat("  -> the priors claim this model explains most of the variance before seeing\n",
          "     any data. Set the prior on R2 directly with brms::R2D2() rather than\n",
          "     searching for a coefficient scale that happens to work.\n", sep = "")
    }
  }

  }

  # --- what outcomes do the priors consider possible?
  if (fam %in% c("bernoulli", "binomial", "beta_binomial")) {
    # posterior_epred() returns the expected COUNT of successes when the model
    # carries a trials() term, so it cannot be compared against probability
    # thresholds. The inverse-linked linear predictor is on the probability scale
    # for both families.
    prob <- brms::posterior_linpred(fit_prior, newdata = newdata, transform = TRUE, ...)
    rate <- rowMeans(prob)
    qr   <- stats::quantile(rate, c(0.05, 0.5, 0.95))
    cat(sprintf("%-32s q05 %.3g | median %.3g | q95 %.3g\n",
                "implied prior event rate", qr[1], qr[2], qr[3]))
    extreme <- mean(rate < 0.02 | rate > 0.98)
    cat(sprintf("%-32s %.0f%% of draws\n",
                "  rate below .02 or above .98", 100 * extreme))
    if (extreme > 0.2) {
      cat("  -> the priors put substantial mass on a near-certain outcome. On the\n",
          "     log-odds scale a normal(0, 10) prior is not vague: it piles mass at\n",
          "     0 and 1. Tighten the intercept and slope priors, then check again.\n", sep = "")
    }
  } else {
    cat(sprintf("%-32s q01 %.3g | median %.3g | q99 %.3g\n",
                "prior predictive outcome", qy[1], qy[2], qy[3]))
    if (!is.null(y) && all(is.finite(y))) {
      cat(sprintf("%-32s min %.3g | median %.3g | max %.3g\n",
                  "observed outcome", min(y), stats::median(y), max(y)))
    }
    if (off_scale) {
      cat(sprintf("  -> the prior predictive median is 10^%.0f times the largest observed\n",
                  log10(scale_ratio)))
      cat("     value. A prior this far from the outcome's own scale almost always\n",
          "     means its values were chosen on one scale and applied on another:\n",
          "     normal(250, 100) on an intercept is a reaction time on an identity link\n",
          "     and e^250 on a log link. Rewrite the priors on the scale the link puts\n",
          "     them on, then run this check again.\n", sep = "")
    }
    neg <- mean(as.vector(yrep) < 0, na.rm = TRUE)
    if (neg > 0.001) {
      cat(sprintf("%-32s %.1f%% of draws\n", "  outcome below zero", 100 * neg))
      cat("  -> if the outcome cannot be negative, the priors admit what the world\n",
          "     does not, whatever the R2 says.\n", sep = "")
    }
  }

  cat("\nPlots worth drawing next (the prior-only fit is in the returned list):\n")
  cat("  res <- bw_prior_check(fit)\n")
  cat("  pp_check(res$fit_prior, ndraws = 100)\n")
  cat("  pp_check(res$fit_prior, type = 'stat', stat = 'sd')\n")

  invisible(list(fit_prior = fit_prior, r2 = r2, epred = mu, yrep = yrep))
}

# A multivariate brmsfit carries no single top-level family, so fit$family is NULL
# and there is no family string to branch on. NA signals that case to the caller.
bw_family_name <- function(fit) {
  f <- fit$family
  if (is.null(f) || is.null(f$family) || length(f$family) != 1) NA_character_ else f$family
}
if (sys.nframe() == 0L) {
  # Rscript entry: Rscript bw_prior_check.R <fit.rds>. The prior-only refit
  # happens inside, so this recompiles nothing but does sample.
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 1L || identical(args[1], "--help")) {
    cat("usage: Rscript bw_prior_check.R <fit.rds>\n")
    quit(status = 1L)
  }
  if (!file.exists(args[[1]])) {
    cat("not found: ", args[[1]], "\n", sep = "")
    quit(status = 1L)
  }
  suppressMessages(library(brms))
  bw_prior_check(readRDS(args[[1]]))
}
