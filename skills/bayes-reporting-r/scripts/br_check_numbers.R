################################################################################
# Title:      Draft-against-output number check
# Purpose:    Check that every number in a manuscript draft traces to a value in
#             the analysis output behind it, and list each sentence that carries
#             a quantifier, with the numbers in it, to be held against the
#             output by eye
# Sourced by: bayes-reporting-r skill; call br_check_numbers()
# Author:     Chris Moreh
# Last updated: 2026-11-08
################################################################################

# Two failure modes, and only the first is mechanical. A number in the prose that
# appears in no output is a typo, a stale value from a superseded fit, or an
# invention, and matching digits finds it. A sentence that quantifies – "no other
# predictor reaches half the folds" – can contradict the table printed directly
# above it, and no string comparison will notice. The digits it carries, if any,
# can match the row labels of that very table. Every such sentence is therefore
# listed with the numbers in it, matched or not, because a reader has to hold the
# claim against the output. It is the class that produced the error this check
# exists for.

# Matching is tolerant of the draft's own rounding, and only of that. A figure
# matches an output value that rounds to it at the draft's decimal places, and,
# when the figure has at least two significant figures, at those: a draft's 0.30
# matches an output 0.2984, its 0.481 an output 0.4805 and its 270 an output
# 274.7. The trailing zeros of a whole number are not significant, so a draft's
# 20 or 40% has one figure and is held to its decimal places, and "about 20"
# against an output 17 is listed for the author. A draft carrying more precision
# than any output has does not match, which is the correct answer.

br_quantifiers <- c(
  "all", "none", "no", "neither", "nor", "both", "every", "never", "always", "few",
  "most", "majority", "half", "twice", "double", "halved",
  "largest", "smallest", "highest", "lowest", "greatest", "best", "worst",
  "only", "sole", "consistently", "uniformly", "throughout",
  "exceeds", "exceed", "exceeded", "outperforms", "outperformed",
  "more than", "fewer than", "less than", "at least", "at most",
  "better than", "worse than", "larger than", "smaller than"
)

# words whose following number names a place in the document rather than a
# result. A page is "p." or "pp." with the point, because a bare "p" is the
# posterior predictive p-value of "p = 0.04", which is a result
br_structural <- c(
  "table", "tables", "figure", "figures", "fig", "figs", "section", "sections",
  "chapter", "chapters", "appendix", "appendices", "equation", "equations",
  "eq", "eqs", "model", "models", "panel", "panels", "step", "steps",
  "stage", "stages", "page", "pages", "p.", "pp.", "wave", "waves",
  "item", "items", "question", "questions"
)

# matched against the text that ends just before a number: one of those words,
# perhaps with a letter before the number ("Table S2") or a list of numbers
# before it ("Tables 3 and 4", "Figures 2–4", "pp. 23–47")
br_structural_rx <- paste0(
  "(^|[^[:alnum:]])(",
  paste(gsub(".", "[.]", br_structural, fixed = TRUE), collapse = "|"),
  ")[.]?[[:space:]]*",
  "([a-z]{0,2}[0-9]+[a-z]?[[:space:]]*(,|and|or|to|&|\u2013|-)[[:space:]]*)*",
  "[a-z]{0,2}$"
)

# what follows an interval width: "a 95% interval", "the 95 percent credible
# interval", "the 50% and 95% intervals", "the 2.5th and 97.5th percentiles".
# The width is a reporting convention chosen in advance, so it will not be in the
# output and flagging it would fire on every draft written
br_width_follows <- paste0(
  "^(st|nd|rd|th)?([[:space:]]*(%|percent|per[[:space:]]+cent))?",
  "([[:space:]]*(,|and|or|to|\u2013|-)[[:space:]]*[0-9]*[.]?[0-9]+",
  "(st|nd|rd|th)?%?([[:space:]]*(percent|per[[:space:]]+cent))?)*",
  "[[:space:]]*(percentile|interval|credible|confidence|hdi\\b|ci\\b|eti\\b|quantile|",
  # these four name a width only with the interval word within two words, so
  # that "a 97% posterior probability" and "the 3 highest regions" are checked
  "(posterior|central|equal-tailed|highest)([-[:space:]]+[^-[:space:]]+)?",
  "[-[:space:]]+(intervals?|region|density|credible)\\b)"
)

