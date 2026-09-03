################################################################################
# Title:      LOO comparison with pointwise attribution
# Purpose:    Compare models by leave-one-out cross-validation, verify they were
#             fitted to the same observations, check Pareto k, and report how
#             concentrated the difference is across cases
# Sourced by: bayes-workflow-r skill; call bw_loo_report(m1, m2), or bw_loo_report(m)
#             for the single-model diagnostics and the optimism check alone
# Author:     Chris Moreh
# Last updated: 2026-08-27
################################################################################

# Models fitted to different rows cannot be compared. This happens silently whenever
# predictors carry missing values and the models use different predictor sets: brms
# drops incomplete rows per model, the pointwise vectors come out different lengths,
# and R recycles them with a warning rather than an error. bw_loo_report() refuses.
#
# One model is a legitimate call. Comparison needs two, but the optimism section -
# in-sample explained variance against its leave-one-out counterpart - is a property
# of a single fit, and it is the check that says whether a model is overfitting at
# all. Passing one fit runs the diagnostics and the optimism section and stops there.
#
# Grouped cross-validation lives in bw_kfold_grouped() below, because it refits the
# model K times and has no business running inside a routine report.

# brms compiles one Stan program for both cases and switches on a data flag, so
# the flag is the reliable marker. Returns NA when it cannot be read, and callers
# treat NA as "not prior-only" rather than refusing on a failed lookup.
bw_is_prior_only <- function(fit) {
  tryCatch(isTRUE(as.integer(brms::standata(fit)$prior_only) == 1L),
           error = function(e) NA)
}

# p_loo means nothing on its own; it means something against the number of
# parameters the model actually has. Counting brms's stored variables and
# dropping the derived and raw ones reproduces the counts a chapter would quote:
# 4 for a four-term Poisson, 5 with a shape parameter, 267 for the same Poisson
# with one varying intercept per observation. Returns NA rather than guessing.
bw_n_parameters <- function(fit) {
  v <- tryCatch(brms::variables(fit), error = function(e) NULL)
  if (is.null(v)) return(NA_integer_)
  # z_ and L_ are the raw standardised group effects behind r_, and counting both
  # doubles every varying term; lprior and lp__ are not parameters at all
  length(v[!grepl("^(lp__|lprior|z_|L_|Lrescor|Intercept)", v)])
}

