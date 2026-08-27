---
name: bayes-reporting-r
description: >-
  Write up a Bayesian analysis for a journal, so that the workflow that produced the estimates
  is visible in the paper rather than buried in an appendix. Covers the methods section stage by
  stage, wording for priors and prior justification, reporting convergence and predictive
  checks without a diagnostic log, reporting posteriors without
  significance thresholds, what belongs in the main text against the supplement,
  assembling a workflow appendix from the analysis log, and phrasing that reads as social
  science rather than as statistics. Use when drafting or revising the methods or results
  section of a paper reporting Bayesian estimates; when a reviewer challenges the priors or
  the choice of a Bayesian analysis itself and the defence has to be written into a response
  memo or a robustness paragraph; when converting an analysis notebook into a manuscript; or when deciding which
  checks to report. For running the analysis use
  bayes-workflow-r; for defining the quantity being reported use bayes-estimands-r.
license: MIT
compatibility: Designed for manuscripts written in Quarto or R Markdown, with analyses fitted using brms.
metadata:
  author: Chris Moreh
  version: "0.1.0"
  repository: https://github.com/CGMoreh/bayes-workflow-r
---

# Writing up a Bayesian workflow

The anti-pattern this skill exists to correct is a methods paragraph that reads: "We fitted
Bayesian models in brms with weakly informative priors. Four chains of 2000 iterations were run;
convergence diagnostics are reported in the appendix." Everything that made the analysis
defensible has been compressed out of it, and the reader is left with a single regression and an
assurance.

The alternative is to present the analysis as what it was. A sequence of models, each motivated
by what the previous one failed to reproduce, with the checks reported at the point where each
bears on a claim.

## The framing sentence

Somewhere in the first paragraph of the methods, say that the estimates are the product of an
iterative workflow rather than a single fitted model, and cite the book once, there. The warrant
for doing so is the book's own argument: where data are sparse or the model is complex, the
choices made about model, prior and computation do real work, and a workflow is how those
choices are made accountable rather than arbitrary.

Do not cite it again in every subsequent paragraph. One framing citation, then the per-stage
methods sources.

## The methods section, stage by stage

Each stage below gets one to three sentences. The whole thing should run to two or three
paragraphs, not two pages.

| Stage | What the sentence has to establish |
|---|---|
| Model and family | What was fitted, to what outcome, with what structure, and why that family suits how the outcome was generated |
| Priors | What they were, on what scale, and what they imply. Name the check you ran, not just the adjective |
| Prior predictive | That the priors were examined before the data were used, and what they implied about plausible outcomes |
| Computation | Chains, iterations, backend, and the diagnostics with actual values. If anything failed and was fixed, say what and how |
| Predictive checks | Which checks were run, which failed, and what the failures changed |
| Sensitivity | That the reported quantity is insensitive to the prior, in those words, with the method named |
| Comparison | The models compared, on what criterion, and whether the difference exceeded its uncertainty |
| Design calibration | At small samples: what the design can recover, as a simulated recovery rate |

## Wording that does the work

**Priors.** The weak version: "weakly informative priors were used". The version a reviewer
cannot object to: "Slope priors were normal(0, 0.5) on standardised predictors. Simulating from
the prior alone implies a median R² of 0.31 with a 95th percentile of 0.68, which brackets the
range reported in this literature."

**Computation.** Not "convergence was satisfactory" but "All R-hat values were below 1.01 and
bulk and tail effective sample sizes exceeded 1500 for every reported parameter, with no
divergent transitions." If there were divergences in an earlier model, that belongs in the text:
it shows the diagnostics were read rather than glanced at.

**Sensitivity.** "The average marginal effect of parental education is insensitive to
power-scaling of the prior and sensitive to power-scaling of the likelihood, indicating that the
estimate reflects the data rather than the prior specification." This is the sentence that
answers the small-sample objection, and it is worth its space in the main text.

**A null.** Where a parameter shows low likelihood sensitivity, the finding is not that the
effect is absent but that the data cannot distinguish it from absent. Word it that way. "The
posterior for origin is centred near zero but the likelihood sensitivity diagnostic indicates the
data are weakly informative about this parameter, so we treat it as undetermined rather than
null."

**Comparison.** "Model 3 improved expected log predictive density by 8.2 (SE of the difference
4.1) over model 2, a difference of about two standard errors, and the improvement is concentrated
in the twelve respondents who changed employment status between waves."

