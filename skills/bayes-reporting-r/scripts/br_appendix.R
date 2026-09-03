################################################################################
# Title:      Workflow appendix scaffold
# Purpose:    Convert a bayes-workflow-log.md into a Quarto supplementary
#             appendix skeleton: one section per logged pass round the loop,
#             plus a stage-coverage table, derived from the log where the
#             workflow skill's generator is installed and left to fill otherwise
# Sourced by: bayes-reporting-r skill; call br_appendix_scaffold()
# Author:     Chris Moreh
# Last updated: 2026-09-03
################################################################################

# The stage-coverage table is derived from the log where the workflow skill's
# generator, bw_scheme.R, is installed beside this skill: the same placement
# rules that write WORKFLOW.md fill it, so the appendix and the record agree.
# Where that skill is absent the scaffold keeps a table to fill by hand. The
# reporting skill therefore works on its own, and works better with the other.
br_find_scheme <- function(scheme_script = NULL) {
  if (!is.null(scheme_script)) return(if (file.exists(scheme_script)) scheme_script else NULL)
  here <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
  if (!length(here)) {
    f <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
    here <- if (is.null(f)) "" else f
  }
  if (!nzchar(here[1])) return(NULL)
  cand <- file.path(dirname(dirname(normalizePath(here[1], mustWork = FALSE))),
                    "..", "bayes-workflow-r", "scripts", "bw_scheme.R")
  if (file.exists(cand)) normalizePath(cand) else NULL
}

# Runs the generator on the log into a temporary file and lifts its Stages
# section, so the appendix reuses the renderer rather than reimplementing it.
br_derived_stages <- function(log, scheme_script) {
  env <- new.env()
  ok  <- tryCatch({ sys.source(scheme_script, envir = env); TRUE }, error = function(e) FALSE)
  if (!ok) return(NULL)
  tmp <- tempfile(fileext = ".md")
  res <- tryCatch(env$bw_scheme(log = log, out = tmp, quiet = TRUE), error = function(e) NULL)
  if (is.null(res) || !file.exists(tmp)) return(NULL)
  md   <- readLines(tmp, warn = FALSE, encoding = "UTF-8")
  from <- which(md == "## Stages")
  if (!length(from)) return(NULL)
  nxt  <- which(grepl("^## ", md) & seq_along(md) > from[1])
  to   <- if (length(nxt)) nxt[1] - 1L else length(md)
  block <- md[(from[1] + 1L):to]
  block[nzchar(trimws(block))]
}

# The log's entry format is one "## <date> - <label>" heading per pass, as set out
# in the bayes-workflow-r SKILL.md. Any second-level heading is accepted, so a log
# kept in a looser style still scaffolds; entries simply keep their own titles.

