################################################################################
# Title:      Computational diagnosis for a brms fit
# Purpose:    Report convergence, divergences, treedepth and E-BFMI, and say what
#             each failing diagnostic implies about the model rather than the sampler
# Sourced by: bayes-workflow-r skill; call bw_diagnose(fit)
# Author:     Chris Moreh
# Last updated: 2026-08-27
################################################################################

# Thresholds follow the reporting standard used throughout the workflow: R-hat below
# 1.01, and bulk and tail ESS each above 400 for any parameter that will be reported.

bw_diagnose <- function(fit, rhat_max = 1.01, ess_min = 400, pars = NULL,
                        div_tol = 0.005) {

  stopifnot(inherits(fit, "brmsfit"))
  requireNamespace("posterior", quietly = TRUE)

  draws <- posterior::as_draws_array(fit)
  if (!is.null(pars)) draws <- posterior::subset_draws(draws, variable = pars)

  smry <- posterior::summarise_draws(
    draws, "rhat", "ess_bulk", "ess_tail"
  )
  smry <- smry[!is.na(smry$rhat), ]

  bad_rhat <- smry[smry$rhat > rhat_max, ]
  bad_bulk <- smry[smry$ess_bulk < ess_min, ]
  bad_tail <- smry[smry$ess_tail < ess_min, ]

  np        <- brms::nuts_params(fit)
  divergent <- sum(np$Value[np$Parameter == "divergent__"])
  n_draws   <- sum(np$Parameter == "divergent__")
  treedepth <- np$Value[np$Parameter == "treedepth__"]
  # against the CONFIGURED limit, not the observed maximum: a fit whose deepest
  # trajectory is 11 under a limit of 12 has saturated nothing, and a fit run at a
  # low limit saturates constantly while its observed maximum merely equals it.
  td_limit  <- unique(unlist(lapply(fit$fit@stan_args, function(a) a$control$max_treedepth)))
  td_limit  <- if (length(td_limit) == 1L && is.numeric(td_limit)) td_limit else 10
  at_max_td <- sum(treedepth >= td_limit, na.rm = TRUE)
  ebfmi     <- tryCatch(rstan::get_bfmi(fit$fit), error = \(e) NA_real_)

  cat("\n=== Computational diagnosis ===\n")
  cat(sprintf("parameters checked : %d\n", nrow(smry)))
  cat(sprintf("post-warmup draws  : %d\n", n_draws))

  cat("\n-- convergence --\n")
  if (nrow(bad_rhat) == 0) {
    cat(sprintf("R-hat        OK   (max %.4f)\n", max(smry$rhat)))
  } else {
    cat(sprintf("R-hat        FAIL  %d parameter(s) above %.2f\n", nrow(bad_rhat), rhat_max))
    print(bad_rhat[order(-bad_rhat$rhat), c("variable", "rhat")], n = 10)
    cat("  -> chains are exploring different regions. Look for multimodality, a flat\n",
        "     ridge, or an unidentified parameter. More chains will show which.\n", sep = "")
  }

  if (nrow(bad_bulk) == 0 && nrow(bad_tail) == 0) {
    cat(sprintf("ESS          OK   (min bulk %.0f, min tail %.0f)\n",
                min(smry$ess_bulk), min(smry$ess_tail)))
  } else {
    cat(sprintf("ESS          FAIL  %d below %d in bulk, %d in tail\n",
                nrow(bad_bulk), ess_min, nrow(bad_tail)))
    cat("  -> the posterior is being explored slowly. Standardise predictors first;\n",
        "     if that does not help, the parameter may be weakly identified.\n", sep = "")
  }

  cat("\n-- geometry --\n")
  div_rate <- divergent / n_draws
  if (divergent == 0) {
    cat("divergences  OK   (none)\n")
  } else if (div_rate <= div_tol) {
    cat(sprintf("divergences  WARN  %d of %d draws (%.2f%%)\n",
                divergent, n_draws, 100 * div_rate))
    cat("  -> few enough to be tolerable IF they are scattered rather than clustered in\n",
        "     one region. Check that before accepting them:\n",
        "     bayesplot::mcmc_pairs(fit, np = brms::nuts_params(fit))\n", sep = "")
  } else {
    cat(sprintf("divergences  FAIL  %d of %d draws (%.1f%%)\n",
                divergent, n_draws, 100 * div_rate))
    ad <- fit$fit@stan_args[[1]]$control$adapt_delta
    ad <- if (is.null(ad)) 0.8 else ad
    if (ad < 0.99) {
      cat(sprintf("  -> adapt_delta is %.3f. Raise it to 0.99 and refit before concluding\n", ad),
          "     anything about the geometry.\n", sep = "")
    } else {
      cat(sprintf("  -> adapt_delta is already %.3f, so this is geometry rather than tuning.\n", ad),
          "     Usual cause is a funnel where a group-level SD approaches zero: tighten\n",
          "     the prior on that SD, or ask whether the grouping factor has enough levels.\n", sep = "")
    }
    cat("     Locate them with: bayesplot::mcmc_pairs(fit, np = brms::nuts_params(fit))\n")
  }

  if (at_max_td > 0) {
    cat(sprintf("treedepth    WARN  %d draws hit the configured limit of %d\n",
                at_max_td, td_limit))
    cat("  -> efficiency, not validity. Centre and scale the predictors to decorrelate\n",
        "     the posterior; raising max_treedepth hides the warning, not the cause.\n", sep = "")
  } else {
    cat("treedepth    OK\n")
  }

  if (!all(is.na(ebfmi))) {
    if (any(ebfmi < 0.2)) {
      cat(sprintf("E-BFMI       WARN  min %.2f (below 0.2)\n", min(ebfmi)))
      cat("  -> the sampler is struggling with the energy distribution, often a sign of\n",
          "     heavy tails. Consider a reparameterisation or a lighter-tailed prior.\n", sep = "")
    } else {
      cat(sprintf("E-BFMI       OK   (min %.2f)\n", min(ebfmi)))
    }
  }

  passed <- nrow(bad_rhat) == 0 && nrow(bad_bulk) == 0 &&
            nrow(bad_tail) == 0 && div_rate <= div_tol
  cat("\n", if (passed) "All gates passed: estimates may be reported.\n"
           else "Gates NOT passed: resolve the above before reporting estimates.\n", sep = "")

  invisible(list(summary = smry, divergent = divergent,
                 treedepth_saturated = at_max_td, treedepth_limit = td_limit, ebfmi = ebfmi, passed = passed))
}
if (sys.nframe() == 0L) {
  # Rscript entry: Rscript bw_diagnose.R <fit.rds>
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 1L || identical(args[1], "--help")) {
    cat("usage: Rscript bw_diagnose.R <fit.rds>\n")
    quit(status = 1L)
  }
  if (!file.exists(args[[1]])) {
    cat("not found: ", args[[1]], "\n", sep = "")
    quit(status = 1L)
  }
  suppressMessages(library(brms))
  bw_diagnose(readRDS(args[[1]]))
}