# a number followed by one of these is a percentage, as if it carried the sign
br_percent_follows <- "^[[:space:]]*(%|per[[:space:]]*cent\\b|percentage[[:space:]]+points?)"

# A number after one of these words is a bound and is checked as an inequality,
# on the side named here: gt and ge above the bound, lt and le below it
br_bounds <- c(
  "above" = "gt", "exceeds" = "gt", "exceeded" = "gt", "exceed" = "gt",
  "exceeding" = "gt", "more than" = "gt", "larger than" = "gt",
  "greater than" = "gt", "over" = "gt",
  "at least" = "ge",
  "below" = "lt", "less than" = "lt", "fewer than" = "lt", "smaller than" = "lt",
  "under" = "lt",
  "at most" = "le"
)

# A bound followed within two words by one of these sampler settings – "at least
# 333 draws", "over 1,000 post-warmup iterations" – is an input chosen in advance,
# and is skipped like a diagnostic threshold
br_settings <- paste0(
  "^%?([[:space:]]+[^[:space:]]+)?[[:space:]]+",
  "(draws?|iterations?|chains?|warm-?ups?|samples?|cores?|threads?)\\b"
)

# A bound is a threshold chosen in advance – "R-hat below 1.01", "bulk ESS above
# 400" – when one of these diagnostics is named in the same clause within the
# six words before the bound word. It is then skipped, like an interval width
br_diagnostics <- paste0(
  "(^|[^[:alpha:]])(r[-_ ]?hat|ess|effective sample size|pareto[-_ ]?k|k[-_ ]?hat|",
  "adapt[-_ ]?delta|tree[-_ ]?depth|divergen(t|ces?)|mcse|monte carlo standard error)",
  "([^[:alpha:]]|$)"
)

br_strip_prose <- function(lines) {
  # code, its output, YAML, maths and HTML comments are not prose claims: a number
  # inside them is either an input to the analysis or the analysis printing itself
  fence      <- ""
  in_math    <- FALSE
  in_comment <- FALSE
  in_yaml  <- length(lines) > 0L && identical(trimws(lines[1]), "---")
  out <- character(length(lines))
  for (i in seq_along(lines)) {
    ln <- lines[i]
    if (in_yaml) {
      out[i] <- ""
      if (i > 1L && identical(trimws(ln), "---")) in_yaml <- FALSE
      next
    }
    # a fence closes only on its own mark, so a ~~~ block may hold ``` lines
    if (nzchar(fence)) {
      if (startsWith(trimws(ln, "left"), fence)) fence <- ""
      out[i] <- ""
      next
    }
    # a comment or display-maths block runs to its closing mark, and the rest of
    # that line goes with it
    if (in_comment || in_math) {
      if (in_comment && grepl("-->", ln, fixed = TRUE)) in_comment <- FALSE
      if (in_math && grepl("$$", ln, fixed = TRUE)) in_math <- FALSE
      out[i] <- ""
      next
    }
    opens <- regmatches(ln, regexpr("^[[:space:]]*(`{3}|~{3})", ln))
    if (length(opens)) {
      fence  <- trimws(opens)
      out[i] <- ""
      next
    }
    if (grepl("^[[:space:]]*#", ln)) {
      out[i] <- ""
      next
    }
    # a Unicode minus (U+2212) or a non-breaking space before a number is what
    # typeset prose carries; read both as their ASCII forms so a correct negative
    # is not counted as an orphan
    ln <- gsub("−", "-", ln)
    ln <- gsub(" ", " ", ln)
    ln <- gsub("[`][^`]*[`]", " ", ln)             # inline code, including `r ...`
    # Pandoc attributes, {#fig-ppc width=80%} or {.class key=value}
    ln <- gsub("[{]([#.][^{}]*|[^{}]*=[^{}]*)[}]", " ", ln)
    ln <- gsub("<!--.*?-->", " ", ln, perl = TRUE)
    if (grepl("<!--", ln, fixed = TRUE)) {
      ln <- sub("<!--.*$", "", ln)
      in_comment <- TRUE
    }
    ln <- gsub("[$][$].*?[$][$]", " ", ln, perl = TRUE)
    if (grepl("$$", ln, fixed = TRUE)) {
      ln <- sub("[$][$].*$", "", ln)
      in_math <- TRUE
    }
    ln <- gsub("[$][^$]*[$]", " ", ln)             # inline maths
    ln <- gsub("[0-9]+([.][0-9]+)?\\^-?[0-9]+\\^", " ", ln)  # a power, base included: 10^3^
    ln <- gsub("\\^[^^]*\\^", " ", ln)             # Quarto superscripts, e.g. R^2^
    ln <- gsub("~[^~[:space:]]+~", " ", ln)        # Pandoc subscripts, which hold no space
    ln <- gsub("[[]@[^]]*[]]", " ", ln)            # citation keys and their years
    ln <- gsub("@[[:alnum:]_-]+", " ", ln)         # cross-references
    ln <- gsub("https?://[^[:space:]]+", " ", ln)  # URLs
    out[i] <- ln
  }
  out
}

