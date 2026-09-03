################################################################################
# Title:      Workflow scheme generator
# Purpose:    Read bayes-workflow-log.md and the files in an analysis directory
#             and write WORKFLOW.md – an index of the log's entries and of the
#             files on disk, placed on the nine-stage loop. The scheme is derived
#             from the log and the disk and never instructs: every sentence it
#             emits names an entry, a file or a sentence quoted from the log.
#             Base R only, so it runs wherever Rscript does.
# Sourced by: the bayes-workflow-r skill, which calls bw_scheme(); the
#             bayes-reporting-r skill's br_appendix.R, which calls the pure
#             parsers bw_read_log, bw_place_entries, bw_scan_dir and bw_link
# Author:     Chris Moreh
# Last updated: 2026-09-03
################################################################################

# The dashes and the middle dot are written as \u escapes so that the source
# parses identically under any native encoding; the output is always UTF-8.

# ---- the loop ----------------------------------------------------------------

STAGE_NAMES <- c(
  "1" = "Simplest defensible model",
  "2" = "Priors and what they imply",
  "3" = "Prior predictive simulation",
  "4" = "Fit",
  "5" = "Computational diagnosis",
  "6" = "Posterior predictive checks",
  "7" = "Sensitivity by power-scaling",
  "8" = "Expand or compare",
  "9" = "Design calibration"
)

DIAGRAM_COLUMNS <- list(
  list(id = "P1", title = "Before the data are used",            stages = 1:3),
  list(id = "P2", title = "Fit and check",                       stages = 4:6),
  list(id = "P3", title = "Sensitivity, expansion, calibration", stages = 7:9)
)

# ---- cue tables: PCRE, case-insensitive --------------------------------------

# One heading hit places an entry (or a script by its banner title). "W" is the
# write-up bin outside the loop. Stage 4 is consulted for scripts and banner
# titles only: every pass fits, so the word places no entry.
HEADING_CUES <- c(
  "1" = "estimand|simplest|the question|before any (model|fit)|quantity of interest|data description|description of the data|descriptive|explor|\\beda\\b|first look",
  "2" = "\\bpriors?\\b",
  "3" = "prior[- ]predictive",
  "5" = "diagnos|converg|divergen|r-?hat|treedepth",
  "6" = "predictive check|\\bppc|posterior[- ]predictive",
  "7" = "sensitiv|power[- ]scal|priorsense",
  "8" = "compar|expan|\\bloo\\b|elpd|cross-valid|k-?fold",
  "9" = "calibrat|recover|fake[- ]data|simulation[- ]based|\\bsbc\\b",
  "W" = "\\breport\\b|manuscript|number check|check_numbers|methods section|appendix|write-?up|session ?info",
  "4" = "\\bfit(ted|s|ting)?\\b|\\bbrm\\("
)

# Two non-overlapping body hits place or reach a stage. Stage 4 has no body
# cue: it is carried by model ids, or by FIT_FALLBACK in a log without ids.
BODY_CUES <- c(
  "1" = "estimand|quantity of interest|abandon|simplest|subject knowledge|before any (model|fit)|what contrast|the question\\b|target population",
  "2" = "\\b(normal|student_t|exponential|cauchy|gamma|beta|lognormal|lkj|dirichlet|horseshoe|r2d2)\\s*\\(|set_prior|\\bprior\\(",
  "3" = "prior[- ]predictive|sample_prior|from the prior alone|prior (simulation|replicate)|simulat\\w*.{0,40}\\bprior|\\bprior\\w*.{0,40}simulat",
  "5" = "divergent|divergences\\b|r-?hat|effective sample|\\bess\\b|treedepth|bfmi|converg|mixing|adapt_delta|funnel|reparameteris",
  "6" = "posterior[- ]predictive|pp_check|\\bppc|predictive p-value|predictive interval|reproduc|zero proportion|share of zeros|proportion of zeros|\\bp = ?0?\\.\\d+|misfit|predicted (maximum|standard deviation|mean|share|proportion|sd)|grouped cell",
  "7" = "power[- ]scal|priorsense|sensitivit|prior-data conflict",
  "8" = "\\belpd|\\bloo\\b|loo-cv|k-?fold|cross-validat|pareto k|moment[- ]match|p_loo|projpred|compar(e|ed|es|ison)|expand|expansion|adds? (a|the|an) .{0,30}term|carried forward|is dropped|indistinguishable|\\bbehind\\b",
  "9" = "calibrat|\\brecover(ed|y|s)?\\b|fake[- ]data|simulation[- ]based|\\bsbc\\b|sign[- ]error|exaggerat|trials simulated|simulated at n"
)

# On the lower-cased file stem or basename; lookarounds stand in for \b because
# "_" is a word character.
FILE_CUES <- c(
  "1" = "estimand|(?<![a-z])eda(?![a-z])|explore|describ|(?<![a-z])dag(?![a-z])",
  "2" = "prior(?![-_ ]?(pred|check|only|sim))",
  "3" = "prior[-_ ]?(pred|check|only|sim)|sample_prior",
  "4" = "(?<![a-z])fit|(?<![a-z])models?(?![a-z])",
  "5" = "diagnos|converg|trace|rhat|divergen|mcmc",
  "6" = "(?<![a-z])ppc|pp_check|posterior_?pred",
  "7" = "sensitiv|power|priorsense|(?<![a-z])sens(?![a-z])",
  "8" = "compar|(?<![a-z])loo|kfold|elpd|expand|extra|projpred|select",
  "9" = "calibrat|recover|(?<![a-z])sbc(?![a-z])|simul",
  "W" = "report|check_numbers|number_check|session|manuscript"
)

# Verdict phrases for the Models table, attributed within a sentence to the
# nearest model id before the phrase, else the first id after it.
VERDICTS <- "carried forward|carr(y|ies) forward|best model|reported model|primary model|final model|preferred model|kept in the report|is dropped|dropped|superseded|retired|abandoned|indistinguishable|does not contain|the offset stands"

# The sentence quoted on the first screen: the last one in log order that has
# one of these phrases and names a model id.
CARRIED_RX <- "carried forward|carr(y|ies) forward|best model|reported model|primary model|final model|preferred model|is the answer|model reported"

# Stage 4 in a log that names no model at all: one guarded body hit.
FIT_FALLBACK <- "(?<!nothing )(?<!not )(?<!never )(?<!no )\\bfit(ted|s)?\\b|\\brefit"

# The last entry's own sentence on what is left, quoted when it has no "Next".
REMAINS_RX <- "remains|still to|to run|not\\s+yet|next step"

ID_RX      <- "(?<![a-z0-9])m(\\d{1,3})(?![0-9])"
ID_RANGE   <- "(?<![a-z0-9])m(\\d{1,3})\\s*(to|through|–|\u2014|-)\\s*m(\\d{1,3})(?![0-9])"
SEP_CHARS  <- "[–\u2014:-]"
SEP_RX     <- paste0("^\\s*", SEP_CHARS, "\\s*")
MARKER_RX  <- "\\[(stages?|steps?)\\s*[0-9][0-9 ,and–\u2014-]*\\]\\s*$"
DASH_RANGE <- "\\d+\\s*[–\u2014-]\\s*\\d+"
FIT_FILE   <- "^m\\d{1,3}[_.-]"
PREFIX_RX  <- "^\\d+[a-z]?(?=_)"
SCRIPT_EXT <- "\\.(R|r|qmd|Rmd|rmd)$"
PATH_EXT   <- "txt|csv|png|pdf|rds|R|qmd|md|html|svg|json"

