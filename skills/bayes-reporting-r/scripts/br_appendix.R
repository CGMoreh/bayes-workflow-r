################################################################################
# Title:      Workflow appendix scaffold
# Purpose:    Convert a bayes-workflow-log.md into a Quarto supplementary
#             appendix skeleton: one numbered section per logged pass round the
#             loop, plus a stage-coverage table of the nine stages, derived
#             from the log where the workflow skill's generator is installed
#             and left to fill otherwise
# Sourced by: bayes-reporting-r skill; call br_appendix_scaffold()
# Author:     Chris Moreh
# Last updated: 2026-11-08
################################################################################

# The stage-coverage table is derived from the log where the workflow skill's
# generator, bw_scheme.R, is installed beside this skill: the same placement
# rules that write WORKFLOW.md fill it, so the appendix and the record agree.
# Where that skill is absent the scaffold keeps a table to fill by hand. The
# reporting skill therefore works on its own, and works better with the other.

# the nine stages of the loop as bw_scheme.R names them, used when the generator
# is not there to supply its own STAGE_NAMES
br_stage_names <- c(
  "Simplest defensible model", "Priors and what they imply",
  "Prior predictive simulation", "Fit", "Computational diagnosis",
  "Posterior predictive checks", "Sensitivity by power-scaling",
  "Expand or compare", "Design calibration"
)

br_reported_where <- "[main text section / appendix section / not run, because ...]"

# The path of this file, recorded while the file is being read. Under source()
# the path is kept in the frame of source(), which has gone by the time a
# function defined here runs; when the file is run as a script, the path is the
# --file argument of the command line.
br_appendix_file <- local({
  src <- Filter(function(e) is.character(e$ofile), sys.frames()) # r-style: keep – base R only, the plugin adds no package
  if (length(src)) {
    e <- src[[length(src)]]
    # with chdir = TRUE, source() has already moved into the folder of the file
    if (is.null(e$owd)) normalizePath(e$ofile, mustWork = FALSE) else file.path(getwd(), basename(e$ofile))
  } else {
    f <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
    if (length(f)) normalizePath(f[1], mustWork = FALSE) else ""
  }
})

br_find_scheme <- function(scheme_script = NULL) {
  if (!is.null(scheme_script)) return(if (file.exists(scheme_script)) scheme_script else NULL)
  here <- get0("br_appendix_file", ifnotfound = "")
  if (!nzchar(here)) return(NULL)
  cand <- file.path(dirname(dirname(here)), "..", "bayes-workflow-r", "scripts", "bw_scheme.R")
  if (file.exists(cand)) normalizePath(cand) else NULL
}

# Runs the generator on the log into a temporary file and lifts its Stages
# section, so the appendix reuses the renderer rather than reimplementing it.
# Returns the generator's stage names and the table, whose rows are NULL when the
# generator cannot derive them from this log; NULL when it cannot be sourced.
br_derived_stages <- function(log, scheme_script) {
  env <- new.env()
  ok  <- tryCatch({ sys.source(scheme_script, envir = env); TRUE }, error = function(e) FALSE)
  if (!ok) return(NULL)
  names <- if (is.character(env$STAGE_NAMES) && length(env$STAGE_NAMES) == 9L) {
    unname(env$STAGE_NAMES)
  } else {
    br_stage_names
  }
  tmp <- tempfile(fileext = ".md")
  res <- tryCatch(env$bw_scheme(log = log, out = tmp, quiet = TRUE), error = function(e) NULL)
  if (is.null(res) || !file.exists(tmp)) return(list(names = names, table = NULL))
  md   <- readLines(tmp, warn = FALSE, encoding = "UTF-8")
  from <- which(md == "## Stages")
  if (!length(from)) return(list(names = names, table = NULL))
  nxt  <- which(grepl("^## ", md) & seq_along(md) > from[1])
  to   <- if (length(nxt)) nxt[1] - 1L else length(md)
  block <- md[(from[1] + 1L):to]
  block <- block[nzchar(trimws(block))]
  # the generator writes a row only for a stage it placed something at; the
  # appendix keeps all nine in the generator's order, and the entry cell of a
  # stage with no entry placed at it says so
  dash <- "\u2013"
  rows <- vapply(seq_along(names), function(s) { # r-style: keep – base R only, the plugin adds no package
    row <- block[startsWith(block, paste0("| ", s, " "))]
    row <- if (length(row)) row[1] else paste0("| ", s, " ", names[s], " | ", dash, " | ", dash, " | ", dash, " |")
    row <- sub(paste0("^([|] ", s, " [^|]+[|] )", dash, " [|]"),
               "\\1no entry placed here by the log's wording |", row)
    paste0(row, " ", br_reported_where, " |")
  }, character(1))
  writeup <- block[startsWith(block, "| Write-up |")]
  list(names = names,
       table = c(paste0(block[1], " Reported where |"), paste0(block[2], "---|"), rows,
                 if (length(writeup)) paste0(writeup[1], " ", dash, " |")))
}

# The log's entry format is one "## <date> – <label>" heading per pass, as set out
# in the bayes-workflow-r SKILL.md. Any second-level heading is accepted, so a log
# kept in a looser style still scaffolds; entries simply keep their own titles,
# and are numbered in log order as the generator numbers them.

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

  derived <- if (!is.null(scheme_script)) br_derived_stages(log, scheme_script) else NULL
  names   <- if (is.null(derived)) br_stage_names else derived$names
  table   <- if (is.null(derived)) NULL else derived$table
  coverage <- if (!is.null(table)) {
    c("## Stage coverage",
      "",
      paste0("Derived from the workflow log by the same rules that write `WORKFLOW.md`. ",
             "Each of the nine stages lists the entries placed at it by the wording of the ",
             "log, the entries whose text also reaches it and the files placed at it, and ",
             "the numbers are those of the entry sections below. Fill the last column with ",
             "the manuscript section that reports each stage. A stage with no entry placed ",
             "at it may still have been run inside another entry, as a prior predictive ",
             "check often is, so read the entries that reach it before writing that the ",
             "stage was not run."),
      "",
      table,
      "")
  } else {
    c("## Stage coverage",
      "",
      "| Stage | Reported where |",
      "|---|---|",
      paste0("| ", seq_along(names), " ", names, " | ", br_reported_where, " |"),
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

  for (i in seq_along(entries)) {
    e <- entries[[i]]
    qmd <- c(
      qmd,
      paste0("## Entry ", i, " \u2013 ", e$title),
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
  how <- if (!is.null(table)) {
    paste0("the stage coverage table derived from the log by ", basename(scheme_script))
  } else if (is.null(scheme_script)) {
    "a stage coverage table to fill by hand, because bw_scheme.R was not found beside this skill"
  } else {
    paste0("a stage coverage table to fill by hand, because ", basename(scheme_script),
           " could not derive one from this log")
  }
  cat("wrote ", out, ": ", length(entries), " workflow section(s) and ", how, "\n", sep = "") # r-style: keep – the console line is the scaffolder's report
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
