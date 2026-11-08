# The workflow log, and the appendix it becomes

The supplementary appendix of a workflow paper has one job: to let a sceptical reader
reconstruct how the reported model was arrived at, including the models it replaced. The
cheapest way to produce it is not to write it at the end but to keep the workflow log as
the analysis runs and convert it when the manuscript is drafted. This file covers both
halves.

---

## Keeping the log

The format is defined under "The workflow log" in the `bayes-workflow-r` SKILL.md, which asks for "One dated entry per pass round the loop, recording the model fitted, the check run, what it showed, and what changed as a result." The example given there heads each entry `## <date> – <label>` and closes it with a "Next:" line, and the appendix can join a model to its file when the model is named `m1`, `m2` and so on in the log and saved as `model-data/m<n>_<label>.rds`. An entry is written when the pass happens, not reconstructed later, because the reconstruction always loses the failures and the failures are the argument.

What makes a log convertible rather than merely kept:

- **One entry per decision, not per session.** A day that fitted one model and ran three
  checks on it is one entry; a day that abandoned a specification and started another is
  two.
- **Name the check and its verdict in the first sentence.** "PPC on region-level rates
  failed" converts to an appendix section; "looked at some plots" does not.
- **Record what did NOT change.** "Power-scaling clean, nothing to do" is an entry, and it
  becomes the sentence in the paper that says the check was run.
- **Point at artefacts by path.** A log line naming `model-data/m3_varying-slopes.rds` and
  the figure it produced lets the appendix chunk be filled in months later without
  archaeology.

## Converting it

`scripts/br_appendix.R` turns the log into a Quarto skeleton, written beside the write-up. In the calls below `${CLAUDE_SKILL_DIR}` stands for the folder of this skill; R does not expand it, so replace it with the path of that folder before the call runs.

```r
source("${CLAUDE_SKILL_DIR}/scripts/br_appendix.R")
br_appendix_scaffold("bayes-workflow-log.md", "appendix-workflow.qmd")

# or from the shell
# Rscript "${CLAUDE_SKILL_DIR}/scripts/br_appendix.R" bayes-workflow-log.md appendix-workflow.qmd
```

The scaffold contains, in order: a framing paragraph; a **stage-coverage table** – derived
from the log by the workflow skill's `bw_scheme.R` where that skill is installed, with all nine stages and a "Reported where" column to fill, and otherwise the nine stages with that column alone; one section per log entry, numbered as the generator numbers the entries ("Entry 3 – …"), quoting the entry and holding a labelled, empty figure chunk; and a `sessionInfo()` block. The console message says which of the two tables was written.
The scaffolder refuses to overwrite an existing output file, because the scaffold is filled
by hand and a re-run after a new log entry would otherwise destroy that work; move the old
file aside, or pass `overwrite = TRUE` (`--force` on the command line) when replacement is
what you want.

Fill the scaffold from the log and the saved output. Each entry section gets the figure or table that its check produced and one sentence of reading, saying what the check showed and what changed as a result. A placeholder that neither the log nor the output can fill stays in place, and the reply lists it. The coverage table is filled last, from the log. It is a write-up-time record of where each stage is reported, for the reviewer who wants to find it. A stage marked "no entry placed here by the log's wording" may still have been run inside another entry, as a prior predictive check often is, so read the entries that reach it before writing that it was not run. A row with nothing to point at is written as what it is – a stage that this analysis did not run, with the reason if the log gives one – and the appendix is the place where that fact belongs. It is not a list of work to go back and do: an analysis is finished when its question is answered, and the appendix records the route taken, not the route that a template would have preferred.

## What the finished appendix contains, and in what order

After the framing paragraph and the stage-coverage table written by the scaffold, the finished appendix has five parts, in this order.

1. **The model sequence.** The sections that the scaffold writes for the log entries, in the
   order of the log: every specification fitted on the way to the reported one, each with the
   check that retired it. This is the part that reviewers actually read, because it answers
   the question that the methods section compresses: why this model.
2. **The checks in full.** The prior predictive figures, the diagnostic tables with every
   parameter, the posterior predictive panels, the sensitivity output – everything that the
   main text summarised into a sentence, at full resolution.
3. **The comparison detail.** Pointwise attribution plots, Pareto k diagnostics, the
   grouped cross-validation where one was run.
4. **The calibration.** The simulation settings and the table of results, so that the rates
   reported in the results section can be re-derived.
5. **Software and seeds.** Versions, backends, the seed policy, and where the code lives, in
   the software section with which the scaffold ends.

Parts 2 to 4 are sections added after the model sequence and before the software section. The order follows the analysis rather than the manuscript, because the organising claim of the appendix is that the analysis was a sequence, and the scaffold already places the sections of the model sequence in the order of the log.

## The division of labour with the main text

The main text carries whatever a reader needs to *evaluate* a claim; the appendix carries
whatever a reader needs to *reproduce* the analysis. The test for any given artefact: if a
sceptic's assessment of a central result would change on seeing it, it belongs in the
text, however bulky – a failed check that motivated the reported specification is the
canonical case. If it documents diligence without bearing on any particular claim, it
belongs here.

Two placements that are commonly got wrong in both directions:

- **Design calibration at small N goes in the text.** It conditions how every estimate
  should be read, which is the definition of bearing on a claim. The methods say how the
  simulation was run, and the results give its rates, each beside the estimate that it qualifies.
- **The full R-hat table goes in the appendix.** The text reports the worst values; the
  table proves the sentence, and proof is this document's business.

## Register of the appendix

A last practical point. When the appendix is assembled from the log, its prose inherits
the log's register – terse, dated, decision-oriented. Convert the register, keep the
content: appendix prose is written for a reader of the paper, in full sentences, in the
same voice as the methods section. What must survive the conversion untouched is the
sequence and the verdicts, because an appendix that has been smoothed into a story of
uninterrupted success no longer documents a workflow, and a reviewer who has run one can
tell.