# ---- fixed strings -------------------------------------------------------------

STRINGS <- list(
  dash   = "–",
  dot    = " · ",
  title  = "# Workflow record – ",
  rewritten = "This file is rewritten from the log by `bw_scheme.R`; changes made here do not survive regeneration.",
  h_stands  = "## Where the analysis stands",
  h_loop    = "## The loop as the log walked it",
  caption   = "Each node names the entries placed at that stage; \"also\" marks entries placed elsewhere whose text reaches the stage. Step 10, the return to step 1, is read from the passes table: an entry placed at an earlier stage than the entry before it. Entries outside the loop (the write-up) are in the passes table.",
  h_stages  = "## Stages",
  stages_header = c("| Stage | Entries placed here | Also reached by | Files placed here |", "|---|---|---|---|"),
  h_passes  = "## Passes in the order logged",
  passes_header = c("| # | Date | Entry | Stage | Also | Placed by | Models first named | Files named | Next, as written |", "|---:|---|---|---|---|---|---|---|---|"),
  not_on_disk = "(not on disk)",
  paths_absent = "Paths named in the log that are not on disk: ",
  h_models  = "## Models",
  models_header = c("| Model | Files with this id in the name | First entry | Last entry | What the log says of it |", "|---|---|---|---|---|"),
  not_in_log = "not in the log",
  h_repro   = "## Reproducibility record",
  data_files = "- Data files: ",
  helpers    = "- Helper scripts (sourced by others): ",
  seeds      = "- Seed calls found in the scripts: ",
  session    = "- Session information: ",
  evidence_summary = "Evidence for each placement",
  files_summary    = "Files on disk",
  scripts_title    = "Scripts",
  scripts_header   = c("| Script | Stage | Stage by | Banner title | Declared output | Named in entries |", "|---|---|---|---|---|---|"),
  files_title      = "Output, figures and model files",
  files_header     = c("| File | Script | Stage | Stage by | Entries |", "|---|---|---|---|---|"),
  h_made = "## How this file was made",
  made   = "`bw_scheme.R` reads `bayes-workflow-log.md`, the scripts in this directory, and the names of the files in `output/`, `figures/` and `model-data/`; it reads no file's contents apart from the log and the scripts. An entry is placed by the first rule that applies: a `[stage n]` marker at the end of its heading; a heading naming the estimand or describing the data, before any model id has appeared in the log; a heading naming the report; cue words in the heading; two or more cue words in the body; a model id first named in the entry (stage 4); otherwise it is unplaced. Other stages an entry reaches are those with a cue in its heading or two cues in its body, and stage 4 whenever the entry first names a model. A file is placed through the script that declares it in its banner or shares its numeric prefix, else by words in its name, and a `model-data/m<n>_*.rds` file always carries stage 4. A placement is changed by editing the log entry; nothing else is inferred.",
  placed_marker  = "marker",
  placed_p1      = "heading wording, before the first fit",
  placed_heading = "heading wording",
  placed_body    = "body wording",
  placed_models  = "models first named",
  placed_none    = "no match",
  writeup = "write-up",
  helper  = "helper",
  last_entry     = "- Last entry: ",
  last_in_loop   = "- Last entry inside the loop: ",
  outside        = "outside the loop: write-up",
  no_stage       = "no stage placed",
  next_written   = "- Next, as the last entry writes it: ",
  no_next        = "- The last entry has no line marked \"Next\". ",
  remains        = "Its last sentence on what remains: ",
  it_ends        = "It ends: ",
  carried        = "- Model the log last describes as carried forward, best or reported: ",
  models_named   = "- Models named in the log: ",
  fit_on_disk    = "Fit files on disk for ",
  disk_only      = "On disk but not in the log: ",
  log_only       = "In the log with no fit file on disk: ",
  ev_precedes    = "; the entry precedes the first fit, so its body was not scanned.",
  ev_writeup     = "; the body of a write-up entry is not scanned.",
  ev_below       = "Below the two hits a stage needs: ",
  ev_body_words  = "; body words for ",
  ev_first_named = " first named here.",
  ev_brm         = "brm( in the body.",
  ev_fit_word    = "a fit word in the body.",
  ev_unplaced    = "Unplaced: no cue in the heading or the body.",
  ev_opens = "Opens: ",
  ev_ends  = "Ends: ",
  by_file_name   = "file name",
  by_banner_title = "banner title",
  by_banner_purpose = "banner purpose",
  by_sourced      = "banner purpose (sourced by)",
  by_script       = "script",
  by_script_name  = "script and file name",
  by_fit_file     = "fit file",
  by_fit_script   = "fit file and script",
  by_fit_name     = "fit file and file name",
  own_banner = "banner",
  own_prefix = "prefix",
  console = "wrote ",
  usage = c("usage: bw_scheme.R [log] [dir] [out] [--silent]",
            "  log   the workflow log (default bayes-workflow-log.md)",
            "  dir   the analysis directory (default: the log's directory)",
            "  out   the file to write (default: WORKFLOW.md beside the log)",
            "  --silent   write the file and print nothing")
)

# ---- small helpers ----------------------------------------------------------------

collapse_ws <- function(x) trimws(gsub("\\s+", " ", paste(x, collapse = " ")))

# Every match of a cue, in text order, lower-cased and extended to the end of
# the word it stops inside, so that "power-scal" is shown as "power-scaling".
hits_of <- function(rx, text) {
  if (!length(text) || !nzchar(text)) return(character())
  m <- gregexpr(rx, text, perl = TRUE, ignore.case = TRUE)[[1]]
  if (m[1] == -1L) return(character())
  starts <- as.integer(m)
  ends   <- starts + attr(m, "match.length") - 1L
  vapply(seq_along(starts), function(i) {
    rest <- substring(text, ends[i] + 1L)
    ext  <- regmatches(rest, regexpr("^[A-Za-z]+", rest))
    tolower(substring(text, starts[i], ends[i] + if (length(ext)) nchar(ext) else 0L))
  }, "")
}

model_ids <- function(text) {
  text <- paste(text, collapse = " ")
  if (!nzchar(text)) return(integer())
  ids <- integer()
  for (r in regmatches(text, gregexpr(ID_RANGE, text, perl = TRUE, ignore.case = TRUE))[[1]]) {
    n <- as.integer(regmatches(r, gregexpr("\\d+", r))[[1]])
    if (n[2] > n[1] && n[2] - n[1] <= 50L) ids <- c(ids, seq(n[1], n[2]))
  }
  s <- regmatches(text, gregexpr(ID_RX, text, perl = TRUE, ignore.case = TRUE))[[1]]
  sort(unique(c(ids, as.integer(sub("^[mM]", "", s)))))
}

