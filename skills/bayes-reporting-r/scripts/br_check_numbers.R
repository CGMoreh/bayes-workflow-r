################################################################################
# Title:      Draft-against-output number check
# Purpose:    Check that every number in a manuscript draft traces to a value in
#             the analysis output behind it, and list the quantified claims that
#             carry no number and so have to be checked by eye
# Sourced by: bayes-reporting-r skill; call br_check_numbers()
# Author:     Chris Moreh
# Last updated: 2026-09-03
################################################################################

# Two failure modes, and only the first is mechanical. A number in the prose that
# appears in no output is a typo, a stale value from a superseded fit, or an
# invention, and matching digits finds it. A sentence that quantifies without any
# digits – "no other predictor reaches half the folds" – can contradict the table
# printed directly above it, and no string comparison will notice. That class is
# listed rather than judged, because a reader has to hold the claim against the
# output. It is the class that produced the error this check exists for.

# Matching is tolerant of the draft's own rounding, and only of that. A figure
# matches an output value within half a unit of its last stated place, so a
# draft's 0.30 matches an output 0.2984 and its 0.481 matches an output 0.4805.
# A draft carrying more precision than any output has does not match, which is
# the correct answer.

br_quantifiers <- c(
  "all", "none", "no other", "no more", "every", "never", "always", "any",
  "most", "majority", "half", "twice", "double", "halved", "each",
  "largest", "smallest", "highest", "lowest", "greatest", "best", "worst",
  "only", "sole", "consistently", "uniformly", "throughout",
  "exceeds", "exceed", "exceeded", "outperforms", "outperformed",
  "more than", "fewer than", "less than", "at least", "at most",
  "better than", "worse than", "larger than", "smaller than"
)

# words whose following number names a place in the document rather than a result
br_structural <- c(
  "table", "figure", "fig", "section", "chapter", "appendix", "equation", "eq",
  "model", "panel", "step", "stage", "page", "p", "pp", "wave", "item", "question"
)

# what follows an interval width: "a 95% interval", "the 89% credible interval",
# "the 95th percentile". The width is a reporting convention chosen in advance, so
# it will not be in the output and flagging it would fire on every draft written
br_width_follows <- paste0(
  "^[[:space:]]*(th[[:space:]]+percentile|percentile|interval|credible|",
  "confidence|posterior|central|equal-tailed|highest|hdi|ci|eti|quantile)"
)

br_strip_prose <- function(lines) {
  # code, its output, YAML and maths are not prose claims: a number inside them is
  # either an input to the analysis or the analysis printing itself
  in_fence <- FALSE
  in_yaml  <- length(lines) > 0L && identical(trimws(lines[1]), "---")
  out <- character(length(lines))
  for (i in seq_along(lines)) {
    ln <- lines[i]
    if (in_yaml) {
      out[i] <- ""
      if (i > 1L && identical(trimws(ln), "---")) in_yaml <- FALSE
      next
    }
    if (grepl("^[[:space:]]*[`]{3}", ln)) {
      in_fence <- !in_fence
      out[i] <- ""
      next
    }
    if (in_fence || grepl("^[[:space:]]*#", ln)) {
      out[i] <- ""
      next
    }
    # a Unicode minus (U+2212) or a non-breaking space before a number is what
    # typeset prose carries; read both as their ASCII forms so a correct negative
    # is not counted as an orphan
    ln <- gsub("−", "-", ln)
    ln <- gsub(" ", " ", ln)
    ln <- gsub("[`][^`]*[`]", " ", ln)             # inline code, including `r ...`
    ln <- gsub("[$][^$]*[$]", " ", ln)             # inline maths
    ln <- gsub("\\^[^^]*\\^", " ", ln)             # Quarto superscripts, e.g. R^2^
    ln <- gsub("~[^~]*~", " ", ln)                 # Quarto subscripts
    ln <- gsub("[[]@[^]]*[]]", " ", ln)            # citation keys and their years
    ln <- gsub("@[[:alnum:]_-]+", " ", ln)         # cross-references
    ln <- gsub("https?://[^[:space:]]+", " ", ln)  # URLs
    out[i] <- ln
  }
  out
}