br_appendix_scaffold <- function(log = "bayes-workflow-log.md",
                                 out = "appendix-workflow.qmd",
                                 title = "Supplementary appendix: analysis workflow",
                                 overwrite = FALSE,
                                 scheme_script = br_find_scheme()) {

  # the scaffold is filled in BY HAND after generation, so re-running over a
  # filled appendix would destroy work; refuse unless told otherwise
  if (file.exists(out) && !overwrite) {
    stop("'", out, "' already exists, and scaffolds are hand-filled after generation. ",
         "Move it aside, or pass overwrite = TRUE (--force from the command line) ",
         "to replace it.", call. = FALSE)
  }

  if (!file.exists(log)) {
    stop("no workflow log found at '", log, "'. The appendix is built from the log ",
         "the bayes-workflow-r skill keeps; start one there, or point `log` at yours.",
         call. = FALSE)
  }

  lines <- readLines(log, warn = FALSE)
  heads <- grep("^## ", lines)
  if (!length(heads)) {
    stop("'", log, "' has no '## ' entries to scaffold. One heading per pass round ",
         "the loop is the format this expects.", call. = FALSE)
  }

  ends    <- c(heads[-1] - 1L, length(lines))
  entries <- Map(function(h, e) {
    # an entry whose heading is the last line, or which abuts the next heading,
    # has no body lines at all; indexing past it would fabricate content
    list(title = sub("^## +", "", lines[h]),
         body  = if (e > h) trimws(paste(lines[seq(h + 1L, e)], collapse = "\n")) else "")
  }, heads, ends)

  stages <- c("Priors, and what they imply", "Prior predictive simulation", "Fit",
              "Computational diagnosis", "Posterior predictive checks",
              "Prior and likelihood sensitivity", "Model comparison or expansion",
              "Design calibration")

  derived <- if (!is.null(scheme_script)) br_derived_stages(log, scheme_script) else NULL
  coverage <- if (!is.null(derived)) {
    c("## Stage coverage",
      "",
      "Derived from the workflow log by the same rules that write `WORKFLOW.md`: a stage",
      "appears where the log placed an entry or a file at it. Add the manuscript section",
      "that reports each row.",
      "",
      derived,
      "")
  } else {
    c("## Stage coverage",
      "",
      "| Workflow stage | Reported where |",
      "|---|---|",
      paste0("| ", stages, " | [main text section / appendix section / not run, because ...] |"),
      "",
      "A row with nothing to point at is written as what it is: a stage this analysis did",
      "not run, with the reason if there is one. The appendix records the route taken.",
      "")
  }

  qmd <- c(
    "---",
    paste0("title: \"", title, "\""),
    "format:",
    "  html:",
    "    toc: true",
    "  pdf: default",
    "execute:",
    "  echo: false",
    "---",
    "",
    "The estimates in the main text are the product of an iterative workflow rather than",
    "of a single fitted model. This appendix records that workflow as it happened: each",
    "section below is one pass round the loop, in order, with the check that motivated",
    "it and the decision it produced. The main text reports each check at the point",
    "where it bears on a claim; this appendix holds the full record and the figures.",
    "",
    coverage
  )

  for (e in entries) {
    qmd <- c(
      qmd,
      paste0("## ", e$title),
      "",
      "From the workflow log:",
      "",
      if (nzchar(e$body)) paste0("> ", strsplit(e$body, "\n")[[1]]) else "> [log entry was empty]",
      "",
      "[Replace this placeholder with the check's figure or table, and one sentence on",
      "what it showed and what changed as a result. Keep the failures: an appendix that",
      "contains only models that worked is not a record of a workflow.]",
      "",
      "```{r}",
      "#| label: " ,
      "#| fig-cap: \"\"",
      "# insert the pp_check / mcmc_pairs / sensitivity plot for this pass",
      "```",
      ""
    )
  }

  qmd <- c(qmd,
           "## Software",
           "",
           "```{r}",
           "#| echo: true",
           "sessionInfo()",
           "```",
           "")

  # chunk labels must be unique and non-empty; derive them from the entry titles
  lab_at <- which(qmd == "#| label: ")
  labs   <- vapply(seq_along(lab_at), function(i) {
    raw  <- gsub("[^a-z0-9]+", "-", tolower(entries[[i]]$title))
    slug <- gsub("(^-+|-+$)", "", raw)
    # a title with no ASCII alphanumerics slugs to nothing; fall back to the index
    if (!nzchar(slug)) slug <- paste0("entry-", i)
    paste0("#| label: fig-", slug)
  }, character(1))
  qmd[lab_at] <- make.unique(labs, sep = "-")

  writeLines(qmd, out)
  cat("wrote ", out, ": ", length(entries), " workflow section(s) plus the stage coverage table\n",
      sep = "")
  invisible(out)
}

if (sys.nframe() == 0L) {
  args  <- commandArgs(trailingOnly = TRUE)
  force <- "--force" %in% args
  args  <- setdiff(args, "--force")
  if (length(args) > 2L || identical(args[1], "--help")) {
    cat("usage: br_appendix.R [bayes-workflow-log.md] [appendix-workflow.qmd] [--force]\n")
    quit(status = 1L)
  }
  do.call(br_appendix_scaffold, c(as.list(args), list(overwrite = force)))
}