# ids in text order, with their start positions
ids_in_order <- function(text) {
  m <- gregexpr(ID_RX, text, perl = TRUE, ignore.case = TRUE)[[1]]
  if (m[1] == -1L) return(data.frame(id = integer(), at = integer()))
  s <- regmatches(text, list(m))[[1]]
  data.frame(id = as.integer(sub("^[mM]", "", s)), at = as.integer(m))
}

# "1–2", "4–7, 10"; with prefix "m": "m1–m6, m9–m14"
compress_nums <- function(v, prefix = "") {
  v <- sort(unique(as.integer(v)))
  if (!length(v)) return("")
  runs <- split(v, cumsum(c(1L, diff(v) != 1L)))
  paste(vapply(runs, function(r) {
    if (length(r) > 1L) paste0(prefix, r[1], STRINGS$dash, prefix, r[length(r)]) else paste0(prefix, r)
  }, ""), collapse = ", ")
}

entry_word <- function(v) {
  v <- unique(v)
  paste(if (length(v) > 1L) "entries" else "entry", compress_nums(v))
}

nat_sort <- function(x) {
  if (!length(x)) return(x)
  key <- vapply(x, function(s) {
    m <- gregexpr("[0-9]+", s)
    regmatches(s, m) <- list(formatC(as.integer(regmatches(s, m)[[1]]), width = 12, flag = "0"))
    s
  }, "")
  x[order(key, method = "radix")]
}

tick <- function(x) paste0("`", x, "`")

md_cell <- function(x) {
  x <- paste(x, collapse = ", ")
  x <- gsub("|", "\\|", x, fixed = TRUE)
  if (!nzchar(x)) STRINGS$dash else x
}

stage_label <- function(s) {
  if (identical(s, "W")) STRINGS$writeup else if (identical(s, "") || is.na(s)) STRINGS$dash else s
}

stamp <- function() {
  t <- as.POSIXlt(Sys.time())
  two <- function(n) formatC(n, width = 2L, flag = "0")
  paste0(1900L + t$year, "-", two(t$mon + 1L), "-", two(t$mday), " ", two(t$hour), ":", two(t$min))
}

# Sentences of a body: short bold labels go, then all ** and backticks; a
# sentence beginning "Output:" is dropped.
sentences <- function(body) {
  t <- gsub("\\*\\*[^*]{1,40}\\*\\*", "", body, perl = TRUE)
  t <- gsub("\\*\\*|`", "", t)
  t <- collapse_ws(t)
  if (!nzchar(t)) return(character())
  s <- trimws(strsplit(t, "(?<=[.!?])\\s+", perl = TRUE)[[1]])
  s <- s[nzchar(s)]
  s[!grepl("^Outputs?:", s)]
}

paths_named <- function(text) {
  a <- regmatches(text, gregexpr(paste0("`([^` ]*?\\.(", PATH_EXT, "))`"), text, perl = TRUE))[[1]]
  a <- gsub("`", "", a)
  b <- regmatches(text, gregexpr(paste0("(?<![A-Za-z0-9_/`])(output|figures|model-data|data)/[A-Za-z0-9_./-]+\\.(", PATH_EXT, ")(?![A-Za-z])"), text, perl = TRUE))[[1]]
  unique(c(a, b))
}

next_text <- function(body) {
  m <- regmatches(body, regexpr("\\bNext[:.]\\s+.*?(?<=[.!?])(?=\\s|$)|\\bNext[:.]\\s+.*$", body, perl = TRUE))
  if (!length(m)) return(NA_character_)
  trimws(sub("^Next[:.]\\s+", "", m, perl = TRUE))
}

# ---- the log ------------------------------------------------------------------

# Returns a list: exists, path, n_lines, h1 (the title after the log prefix, or
# ""), h1_second (line number of a second H1, or NA), entries. Each entry is a
# list with n, date, label, marker (integer stages), marker_text, body (one
# collapsed string), text (label and body together).
bw_read_log <- function(path) {
  if (!file.exists(path)) {
    return(list(exists = FALSE, path = path, n_lines = 0L, h1 = "", h1_second = NA_integer_,
                entries = list()))
  }
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  h1_at <- grep("^# ", lines)
  h1 <- if (length(h1_at)) trimws(sub("^#\\s*", "", lines[h1_at[1]])) else ""
  h1 <- trimws(sub(paste0("^(bayesian workflow log|workflow log)\\s*", SEP_CHARS, "?\\s*"), "", h1,
                   ignore.case = TRUE, perl = TRUE))
  heads <- grep("^## ", lines)
  ends  <- c(heads[-1] - 1L, length(lines))
  entries <- lapply(seq_along(heads), function(i) {
    title <- trimws(sub("^## ", "", lines[heads[i]]))
    date  <- regmatches(title, regexpr("^\\d{4}-\\d{2}-\\d{2}", title))
    label <- sub("^\\d{4}-\\d{2}-\\d{2}", "", title)
    label <- trimws(sub(SEP_RX, "", label, perl = TRUE))
    marker_text <- regmatches(label, regexpr(MARKER_RX, label, perl = TRUE, ignore.case = TRUE))
    marker <- integer()
    if (length(marker_text)) {
      label  <- trimws(sub(MARKER_RX, "", label, perl = TRUE, ignore.case = TRUE))
      inner  <- sub("^\\[(stages?|steps?)", "", marker_text, ignore.case = TRUE)
      for (r in regmatches(inner, gregexpr(DASH_RANGE, inner, perl = TRUE))[[1]]) {
        n <- as.integer(regmatches(r, gregexpr("\\d+", r))[[1]])
        if (n[2] >= n[1]) marker <- c(marker, seq(n[1], n[2]))
      }
      marker <- c(marker, as.integer(regmatches(inner, gregexpr("\\d+", inner))[[1]]))
      marker <- unique(marker[marker >= 1L & marker <= 9L])
    }
    body <- if (ends[i] > heads[i]) collapse_ws(lines[(heads[i] + 1L):ends[i]]) else ""
    list(n = i, date = if (length(date)) date else NA_character_, label = label,
         marker = marker, marker_text = if (length(marker_text)) marker_text else "",
         body = body, text = paste(label, body))
  })
  list(exists = TRUE, path = path, n_lines = length(lines), h1 = h1,
       h1_second = if (length(h1_at) > 1L) h1_at[2] else NA_integer_, entries = entries)
}

# ---- placement ------------------------------------------------------------------

LOOP_HEAD <- c("1", "2", "3", "5", "6", "7", "8", "9")