br_numbers_in <- function(lines, prose = TRUE) {
  pat   <- "-?[0-9]+([.][0-9]+)?%?"
  found <- vector("list", length(lines))
  for (i in seq_along(lines)) {
    m <- gregexpr(pat, lines[i])[[1]]
    if (m[1] == -1L) next
    txt    <- regmatches(lines[i], gregexpr(pat, lines[i]))[[1]]
    ends   <- m + attr(m, "match.length")
    before <- substr(rep(lines[i], length(txt)), pmax(1L, m - 12L), pmax(1L, m - 1L))
    after  <- substr(rep(lines[i], length(txt)), ends, ends + 14L)
    found[[i]] <- data.frame(line = i, text = txt, before = before, after = after,
                             stringsAsFactors = FALSE)
  }
  d <- do.call(rbind, found)
  if (is.null(d)) {
    return(data.frame(line = integer(0), text = character(0), value = numeric(0),
                      digits = integer(0), pct = logical(0),
                      stringsAsFactors = FALSE))
  }
  if (is.null(d$after)) d$after <- ""
  d$pct   <- grepl("%$", d$text)
  bare    <- sub("%$", "", d$text)
  d$value <- as.numeric(bare)
  # decimals as WRITTEN set the rounding tolerance, so count only what follows the
  # point; counting the whole string makes the tolerance far too tight and every
  # rounded figure in the draft then reads as an orphan
  d$digits <- ifelse(grepl("[.]", bare), nchar(sub("^[^.]*[.]", "", bare)), 0L)

  if (prose) {
    # a bare four-digit number in the 1900-2100 range is a year far more often than
    # it is a result, and dropping it costs less than the noise of reporting it
    is_year  <- d$digits == 0L & abs(d$value) >= 1900 & abs(d$value) <= 2100 & !d$pct
    prev     <- tolower(gsub("[^[:alpha:]]+$", "", d$before))
    prev     <- sub("^.*[^[:alpha:]]", "", prev)
    is_ref   <- prev %in% br_structural
    is_width <- grepl(br_width_follows, tolower(d$after))
    # a seed is stated so the analysis can be repeated, not because anything
    # computed it, so it is never in the output and always reads as an orphan
    is_seed  <- grepl("seed", tolower(d$before))
    # a threshold - "ESS above 1500", "Pareto k below 0.7", "at least 200" - is the
    # author's criterion, chosen rather than computed, and the same holds for
    # it as for an interval width. Only the strict forms are skipped: "over" and
    # "more than" also introduce results ("rises by more than 350") and stay
    is_thr   <- grepl("(above|below|at least|at most|exceed(s|ed)?)[[:space:]]*$",
                      tolower(d$before))
    d <- d[!is_year & !is_ref & !is_width & !is_seed & !is_thr, , drop = FALSE]
  }
  d[, c("line", "text", "value", "digits", "pct"), drop = FALSE]
}

br_read_outputs <- function(outputs) {
  files <- unlist(lapply(outputs, function(p) {
    # non-recursive by design: point this at the folder holding the saved output,
    # not at a project root, and it stays fast and stays predictable
    if (dir.exists(p)) {
      list.files(p, pattern = "[.](txt|log|out|md|csv|tsv|json|R|r)$",
                 full.names = TRUE, recursive = FALSE)
    } else {
      p
    }
  }), use.names = FALSE)
  files <- files[file.exists(files)]
  if (!length(files)) {
    stop("no output files found in: ", paste(outputs, collapse = ", "),
         ". Point `outputs` at the saved printing of the analysis - the captured ",
         "console output, the summary tables, the csv behind the figures.",
         call. = FALSE)
  }
  vals <- unlist(lapply(files, function(f) {
    br_numbers_in(readLines(f, warn = FALSE), prose = FALSE)$value
  }), use.names = FALSE)
  list(files = files, values = vals[is.finite(vals)])
}

br_match_one <- function(value, digits, pct, pool) {
  # a percentage may be stored either way round, but dividing by 100 moves the
  # point two places and the tolerance has to move with it: comparing 0.95 at zero
  # decimals rounds it to 1 and matches any pool holding a 1
  cand <- list(list(v = value, d = digits))
  if (pct) cand <- c(cand, list(list(v = value / 100, d = digits + 2L)))
  # a draft's figure matches an output value when the two are within half a unit
  # of the draft's last stated place: 0.481 is consistent with an output 0.4805.
  # Rounding both sides instead fails exactly at that boundary, because 0.4805 is
  # held as 0.48049... and rounds down - a false orphan on a correctly rounded
  # number, which is the first thing this check got wrong on a real report.
  tol <- function(d) 0.5 * 10^(-d) + 1e-9
  for (k in cand) {
    if (any(abs(pool - k$v) <= tol(k$d))) return("matched")
  }
  for (k in cand) {
    if (any(abs(abs(pool) - abs(k$v)) <= tol(k$d))) return("sign")
  }
  "orphan"
}

