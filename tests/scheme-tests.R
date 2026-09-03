################################################################################
# Title:      Workflow scheme tests
# Purpose:    Guard bw_scheme.R against checklist drift and check its fidelity:
#             no vocabulary of absence, completion arithmetic, percentage,
#             colour class or em-dash in its strings or in its unquoted output;
#             no recursive listing and no modification times; and the output
#             for the current real log reproduced against the specification's
#             worked example apart from the timestamp
# Reads:      skills/bayes-workflow-r/scripts/bw_scheme.R and the fixtures under
#             tests/fixtures/scheme/: two real analysis directories reduced to
#             what the generator reads, five loose-log cases, and the accepted
#             output for the first directory
# Writes:     WORKFLOW_<name>.md under a temporary directory, nothing in the
#             tree; exit status 0 if every check passes, 1 otherwise
# Author:     Chris Moreh
# Last updated: 2026-09-03
################################################################################

# Every directory is listed one level deep only: the machine's rule against
# recursive traversals applies to this test as much as to the generator.

test_file <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
root      <- normalizePath(file.path(dirname(test_file[1]), ".."), winslash = "/", mustWork = TRUE)
script    <- file.path(root, "skills", "bayes-workflow-r", "scripts", "bw_scheme.R")
# every input lives under tests/fixtures/scheme, so the test runs on any machine
# that has the repository; outputs go to a temporary directory and nothing is
# written into the tree
fixtures  <- file.path(root, "tests", "fixtures", "scheme")
blind     <- fixtures
proto     <- fixtures
expected_file <- file.path(fixtures, "expected", "WORKFLOW_current.md")
generated <- file.path(tempdir(), "scheme-tests")
dir.create(generated, showWarnings = FALSE, recursive = TRUE)

BANNED <- "\\b(should|must|todo|to do|missing|skipped|done|complete|remaining|pending|not yet|no log entry|unvisited)\\b"
ARITH  <- "[0-9]+ ?(/|of) ?(9|10)\\b"
FIXED  <- c(percent = "%", classDef = "classDef", emdash = "\u2014")

results <- list()
check <- function(label, ok, detail = "") {
  results[[length(results) + 1L]] <<- isTRUE(ok)
  cat(sprintf("[%s] %s%s\n", if (isTRUE(ok)) "ok" else "FAIL", label,
              if (nzchar(detail)) paste0(" ", detail) else ""))
  invisible(ok)
}

offenders <- function(x) {
  hits <- c(x[grepl(BANNED, x, ignore.case = TRUE, perl = TRUE)],
            x[grepl(ARITH, x, perl = TRUE)],
            unlist(lapply(FIXED, function(f) x[grepl(f, x, fixed = TRUE)])))
  unique(hits)
}

# ---- 1. the generator's own strings -------------------------------------------

src <- readLines(script, warn = FALSE, encoding = "UTF-8")
pd  <- getParseData(parse(script, keep.source = TRUE, encoding = "UTF-8"))
literals <- pd$text[pd$token == "STR_CONST"]
bad <- offenders(literals)
check("string literals in bw_scheme.R carry none of the guarded words, arithmetic, %, classDef or em-dash",
      !length(bad), if (length(bad)) paste("--", paste(bad, collapse = " | ")) else "")

G <- new.env()
sys.source(script, envir = G)
tables <- unlist(c(G$STRINGS, G$HEADING_CUES, G$BODY_CUES, G$FILE_CUES, G$VERDICTS))
bad <- offenders(tables)
check("STRINGS, HEADING_CUES, BODY_CUES, FILE_CUES and VERDICTS carry none of them",
      !length(bad), if (length(bad)) paste("--", paste(bad, collapse = " | ")) else "")

# ---- 2. static constraints ------------------------------------------------------

check("list.files() is never called with recursive = TRUE",
      !any(grepl("recursive\\s*=\\s*T", src)))
check("file.info and file.mtime never appear", !any(grepl("file\\.(info|mtime)", src)))
check("no library() or requireNamespace() call", !any(grepl("\\b(library|requireNamespace)\\(", src)))
check("no cat() outside the console line and the usage text",
      sum(grepl("\\bcat\\(", src)) == 2L)

# ---- 3. the generator on the real logs and the fixtures ----------------------------