br_numbers_in <- function(lines, prose = TRUE) {
  # In prose a comma between a digit and exactly three digits is a thousands
  # separator, so "1,204" is one number; in output a comma is as often a field
  # separator, and br_read_outputs() adds the grouped reading there instead. A
  # point with nothing alphanumeric before it opens a decimal, as in ".984". A
  # hyphen directly after a digit separates a range ("0.27-0.63") rather than
  # signing the number that follows it
  whole <- if (prose) "[0-9]{1,3}(?:,[0-9]{3})+(?![0-9])|[0-9]+" else "[0-9]+"
  pat   <- paste0("(?:(?<![0-9])-)?(?:(?:", whole,
                  ")(?:[.][0-9]+)?|(?<![[:alnum:].])[.][0-9]+)%?")
  found <- vector("list", length(lines))
  for (i in seq_along(lines)) {
    m <- gregexpr(pat, lines[i], perl = TRUE)[[1]]
    if (m[1] == -1L) next
    txt    <- regmatches(lines[i], list(m))[[1]]
    ends   <- m + attr(m, "match.length")
    before <- substr(rep(lines[i], length(txt)), pmax(1L, m - 60L), m - 1L)
    after  <- substr(rep(lines[i], length(txt)), ends, ends + 60L)
    found[[i]] <- data.frame(line = i, at = as.integer(m), text = txt, before = before,
                             after = after, stringsAsFactors = FALSE)
  }
  d <- do.call(rbind, found)
  if (is.null(d)) {
    return(data.frame(line = integer(0), at = integer(0), text = character(0),
                      shown = character(0), value = numeric(0), digits = integer(0),
                      sig = integer(0), unit = numeric(0), pct = logical(0),
                      kind = character(0), side = character(0), stringsAsFactors = FALSE))
  }
  bare  <- gsub(",", "", sub("%$", "", d$text), fixed = TRUE)
  value <- as.numeric(bare)
  after <- tolower(d$after)
  pct   <- grepl("%$", d$text) | grepl(br_percent_follows, after, perl = TRUE)
  # decimals as WRITTEN set the rounding tolerance, so count only what follows the
  # point; counting the whole string makes the tolerance far too tight and every
  # rounded figure in the draft then reads as an orphan
  digits <- ifelse(grepl("[.]", bare), nchar(sub("^[^.]*[.]", "", bare)), 0L)
  # significant figures as written, the trailing zeros of a whole number not
  # counted: 270 has two, 0.30 two, 1204 four. A number with fewer than two is
  # matched at its decimal places alone, so a loose "about 20" is not matched by 17
  figs <- sub("^0+", "", gsub("[^0-9]", "", bare))
  sig  <- ifelse(grepl("[.]", bare), nchar(figs), nchar(sub("0+$", "", figs)))
  sig[sig < 2L] <- NA_integer_
  # one unit of the last significant digit, the width that a bound is read to: the
  # last decimal place, or for a whole number the last digit before its trailing
  # zeros, so that "above 90%" reads to tens
  zeros <- nchar(sub("^-?[0-9]*?(0*)$", "\\1", bare, perl = TRUE))
  unit  <- ifelse(digits > 0L | value == 0, 10^(-digits), 10^zeros)
  kind  <- rep("exact", nrow(d))
  side  <- rep("eq", nrow(d))
  shown <- d$text
  keep  <- rep(TRUE, nrow(d))

  if (prose) {
    bl <- tolower(d$before)
    # whole numbers from 1900 to 2100 are years more often than results, so they
    # are listed for the reader to confirm rather than checked; a year closing a
    # parenthetical citation, "(2017)" or "(Vehtari et al. 2017)", is dropped. A
    # number written with a thousands separator is never a year
    year <- digits == 0L & abs(value) >= 1900 & abs(value) <= 2100 & !pct &
      !grepl(",", d$text, fixed = TRUE)
    cite <- year & grepl("[(]([^()]*[[:alpha:]][.,]?[[:space:]]+)?$", bl) &
      grepl("^[a-z]?[[:space:]]*[);,]", after)
    ref   <- grepl(br_structural_rx, bl)
    model <- grepl("(^|[^[:alnum:]_])m$", bl)       # model identifiers: m1, m3
    width <- grepl(br_width_follows, after, perl = TRUE)
    # a seed is stated so the analysis can be repeated, not because anything
    # computed it, so it is never in the output and always reads as an orphan
    seed  <- grepl("seed", substring(bl, nchar(bl) - 11L), fixed = TRUE)
    # the bound word, with any negation before it ("no more than", "did not
    # exceed"), which turns the side of the bound round
    at <- regexpr(paste0("(?<![[:alpha:]])((no|not|never|cannot|[[:alpha:]]+n['\u2019]t)",
                         "[[:space:]]+)?(", paste(names(br_bounds), collapse = "|"),
                         ")[[:space:]]*$"), bl, perl = TRUE)
    phrase <- character(nrow(d))
    phrase[at > 0L] <- gsub("[[:space:]]+", " ", trimws(regmatches(bl, at)))
    neg  <- grepl("^(no|not|never|cannot|[[:alpha:]]+n['\u2019]t) ", phrase, perl = TRUE)
    word <- ifelse(neg, sub("^[^ ]+ ", "", phrase), phrase)
    side <- unname(br_bounds[word])
    side[is.na(side)] <- "eq"
    side[neg] <- unname(c(gt = "le", ge = "lt", lt = "ge", le = "gt", eq = "eq")[side[neg]])
    # the words before the bound word, at most six, within its clause and after
    # any earlier number, so that "ESS above 400 and the probability above 0.99"
    # leaves the 0.99 to be checked
    pre  <- sub("^.*([,;:!?0-9]|[.][[:space:]])", "", substr(bl, 1L, pmax(0L, at - 1L)))
    near <- sub("^.*?((?:[^[:space:]]+[[:space:]]*){1,6})$", "\\1", pre, perl = TRUE)
    threshold <- side != "eq" &
      (grepl(br_diagnostics, near) | grepl(br_settings, after, perl = TRUE))
    bound <- side != "eq" & !threshold & !year
    kind[year & !cite] <- "year"
    kind[bound]  <- "bound"
    side[!bound] <- "eq"
    shown[bound] <- paste(phrase[bound], d$text[bound])
    keep <- !(cite | ref | model | width | seed | threshold)
  }
  data.frame(line = d$line, at = d$at, text = d$text, shown = shown, value = value,
             digits = digits, sig = sig, unit = unit, pct = pct, kind = kind,
             side = side, stringsAsFactors = FALSE)[keep, , drop = FALSE]
}

