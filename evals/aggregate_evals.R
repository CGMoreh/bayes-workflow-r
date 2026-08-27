################################################################################
# Title:      Aggregate an eval iteration into a benchmark
# Purpose:    Read the grading and timing files an eval run produces, compute the
#             with-skill against without-skill comparison, and report the
#             per-assertion breakdown that says where the skill actually helps
# Reads:      <iteration>/eval-*/{with_skill,without_skill}/{grading,timing}.json
# Writes:     <iteration>/benchmark.json
# Author:     Chris Moreh
# Last updated: 2026-08-27
################################################################################

# Dependencies are already required by the plugin: jsonlite arrives with
# cmdstanr, purrr and dplyr with tidybayes. Nothing new is needed to run this.
#
# The aggregate pass rate is the least interesting number here. What matters is
# the three-way split at the end: assertions that pass in BOTH configurations
# are measuring the model rather than the skill and should be replaced; ones
# that fail in both are either broken or a genuine gap in the skill; and the
# ones only the skill passes are the whole of its measured value.

suppressPackageStartupMessages({
  library(jsonlite)
  library(purrr)
  library(dplyr)
})

bw_read_iteration <- function(iteration) {
  dirs <- list.dirs(iteration, recursive = FALSE)
  dirs <- dirs[grepl("[/\\\\]eval-", dirs)]
  if (!length(dirs)) {
    stop("no eval-* directories under '", iteration, "'. Point this at an ",
         "iteration directory holding one eval-<name> folder per case.",
         call. = FALSE)
  }

  map(dirs, function(d) {
    cfgs <- map(c(with_skill = "with_skill", without_skill = "without_skill"), function(cfg) {
      gfile <- file.path(d, cfg, "grading.json")
      tfile <- file.path(d, cfg, "timing.json")
      if (!file.exists(gfile)) return(NULL)
      g <- fromJSON(gfile, simplifyDataFrame = FALSE)
      timing <- if (file.exists(tfile)) fromJSON(tfile) else list()
      list(
        pass_rate  = g$summary$pass_rate,
        assertions = map(g$assertion_results, \(a) list(text = a$text, passed = isTRUE(a$passed))),
        tokens     = timing$total_tokens %||% NA_real_,
        seconds    = (timing$duration_ms %||% NA_real_) / 1000
      )
    })
    list(eval = basename(d), with_skill = cfgs$with_skill, without_skill = cfgs$without_skill)
  }) |>
    keep(\(e) !is.null(e$with_skill) && !is.null(e$without_skill))
}

bw_summarise_config <- function(cases, cfg) {
  pull <- function(field) map_dbl(cases, \(e) e[[cfg]][[field]] %||% NA_real_)
  stat <- function(v) {
    v <- v[!is.na(v)]
    if (!length(v)) return(NULL)
    list(mean = round(mean(v), 4), sd = if (length(v) > 1) round(sd(v), 4) else 0)
  }
  list(pass_rate = stat(pull("pass_rate")),
       tokens    = stat(pull("tokens")),
       seconds   = stat(pull("seconds")))
}

# One row per assertion, with its outcome in each configuration. Assertions are
# matched on their text, which is why the grading files must quote them verbatim.
bw_assertion_table <- function(cases) {
  map(cases, function(e) {
    without <- set_names(map_lgl(e$without_skill$assertions, "passed"),
                         map_chr(e$without_skill$assertions, "text"))
    map(e$with_skill$assertions, \(a) tibble(
      eval          = e$eval,
      assertion     = a$text,
      with_skill    = a$passed,
      without_skill = unname(without[a$text]) %||% NA
    )) |> list_rbind()
  }) |> list_rbind()
}

bw_aggregate <- function(iteration = "iteration-1", seed = 20260827, n_boot = 10000) {

  cases <- bw_read_iteration(iteration)
  with_s    <- bw_summarise_config(cases, "with_skill")
  without_s <- bw_summarise_config(cases, "without_skill")

  deltas <- map_dbl(cases, \(e) e$with_skill$pass_rate - e$without_skill$pass_rate)
  improved  <- sum(deltas > 0)
  regressed <- sum(deltas < 0)

  # a case-level bootstrap, because the cases are the unit of replication: one
  # run per cell means there is no within-case variance to resample
  set.seed(seed)
  boots <- map_dbl(seq_len(n_boot), \(i) mean(sample(deltas, replace = TRUE)))
  ci    <- unname(quantile(boots, c(0.025, 0.975)))
  # one-sided sign test against the null that the skill never helps
  p_sign <- if (improved + regressed > 0) {
    binom.test(improved, improved + regressed, alternative = "greater")$p.value
  } else NA_real_

  tab <- bw_assertion_table(cases)
  both    <- tab |> filter(with_skill, without_skill)
  neither <- tab |> filter(!with_skill, !without_skill)
  only    <- tab |> filter(with_skill, !without_skill)
  worse   <- tab |> filter(!with_skill, without_skill)

  benchmark <- list(
    n_evals = length(cases),
    run_summary = list(
      with_skill = with_s, without_skill = without_s,
      delta = list(
        pass_rate = round(mean(deltas), 4),
        bootstrap_95 = round(ci, 4),
        cases_improved = improved, cases_regressed = regressed,
        sign_test_p_one_sided = signif(p_sign, 4)
      )
    ),
    assertions = tab
  )
  write_json(benchmark, file.path(iteration, "benchmark.json"),
             auto_unbox = TRUE, pretty = TRUE, digits = 6)

  cat(sprintf("\nevals graded: %d\n", length(cases)))
  for (lab in c("with_skill", "without_skill")) {
    s <- if (lab == "with_skill") with_s else without_s
    cat(sprintf("  %-14s pass rate %.2f (sd %.2f)\n", lab, s$pass_rate$mean, s$pass_rate$sd))
  }
  cat(sprintf("  delta          %+.3f   bootstrap 95%% [%+.3f, %+.3f]\n",
              mean(deltas), ci[1], ci[2]))
  cat(sprintf("  cases          %d improved, %d regressed, one-sided sign test p = %.5f\n",
              improved, regressed, p_sign))

  cat(sprintf("\nassertions passing in both configurations : %d  (candidates for removal)\n", nrow(both)))
  cat(sprintf("assertions failing in both configurations : %d  (broken, or a gap in the skill)\n", nrow(neither)))
  cat(sprintf("assertions the skill alone passes         : %d  (where the value is)\n", nrow(only)))
  if (nrow(worse)) {
    cat(sprintf("assertions the BASELINE alone passes      : %d  (read these carefully)\n", nrow(worse)))
  }
  walk2(only$eval, only$assertion, \(e, a) cat(sprintf("    [%s] %s\n", e, substr(a, 1, 88))))
  walk2(neither$eval, neither$assertion, \(e, a) cat(sprintf("  FAILS BOTH [%s] %s\n", e, substr(a, 1, 80))))
  walk2(worse$eval, worse$assertion, \(e, a) cat(sprintf("  BASELINE ONLY [%s] %s\n", e, substr(a, 1, 78))))

  invisible(benchmark)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (identical(args[1], "--help")) {
    cat("usage: Rscript aggregate_evals.R [iteration-directory]\n")
    quit(status = 1L)
  }
  bw_aggregate(if (length(args)) args[[1]] else "iteration-1")
}