runs <- list(
  current = list(dir = file.path(blind, "with_plugin_current")),
  pre     = list(dir = file.path(blind, "with_plugin_pre"))
)
for (fx in c("loose", "emptylog", "nolog", "fx_noheads", "fx_empty")) {
  if (fx %in% list.files(proto) && dir.exists(file.path(proto, fx))) runs[[fx]] <- list(dir = file.path(proto, fx))
}
outputs <- list()
for (nm in names(runs)) {
  d   <- runs[[nm]]$dir
  out <- file.path(generated, paste0("WORKFLOW_", nm, ".md"))
  res <- tryCatch(G$bw_scheme(log = file.path(d, "bayes-workflow-log.md"), dir = d, out = out, quiet = TRUE),
                  error = function(e) e)
  ok <- !inherits(res, "error") && file.exists(out)
  check(paste0(nm, ": generator runs and writes ", basename(out)), ok,
        if (inherits(res, "error")) paste("--", conditionMessage(res)) else "")
  if (ok) {
    outputs[[nm]] <- readLines(out, warn = FALSE, encoding = "UTF-8")
    check(paste0(nm, ": returned list has entries, files, models and out"),
          all(c("entries", "files", "models", "out") %in% names(res)) && is.data.frame(res$entries))
  }
}

# ---- 4. the outputs, with the log's own words removed -------------------------------

strip_quoted <- function(x) {
  x <- gsub("\"[^\"]*\"", "", x)
  gsub("`[^`]*`", "", x)
}
for (nm in names(outputs)) {
  rest <- strip_quoted(outputs[[nm]])
  bad <- offenders(rest)
  check(paste0(nm, ": unquoted output carries none of the guarded words, arithmetic, %, classDef or em-dash"),
        !length(bad), if (length(bad)) paste("--", paste(bad, collapse = " | ")) else "")
}
if (!is.null(outputs$current)) {
  check("current: the diagram has nine nodes and no classDef",
        sum(grepl("^    s[1-9]\\[", outputs$current)) == 9L && !any(grepl("classDef", outputs$current)))
  check("current: every stage node line is unstyled",
        !any(grepl("style |:::|fill:|stroke", outputs$current)))
}

# ---- 5. the command line ----------------------------------------------------------------

rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
cli_out <- file.path(generated, "WORKFLOW_cli.md")
if (file.exists(cli_out)) invisible(file.remove(cli_out))
d <- runs$current$dir
res <- system2(rscript, shQuote(c(script, file.path(d, "bayes-workflow-log.md"), d, cli_out, "--silent")),
               stdout = TRUE, stderr = TRUE)
check("--silent writes the file, prints nothing and exits 0",
      file.exists(cli_out) && !length(res) && is.null(attr(res, "status")))
res <- system2(rscript, shQuote(c(script, file.path(d, "bayes-workflow-log.md"), d, cli_out)),
               stdout = TRUE, stderr = TRUE)
check("without --silent the console carries the single wrote line",
      length(res) == 1L && grepl("^wrote .*\\(11 entries\\)$", res))
res <- system2(rscript, shQuote(c(script, "--help")), stdout = TRUE, stderr = TRUE)
check("--help prints usage and exits 1", identical(attr(res, "status"), 1L) && any(grepl("usage", res)))
res <- system2(rscript, shQuote(c(script, "a", "b", "c", "d")), stdout = TRUE, stderr = TRUE)
check("more than three positional arguments exits 1", identical(attr(res, "status"), 1L))

# ---- 6. fidelity against the accepted output ---------------------------------------------

expected <- readLines(expected_file, warn = FALSE, encoding = "UTF-8")
normalise <- function(x) sub("^Generated \\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}", "Generated <ts>", x)
got <- if (!is.null(outputs$current)) normalise(outputs$current) else character()
exp_n <- normalise(expected)
same <- identical(got, exp_n)
check("current: output matches the vendored expected file apart from the timestamp", same,
      if (!same) sprintf("-- %d expected lines, %d written", length(exp_n), length(got)) else "")
if (!same) {
  only_exp <- setdiff(exp_n, got); only_got <- setdiff(got, exp_n)
  for (l in only_exp) cat(sprintf("  expected (line %d): %s\n", match(l, exp_n), l))
  for (l in only_got) cat(sprintf("  written  (line %d): %s\n", match(l, got), l))
}

# ---- verdict --------------------------------------------------------------------------------

n_fail <- sum(!unlist(results))
cat(sprintf("%d checks, %d failed\n", length(results), n_fail))
quit(status = if (n_fail) 1L else 0L)