# Adds to each entry: stage ("1".."9", "W", or ""), also (integer), placed_by,
# new_ids, ids, carries4, scanned, paths, next_text, opens, closes, closes_long,
# sents, evidence. Placement is sequential because P1 and stage 4 depend on
# which ids earlier entries introduced; the pass runs twice so that the
# before-the-first-fit restriction applies only when some entry carries 4.
bw_place_entries <- function(entries) {
  if (!length(entries)) return(entries)
  no_ids_log <- !length(model_ids(vapply(entries, `[[`, "", "text")))
  run <- function(restrict) {
    introduced <- integer()
    fit_seen   <- FALSE
    for (i in seq_along(entries)) {
      e <- entries[[i]]
      h_hits <- lapply(HEADING_CUES[LOOP_HEAD], hits_of, text = e$label)
      w_hits <- hits_of(HEADING_CUES[["W"]], e$label)
      has_marker <- length(e$marker) > 0L
      p1 <- !has_marker && !length(introduced) && length(h_hits[["1"]]) > 0L
      w  <- !has_marker && !p1 && length(w_hits) > 0L && !any(lengths(h_hits) > 0L)
      plan <- p1 || w
      ids_all <- model_ids(e$text)
      new_ids <- if (plan) integer() else setdiff(ids_all, introduced)
      has_brm <- !plan && grepl("\\bbrm\\(", e$body, perl = TRUE)
      fit_word <- no_ids_log && !plan && length(hits_of(FIT_FALLBACK, e$body)) > 0L
      carries4 <- length(new_ids) > 0L || has_brm || fit_word
      allowed <- if (restrict && !fit_seen && !carries4 && !has_marker) c(1L, 2L, 3L, 9L) else 1:9
      b_hits <- if (plan) setNames(vector("list", length(BODY_CUES)), names(BODY_CUES))
                else lapply(BODY_CUES, hits_of, text = e$body)
      head_st <- intersect(as.integer(names(h_hits)[lengths(h_hits) > 0L]), allowed)
      body_n  <- lengths(b_hits)
      body_st <- intersect(as.integer(names(b_hits)[body_n >= 2L]), allowed)
      also <- integer()
      if (has_marker) {
        stage <- as.character(e$marker[1]); also <- e$marker[-1]; by <- STRINGS$placed_marker
      } else if (p1) {
        stage <- "1"; by <- STRINGS$placed_p1
      } else if (w) {
        stage <- "W"; by <- STRINGS$placed_heading
      } else if (length(head_st)) {
        stage <- as.character(max(head_st)); by <- STRINGS$placed_heading
      } else if (length(body_st)) {
        top <- body_st[body_n[as.character(body_st)] == max(body_n[as.character(body_st)])]
        stage <- as.character(max(top)); by <- STRINGS$placed_body
      } else if (length(new_ids) || has_brm) {
        stage <- "4"; by <- STRINGS$placed_models
      } else {
        stage <- ""; by <- STRINGS$placed_none
      }
      if (!has_marker && !plan) also <- c(also, head_st, body_st)
      if (carries4) also <- c(also, 4L)
      also <- sort(setdiff(unique(also), suppressWarnings(as.integer(stage))))
      if (carries4) fit_seen <- TRUE
      introduced <- c(introduced, new_ids)
      sents <- sentences(e$body)
      closes <- if (length(sents)) sents[length(sents)] else NA_character_
      closes_long <- closes
      if (length(sents) > 1L && nchar(closes) < 60L) closes_long <- paste(sents[length(sents) - 1L], closes)
      entries[[i]][c("stage", "also", "placed_by", "new_ids", "ids", "carries4", "scanned",
                     "paths", "next_text", "opens", "closes", "closes_long", "sents")] <-
        list(stage, also, by, new_ids, ids_all, carries4, !plan,
             paths_named(e$text), next_text(e$body),
             if (length(sents)) sents[1] else NA_character_, closes, closes_long, sents)
      entries[[i]]$evidence <- evidence_text(entries[[i]], h_hits, w_hits, b_hits, allowed, has_brm, fit_word)
    }
    entries
  }
  first <- run(FALSE)
  if (any(vapply(first, `[[`, TRUE, "carries4"))) run(TRUE) else first
}

# One paragraph per entry: the stage, the rule, the words matched per stage,
# the ids first named, and the opening and closing sentences verbatim.
evidence_text <- function(e, h_hits, w_hits, b_hits, allowed, has_brm, fit_word) {
  q <- function(x) paste0("\"", x, "\"")
  words <- function(v) paste(unique(v), collapse = ", ")
  stage_words <- function(s) {
    s <- as.character(s)
    c(if (s %in% names(h_hits) && length(h_hits[[s]])) paste0(h_hits[[s]], " (heading)"),
      if (s %in% names(b_hits) && length(b_hits[[s]])) b_hits[[s]])
  }
  head <- paste0("**Entry ", e$n, " ", STRINGS$dash, " ", gsub("\\*\\*", "", e$label), ".** ")
  s <- e$stage
  if (e$placed_by == STRINGS$placed_p1) {
    main <- paste0("Placed at 1 by ", STRINGS$placed_heading, " (", words(h_hits[["1"]]), ")", STRINGS$ev_precedes)
  } else if (s == "W") {
    main <- paste0("Placed outside the loop (", STRINGS$writeup, ") by ", STRINGS$placed_heading,
                   " (", words(w_hits), ")", STRINGS$ev_writeup)
  } else if (e$placed_by == STRINGS$placed_none) {
    main <- STRINGS$ev_unplaced
  } else {
    if (e$placed_by == STRINGS$placed_marker) {
      main <- paste0("Placed at ", s, " by ", STRINGS$placed_marker, " (", e$marker_text, ")")
    } else if (e$placed_by == STRINGS$placed_heading) {
      main <- paste0("Placed at ", s, " by ", STRINGS$placed_heading, " (", words(h_hits[[s]]), ")")
    } else if (e$placed_by == STRINGS$placed_body) {
      main <- paste0("Placed at ", s, " by ", STRINGS$placed_body, " (", paste(b_hits[[s]], collapse = ", "), ")")
    } else {
      main <- paste0("Placed at 4 by ", STRINGS$placed_models, " (",
                     if (length(e$new_ids)) compress_nums(e$new_ids, "m") else "brm(", ")")
    }
    if (e$placed_by != STRINGS$placed_body && s %in% names(b_hits) && length(b_hits[[s]])) {
      main <- paste0(main, STRINGS$ev_body_words, s, ": ", words(b_hits[[s]]),
                     " (", length(b_hits[[s]]), if (length(b_hits[[s]]) == 1L) " hit)" else " hits)")
    }
    main <- paste0(main, ".")
  }
  out <- paste0(head, main)
  for (a in e$also) {
    if (a == 4L) {
      what <- if (length(e$new_ids)) paste0(compress_nums(e$new_ids, "m"), STRINGS$ev_first_named)
              else if (has_brm) STRINGS$ev_brm else STRINGS$ev_fit_word
      out <- paste0(out, " Also 4: ", what)
    } else {
      sw <- stage_words(a)
      out <- paste0(out, " Also ", a, if (length(sw)) paste0(": ", words(sw)) else "", ".")
    }
  }
  if (e$scanned) {
    below <- setdiff(intersect(as.integer(names(b_hits)[lengths(b_hits) == 1L]), allowed),
                     c(suppressWarnings(as.integer(s)), e$also))
    if (length(below)) {
      out <- paste0(out, " ", STRINGS$ev_below,
                    paste(vapply(below, function(b) paste0(b, " (", b_hits[[as.character(b)]], ")"), ""),
                          collapse = ", "), ".")
    }
  }
  if (!is.na(e$opens)) {
    out <- paste0(out, " ", STRINGS$ev_opens, q(e$opens))
    if (length(e$sents) > 1L) out <- paste0(out, " ", STRINGS$ev_ends, q(e$closes))
  }
  out
}

