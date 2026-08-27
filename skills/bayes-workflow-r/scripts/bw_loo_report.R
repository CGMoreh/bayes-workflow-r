################################################################################
# Title:      LOO comparison with pointwise attribution
# Purpose:    Compare models by leave-one-out cross-validation, verify they were
#             fitted to the same observations, check Pareto k, and report how
#             concentrated the difference is across cases
# Sourced by: bayes-workflow-r skill; call bw_loo_report(m1, m2)
# Author:     Chris Moreh
# Last updated: 2026-08-27
################################################################################

# Models fitted to different rows cannot be compared. This happens silently whenever
# predictors carry missing values and the models use different predictor sets: brms
# drops incomplete rows per model, the pointwise vectors come out different lengths,
# and R recycles them with a warning rather than an error. bw_loo_report() refuses.
#
# Grouped cross-validation lives in bw_kfold_grouped() below, because it refits the
# model K times and has no business running inside a routine report.

bw_loo_report <- function(..., top_n = 10, data = NULL, annotate = NULL) {

  fits <- list(...)
  nms  <- vapply(substitute(list(...))[-1], deparse, character(1))
  names(fits) <- nms
  stopifnot(length(fits) >= 2, all(vapply(fits, inherits, logical(1), "brmsfit")))
  requireNamespace("loo", quietly = TRUE)

  cat("\n=== LOO comparison ===\n")

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

  cat("\n-- Pareto k diagnostics --\n")
  for (i in seq_along(loos)) {
    k   <- loos[[i]]$diagnostics$pareto_k
    bad <- sum(k > 0.7)
    cat(sprintf("%-20s max k %.2f, %d above 0.7\n", nms[i], max(k), bad))
    if (bad > 0) {
      cat("  -> the LOO estimate is unreliable for those cases. Try\n",
          "     loo_moment_match(), or reloo() to refit without them.\n", sep = "")
    }
  }

  cat("\n-- comparison --\n")
  cmp <- loo::loo_compare(loos)
  print(cmp)

  ed <- cmp[2, "elpd_diff"]; se <- cmp[2, "se_diff"]
  cat(sprintf("\nelpd_diff %.1f against se_diff %.1f: ", ed, se))
  if (se > 0 && abs(ed) < 2 * se) {
    cat("within twice its standard error.\n")
    cat("  -> report the models as indistinguishable in predictive terms rather than\n",
        "     picking a winner.\n", sep = "")
  } else if (se == 0) {
    cat("the standard error of the difference is zero.\n")
    cat("  -> the two fits give identical pointwise values. Check they are not the same\n",
        "     model, or the same object passed twice.\n", sep = "")
  } else {
    cat("larger than twice its standard error.\n")
  }

  if (nrow(fits[[1]]$data) < 100) {
    cat("  Fewer than 100 observations: se_diff is itself poorly estimated here, so\n",
        "  treat the comparison as suggestive and say so in the write-up.\n", sep = "")
  }

  # --- where does the difference come from?
  best  <- rownames(cmp)[1]
  other <- rownames(cmp)[2]
  pw    <- loos[[best]]$pointwise[, "elpd_loo"] - loos[[other]]$pointwise[, "elpd_loo"]
  names(pw) <- rows[[1]]

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