bw_loo_report <- function(..., top_n = 10, data = NULL, annotate = NULL) {

  fits <- list(...)
  nms  <- vapply(substitute(list(...))[-1], deparse, character(1))
  # a name given in the call is the label the user chose; the deparsed
  # expression is only the fallback for an unnamed argument
  given <- names(fits)
  if (!is.null(given)) nms[nzchar(given)] <- given[nzchar(given)]
  names(fits) <- nms
  stopifnot(length(fits) >= 1, all(vapply(fits, inherits, logical(1), "brmsfit")))
  requireNamespace("loo", quietly = TRUE)
  solo <- length(fits) == 1L

  cat(if (solo) "\n=== LOO report ===\n" else "\n=== LOO comparison ===\n")

  # --- are these models even comparable?
  rows <- lapply(fits, \(f) rownames(f$data))
  if (!all(vapply(rows, identical, logical(1), rows[[1]]))) {
    n <- vapply(rows, length, integer(1))
    cat("\nObservations used, by model:\n")
    for (i in seq_along(n)) cat(sprintf("  %-20s %d\n", nms[i], n[i]))
    common <- Reduce(intersect, rows)
    dropped <- setdiff(Reduce(union, rows), common)
    cat(sprintf("\n%d rows are common to all models; %d are not.\n",
                length(common), length(dropped)))
    cat("rows not used by every model: ",
        paste(utils::head(dropped, 15), collapse = ", "),
        if (length(dropped) > 15) ", ..." else "", "\n", sep = "")
    stop("models were fitted to different observations, so their LOO values are not ",
         "comparable. This is almost always missing data: a predictor present in one ",
         "model and absent from another carries NAs, and brms drops those rows only ",
         "for the model that uses it. Refit both on the same complete-case subset, ",
         "for example data = tidyr::drop_na(d, <all predictors in any model>).",
         call. = FALSE)
  }

  # --- cache the criterion on the in-memory fit so repeated calls do not
  # recompute it. Strip the $file field first: add_criterion() auto-saves any
  # fit that carries one, and a reporting function must not write model files.
  fits <- lapply(fits, \(f) { f$file <- NULL; brms::add_criterion(f, "loo") })
  names(fits) <- nms
  loos <- lapply(fits, \(f) f$criteria$loo)

  # second layer behind the row-name check: dplyr filtering resets tibble row
  # names, so two separately filtered samples of equal size can carry identical
  # names over different observations. loo hashes the response; compare that.
  yh <- vapply(loos, function(l) {
    h <- attr(l, "yhash")
    if (is.null(h)) NA_character_ else paste(as.character(h), collapse = "")
  }, character(1))
  if (!anyNA(yh) && length(unique(yh)) > 1L) {
    stop("the models carry identical row names but their response vectors hash ",
         "differently (loo's 'yhash'), so they were fitted to different observations. ",
         "The usual route here is two separately filtered analytic samples of equal ",
         "size. Refit every model on one shared complete-case subset.", call. = FALSE)
  }

  # recorded rather than only printed: the comparison further down has to be able
  # to say that it rests on an estimate these diagnostics called unreliable
  n_obs <- length(loos[[1]]$diagnostics$pareto_k)
  bad_k <- integer(length(loos))

  cat("\n-- Pareto k diagnostics --\n")
  for (i in seq_along(loos)) {
    k        <- loos[[i]]$diagnostics$pareto_k
    bad_k[i] <- sum(k > 0.7)
    cat(sprintf("%-20s max k %.2f, %d of %d above 0.7\n",
                nms[i], max(k), bad_k[i], n_obs))
    if (bad_k[i] > 0) {
      cat("  -> the LOO estimate is unreliable for those cases. Try\n",
          "     loo_moment_match(), or reloo() to refit without them.\n", sep = "")
    }
    if (bad_k[i] > 0.1 * n_obs) {
      cat("  -> above roughly a tenth of the sample, moment matching often does not\n",
          "     recover enough. A model carrying one varying intercept per\n",
          "     observation is the standard case: leaving a point out moves its own\n",
          "     intercept too far for any reweighting to bridge. Compare by K-fold\n",
          "     instead - kfold(fit, K = 10), or bw_kfold_grouped() when the data are\n",
          "     clustered - and treat the numbers below as provisional until you do.\n",
          sep = "")
    }
  }

  # p_loo against the parameter count is the first thing a misspecified model
  # gives away, and it costs nothing: it is already inside every loo object.
  cat("\n-- effective parameters --\n")
  for (i in seq_along(loos)) {
    p_loo <- loos[[i]]$estimates["p_loo", "Estimate"]
    n_par <- bw_n_parameters(fits[[i]])
    cat(sprintf("%-20s p_loo %.1f against %s parameters\n", nms[i], p_loo,
                if (is.na(n_par)) "an unknown number of" else format(n_par)))
    if (!is.na(n_par) && p_loo > 2 * n_par) {
      cat("  -> p_loo far above the parameter count marks misspecification rather\n",
          "     than flexibility. For counts the family is the usual cause: a\n",
          "     Poisson fitted to overdispersed data produces exactly this.\n", sep = "")
    } else if (p_loo > n_obs / 5) {
      # only where p_loo has NOT already been read as misspecification: a
      # four-parameter model returning a p_loo of 254 is not flexible, it is wrong
      cat("  -> p_loo above a fifth of the sample marks a model flexible enough that\n",
          "     leaving one observation out moves the posterior a long way. Expect\n",
          "     the Pareto k to be bad, and prefer K-fold to importance sampling.\n",
          sep = "")
    }
  }

  # --- how far each model's in-sample fit outruns its out-of-sample fit.
  # A model comparison says which model predicts better; it never says whether
  # EITHER is overfitting, and the two questions have different answers. The gap
  # between a model-based R2 and its leave-one-out counterpart measures the
  # second directly, which a comparison of elpd cannot.
  cat("\n-- optimism: in-sample against out-of-sample --\n")
  for (i in seq_along(fits)) {
    # A prior-only fit has no in-sample fit to be optimistic about, and
    # bayes_R2() on one is contaminated: it forms the residual against an
    # outcome the prior never saw. Refuse rather than print a number.
    if (isTRUE(bw_is_prior_only(fits[[i]]))) {
      cat(sprintf("%-20s prior-only fit: no out-of-sample counterpart to compare
", nms[i]))
      cat("  -> for what a prior implies about explained variance, use bw_prior_check().
")
      next
    }
    gap <- tryCatch({
      # bayes_R2() forms the residual on the RESPONSE scale, so it stays
      # comparable with loo_R2() whatever the family. Computing the ratio from
      # var(mu) and sigma^2 instead mixes scales the moment the family stores
      # sigma anywhere but the response scale: on a lognormal fit that returned
      # 0.83 against a response-scale 0.20, a false overfitting flag. On a
      # gaussian fit the two agree to three decimals, so nothing is lost.
      r2_in    <- stats::median(brms::bayes_R2(fits[[i]], summary = FALSE)[, 1])
      r2_loo_d <- brms::loo_R2(fits[[i]], summary = FALSE)[, 1]
      r2_loo   <- stats::median(r2_loo_d)
      c(r2_in, r2_loo, r2_in - r2_loo,
        mean(r2_loo_d <= min(r2_loo_d) + 1e-9))
    }, error = function(e) NULL)
    if (is.null(gap)) {
      cat(sprintf("%-20s not available for this family\n", nms[i]))
      next
    }
    # loo_R2 collapses onto a bound whenever the leave-one-out residual variance
    # exceeds the variance of the outcome, which is routine for an overdispersed
    # count: on a roaches negative binomial 99% of the draws sat exactly at -1.
    # Subtracting a floor from an in-sample figure turns that into an
    # overfitting verdict on a model that is not overfitting, so refuse instead.
    if (gap[4] > 0.5 || gap[2] <= 0) {
      cat(sprintf("%-20s explained variance is not a usable summary here\n", nms[i]))
      cat(sprintf("  %.0f%% of the loo_R2 draws sit at the same bound (median %.3f).\n",
                  100 * gap[4], gap[2]))
      cat("  -> judge this model by elpd and by predictive checks on the outcome's\n",
          "     own scale. R2 answers a question this outcome does not support.\n",
          sep = "")
      next
    }
    cat(sprintf("%-20s R2 %.3f in-sample, %.3f out-of-sample, gap %+.3f\n",
                nms[i], gap[1], gap[2], gap[3]))
    if (gap[3] > 0.10) {
      cat("  -> the in-sample fit outruns the out-of-sample fit substantially, so the\n",
          "     residual variance is being underestimated.\n", sep = "")
      fam <- tryCatch(fits[[i]]$family$family, error = function(e) NA_character_)
      # a prior is the right lever only where the outcome's spread is a free
      # parameter; where the family fixes the mean-variance relation, the same
      # gap comes from the family and no prior will close it
      if (!is.na(fam) && fam %in% c("gaussian", "student", "skew_normal",
                                    "lognormal", "exgaussian")) {
        cat("     A prior that pulls less hard towards high explained variance usually\n",
            "     shrinks the gap without costing predictive performance.\n", sep = "")
      } else {
        cat("     Check the family before the prior. A likelihood that cannot represent\n",
            "     the dispersion in the outcome produces this same gap, and no prior\n",
            "     closes it: the move is to a family that can.\n", sep = "")
      }
    }
  }

  if (solo) {
    cat("\nOne model was supplied, so there is no comparison to make. The Pareto k and\n",
        "optimism sections above are the whole of what a single fit supports here. To\n",
        "compare, pass the models together: bw_loo_report(m1, m2).\n", sep = "")
    return(invisible(list(fits = fits, loos = loos, comparison = NULL, pointwise = NULL)))
  }

  cat("\n-- comparison --\n")
  cmp <- loo::loo_compare(loos)
  print(cmp)

  best  <- rownames(cmp)[1]
  other <- rownames(cmp)[2]
  pw    <- loos[[best]]$pointwise[, "elpd_loo"] - loos[[other]]$pointwise[, "elpd_loo"]
  names(pw) <- rows[[1]]

  ed <- cmp[2, "elpd_diff"]; se <- cmp[2, "se_diff"]
  if (se == 0) {
    cat("\nthe standard error of the difference is zero.\n")
    cat("  -> the two fits give identical pointwise values. Check they are not the same\n",
        "     model, or the same object passed twice.\n", sep = "")
  } else {
    # Report the quantity rather than a verdict at a threshold. A difference is
    # not a decision, and collapsing it to "distinguishable or not" throws away
    # what the reader needs - the same move this plugin's reporting skill refuses
    # to make for a posterior, and there is no reason elpd deserves worse.
    cat(sprintf("\nelpd_diff %.1f against se_diff %.1f: %.1f standard errors.\n",
                ed, se, abs(ed) / se))
    p_norm <- stats::pnorm(abs(ed) / se)
    cat(sprintf("  P(%s predicts worse) = %.2f under a normal approximation.\n",
                other, p_norm))

    # That probability comes from a normal approximation to a sum, and the sum is
    # over pointwise differences that are routinely heavy-tailed - excess kurtosis
    # above 20 is ordinary here. Kurtosis on its own is the wrong thing to report,
    # because it is large in comparisons whose answer is not in doubt. What matters
    # is whether the probability MOVES, so drop the three most influential cases
    # and recompute it. On the book's roaches comparison that shifts 0.96 to 1.00,
    # which is the sensitivity the chapter warns about, stated as a number.
    p_after <- tryCatch({
      if (length(pw) < 20L) NA_real_ else {
        v <- pw[-order(abs(pw), decreasing = TRUE)[1:3]]
        stats::pnorm(abs(sum(v)) / (sqrt(length(v)) * stats::sd(v)))
      }
    }, error = function(e) NA_real_)

    if (!is.na(p_after) && abs(p_after - p_norm) > 0.01) {
      cat(sprintf("  Dropping the three most influential cases moves it to %.2f.\n", p_after))
      cat("  -> the probability rests on a few observations, so quote elpd_diff and\n",
          "     se_diff and treat it as indicative. Naming those cases and saying what\n",
          "     is unusual about them is worth more than the probability is.\n", sep = "")
    } else if (abs(ed) < 2 * se) {
      cat("  -> under two standard errors. The conventional reading is that the models\n",
          "     are not distinguishable in predictive terms; the probability above is\n",
          "     the same evidence without the threshold, and is worth reporting instead.\n",
          sep = "")
    }
  }

  # The diagnostics above and this verdict are about the same numbers, and a
  # report that prints them without connecting them invites the reader to act on
  # the second having read the first. On the book's roaches comparison that is a
  # 251-elpd margin at fourteen standard errors, resting on an estimate that was
  # unreliable for 205 of 262 observations, and it reverses under K-fold.
  if (any(bad_k > 0)) {
    worst <- which.max(bad_k)
    cat(sprintf("\n  Read against the diagnostics above: %s has %d of %d observations\n",
                nms[worst], bad_k[worst], n_obs))
    cat("  above k = 0.7, so this ranking rests on an estimate already called\n",
        "  unreliable. The number of standard errors does not repair that. Moment\n",
        "  match or reloo first; if enough k stay high, compare by K-fold and use\n",
        "  that result instead of this one.\n", sep = "")
  }

  if (nrow(fits[[1]]$data) < 100) {
    cat("  Fewer than 100 observations: se_diff is itself poorly estimated here, so\n",
        "  treat the comparison as suggestive and say so in the write-up.\n", sep = "")
  }

  # --- where does the difference come from? pw was formed above, because the
  # probability check needs it too
  cat("\n-- pointwise attribution --\n")
  k <- min(top_n, length(pw))

  # Pointwise differences carry both signs, so a top-k share of the NET total can
  # exceed 100% whenever the net is small relative to the case-by-case spread.
  # Concentration is therefore measured against total absolute disagreement.
  net   <- sum(pw)
  gross <- sum(abs(pw))
  if (gross < .Machine$double.eps^0.5) {
    cat("pointwise values are identical across models; there is no disagreement to attribute.\n")
    return(invisible(list(fits = fits, loos = loos, comparison = cmp, pointwise = pw)))
  }
  # select by MAGNITUDE: sorting the signed differences and taking absolute values
  # afterwards picks the k cases most favourable to the winner, not the k largest
  # disagreements, which is a different and much less useful quantity.
  share <- sum(sort(abs(pw), decreasing = TRUE)[seq_len(k)]) / gross

  cat(sprintf("net difference          %+.1f across %d cases\n", net, length(pw)))
  cat(sprintf("absolute disagreement    %.1f\n", gross))
  cat(sprintf("top %d cases hold        %.0f%% of the absolute disagreement\n",
              k, 100 * share))

  if (abs(net) / gross < 0.25) {
    cat("  -> the models disagree case by case but largely cancel overall. The net\n",
        "     difference is a small residue of much larger offsetting differences,\n",
        "     so read it cautiously whatever its standard error says.\n", sep = "")
  }

  if (share > 0.5) {
    cat("  -> the comparison rests on a small number of cases. Say so, and find out\n",
        "     what is unusual about them before drawing a general conclusion.\n", sep = "")
    top <- names(sort(pw, decreasing = TRUE))[seq_len(k)]
    cat("  rows favouring ", best, " most: ", paste(top, collapse = ", "), "\n", sep = "")
    if (!is.null(data) && !is.null(annotate)) {
      cat("\n  those rows:\n")
      print(data[top, annotate, drop = FALSE])
    }
  }

  invisible(list(fits = fits, loos = loos, comparison = cmp, pointwise = pw))
}


# Leave-one-group-out cross-validation. Refits every model K times, so the cost is
# K x the original fit, per model. Importance sampling cannot substitute: leaving out
# a whole group moves the posterior too far for reweighting to bridge.
bw_kfold_grouped <- function(..., group, k_folds = 10, confirm = TRUE) {

  fits <- list(...)
  nms  <- vapply(substitute(list(...))[-1], deparse, character(1))
  names(fits) <- nms
  stopifnot(length(fits) >= 1, all(vapply(fits, inherits, logical(1), "brmsfit")))
  requireNamespace("loo", quietly = TRUE)

  if (length(group) != nrow(fits[[1]]$data)) {
    stop("group has length ", length(group), " but the model used ",
         nrow(fits[[1]]$data), " rows. Subset group to the rows the model kept: ",
         "group = fits[[1]]$data[[\"<grouping column>\"]], which is the right length ",
         "by construction.", call. = FALSE)
  }

  n_refits <- k_folds * length(fits)
  cat(sprintf("\n=== Leave-one-group-out cross-validation ===\n"))
  cat(sprintf("%d folds x %d models = %d refits.\n", k_folds, length(fits), n_refits))
  if (confirm) {
    cat("Set confirm = FALSE to run. Estimate the cost first: one refit of this model\n")
    cat("takes about as long as the original fit did.\n")
    return(invisible(NULL))
  }

  folds <- loo::kfold_split_grouped(K = k_folds, x = group)
  res   <- lapply(fits, \(f) brms::kfold(f, folds = folds))
  names(res) <- nms
  print(loo::loo_compare(res))
  cat("\nCompare this against the leave-one-out ranking. A model that wins under LOO\n",
      "and loses here predicts within groups but not to new groups, which matters if\n",
      "the paper claims to generalise to new participants, schools or countries.\n", sep = "")
  invisible(res)
}
if (sys.nframe() == 0L) {
  # Rscript entry: Rscript bw_loo_report.R <fit1.rds> <fit2.rds> [more.rds ...]
  # Models are named by file basename, made syntactic and unique.
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 2L || identical(args[1], "--help")) {
    cat("usage: Rscript bw_loo_report.R <fit1.rds> <fit2.rds> [more.rds ...]\n")
    quit(status = 1L)
  }
  if (!all(file.exists(args))) {
    cat("not found:", paste(args[!file.exists(args)], collapse = ", "), "\n")
    quit(status = 1L)
  }
  suppressMessages(library(brms))
  # a dedicated environment, so a file named nms.rds or args.rds cannot
  # overwrite the loop's own variables mid-read
  fit_env <- new.env()
  nms <- make.names(tools::file_path_sans_ext(basename(args)), unique = TRUE)
  for (i in seq_along(args)) assign(nms[[i]], readRDS(args[[i]]), envir = fit_env)
  do.call(bw_loo_report, lapply(nms, as.name), envir = fit_env)
}
