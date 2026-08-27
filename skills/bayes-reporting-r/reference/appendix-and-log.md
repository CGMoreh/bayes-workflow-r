# The workflow log, and the appendix it becomes

The supplementary appendix of a workflow paper has one job: to let a sceptical reader
reconstruct how the reported model was arrived at, including the models it replaced. The
cheapest way to produce it is not to write it at the end but to keep the workflow log as
the analysis runs and convert it when the manuscript is drafted. This file covers both
halves.

---

## Keeping the log

The format is defined in the `bayes-workflow-r` SKILL.md and repeated here because this
skill consumes it: one `## <date> – <label>` heading per pass round the loop, three lines
of body – the check run, what it showed, what changed. An entry is written when the pass
happens, not reconstructed later, because the reconstruction always loses the failures and
the failures are the argument.

What makes a log convertible rather than merely kept:

- **One entry per decision, not per session.** A day that fitted one model and ran three
  checks on it is one entry; a day that abandoned a specification and started another is
  two.
- **Name the check and its verdict in the first sentence.** "PPC on region-level rates
  failed" converts to an appendix section; "looked at some plots" does not.
- **Record what did NOT change.** "Power-scaling clean, nothing to do" is an entry, and it
  becomes the sentence in the paper that says the check was run.
- **Point at artefacts by path.** A log line naming `model-data/m3.rds` and the figure it
  produced lets the appendix chunk be filled in months later without archaeology.

## Converting it

`scripts/br_appendix.R` turns the log into a Quarto skeleton:

```r
source("${CLAUDE_SKILL_DIR}/scripts/br_appendix.R")
br_appendix_scaffold("bayes-workflow-log.md", "appendix-workflow.qmd")

# or from the shell
# Rscript "${CLAUDE_SKILL_DIR}/scripts/br_appendix.R" bayes-workflow-log.md appendix-workflow.qmd
```

The scaffold contains, in order: a framing paragraph; a **stage-coverage checklist**, one
row per workflow stage with a "reported where" cell to fill; one section per log entry,
quoting the entry and holding a labelled, empty figure chunk; and a `sessionInfo()` block.
The scaffolder refuses to overwrite an existing output file, because the scaffold is filled
by hand and a re-run after a new log entry would otherwise destroy that work; move the old
file aside, or pass `overwrite = TRUE` (`--force` on the command line) when replacement is
what you want. Filling it is mechanical – replace each placeholder with the pass's figure or
table and one sentence of reading – and the checklist is filled last, because filling it is an audit: a
row you cannot point at a section is a stage the analysis skipped, discovered while there
is still time to run it.

## What the finished appendix contains, and in what order

1. **The model sequence.** Every specification fitted on the way to the reported one, each
   with the check that retired it. This is the section reviewers actually read, because it
   answers the question the methods section compresses: why this model.
2. **The checks in full.** The prior predictive figures, the diagnostic tables with every
   parameter, the posterior predictive panels, the sensitivity output – everything the main
   text summarised into a sentence, at full resolution.
3. **The comparison detail.** Pointwise attribution plots, Pareto k diagnostics, the
   grouped cross-validation where one was run.
4. **The calibration.** The simulated-recovery table with its settings, so the four numbers
   in the methods can be re-derived.
5. **Software and seeds.** Versions, backends, the seed policy, and where the code lives.

Order by workflow stage, not by manuscript section: the appendix's organising claim is
that the analysis was a sequence, and its structure should perform that claim.

## The division of labour with the main text

The main text carries whatever a reader needs to *evaluate* a claim; the appendix carries
whatever a reader needs to *reproduce* the analysis. The test for any given artefact: if a
sceptic's assessment of a central result would change on seeing it, it belongs in the
text, however bulky – a failed check that motivated the reported specification is the
canonical case. If it documents diligence without bearing on any particular claim, it
belongs here.

Two placements that are commonly got wrong in both directions:

- **Design calibration at small N goes in the text.** It conditions how every estimate
  should be read, which is the definition of bearing on a claim.
- **The full R-hat table goes in the appendix.** The text reports the worst values; the
  table proves the sentence, and proof is this document's business.

## Renaming the inheritance

A last practical point. When the appendix is assembled from the log, its prose inherits
the log's register – terse, dated, decision-oriented. Convert the register, keep the
content: appendix prose is written for a reader of the paper, in full sentences, in the
same voice as the methods section. What must survive the conversion untouched is the
sequence and the verdicts, because an appendix that has been smoothed into a story of
uninterrupted success no longer documents a workflow, and a reviewer who has run one can
tell.
