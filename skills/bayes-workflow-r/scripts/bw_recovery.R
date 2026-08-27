################################################################################
# Title:      Design calibration by simulated recovery
# Purpose:    Ask whether this design, at this sample size, can recover an effect
#             of the size expected, and report recovery, coverage and sign error
# Sourced by: bayes-workflow-r skill; call bw_recovery(fit, simulate_fn, ...)
# Author:     Chris Moreh
# Last updated: 2026-08-26
################################################################################

# The Bayesian analogue of a power calculation. Run it before the real analysis if
# possible: learning that the design cannot answer the question is much more useful
# before the analysis than after it.
#
# simulate_fn(n, truth) must return a data frame with the same columns the model
# expects. Use the same priors as the real analysis; simulating under one prior and
# fitting under another answers a question nobody asked.

bw_recovery <- function(fit, simulate_fn, truth, parameter,
                        n = NULL, n_sims = 200, width = 0.89,
                        seed = 20260826) {

  stopifnot(inherits(fit, "brmsfit"), is.function(simulate_fn))
  requireNamespace("posterior", quietly = TRUE)

  if (is.null(n)) n <- stats::nobs(fit)
  set.seed(seed)
  lo <- (1 - width) / 2
  hi <- 1 - lo

  one_run <- function(i) {
    d_sim   <- simulate_fn(n, truth)
    fit_sim <- stats::update(fit, newdata = d_sim, refresh = 0, silent = 2)
    dr      <- posterior::as_draws_df(fit_sim)[[parameter]]
    if (is.null(dr)) {
      stop("parameter '", parameter, "' not found; available: ",
           paste(utils::head(posterior::variables(fit_sim), 20), collapse = ", "))
    }
    data.frame(
      iteration = i,
      median    = stats::median(dr),
      lower     = unname(stats::quantile(dr, lo)),
      upper     = unname(stats::quantile(dr, hi))
    )
  }

  res <- do.call(rbind, lapply(seq_len(n_sims), one_run))

  res$covers    <- res$lower <= truth & truth <= res$upper
  res$excludes0 <- res$lower > 0 | res$upper < 0
  res$wrong_sign <- sign(res$median) != sign(truth)

  recovery <- mean(res$excludes0)
  coverage <- mean(res$covers)
  bias     <- mean(res$median) - truth
  type_s   <- mean(res$wrong_sign)
  # among the runs that would have been reported as a finding, matching the
  # conditioning of the exaggeration ratio below
  detected   <- res$median[res$excludes0]
  type_s_det <- if (length(detected)) mean(sign(detected) != sign(truth)) else NA_real_
  type_m     <- if (length(detected)) mean(abs(detected)) / abs(truth) else NA_real_

  cat("\n=== Design calibration ===\n")
  cat(sprintf("n = %d, true effect = %.3f, %d simulations, %.0f%% intervals\n",
              n, truth, n_sims, 100 * width))
  cat(sprintf("\nrecovery rate    %.0f%%   (interval excludes zero)\n", 100 * recovery))
  cov_mcse <- sqrt(width * (1 - width) / n_sims)
  cat(sprintf("coverage         %.0f%%   (nominal %.0f%%, MCSE %.1f%%)\n",
              100 * coverage, 100 * width, 100 * cov_mcse))
  cat(sprintf("median bias      %+.3f\n", bias))
  cat(sprintf("sign error rate  %.1f%%   (%.1f%% among detections)\n",
              100 * type_s, 100 * type_s_det))
  if (!is.na(type_m)) {
    cat(sprintf("exaggeration     %.2fx  (mean |estimate| among detections / truth)\n", type_m))
  }

  cat("\n")
  if (recovery < 0.5) {
    cat("This design recovers the expected effect less than half the time. A null\n",
        "result in the real data says very little, and the paper should say so.\n", sep = "")
  }
  if (!is.na(type_m) && type_m > 1.3) {
    cat("Estimates that clear the threshold are inflated by more than 30% on average.\n",
        "Report the magnitude with that in mind rather than at face value.\n", sep = "")
  }
  if (abs(coverage - width) > 2 * cov_mcse) {
    cat("Coverage departs from nominal by more than twice its Monte Carlo error, which\n",
        "may point at the model or the priors rather than at the design.\n", sep = "")
  }

  invisible(res)
}
if (sys.nframe() == 0L) {
  # No Rscript entry: design calibration needs a simulate_fn written for the
  # design at hand, which cannot arrive through the command line. Source the
  # file and follow reference/calibration.md.
  cat("bw_recovery() needs a simulate_fn for your design, so it has no command-line\n")
  cat("form. source() this file and see reference/calibration.md for the pattern.\n")
  quit(status = 1L)
}