br_read_outputs <- function(outputs, exclude = character(0)) {
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
  # the draft is never evidence for itself, whichever folder holds it
  files <- files[!normalizePath(files, winslash = "/", mustWork = FALSE) %in%
                   normalizePath(exclude, winslash = "/", mustWork = FALSE)]
  if (!length(files)) {
    stop("no output files found in: ", paste(outputs, collapse = ", "),
         " (the draft itself is never read as output). Point `outputs` at the ",
         "saved printing of the analysis - the captured console output, the ",
         "summary tables, the csv behind the figures, the log.",
         call. = FALSE)
  }
  vals <- unlist(lapply(files, function(f) {
    txt <- readLines(f, warn = FALSE)
    # a number printed with thousands separators is read whole as well as in its
    # comma-separated parts, because a comma in output may be either
    grouped <- unlist(regmatches(txt, gregexpr(
      "(?<![0-9.])-?[0-9]{1,3}(,[0-9]{3})+([.][0-9]+)?(?![0-9])", txt, perl = TRUE)))
    c(br_numbers_in(txt, prose = FALSE)$value,
      as.numeric(gsub(",", "", grouped, fixed = TRUE)))
  }), use.names = FALSE)
  list(files = files, values = vals[is.finite(vals)])
}

br_match_one <- function(value, digits, sig, unit, pct, side, pool) {
  # a percentage may be stored either way round, but dividing by 100 moves the
  # point two places and the tolerance has to move with it: comparing 0.95 at zero
  # decimals rounds it to 1 and matches any pool holding a 1
  cand <- list(list(v = value, d = digits, u = unit))
  if (pct) cand <- c(cand, list(list(v = value / 100, d = digits + 2L, u = unit / 100)))
  # a draft's figure matches an output value when the two are within half a unit
  # of the draft's last stated place: 0.481 is consistent with an output 0.4805.
  # Rounding both sides instead fails exactly at that boundary, because 0.4805 is
  # held as 0.48049... and rounds down - a false orphan on a correctly rounded
  # number, which is the first thing this check got wrong on a real report.
  # A figure with two or more significant figures also matches an output value
  # that rounds to it at those figures, which is where a whole number such as 270
  # earns its tolerance against an output 274.7.
  # A bound is matched by a value on its side and within one unit of it, the
  # reading of a value rounded to the bound: "above 0.99" by one in (0.99, 1.00],
  # "at least 0.95" by one in [0.95, 0.96)
  eps <- 1e-9
  for (st in c("matched", "sign")) {
    p <- if (st == "sign") abs(pool) else pool
    for (k in cand) {
      v  <- if (st == "sign") abs(k$v) else k$v
      ok <- switch(side,
                   gt = p > v + eps & p <= v + k$u + eps,
                   ge = p >= v - eps & p < v + k$u - eps,
                   lt = p < v - eps & p >= v - k$u - eps,
                   le = p <= v + eps & p > v - k$u + eps,
                   abs(p - v) <= 0.5 * 10^(-k$d) + eps |
                     (!is.na(sig) & abs(signif(p, sig) - v) <= eps * max(1, abs(v))))
      if (any(ok)) return(st)
    }
  }
  "orphan"
}