# ---- the disk -----------------------------------------------------------------

read_banner <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  head_end <- match(FALSE, grepl("^\\s*(#|$)", lines), nomatch = length(lines) + 1L) - 1L
  fields <- list(); cur <- ""
  for (x in lines[seq_len(head_end)]) {
    m <- regmatches(x, regexec("^#\\s*(Title|Purpose|Output|Outputs|Writes|Sourced by)\\s*:\\s*(.*)$", x,
                               ignore.case = TRUE))[[1]]
    if (length(m)) {
      cur <- tolower(m[2]); if (cur == "outputs" || cur == "writes") cur <- "output"
      fields[[cur]] <- trimws(paste(c(fields[[cur]], trimws(m[3])), collapse = " "))
    } else if (nzchar(cur) && grepl("^#\\s{4,}\\S", x)) {
      fields[[cur]] <- paste(fields[[cur]], trimws(sub("^#\\s*", "", x)))
    } else cur <- ""
  }
  seeds <- unlist(regmatches(lines, gregexpr("set\\.seed\\([^)]*\\)", lines)))
  list(title = if (is.null(fields$title)) "" else fields$title,
       purpose = if (is.null(fields$purpose)) "" else fields$purpose,
       output = if (is.null(fields$output)) "" else fields$output,
       sourced = !is.null(fields[["sourced by"]]), seeds = unique(seeds))
}

file_stages <- function(base) {
  s <- tolower(base)
  names(FILE_CUES)[vapply(FILE_CUES, function(rx) grepl(rx, s, perl = TRUE), TRUE)]
}

# Every stage a script carries and how it was found, from the stem, then the
# banner title, then the banner purpose. A helper is a script sourced by others.
script_stage <- function(base, banner) {
  if (banner$sourced || grepl("sourced by", banner$purpose, ignore.case = TRUE)) {
    return(list(stages = STRINGS$helper, by = STRINGS$by_sourced))
  }
  st <- file_stages(sub("\\.[^.]+$", "", base))
  if (length(st)) return(list(stages = st, by = STRINGS$by_file_name))
  st <- names(HEADING_CUES)[vapply(HEADING_CUES, function(rx) length(hits_of(rx, banner$title)) > 0L, TRUE)]
  if (length(st)) return(list(stages = st, by = STRINGS$by_banner_title))
  n <- vapply(BODY_CUES, function(rx) length(hits_of(rx, banner$purpose)), 0L)
  if (any(n >= 2L)) {
    top <- names(n)[n == max(n)]
    return(list(stages = top[length(top)], by = STRINGS$by_banner_purpose))
  }
  list(stages = character(), by = STRINGS$placed_none)
}

# Returns a list: dir, scripts (one list per script: path, base, prefix, title,
# purpose, output, declared, seeds, stages, stage_by), files (path, kind, base,
# prefix, ids, own_stages), data (paths under data/). Nothing is listed below
# one level, and no modification time is read.
bw_scan_dir <- function(dir) {
  top <- list.files(dir)
  top <- top[!dir.exists(file.path(dir, top))]
  script_paths <- nat_sort(top[grepl(SCRIPT_EXT, top)])
  for (sub in c("scripts", "R", "code")) {
    p <- file.path(dir, sub)
    if (dir.exists(p)) {
      f <- list.files(p)
      f <- f[grepl(SCRIPT_EXT, f) & !dir.exists(file.path(p, f))]
      script_paths <- c(script_paths, paste0(sub, "/", nat_sort(f)))
    }
  }
  scripts <- lapply(script_paths, function(sp) {
    base <- basename(sp)
    b <- read_banner(file.path(dir, sp))
    declared <- if (nzchar(b$output)) trimws(strsplit(b$output, ",")[[1]]) else character()
    declared <- declared[nzchar(declared)]
    st <- script_stage(base, b)
    list(path = sp, base = base,
         prefix = regmatches(base, regexpr(PREFIX_RX, base, perl = TRUE)),
         title = b$title, purpose = b$purpose, output = b$output, declared = declared,
         seeds = b$seeds, stages = st$stages, stage_by = st$by)
  })
  files <- list()
  for (sub in c("output", "figures", "model-data")) {
    p <- file.path(dir, sub)
    if (!dir.exists(p)) next
    f <- list.files(p)
    f <- nat_sort(f[!dir.exists(file.path(p, f))])
    for (x in f) {
      files[[length(files) + 1L]] <- list(
        path = paste0(sub, "/", x), kind = sub, base = x,
        prefix = regmatches(x, regexpr(PREFIX_RX, x, perl = TRUE)),
        ids = ids_in_order(x)$id, own_stages = file_stages(x),
        fit_file = sub == "model-data" && grepl(FIT_FILE, x, perl = TRUE, ignore.case = TRUE))
    }
  }
  data <- character()
  p <- file.path(dir, "data")
  if (dir.exists(p)) {
    f <- list.files(p)
    data <- paste0("data/", nat_sort(f[!dir.exists(file.path(p, f))]))
  }
  list(dir = dir, scripts = scripts, files = files, data = data)
}

# ---- links --------------------------------------------------------------------------

# Adds to each file: owner, owner_by, stage (character vector of stages),
# stage_by, cited_in (entry numbers), id_entry (the entry first naming the
# file's first id, or NA). Adds cited_in to each script. A link never moves a
# file's stage.
bw_link <- function(entries, disk) {
  scripts <- disk$scripts; files <- disk$files
  texts <- vapply(entries, `[[`, "", "text")
  cited <- function(base) {
    if (!length(texts)) return(integer())
    which(vapply(texts, function(t) grepl(base, t, fixed = TRUE), TRUE))
  }
  first_naming <- function(id) {
    for (e in entries) if (id %in% e$new_ids) return(e$n)
    NA_integer_
  }
  specific <- function(g) grepl("[A-Za-z0-9_]", sub("\\.[A-Za-z0-9]+$", "", basename(g)))
  owners <- scripts[vapply(scripts, function(s) !identical(s$stages, STRINGS$helper), TRUE)]
  for (i in seq_along(scripts)) scripts[[i]]$cited_in <- cited(scripts[[i]]$base)
  for (i in seq_along(files)) {
    f <- files[[i]]
    owner <- NULL; owner_by <- ""
    best <- -1L
    for (s in owners) for (g in s$declared) {
      if (!specific(g)) next
      if (grepl(glob2rx(g), f$path) && nchar(gsub("[*?]", "", g)) > best) {
        best <- nchar(gsub("[*?]", "", g)); owner <- s; owner_by <- STRINGS$own_banner
      }
    }
    if (is.null(owner) && length(f$prefix)) {
      for (s in owners) if (length(s$prefix) && s$prefix == f$prefix) { owner <- s; owner_by <- STRINGS$own_prefix; break }
    }
    stage <- character(); by <- STRINGS$placed_none
    if (!is.null(owner) && length(owner$stages)) {
      both <- intersect(owner$stages, f$own_stages)
      if (length(both)) { stage <- both; by <- if (setequal(both, owner$stages)) STRINGS$by_script else STRINGS$by_script_name }
      else { stage <- owner$stages; by <- STRINGS$by_script }
    } else if (length(f$own_stages)) {
      stage <- f$own_stages; by <- STRINGS$by_file_name
    }
    if (f$fit_file) {
      by <- if (!length(stage)) STRINGS$by_fit_file
            else if (by == STRINGS$by_file_name) STRINGS$by_fit_name else STRINGS$by_fit_script
      stage <- union("4", stage)
    }
    stage <- stage[order(match(stage, c(as.character(1:9), "W")))]
    files[[i]]$owner    <- if (is.null(owner)) "" else owner$path
    files[[i]]$owner_by <- owner_by
    files[[i]]$stage    <- stage
    files[[i]]$stage_by <- by
    files[[i]]$cited_in <- cited(f$base)
    files[[i]]$id_entry <- if (length(f$ids)) first_naming(f$ids[1]) else NA_integer_
  }
  list(dir = disk$dir, scripts = scripts, files = files, data = disk$data)
}

