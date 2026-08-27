################################################################################
# Title:      Prior and likelihood sensitivity by power-scaling
# Purpose:    Report power-scaling sensitivity for model parameters and, more
#             usefully, for the derived quantity the paper actually reports
# Sourced by: bayes-workflow-r skill; call bw_sensitivity(fit, newdata = ...)
# Author:     Chris Moreh
# Last updated: 2026-08-27
################################################################################

# Marginal sensitivity is uninformative wherever parameters are correlated in the
# posterior, because the marginal posterior itself is not interpretable there.
# Supply newdata to carry a derived quantity through and power-scale that instead.
#
# Group-level deviations (r_*) are excluded by default: there is one per group per
# term, they swamp the table, and their marginal sensitivity is rarely the question.
# Pass variable = "all" to see them.

bw_sensitivity <- function(fit, newdata = NULL, predict_fn = brms::posterior_epred,
                           quantity_names = NULL, variable = NULL, ...) {

  stopifnot(inherits(fit, "brmsfit"))
  requireNamespace("priorsense", quietly = TRUE)
  requireNamespace("posterior", quietly = TRUE)

  variable <- bw_select_variables(fit, variable)

  cat("\n=== Power-scaling sensitivity ===\n")

  cat("\n-- model parameters --\n")
  ps_par <- priorsense::powerscale_sensitivity(fit, variable = variable)
  print(ps_par)
  bw_read_diagnosis(ps_par)

  out <- list(parameters = ps_par, quantities = NULL)

  if (!is.null(newdata)) {
    cat("\n-- derived quantities --\n")
    if (is.null(quantity_names)) quantity_names <- paste0("q", seq_len(nrow(newdata)))

    # ... reaches predict_fn, so allow_new_levels and re_formula can be set. Without
    # one of those a multilevel model errors on any newdata containing unseen groups.
    pred <- try(
      priorsense::predictions_as_draws(
        fit, predict_fn, newdata = newdata,
        prediction_names = quantity_names, ...
      ),
      silent = TRUE
    )

    if (inherits(pred, "try-error")) {
      msg <- attr(pred, "condition")$message
      cat("could not compute derived quantities: ", msg, "\n", sep = "")
      if (grepl("grouping factor|new levels", msg)) {
        cat("  -> this model has group-level terms. Pass re_formula = NA for a\n",
            "     population-level quantity, or allow_new_levels = TRUE with\n",
            "     sample_new_levels = 'gaussian' to average over new groups.\n", sep = "")
      }
    } else {
      psd    <- priorsense::create_priorsense_data(pred, fit = fit)
      ps_qty <- priorsense::powerscale_sensitivity(psd)
      print(ps_qty)
      bw_read_diagnosis(ps_qty)
      out$quantities <- ps_qty
    }
  } else {
    cat("\nNo newdata supplied, so only marginal parameter sensitivity was computed.\n")
    cat("Pass newdata to test the quantity the paper reports, which is the one a\n")
    cat("reviewer will ask about.\n")
  }

  invisible(out)
}

# Population-level parameters and variance components, but not the per-group
# deviations, unless the caller asks for everything or names a set explicitly.
bw_select_variables <- function(fit, variable) {
  if (identical(variable, "all")) return(NULL)     # NULL means "all" to priorsense
  if (!is.null(variable)) return(variable)
  v <- posterior::variables(fit)
  # drop by pattern rather than keep by pattern, so an unanticipated parameter
  # class (sds_, ar, sdgp_, ...) is checked by default instead of silently skipped
  drop <- grepl("^(r_|z_|L_|Lrescor|zgp_|Intercept($|\\[)|lprior$|lp__$)", v)
  sel  <- v[!drop]
  n_dropped <- sum(drop)
  if (n_dropped > 0) {
    cat(sprintf("(%d group-level deviations and internals excluded; variable = \"all\" includes them)\n",
                n_dropped))
  }
  if (!length(sel)) NULL else sel
}

# Translate the diagnosis strings into what they mean for the write-up. priorsense
# emits "potential prior-data conflict" and "potential strong prior / weak likelihood";
# match loosely so a wording change upstream does not silence this.
bw_read_diagnosis <- function(ps) {
  d <- as.data.frame(ps)
  if (!"diagnosis" %in% names(d)) return(invisible(NULL))
  dg <- tolower(as.character(d$diagnosis))

  conflict <- d$variable[grepl("conflict", dg)]
  weak     <- d$variable[grepl("weak likelihood", dg)]

  if (length(conflict)) {
    cat("\n  prior-data conflict: ", paste(conflict, collapse = ", "), "\n", sep = "")
    cat("  -> prior and data disagree. Work out which is telling you something you did\n",
        "     not expect. Do NOT widen the prior until the message disappears.\n", sep = "")
  }
  if (length(weak)) {
    cat("\n  strong prior, weak likelihood: ", paste(weak, collapse = ", "), "\n", sep = "")
    cat("  -> the data barely inform these. A posterior centred near zero here is\n",
        "     undetermined rather than null, and the write-up should say so.\n", sep = "")
  }
  if (!length(conflict) && !length(weak)) {
    cat("\n  No sensitivity flags: the quantities checked are insensitive to reasonable\n",
        "  perturbation of prior and likelihood.\n", sep = "")
  }
  invisible(NULL)
}
if (sys.nframe() == 0L) {
  # Rscript entry: Rscript bw_sensitivity.R <fit.rds>. Parameter sensitivity
  # only; power-scaling a derived quantity needs newdata, so source the file
  # and call bw_sensitivity(fit, newdata = ...) for that.
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 1L || identical(args[1], "--help")) {
    cat("usage: Rscript bw_sensitivity.R <fit.rds>\n")
    cat("       (derived-quantity sensitivity needs newdata: source and call directly)\n")
    quit(status = 1L)
  }
  if (!file.exists(args[[1]])) {
    cat("not found: ", args[[1]], "\n", sep = "")
    quit(status = 1L)
  }
  suppressMessages(library(brms))
  bw_sensitivity(readRDS(args[[1]]))
}