br_claims_in <- function(lines) {
  empty <- data.frame(line = integer(0), from = integer(0), to = integer(0),
                      text = character(0), stringsAsFactors = FALSE)
  if (!length(lines)) return(empty)
  # A sentence ends at . ! or ? before a space, or at a blank line, so that a
  # paragraph without a full stop does not run on into the next. Each keeps its
  # span in the lines joined by newlines, which is where the numbers found in it
  # are placed
  txt   <- paste(lines, collapse = "\n")
  cut   <- gregexpr("(?<=[.!?])[[:space:]]+|\n[[:space:]]*\n", txt, perl = TRUE)[[1]]
  from  <- c(1L, if (cut[1] > 0L) cut + attr(cut, "match.length"))
  to    <- c(if (cut[1] > 0L) cut - 1L, nchar(txt))
  parts <- substring(txt, from, to)
  from  <- from + attr(regexpr("^[[:space:]]*", parts), "match.length")
  parts <- trimws(gsub("[[:space:]]+", " ", parts))
  line  <- findInterval(from, cumsum(c(1L, nchar(lines) + 1L))[seq_along(lines)])
  # pad and strip punctuation so a quantifier matches as a word rather than inside
  # one: " all " must not fire on "small" or "generally"
  padded <- paste0(" ", tolower(gsub("[^[:alnum:][:space:]]+", " ", parts)), " ")
  hits   <- vapply(padded, function(s) {
    any(vapply(br_quantifiers,
               function(q) grepl(paste0(" ", q, " "), s, fixed = TRUE),
               logical(1)))
  }, logical(1), USE.NAMES = FALSE)
  keep <- nzchar(parts) & hits
  if (!any(keep)) return(empty)
  data.frame(line = line[keep], from = from[keep], to = to[keep], text = parts[keep],
             stringsAsFactors = FALSE)
}

