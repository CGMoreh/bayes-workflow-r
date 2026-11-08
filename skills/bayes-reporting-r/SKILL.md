---
name: bayes-reporting-r
description: >-
  Write up a Bayesian analysis for a journal, so the workflow behind the estimates is visible in
  the paper rather than buried in an appendix. Produces an article's methods and results
  sections in one file, in the interpretive register of the workflow authors' case studies, with
  an appendix built from the analysis log and every number checked against the output behind it.
  Covers wording for priors, reporting posteriors without significance thresholds, and what
  belongs in the main text against the supplement. Use when writing up a finished Bayesian
  analysis, or drafting or revising the methods or results section of a paper reporting Bayesian
  estimates; when a reviewer challenges the priors or the choice of a Bayesian analysis; when
  converting an analysis notebook or report into manuscript sections; when checking that a
  draft's numbers trace to its output; or when deciding which checks to report. For running the
  analysis use bayes-workflow-r; for the quantity reported use bayes-estimands-r.
license: MIT
compatibility: Designed for manuscripts written in Quarto, R Markdown or plain Markdown, with analyses fitted using brms.
metadata:
  author: Chris Moreh
  version: "0.2.0"
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

## Article sections

A request to write up a finished analysis – "write this up", "draft the paper's analysis" – is answered with the sections of an article, in one file: a methods section headed as the target venue heads it ("Data and Analysis", "Data and Methods" or "Methods") and a results section. Both sit at the heading level of the manuscript's own sections, or at the second level where there is no manuscript. A venue that uses subsections gets them, each headed by a brief phrase that names its topic rather than stating a finding. The file is Quarto where the manuscript is Quarto, R Markdown where it is R Markdown, and plain Markdown otherwise. It is named `writeup.qmd` (or `.Rmd`, `.md`) unless the author names another, and it is written beside the manuscript rather than into it, so that the merging stays with the author. With no manuscript, it goes in the project root. An existing write-up is never overwritten: the new one is written as `writeup-2.qmd` (and so on), or the author is asked first.

The test for which form a request gets is the reader addressed. A text written for the readers of the paper takes the form of article sections, whatever name the request gives the text. A document addressed to someone else, such as a memo to co-authors, a report to a funder or a supervisor, or a talk, keeps its own form and is written in the same register.

The sections are organised as an article is, not as the analysis ran. The stages of the workflow – priors, computation, predictive checks, comparison, sensitivity, design calibration – become sentences inside the paragraphs of the two sections, as the table under "Stages by section" sets out. Headings named after stages ("Prior predictive checks", "Step 4") and headings addressed to a client ("What I did", "How much to trust this") belong to a working report, a purpose already served by the workflow log and `WORKFLOW.md`. The annotation table that follows each template in the reference files says which stage each sentence reports. It describes the template and stays out of the file.

One rule divides the material between the two sections. The methods section says what was done and how each check was read: the data, the model and its family, the priors and what the priors imply, the computation and its diagnostics, the model sequence with the checks that changed the model (a predictive check that failed, the comparison that chose between models), and that a sensitivity analysis and a design calibration were run, and how. The results section gives the reported quantities first and then what the checks of the final model showed, namely the sensitivity of the reported quantity, the predictive checks of the final model, and the result of the design calibration, which qualifies the claims. Each number that the analysis produced appears once, in the section to which this rule assigns it, and the other section refers to it in words. Asked for one of the two sections alone, write it by the same rule, and say in the reply what the rule leaves to the other section.

A finished analysis is reported as it was run. A stage that was not run is stated as not run, in one clause, with the reason where the log gives one. A bracket in a template is filled only from the log or the saved output, never from invention, and a value that neither of them holds stays a bracket in the file and is listed in the reply.

The workflow appendix goes in a second file, beside the write-up. Start it from the scaffold that `scripts/br_appendix.R` writes from the log. The scaffold has one section per log entry, in the order of the log, and so in the order of the model sequence. Fill its placeholders from the log and the saved output, leave a placeholder wherever neither holds the value, and list those placeholders in the reply. The methods section refers to the appendix once, and "Building the appendix from the log" below describes the finished appendix.