## Reporting the posterior rather than a verdict

Report the distribution, not a decision. A posterior median with a credible interval, and where
it adds something, the probability of direction and a region of practical equivalence. Say which
interval width you used and be consistent.

Three habits to avoid, all of them significance testing wearing different clothes:

- Treating "the 95% interval excludes zero" as the finding. It is one summary of a distribution,
  and the distribution is what you have.
- Reporting the probability of direction as though it were a p-value, with a threshold at 95%.
- Choosing the interval width after seeing which one excludes zero.

Where the outcome is on a scale readers do not have intuitions about, report a marginal effect or
a predicted probability at interpretable covariate values instead of, or alongside, the
coefficient. Most readers of a sociology journal can evaluate "the predicted probability rises
from 0.22 to 0.38" and cannot evaluate a log-odds coefficient.

Figures carry uncertainty better than tables. A half-eye or interval plot of the posterior for
the quantities the argument depends on communicates more than a coefficient table, and takes less
space.

## Register

Write for the discipline the paper is in. Terms that appear in the general methods literature of
your field are fine and should be used plainly: estimand, identification, specification,
marginal effect, counterfactual, partial pooling, posterior. Terms that belong to statistics or
machine learning and have a disciplinary equivalent should use the equivalent. Terms with no
equivalent should be defined once, on first use, and then used.

Do not explain what Bayesian inference is. Explain what this Bayesian analysis does that the
alternative would not, and anchor that to the methods literature: partial pooling where cells are
sparse, posterior uncertainty on quantities that maximum likelihood does not naturally provide,
a measurement model the outcome actually requires.

If the paper mixes frequentist and Bayesian estimation, report each in its own idiom. Confidence
intervals and effect sizes for one, posterior intervals for the other. Constructing a single
vocabulary across both produces imprecision, and it is not a contribution.

## What goes where

**Main text**: the model, the priors and what they imply, the diagnostics as a sentence, the
checks that changed the model, the sensitivity result for the reported quantity, and the design
calibration if the sample is small.

**Supplementary appendix**: the figures for every check, the full diagnostic tables, the model
sequence in detail, the prior predictive plots, the code.

The dividing line is whether a reader needs it to evaluate the claim or to reproduce the
analysis. The first goes in the text; the second goes in the supplement. A robustness result that
a claim depends on is not a supplementary detail, whatever its length.

## Building the appendix from the log

If the analysis kept a `bayes-workflow-log.md` as `bayes-workflow-r` recommends, the appendix is
largely written. Each entry is a model, a check, a result and a decision, which is exactly the
structure the appendix needs. Convert it by:

1. Grouping entries into the model sequence they describe.
2. Replacing the working notes with the figure or table each check produced.
3. Adding, for each model, one sentence saying why it was superseded.
4. Keeping the failures. A workflow appendix that contains only models that worked is not a
   workflow appendix, and reviewers can tell.

## Where the detail lives

| Reference file | Load it when |
|---|---|
| `reference/methods-templates.md` | Drafting a methods section: three complete worked templates – multilevel survey logistic, small-N repeated measures, overdispersed counts – each annotated sentence-by-stage |
| `reference/reviewer-responses.md` | Answering the standard objections: priors-drove-it, n-too-small, why-Bayesian-at-all, each with the evidence to generate, memo text and the manuscript change |
| `reference/appendix-and-log.md` | Keeping a convertible workflow log and assembling the supplementary appendix from it |

One bundled script: `scripts/br_appendix.R` converts a `bayes-workflow-log.md` into a
Quarto appendix skeleton with a stage-coverage checklist –
`Rscript "${CLAUDE_SKILL_DIR}/scripts/br_appendix.R" bayes-workflow-log.md appendix-workflow.qmd`.

## A note on reproducibility statements

State the software versions, the seed, and where the code and data are deposited. Say which
results require the raw data and which can be reproduced from derived files. If some data cannot
be shared, say which, and why, and what a reader can verify without them.

---

Source for the workflow argument: Gelman, Vehtari, McElreath et al., *Bayesian Workflow* (CRC
Press, 2026), particularly chapter 10 on statistical against scientific inference. The reporting
conventions draw on Kruschke's work on threshold-free reporting and on the visualisation
literature. See `skills/bayes-workflow-r/reference/book-map.md` in this plugin.