br_check_numbers <- function(draft, outputs, ignore = numeric(0), claims = TRUE) {

  if (missing(outputs) || !length(outputs)) {
    stop("no output given to check the draft against. Call br_check_numbers(draft, ",
         "outputs) with `outputs` the files or folders holding the saved printing of ",
         "the analysis; the draft is never read as its own output.", call. = FALSE)
  }
  if (!file.exists(draft)) {
    stop("no draft found at '", draft, "'.", call. = FALSE)
  }

  lines <- readLines(draft, warn = FALSE)
  prose <- br_strip_prose(lines)
  found <- br_numbers_in(prose, prose = TRUE)
  years <- found[found$kind == "year", , drop = FALSE]
  nums  <- found[found$kind != "year" & !found$value %in% ignore, , drop = FALSE]

  pool <- br_read_outputs(outputs, exclude = draft)

  nums$status <- vapply(seq_len(nrow(nums)), function(i) { # r-style: keep – base R only, the plugin adds no package
    br_match_one(nums$value[i], nums$digits[i], nums$sig[i], nums$unit[i], nums$pct[i],
                 nums$side[i], pool$values)
  }, character(1))

  orphan <- nums[nums$kind == "exact" & nums$status == "orphan", , drop = FALSE]
  bounds <- nums[nums$kind == "bound" & nums$status == "orphan", , drop = FALSE]
  signed <- nums[nums$status == "sign", , drop = FALSE]

  # each number belongs to the quantified sentence whose span holds its position
  # in the lines joined by newlines, the measure that br_claims_in() uses
  claim <- br_claims_in(if (claims) prose else character(0))
  pos   <- cumsum(c(1L, nchar(prose) + 1L))[nums$line] + nums$at - 1L
  owner <- vapply(pos, function(p) { # r-style: keep – base R only, the plugin adds no package
    c(which(claim$from <= p & claim$to >= p), NA_integer_)[1]
  }, integer(1))
  says <- lapply(c(matched = "matched", sign_only = "sign", unmatched = "orphan"), function(st) { # r-style: keep – base R only, the plugin adds no package
    vapply(seq_len(nrow(claim)), function(j) { # r-style: keep – base R only, the plugin adds no package
      paste(nums$shown[owner %in% j & nums$status == st], collapse = ", ")
    }, character(1))
  })
  claim <- cbind(claim, as.data.frame(says, stringsAsFactors = FALSE))

  cat("=== Draft against output ===\n") # r-style: keep – the printed report is this script's output
  cat(sprintf("draft:   %s\n", draft))
  cat(sprintf("outputs: %d file(s), %d numeric values\n",
              length(pool$files), length(pool$values)))
  cat(sprintf("checked: %d number(s) in prose, %d traced to an output value\n",
              nrow(nums), sum(nums$status == "matched")))
  if (any(nums$kind == "bound")) {
    cat(sprintf("bounds:  %d of them, checked as inequalities, %d matched\n",
                sum(nums$kind == "bound"), sum(nums$kind == "bound" & nums$status == "matched")))
  }
  if (nrow(years)) {
    cat(sprintf("years:   %d whole number(s) from 1900 to 2100, not checked\n", nrow(years)))
  }
  cat("\n") # r-style: keep – the printed report is this script's output

  if (nrow(orphan)) {
    cat("Numbers that appear in no output\n")
    for (i in seq_len(nrow(orphan))) {
      cat(sprintf("  line %-5d %-12s %s\n", orphan$line[i], orphan$text[i],
                  trimws(substr(lines[orphan$line[i]], 1, 62))))
    }
    cat("  -> each is a typo, a value carried over from a superseded fit, or a\n",
        "     number nobody computed. Re-derive it or delete the sentence.\n\n",
        sep = "")
  }

  if (nrow(bounds)) {
    up  <- bounds$side %in% c("gt", "ge")
    lo  <- signif(ifelse(up, bounds$value, bounds$value - bounds$unit), 12)
    hi  <- signif(ifelse(up, bounds$value + bounds$unit, bounds$value), 12)
    shut <- bounds$side %in% c("gt", "le")
    pc  <- ifelse(bounds$pct, "%", "")
    rng <- paste0(ifelse(shut, "(", "["), lo, pc, ", ", hi, pc, ifelse(shut, "]", ")"))
    cat("Bounds not matched at the stated precision\n") # r-style: keep – the printed report is this script's output
    for (i in seq_len(nrow(bounds))) {
      cat(sprintf("  line %-5d %-20s no output value in %s\n", bounds$line[i],
                  bounds$shown[i], rng[i]))
    }
    cat("  -> a bound is matched by an output value on its stated side and within\n", # r-style: keep – the printed report is this script's output
        "     one unit of its last digit, as a value rounded to the bound would be:\n",
        "     'above 0.99' by a value in (0.99, 1]. A bound listed here is false, or\n",
        "     looser than the output allows. Check the sentence against the output.\n\n",
        sep = "")
  }

  if (!nrow(orphan) && !nrow(bounds)) {
    cat("Every number in the prose traces to an output value.\n\n") # r-style: keep – the printed report is this script's output
  }

  if (nrow(signed)) {
    cat("Numbers that match only once the sign is dropped\n")
    for (i in seq_len(nrow(signed))) {
      cat(sprintf("  line %-5d %s\n", signed$line[i], signed$shown[i]))
    }
    cat("  -> usual where the prose says 'lower by' and the output is negative.\n",
        "     Check that the direction the sentence states is the right one.\n\n",
        sep = "")
  }

  if (nrow(years)) {
    cat("Whole numbers from 1900 to 2100, read as years and not checked\n") # r-style: keep – the printed report is this script's output
    for (i in seq_len(nrow(years))) {
      cat(sprintf("  line %-5d %-12s %s\n", years$line[i], years$text[i],
                  trimws(substr(lines[years$line[i]], 1, 62))))
    }
    cat("  -> confirm that each is a year. A count in this range is checked when it\n", # r-style: keep – the printed report is this script's output
        "     is written with a thousands separator, as 1,987.\n\n", sep = "")
  }

  if (nrow(claim)) {
    cat("Sentences with a quantifier, and the numbers in each\n") # r-style: keep – the printed report is this script's output
    indent <- strrep(" ", 13)
    for (j in seq_len(nrow(claim))) {
      cat(sprintf("  line %-5d ", claim$line[j]),
          paste(strwrap(claim$text[j], width = 64), collapse = paste0("\n", indent)),
          "\n", sep = "")
      held <- c(if (nzchar(claim$matched[j])) paste("matched:", claim$matched[j]),
                if (nzchar(claim$sign_only[j])) paste("matched without the sign:", claim$sign_only[j]),
                if (nzchar(claim$unmatched[j])) paste("not matched:", claim$unmatched[j]))
      if (!length(held)) held <- "no number checked"
      cat(paste0(indent, held, collapse = "\n"), "\n", sep = "")
    }
    cat("  -> matching digits checks the numbers, not the claim. Hold each sentence\n", # r-style: keep – the printed report is this script's output
        "     against the output it summarises: a number that matches can be a row\n",
        "     label of the very table that the sentence misreads, and a sentence\n",
        "     with no number still asserts something about a distribution.\n\n",
        sep = "")
  }

  cat("A clean run means the numbers exist somewhere in the output supplied. It does\n",
      "not mean each one came from the right place, and it says nothing about\n",
      "whether the claim built on it holds.\n", sep = "")

  invisible(list(numbers = nums, orphan = orphan, bounds = bounds, sign_only = signed,
                 years = years, claims = claim, files = pool$files))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 2L || "--help" %in% args) {
    cat("usage: Rscript br_check_numbers.R <draft> <output-file-or-dir> [more output ...]\n", # r-style: keep – the usage message is the command line's answer
        "  The output is required: the files or folders holding the saved printing\n",
        "  of the analysis, and the log. The draft is never read as output.\n",
        sep = "")
    quit(status = 1L)
  }
  res <- br_check_numbers(args[1], args[-1])
  quit(status = if (nrow(res$orphan) || nrow(res$bounds)) 1L else 0L)
}