Once the file is written, run `scripts/br_check_numbers.R` on it. Give it as sources the saved output, the workflow log and the analysis scripts, since many diagnostic values live in the log and inputs such as prior scales are set in the scripts; its command line takes several paths, for example `Rscript "${CLAUDE_SKILL_DIR}/scripts/br_check_numbers.R" writeup.qmd output/ bayes-workflow-log.md R/`. Name the sources one by one, never the folder that holds the write-up. The check reads text, CSV and JSON output and not rendered HTML, so a Quarto notebook that holds results is rendered with `keep-md: true`, which keeps a Markdown copy of the executed document with its printed output. A number that the prose derives, such as a percentage-point difference or the rate for a participant one standard deviation above the average, is saved to the output before it is quoted, so that the check can trace it. In the reply rather than the file, give the untraced numbers, the bounds not matched at the stated precision, the numbers taken for years, and the quantified sentences with the numbers in each, and list apart from the results the inputs chosen in advance that the draft states: prior scales, chain and iteration counts, `adapt_delta`, software versions.

## The framing sentence

Somewhere in the first paragraph of the methods, say that the estimates are the product of an
iterative workflow rather than a single fitted model, and cite the book once, there. The warrant
for doing so is the book's own argument: where data are sparse or the model is complex, the
choices made about model, prior and computation do real work, and a workflow is how those
choices are made accountable rather than arbitrary.

Do not cite it again in every subsequent paragraph. One framing citation, then the per-stage
methods sources.

## Stages by section

Each stage below gets one to three sentences, in the section to which the rule under "Article sections" assigns it. The methods should run to two to four paragraphs, not two pages.

| Stage | Methods | Results |
|---|---|---|
| Model and family | What was fitted, to what outcome, with what structure, and why that family suits how the outcome was generated | – |
| Priors | What they were, on what scale, and what they imply. Name the check you ran, not just the adjective | – |
| Prior predictive | That the priors were examined before the data were used, and what they implied about plausible outcomes | – |
| Computation | Chains, iterations, backend, and the diagnostics with actual values. If anything failed and was fixed, say what and how | – |
| Model sequence | Each model that was replaced, the predictive check that retired it, with its values, and what the failure changed | Referred to in words where a claim depends on it |
| Comparison | The models compared, on what criterion, the difference and its standard error, and what the pointwise differences show | Where models cannot be separated, the estimate and interval under each, as sensitivity to the choice of model |
| Predictive checks of the final model | Which checks were run, on which summaries | What each showed, read as what it could detect and what it could not |
| Sensitivity | That the reported quantity was power-scaled, with the method named, and any refit under a visibly different prior | Whether the reported quantity is sensitive to power-scaling of the prior and of the likelihood, with both readings given, and the estimate under any refit |
| Design calibration | At small samples: how the design was simulated (sample size and structure, the assumed effect and its source outside the data, the number of replications, the interval width) and what each rate counts | The rates, each beside the claim that it qualifies |

## Wording that does the work

**Priors.** The weak version: "weakly informative priors were used". The version a reviewer
cannot object to: "Slope priors were normal(0, 0.5) on standardised predictors. Simulating from
the prior alone implies a median R-squared of 0.31, with 90 per cent of the prior mass between
0.04 and 0.68, which covers the range reported in this literature."

**Computation.** Not "convergence was satisfactory" but "All R-hat values were below 1.01 and
bulk and tail effective sample sizes exceeded 1500 for every reported parameter, with no
divergent transitions." If there were divergences in an earlier model, that belongs in the text:
it shows the diagnostics were read rather than glanced at.

**Sensitivity.** "The average marginal effect of parental education is insensitive to
power-scaling of the prior and sensitive to power-scaling of the likelihood, indicating that the
estimate reflects the data rather than the prior specification." This is the sentence that
answers the small-sample objection. It belongs in the results, where the estimate is claimed,
while the methods say that power-scaling was run on that quantity, and it gives both readings
because each means something only beside the other.

