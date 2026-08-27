################################################################################
# Title:      Workflow appendix scaffold
# Purpose:    Convert a bayes-workflow-log.md into a Quarto supplementary
#             appendix skeleton: one section per logged pass round the loop,
#             plus a stage-coverage checklist to fill in
# Sourced by: bayes-reporting-r skill; call br_appendix_scaffold(), or run
#             Rscript br_appendix.R [log.md] [out.qmd]
# Author:     Chris Moreh
# Last updated: 2026-08-27
################################################################################

# The log's entry format is one "## <date> - <label>" heading per pass, as set out
# in the bayes-workflow-r SKILL.md. Any second-level heading is accepted, so a log
# kept in a looser style still scaffolds; entries simply keep their own titles.

br_appendix_scaffold <- function(log = "bayes-workflow-log.md",
                                 out = "appendix-workflow.qmd",
                                 title = "Supplementary appendix: analysis workflow",
                                 overwrite = FALSE) {

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
    "## Stage coverage",
    "",
    "| Workflow stage | Reported where |",
    "|---|---|",
    paste0("| ", stages, " | [main text section / appendix section / not applicable because ...] |"),
    "",
    "A stage marked not applicable needs its reason: an empty cell reads as a stage",
    "that was skipped.",
    ""
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
  cat("wrote ", out, ": ", length(entries), " workflow section(s) plus the stage checklist\n",
      sep = "")
  invisible(out)
}

if (sys.nframe() == 0L) {
  args  <- commandArgs(trailingOnly = TRUE)
  force <- "--force" %in% args
  args  <- setdiff(args, "--force")
  if (length(args) > 2L || identical(args[1], "--help")) {
    cat("usage: Rscript br_appendix.R [bayes-workflow-log.md] [appendix-workflow.qmd] [--force]\n")
    quit(status = 1L)
  }
  do.call(br_appendix_scaffold, c(as.list(args), list(overwrite = force)))
}