br_claims_in <- function(lines) {
  txt   <- paste(lines, collapse = " ")
  parts <- unlist(strsplit(txt, "(?<=[.!?]) +", perl = TRUE))
  parts <- trimws(parts)
  parts <- parts[nzchar(parts)]
  has_num <- grepl("[0-9]", parts)
  # pad and strip punctuation so a quantifier matches as a word rather than inside
  # one: " all " must not fire on "small" or "generally"
  padded <- paste0(" ", tolower(gsub("[^[:alnum:][:space:]]+", " ", parts)), " ")
  hits   <- vapply(padded, function(s) {
    any(vapply(br_quantifiers,
               function(q) grepl(paste0(" ", q, " "), s, fixed = TRUE),
               logical(1)))
  }, logical(1), USE.NAMES = FALSE)
  parts[!has_num & hits]
}

br_check_numbers <- function(draft, outputs = ".", ignore = numeric(0),
                             claims = TRUE) {

  if (!file.exists(draft)) {
    stop("no draft found at '", draft, "'.", call. = FALSE)
  }

  lines <- readLines(draft, warn = FALSE)
  prose <- br_strip_prose(lines)
  nums  <- br_numbers_in(prose, prose = TRUE)
  nums  <- nums[!nums$value %in% ignore, , drop = FALSE]

  pool <- br_read_outputs(outputs)

  nums$status <- if (nrow(nums)) {
    vapply(seq_len(nrow(nums)), function(i) {
      br_match_one(nums$value[i], nums$digits[i], nums$pct[i], pool$values)
    }, character(1))
  } else {
    character(0)
  }

  orphan <- nums[nums$status == "orphan", , drop = FALSE]
  signed <- nums[nums$status == "sign", , drop = FALSE]

  cat("=== Draft against output ===\n")
  cat(sprintf("draft:   %s\n", draft))
  cat(sprintf("outputs: %d file(s), %d numeric values\n",
              length(pool$files), length(pool$values)))
  cat(sprintf("checked: %d number(s) in prose, %d traced to an output value\n\n",
              nrow(nums), sum(nums$status == "matched")))

  if (nrow(orphan)) {
    cat("Numbers that appear in no output\n")
    for (i in seq_len(nrow(orphan))) {
      cat(sprintf("  line %-5d %-12s %s\n", orphan$line[i], orphan$text[i],
                  trimws(substr(lines[orphan$line[i]], 1, 62))))
    }
    cat("  -> each is a typo, a value carried over from a superseded fit, or a\n",
        "     number nobody computed. Re-derive it or delete the sentence.\n\n",
        sep = "")
  } else {
    cat("Every number in the prose traces to an output value.\n\n")
  }

  if (nrow(signed)) {
    cat("Numbers that match only once the sign is dropped\n")
    for (i in seq_len(nrow(signed))) {
      cat(sprintf("  line %-5d %s\n", signed$line[i], signed$text[i]))
    }
    cat("  -> usual where the prose says 'lower by' and the output is negative.\n",
        "     Check that the direction the sentence states is the right one.\n\n",
        sep = "")
  }

  claim_txt <- if (claims) br_claims_in(prose) else character(0)
  if (length(claim_txt)) {
    cat("Quantified claims carrying no number\n")
    for (s in claim_txt) {
      cat("  ", substr(s, 1, 88), if (nchar(s) > 88) " ..." else "", "\n", sep = "")
    }
    cat("  -> none of these can be checked by matching digits. Hold each against\n",
        "     the output it summarises. This is the class where a sentence\n",
        "     contradicts the table printed above it and the draft still reads as\n",
        "     internally consistent.\n\n", sep = "")
  }

  cat("A clean run means the numbers exist somewhere in the output supplied. It does\n",
      "not mean each one came from the right place, and it says nothing about\n",
      "whether the claim built on it holds.\n", sep = "")

  invisible(list(numbers = nums, orphan = orphan, sign_only = signed,
                 claims = claim_txt, files = pool$files))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (!length(args) || identical(args[1], "--help")) {
    cat("usage: Rscript br_check_numbers.R <draft.qmd> [output-file-or-dir ...]\n")
    quit(status = 1L)
  }
  res <- br_check_numbers(args[1], if (length(args) > 1L) args[-1] else ".")
  quit(status = if (nrow(res$orphan)) 1L else 0L)
}