Power-scaling raises the prior, and separately the likelihood, to a power close to one and records how far the posterior moves, so the diagnostic describes the response to a small change around the specified prior rather than to a different prior. It cannot change an improper flat prior, since a constant raised to any power stays constant. brms gives population-level coefficients such a prior by default, and in a model that keeps those defaults the prior side of the diagnostic reflects only the proper priors, such as those on the intercept and the standard deviations. Whether the choice of prior matters is tested by refitting under a visibly different prior, as `reference/reviewer-responses.md` recommends, and the sensitivity sentence reports that refit where it was run.

**A null.** Where a parameter is sensitive to power-scaling of the prior and insensitive to
power-scaling of the likelihood, the finding is not that the effect is absent but that the data
cannot distinguish it from absent. Word it that way. "The posterior for origin is centred near
zero, and it is sensitive to power-scaling of the prior and insensitive to power-scaling of the
likelihood, so the data are weakly informative about this parameter and we treat it as
undetermined rather than null."

**Comparison.** "Model 3 improved expected log predictive density by 8.2 over model 2, with a
standard error of the difference of 4.1. The improvement is concentrated in the person-waves of
the twelve respondents who changed employment status between waves, and dropping the three
person-waves with the largest pointwise differences moves the probability that model 2 predicts
worse from 0.98 to 0.84, so we report the difference and its standard error and not the
probability."

The comparison sentence belongs to the methods, and it is where drafts most often leave the register. Report the difference and its standard error with what the pointwise differences show, which is whether the difference is spread across the sample or concentrated in a few observations. A probability derived from the two is reported only if it survives its leading cases, which means that it does not move when it is recomputed without the three observations with the largest absolute pointwise differences, the check set out in `bayes-workflow-r/reference/comparison.md`. Where the probability moves, it is withdrawn in the sentence that computed it, and the sentence says what is unusual about those observations. In a panel, each pointwise term is one wave of one respondent, so the concentration is stated in person-waves, and a claim about new respondents needs a cross-validation that leaves out whole respondents, as the same file sets out. Below roughly a hundred observations the standard error is itself poorly estimated, and the comparison is reported as suggestive. A model that cross-validation prefers is not thereby called adequate.

## Reporting the posterior rather than a verdict

Report the distribution, not a decision. A posterior median with a credible interval, and where
it adds something, the probability of direction and a region of practical equivalence. Use
central intervals, which run from a lower quantile to the matching upper one (the 5th to the
95th percentile for a 90% interval). The central interval of a transformed quantity is the
transformed central interval, so an interval for a log-odds contrast stays a central interval
when it is moved to the probability scale. A highest-density interval lacks this property. Say
which width you used, use it throughout, and pass the same width to the `width` argument of
`bw_recovery()`, so that the coverage reported by the design calibration refers to the intervals that the paper
reports.

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
the quantities that the argument depends on communicates more than a coefficient table, and takes less
space.

## Register

Write for the discipline that the paper is in. Terms that appear in the general methods literature of
your field are fine and should be used plainly: estimand, identification, specification,
marginal effect, counterfactual, partial pooling, posterior. Terms that belong to statistics or
machine learning and have a disciplinary equivalent should use the equivalent. Terms with no
equivalent should be defined once, on first use, and then used.

Do not explain what Bayesian inference is. Explain what this Bayesian analysis does that the
alternative would not, and anchor that to the methods literature: partial pooling where cells are
sparse, posterior uncertainty on quantities that maximum likelihood does not naturally provide,
a measurement model that the outcome actually requires.

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

If the analysis kept a `bayes-workflow-log.md` as `bayes-workflow-r` recommends, the appendix is largely written, because each entry records a model, a check, what the check showed and what changed. Start from the scaffold that `scripts/br_appendix.R` writes from the log: a framing paragraph, a stage-coverage table, one section per log entry in the order of the log, which is the order of the model sequence, and a closing section for the software. Fill the placeholders from the log and the saved output, giving each entry section the figure or table that its check produced and one sentence on what the check showed and what changed as a result. Leave a placeholder wherever neither the log nor the output holds the value, and list those placeholders in the reply.

After the framing paragraph and the stage-coverage table, the finished appendix has the model sequence first, as the sections that the scaffold writes for the log entries. The checks in full, the comparison detail and the calibration follow, as sections added before the software section, which stays last. `reference/appendix-and-log.md` describes each part. Keep the failures: a workflow appendix that contains only models that worked is not a workflow appendix, and reviewers can tell.