# ---- the Models table --------------------------------------------------------------

models_table <- function(entries, linked) {
  files <- linked$files
  log_ids  <- sort(unique(unlist(lapply(entries, `[[`, "ids"))))
  file_ids <- sort(unique(c(unlist(lapply(files, `[[`, "ids")),
                            unlist(lapply(linked$scripts, function(s) ids_in_order(s$base)$id)))))
  ids <- sort(unique(c(log_ids, file_ids)))
  if (!length(ids)) return(data.frame(model = character(), files = character(), first = character(),
                                      last = character(), says = character(), stringsAsFactors = FALSE))
  verdicts <- lapply(ids, function(i) character())
  names(verdicts) <- as.character(ids)
  for (e in entries) for (s in e$sents) {
    v <- gregexpr(VERDICTS, s, perl = TRUE, ignore.case = TRUE)[[1]]
    if (v[1] == -1L) next
    pos <- ids_in_order(s)
    if (!nrow(pos)) next
    phr <- regmatches(s, list(v))[[1]]
    for (k in seq_along(phr)) {
      before <- pos[pos$at < v[k], ]
      id <- if (nrow(before)) before$id[nrow(before)] else pos$id[1]
      verdicts[[as.character(id)]] <- c(verdicts[[as.character(id)]], paste0(tolower(phr[k]), " (entry ", e$n, ")"))
    }
  }
  rows <- lapply(ids, function(id) {
    with_id <- Filter(function(f) id %in% f$ids, files)
    with_id <- with_id[order(match(vapply(with_id, `[[`, "", "kind"), c("model-data", "output", "figures")))]
    leading <- vapply(with_id, function(f) grepl(paste0("^m", id, "[_.-]"), f$base, ignore.case = TRUE), TRUE)
    bases <- c(vapply(with_id[leading], `[[`, "", "base"), vapply(with_id[!leading], `[[`, "", "base"))
    sbases <- vapply(linked$scripts, `[[`, "", "base")
    bases <- c(bases, sbases[vapply(linked$scripts, function(s) id %in% ids_in_order(s$base)$id, TRUE)])
    naming <- vapply(entries, function(e) id %in% e$ids, TRUE)
    data.frame(model = paste0("m", id),
               files = paste(tick(bases), collapse = ", "),
               first = if (any(naming)) as.character(min(which(naming))) else STRINGS$not_in_log,
               last  = if (any(naming)) as.character(max(which(naming))) else STRINGS$not_in_log,
               says  = paste(unique(verdicts[[as.character(id)]]), collapse = "; "),
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

# ---- rendering ------------------------------------------------------------------------

bw_render <- function(state) {
  log <- state$log; entries <- state$entries; linked <- state$linked
  D <- STRINGS$dash
  files <- linked$files; scripts <- linked$scripts
  stages_of <- function(e) e$stage
  primary <- vapply(entries, stages_of, "")
  in_loop <- primary %in% as.character(1:9)
  placed_at <- function(s) which(primary == s)
  reaching  <- function(s) which(vapply(entries, function(e) as.integer(s) %in% e$also, TRUE))
  files_at  <- function(s) Filter(function(f) s %in% f$stage, files)
  scripts_at <- function(s) Filter(function(x) s %in% x$stages, scripts)
  q <- function(x) paste0("\"", x, "\"")

  # title and provenance
  title <- if (nzchar(log$h1)) log$h1 else basename(normalizePath(state$dir, mustWork = FALSE))
  out <- c(paste0(STRINGS$title, title), "")
  n <- length(entries)
  if (!log$exists) {
    src <- paste0("from no ", tick(state$log_name), " found")
  } else if (!n) {
    src <- paste0("from ", tick(state$log_name), " (no `## ` entries; ", log$n_lines, " lines read")
    if (!is.na(log$h1_second)) src <- paste0(src, "; a second H1 at line ", log$h1_second)
    src <- paste0(src, ")")
  } else {
    dates <- vapply(entries, `[[`, "", "date")
    dd <- sort(unique(dates[!is.na(dates)]))
    span <- if (!length(dd)) "undated"
            else if (length(dd) == 1L && !anyNA(dates)) paste("all dated", dd)
            else paste0("dated ", dd[1], if (length(dd) > 1L) paste0(" to ", dd[length(dd)]) else "",
                        if (anyNA(dates)) " where dated" else "")
    src <- paste0("from ", tick(state$log_name), " (", n, if (n == 1L) " entry, " else " entries, ", span)
    if (!is.na(log$h1_second)) src <- paste0(src, "; a second H1 at line ", log$h1_second)
    src <- paste0(src, ")")
  }
  counts <- c(paste(length(scripts), if (length(scripts) == 1L) "script" else "scripts"))
  first_sub <- TRUE
  for (sub in c("output", "figures", "model-data")) {
    if (!dir.exists(file.path(state$dir, sub))) next
    k <- sum(vapply(files, function(f) f$kind == sub, TRUE))
    counts <- c(counts, paste0(k, if (first_sub) paste0(if (k == 1L) " file" else " files") else "", " in ", tick(paste0(sub, "/"))))
    first_sub <- FALSE
  }
  out <- c(out, paste0("Generated ", stamp(), " ", src, " and the files in ",
                       tick(paste0(basename(normalizePath(state$dir, mustWork = FALSE)), "/")), ": ",
                       paste(counts, collapse = ", "), ". ", STRINGS$rewritten), "")

  # where the analysis stands
  if (n) {
    last <- entries[[n]]
    lab <- function(e) paste0(if (!is.na(e$date)) paste0(e$date, " ", D, " ") else "", gsub("\\*\\*", "", e$label))
    where <- if (last$stage == "W") STRINGS$outside else if (last$stage == "") STRINGS$no_stage else paste("stage", last$stage)
    b <- paste0(STRINGS$last_entry, lab(last), " (", where, ").")
    if (!last$stage %in% as.character(1:9) && any(in_loop)) {
      li <- entries[[max(which(in_loop))]]
      b <- c(b, paste0(STRINGS$last_in_loop, lab(li), " (stage ", li$stage, ", entry ", li$n, ")."))
    }
    if (!is.na(last$next_text)) {
      b <- c(b, paste0(STRINGS$next_written, q(last$next_text)))
    } else if (length(last$sents)) {
      rem <- last$sents[grepl(REMAINS_RX, last$sents, perl = TRUE, ignore.case = TRUE)]
      b <- c(b, if (length(rem)) paste0(STRINGS$no_next, STRINGS$remains, q(rem[length(rem)]))
                else paste0(STRINGS$no_next, STRINGS$it_ends, q(last$closes_long)))
    } else {
      b <- c(b, trimws(STRINGS$no_next))
    }
    carried <- NULL
    for (e in entries) for (s in e$sents) {
      if (grepl(CARRIED_RX, s, perl = TRUE, ignore.case = TRUE)) {
        pos <- ids_in_order(s)
        if (nrow(pos)) carried <- list(id = pos$id[1], sentence = s, n = e$n)
      }
    }
    if (!is.null(carried)) {
      b <- c(b, paste0(STRINGS$carried, "m", carried$id, " ", D, " ", q(carried$sentence), " (entry ", carried$n, ")."))
    }
    log_ids <- sort(unique(unlist(lapply(entries, `[[`, "ids"))))
    if (length(log_ids)) {
      fit_ids <- sort(unique(unlist(lapply(Filter(function(f) f$fit_file, files), function(f) f$ids[1]))))
      m <- paste0(STRINGS$models_named, compress_nums(log_ids, "m"), " (", length(log_ids), ").")
      if (length(fit_ids)) m <- paste0(m, " ", STRINGS$fit_on_disk, compress_nums(fit_ids, "m"), ".")
      if (length(setdiff(fit_ids, log_ids))) m <- paste0(m, " ", STRINGS$disk_only, compress_nums(setdiff(fit_ids, log_ids), "m"), ".")
      if (length(setdiff(log_ids, fit_ids))) m <- paste0(m, " ", STRINGS$log_only, compress_nums(setdiff(log_ids, fit_ids), "m"), ".")
      b <- c(b, m)
    }
    out <- c(out, STRINGS$h_stands, "", b, "")
  }

  # the diagram
  last_loop <- if (any(in_loop)) max(which(in_loop)) else NA_integer_
  log_ids <- sort(unique(unlist(lapply(entries, `[[`, "ids"))))
  mm <- "flowchart LR"
  for (col in DIAGRAM_COLUMNS) {
    mm <- c(mm, paste0("  subgraph ", col$id, "[", q(col$title), "]"), "    direction TB")
    for (s in col$stages) {
      sc <- as.character(s)
      bits <- character()
      pl <- placed_at(sc); re <- reaching(sc)
      if (length(pl)) bits <- c(bits, entry_word(pl))
      if (length(re)) bits <- c(bits, paste("also", entry_word(re)))
      if (s == 4L && length(log_ids)) bits <- c(bits, compress_nums(log_ids, "m"))
      if (!is.na(last_loop) && primary[last_loop] == sc) bits <- c(bits, paste0("last entry: ", last_loop))
      label <- paste0(s, ". ", STAGE_NAMES[[sc]], if (length(bits)) paste0("<br/>", paste(bits, collapse = STRINGS$dot)) else "")
      mm <- c(mm, paste0("    s", s, "[", q(label), "]"))
    }
    mm <- c(mm, paste0("    ", paste0("s", col$stages, collapse = " --> ")), "  end")
  }
  mm <- c(mm, paste0("  ", paste(vapply(DIAGRAM_COLUMNS, `[[`, "", "id"), collapse = " --> ")))
  out <- c(out, STRINGS$h_loop, "", "```mermaid", mm, "```", "", STRINGS$caption, "")

  # the Stages table
  file_cells <- function(s) {
    sc <- vapply(scripts_at(s), `[[`, "", "path")
    fs <- files_at(s)
    named <- vapply(Filter(function(f) f$kind != "model-data", fs), `[[`, "", "path")
    k <- sum(vapply(fs, function(f) f$kind == "model-data", TRUE))
    parts <- c(if (length(c(sc, named))) paste(tick(c(sc, named)), collapse = ", "),
               if (k) paste0("model-data: ", k, if (k == 1L) " file" else " files"))
    paste(parts, collapse = "; ")
  }
  rows <- character()
  for (s in c(as.character(1:9), "W")) {
    pl <- placed_at(s); re <- if (s == "W") integer() else reaching(s)
    has_files <- length(scripts_at(s)) || length(files_at(s))
    if (!length(pl) && !length(re) && !has_files) next
    name <- if (s == "W") "Write-up" else paste(s, STAGE_NAMES[[s]])
    ent <- vapply(entries[pl], function(e) paste0(e$n, " ", D, " ", gsub("\\*\\*", "", e$label)), "")
    rows <- c(rows, paste0("| ", name, " | ", md_cell(paste(ent, collapse = "; ")), " | ",
                           md_cell(compress_nums(re)), " | ", md_cell(file_cells(s)), " |"))
  }
  if (length(rows)) out <- c(out, STRINGS$h_stages, "", STRINGS$stages_header, rows, "")

  # the passes table
  absent <- character()
  if (n) {
    rows <- vapply(entries, function(e) {
      fn <- vapply(e$paths, function(p) {
        on_disk <- file.exists(file.path(state$dir, p))
        if (!on_disk) absent <<- c(absent, p)
        paste0(tick(p), if (!on_disk) paste0(" ", STRINGS$not_on_disk) else "")
      }, "")
      paste0("| ", e$n, " | ", md_cell(if (is.na(e$date)) "" else e$date), " | ",
             md_cell(gsub("\\*\\*", "", e$label)), " | ", stage_label(e$stage), " | ",
             md_cell(paste(e$also, collapse = ", ")), " | ", e$placed_by, " | ",
             md_cell(compress_nums(e$new_ids, "m")), " | ", md_cell(paste(fn, collapse = ", ")), " | ",
             md_cell(if (is.na(e$next_text)) "" else e$next_text), " |")
    }, "")
    out <- c(out, STRINGS$h_passes, "", STRINGS$passes_header, rows, "")
    if (length(absent)) out <- c(out, paste0(STRINGS$paths_absent, paste(tick(unique(absent)), collapse = ", "), "."), "")
  }

  # the Models table
  models <- models_table(entries, linked)
  if (nrow(models)) {
    rows <- apply(models, 1L, function(r) paste0("| ", r[["model"]], " | ", md_cell(r[["files"]]), " | ",
                                                  r[["first"]], " | ", r[["last"]], " | ", md_cell(r[["says"]]), " |"))
    out <- c(out, STRINGS$h_models, "", STRINGS$models_header, rows, "")
  }

  # reproducibility
  helpers <- vapply(Filter(function(x) identical(x$stages, STRINGS$helper), scripts), `[[`, "", "path")
  seeds <- unique(unlist(lapply(scripts, `[[`, "seeds")))
  session <- c(vapply(scripts, `[[`, "", "path"), vapply(files, `[[`, "", "path"))
  session <- session[grepl("session", basename(session), ignore.case = TRUE)]
  rep <- c(if (length(linked$data)) paste0(STRINGS$data_files, paste(tick(linked$data), collapse = ", "), "."),
           if (length(helpers)) paste0(STRINGS$helpers, paste(tick(helpers), collapse = ", "), "."),
           if (length(seeds)) paste0(STRINGS$seeds, paste(tick(seeds), collapse = ", "), "."),
           if (length(session)) paste0(STRINGS$session, paste(tick(session), collapse = ", "), "."))
  if (length(rep)) out <- c(out, STRINGS$h_repro, "", rep, "")

  # evidence
  if (n) {
    out <- c(out, paste0("<details><summary>", STRINGS$evidence_summary, "</summary>"), "")
    for (e in entries) out <- c(out, e$evidence, "")
    out <- c(out, "</details>", "")
  }

  # files on disk
  n_files <- length(scripts) + length(files)
  if (n_files) {
    out <- c(out, paste0("<details><summary>", STRINGS$files_summary, " (", n_files, ")</summary>"), "")
    if (length(scripts)) {
      rows <- vapply(scripts, function(s) {
        st <- if (identical(s$stages, STRINGS$helper)) STRINGS$helper else paste(vapply(s$stages, stage_label, ""), collapse = ", ")
        paste0("| ", tick(s$path), " | ", md_cell(st), " | ", s$stage_by, " | ", md_cell(s$title), " | ",
               md_cell(s$output), " | ", md_cell(paste(s$cited_in, collapse = ", ")), " |")
      }, "")
      out <- c(out, STRINGS$scripts_title, "", STRINGS$scripts_header, rows, "")
    }
    if (length(files)) {
      rows <- vapply(files, function(f) {
        links <- c(as.character(f$cited_in),
                   if (!is.na(f$id_entry)) paste0(f$id_entry, " (m", f$ids[1], ")"))
        paste0("| ", tick(f$path), " | ",
               md_cell(if (nzchar(f$owner)) paste0(f$owner, " (", f$owner_by, ")") else ""), " | ",
               md_cell(paste(vapply(f$stage, stage_label, ""), collapse = ", ")), " | ", f$stage_by, " | ",
               md_cell(paste(links, collapse = ", ")), " |")
      }, "")
      out <- c(out, STRINGS$files_title, "", STRINGS$files_header, rows, "")
    }
    out <- c(out, "</details>", "")
  }

  c(out, STRINGS$h_made, "", STRINGS$made)
}

# ---- entry point --------------------------------------------------------------------

entries_frame <- function(entries) {
  if (!length(entries)) {
    return(data.frame(n = integer(), date = character(), label = character(), stage = character(),
                      also = I(list()), placed_by = character(), new_ids = I(list()), ids = I(list()),
                      paths = I(list()), next_text = character(), opens = character(),
                      closes = character(), evidence = character(), stringsAsFactors = FALSE))
  }
  g <- function(f, mode) vapply(entries, function(e) { v <- e[[f]]; if (is.null(v)) mode else v }, mode)
  data.frame(n = g("n", 0L), date = g("date", ""), label = g("label", ""), stage = g("stage", ""),
             also = I(lapply(entries, `[[`, "also")), placed_by = g("placed_by", ""),
             new_ids = I(lapply(entries, `[[`, "new_ids")), ids = I(lapply(entries, `[[`, "ids")),
             paths = I(lapply(entries, `[[`, "paths")), next_text = g("next_text", ""),
             opens = g("opens", ""), closes = g("closes", ""), evidence = g("evidence", ""),
             stringsAsFactors = FALSE)
}

files_frame <- function(linked) {
  rows <- c(lapply(linked$scripts, function(s) list(path = s$path, kind = "script", owner = "", owner_by = "",
                                                    stage = s$stages, stage_by = s$stage_by,
                                                    ids = ids_in_order(s$base)$id, cited_in = s$cited_in)),
            lapply(linked$files, function(f) f[c("path", "kind", "owner", "owner_by", "stage", "stage_by", "ids", "cited_in")]))
  if (!length(rows)) {
    return(data.frame(path = character(), kind = character(), owner = character(), owner_by = character(),
                      stage = I(list()), stage_by = character(), ids = I(list()), cited_in = I(list()),
                      stringsAsFactors = FALSE))
  }
  data.frame(path = vapply(rows, `[[`, "", "path"), kind = vapply(rows, `[[`, "", "kind"),
             owner = vapply(rows, `[[`, "", "owner"), owner_by = vapply(rows, `[[`, "", "owner_by"),
             stage = I(lapply(rows, `[[`, "stage")), stage_by = vapply(rows, `[[`, "", "stage_by"),
             ids = I(lapply(rows, `[[`, "ids")), cited_in = I(lapply(rows, `[[`, "cited_in")),
             stringsAsFactors = FALSE)
}

# Writes WORKFLOW.md and returns, invisibly, a list: entries, files, models
# (data frames) and out (the path written). The only console output is one
# line naming the file and the entry count.
bw_scheme <- function(log = "bayes-workflow-log.md",
                      dir = dirname(normalizePath(log, mustWork = FALSE)),
                      out = file.path(dir, "WORKFLOW.md"),
                      quiet = FALSE) {
  parsed  <- bw_read_log(log)
  entries <- bw_place_entries(parsed$entries)
  disk    <- bw_scan_dir(dir)
  linked  <- bw_link(entries, disk)
  state <- list(log = parsed, entries = entries, linked = linked, dir = dir, log_name = basename(log))
  md <- bw_render(state)
  writeLines(enc2utf8(md), out, useBytes = TRUE)
  if (!quiet) cat(STRINGS$console, out, " (", length(entries), if (length(entries) == 1L) " entry)" else " entries)", "\n", sep = "")
  invisible(list(entries = entries_frame(entries), files = files_frame(linked),
                 models = models_table(entries, linked), out = out))
}

# ---- command line ---------------------------------------------------------------------

# Runs only when this file is the script the interpreter was given, never when
# it is sourced by another script or from a session.
bw_file_arg <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
if (length(bw_file_arg) && grepl("bw_scheme\\.R$", bw_file_arg[1])) {
  bw_args <- commandArgs(trailingOnly = TRUE)
  bw_silent <- "--silent" %in% bw_args
  bw_args <- bw_args[!bw_args %in% "--silent"]
  if ("--help" %in% bw_args || length(bw_args) > 3L) {
    cat(STRINGS$usage, sep = "\n")
    quit(status = 1L)
  }
  bw_call <- list(quiet = bw_silent)
  if (length(bw_args) >= 1L) bw_call$log <- bw_args[1]
  if (length(bw_args) >= 2L) bw_call$dir <- bw_args[2]
  if (length(bw_args) >= 3L) bw_call$out <- bw_args[3]
  if (bw_silent) {
    tryCatch(do.call(bw_scheme, bw_call), error = function(e) NULL)
    quit(status = 0L)
  }
  invisible(do.call(bw_scheme, bw_call))
}