## Where the detail lives

| Reference file | Load it when |
|---|---|
| `reference/methods-templates.md` | Drafting a methods section: three complete worked templates – multilevel survey logistic, small-N repeated measures, overdispersed counts – each annotated sentence-by-stage |
| `reference/reviewer-responses.md` | Answering the standard objections: priors-drove-it, n-too-small, why-Bayesian-at-all, each with the evidence to generate, memo text and the manuscript change |
| `reference/appendix-and-log.md` | Keeping a convertible workflow log and assembling the supplementary appendix from it |
| `reference/results-register.md` | Writing the results section in the interpretive register of the workflow book's own case studies: how a diagnostic becomes a sentence, how a result is stated, how model progression is narrated, what the prose refuses to claim |
| `reference/results-templates.md` | Drafting a results section: three complete worked templates matching the methods templates, each annotated sentence-by-stage |
| `reference/prose-discipline.md` | What to avoid while writing any of it: the hedging direction, the marks of machine prose, the vocabulary that reads as machine text, and why |

Two bundled scripts. `scripts/br_appendix.R` converts a `bayes-workflow-log.md` into a
Quarto appendix skeleton with a stage-coverage table, derived from the log by the workflow
skill's `bw_scheme.R` where that skill is installed and left to fill by hand otherwise –
`Rscript "${CLAUDE_SKILL_DIR}/scripts/br_appendix.R" bayes-workflow-log.md appendix-workflow.qmd`.
`scripts/br_check_numbers.R` checks a finished draft against the output behind it –
`Rscript "${CLAUDE_SKILL_DIR}/scripts/br_check_numbers.R" writeup.qmd output/ bayes-workflow-log.md R/`.

`${CLAUDE_SKILL_DIR}` stands for the folder that holds this SKILL.md. Where it reaches a command unexpanded – in the reference files, and in any R call, since R does not expand it – replace it with the path of that folder before running the command.

## Writing the results section

A results section in this register opens with the quantity that the paper is about, on the substantive scale, with its uncertainty and before any diagnostic is mentioned: a predicted probability, a ratio of expected counts, a rate per day, never a coefficient on a link scale. What the checks of the final model showed comes next, namely the sensitivity of the reported quantity and the predictive checks of the final model, each read as what it could detect and, in the same sentence, what it could not, since a passed check is the absence of a visible problem rather than a confirmation. Where the design was calibrated, its result follows and grades how firmly each claim is made. The model sequence that produced the final model belongs to the methods, under the rule in "Article sections", and the results refer to it in words where a claim depends on it. What the analysis cannot settle has no fixed place in this order. Each limit is stated beside the claim that it qualifies, wherever that claim falls, rather than in a closing section where it can be skipped.

Where cross-validation cannot separate several models, the results give the estimate and interval under each model, or from a stacked posterior, which mixes the draws from each model in proportion to the stacking weight of that model (`loo::loo_model_weights()`). The spread of the point estimates across the models is then reported as sensitivity to the choice of model. The spread is reported beside the intervals and never instead of the intervals, because a range of point estimates leaves out the uncertainty within each model and can be far narrower than any one interval.

`reference/results-register.md` describes the register from the book's own case studies, with
the moves attributed. `reference/results-templates.md` gives three worked sections in it, one
per design. Both write for a sociology reader: a term that would appear undefined in
*Sociological Methods and Research* or the *European Sociological Review* is used plainly, and
a statistics-only term is defined once at first use. `reference/prose-discipline.md` is the
list of what to avoid while doing any of this, and `scripts/br_check_numbers.R` is run on the
result before it goes anywhere.

## Checking the draft against the output

Before a draft goes anywhere, every number in it should trace to a value in the analysis output, and every quantified claim should be held against the table it summarises, whether or not it carries a number. The second half of that is the one that gets skipped, and it is where the damage is.

The failure worth having in mind came out of testing these skills. A report recommended collecting
three predictors rather than four, and the recommendation rested on one sentence: beyond the first
three, "no other predictor reaches half the folds by size eight". The `cv_proportions` table
printed four lines above it gave one of the excluded predictors at five folds out of five and
another at four out of five. There is no number in the offending sentence to check, the table and
the sentence sit on the same page, and the draft reads as internally consistent throughout. A
reviewer would have to redo the comparison by hand to find it, and the analyst did not.

So the check has two passes:

1. **Numbers.** Each figure in the prose either appears in the saved output, at the precision the
   prose states, or it does not. One that does not is a typo, a value carried over from a
   superseded fit, or something that nobody computed.
2. **Quantified sentences.** Sentences containing "all", "none", "no other", "only", "the largest", "more than half" and their relatives assert something about a distribution or a table. Matching their digits does not test the assertion, because a sentence may carry none, and the digits of one that does can match the row labels of the very table that it misreads. Each has to be read next to the output behind it.

`scripts/br_check_numbers.R` does the first pass mechanically and lists the second for reading, with the numbers of each sentence marked as matched or not:

```r
source("${CLAUDE_SKILL_DIR}/scripts/br_check_numbers.R")
br_check_numbers("writeup.qmd", outputs = c("output/", "bayes-workflow-log.md", "R/"))
```

It does not check numbers in code, inline code, YAML, maths, HTML comments, Pandoc attribute blocks, citation keys, superscripts and the base of a power, subscripts, cross-references, model identifiers such as m3, stated seeds, or interval widths ("the 95% interval", "the 2.5th and 97.5th percentiles"). Nor does it check a structural reference, which is a number after a word such as table, figure, section, model, step or wave, singular or plural, with a letter or in a list, or after "p." or "pp.". Whole numbers from 1900 to 2100 are taken for years and listed rather than checked, and a year closing a parenthetical citation is dropped without being listed; a count in that range is checked when it is written with a thousands separator.

A number after above, below, at least, at most, exceed, exceeds, exceeded, exceeding, more than, less than, fewer than, larger than, greater than, smaller than, under or over is a bound. It is matched by an output value on its stated side and within one unit of its last significant digit, so "above 0.99" is matched by a value in (0.99, 1.00]. A negation before the word reverses the side, and an unmatched bound fails the check as an untraced number does. A bound is skipped as an input chosen in advance when R-hat, ESS, Pareto k, k-hat, `adapt_delta`, treedepth, divergences or the MCSE is named in its clause within the six words before it, or when draws, iterations, chains, warmup, samples, cores or threads follows within two words.

Matching tolerates rounding by the draft in one direction only. A draft number matches an output that rounds to it at the decimal places of the draft, or at its significant figures when it has at least two (the trailing zeros of a whole number do not count), so that 270 matches 274.7 while 20 and 40% are held to their decimal places. A draft more precise than the output never matches: a draft's 0.30 matches an output 0.2984, but a draft's 0.2984 does not match an output that only ever printed 0.30. The check reads "1,204" as 1204, ".984" as 0.984, and "percent", "per cent" and "percentage points" as the % sign; a percentage also matches the same value stored as a proportion, and a hyphen between two digits separates a range rather than signing a number.

The check is worth only as much as the output you saved. Where an analysis printed its results to
a console that is now gone, most of the draft comes back untraceable, and that finding is about
the analysis rather than about the draft. Capture the printing of each stage to a file as you
go – `sink()`, `capture.output()`, or a Quarto notebook rendered with `keep-md: true`, which
keeps a Markdown copy of its printed results – so that there is something for the draft to be
checked against later. The check reads text, CSV and JSON output, and not rendered HTML.

## A note on reproducibility statements

State the software versions, the seed, and where the code and data are deposited. Say which
results require the raw data and which can be reproduced from derived files. If some data cannot
be shared, say which, and why, and what a reader can verify without them.

---

Source for the workflow argument: Gelman, Vehtari, McElreath et al., *Bayesian Workflow* (CRC
Press, 2026), particularly chapter 10 on statistical against scientific inference. The reporting
conventions draw on Kruschke's work on threshold-free reporting and on the visualisation
literature. See `skills/bayes-workflow-r/reference/book-map.md` in this plugin.
