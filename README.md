# bayes-workflow-r

Agent skills for Bayesian analysis in R with brms and Stan, built around the record of the analysis and its write-up. While an agent works through an analysis, the skills have it keep a log of each model fitted, each check run and each decision taken, generate from that log a record of where the analysis stands, and write the finished analysis up as the methods and results sections of an article, with every number in the draft checked against the saved output behind it. The analysis itself follows the workflow guidelines put forward by Andrew Gelman, Aki Vehtari and colleagues and demonstrated in their book *Bayesian Workflow* (2026).

This is an independent project. It is not affiliated with the authors of *Bayesian Workflow* or with its publisher, and it has not been reviewed or endorsed by them.

The skills are built for [Claude Code](https://claude.com/claude-code) and work with any agent that implements the [Agent Skills specification](https://agentskills.io/specification).

## Purpose

A capable coding agent can already fit a Bayesian model and run most of the checks that the workflow literature asks for. What it does not reliably leave behind is a record that a co-author, a reviewer or the analyst returning to the work months later can follow: which models were fitted and why each was replaced, which checks were run and what they showed, and where each number in the paper came from. In the blind case studies used to test these skills, described under "Evaluation" below, agents reached the same conclusions with and without the skills. The difference lay in whether the write-up could be checked against the analysis behind it.

The skills are written for that gap. They have the agent:

- set the workflow up for the problem in hand, with the estimand stated before any model is fitted, the priors checked for what they imply about the outcome, and the design checked for what it can recover at the sample size available;
- keep a log of each pass round the loop of fitting, checking and revising, and regenerate from it a record of the analysis, `WORKFLOW.md`, which a script writes from the log and the files beside it, so that the record cannot claim a step that was not taken;
- write the finished analysis up as the methods and results sections of an article, in one file, in the interpretive register of the case studies published by the authors;
- check every number in the draft against the output behind it, and list for reading every sentence that quantifies, since a number that matches can still sit in a sentence that misreads its table.

The skills also carry the checks on which a capable model, answering a quick question, tends to go wrong in the details: the prior on R-squared, the sensitivity of the reported quantity to the prior, and the observations on which a model comparison rests. These checks are listed under "Features".

## The three skills

| Skill | What it does |
|---|---|
| **bayes-workflow-r** | The analysis and its record. Priors and what they imply, prior predictive simulation, MCMC failure treated as a modelling problem, posterior predictive checks that name the next model, LOO comparison with pointwise attribution, power-scaling sensitivity, design calibration by simulation, and a log of the analysis from which `bw_scheme.R` generates the workflow record, `WORKFLOW.md`, never edited by hand |
| **bayes-estimands-r** | The quantity the analysis is about. Stating the estimand before fitting, sample against population average effects, poststratifying posterior draws to a target population, causal contrasts by simulating counterfactual assignment, direct and indirect effects through a mediator |
| **bayes-reporting-r** | The write-up. The methods and results sections of an article in one file, wording for priors and sensitivity, reporting posteriors without significance thresholds, what belongs in the text against the supplement, a workflow appendix built from the analysis log, and a check of the numbers in a finished draft against the output behind them |

Each works on its own, so install one, two or all three. Where the workflow skill is installed beside the reporting skill, the workflow appendix takes its table of stages from the generated record; otherwise that table is left to be filled in by hand.

## Features

- **The workflow record.** `WORKFLOW.md` is written by `bw_scheme.R` from the log, from the banners of the analysis scripts and from the names of the files in `output/`, `figures/` and `model-data/`, and never by hand. It places each log entry and each file at a stage of the loop and quotes the log on what comes next rather than proposing it. It has no vocabulary for a stage left undone, so nothing in it invites running a check only to fill a gap.
- **The write-up as article sections.** Asked to write up a finished analysis, the reporting skill produces the methods and results sections of an article in one Quarto, R Markdown or Markdown file, organised as an article rather than by workflow stage, with the workflow appendix in a second file built from the log.
- **A check on the draft.** Every number in a write-up should trace to a value in the output behind it, and a sentence that quantifies – "no other predictor reaches half the folds" – can contradict the table printed above it and still read as consistent, whether or not it carries a number. The reporting skill checks the first mechanically and lists the second for reading.
- **The prior on R-squared, computed properly.** Independent `normal(0, 1)` priors on five standardised slopes imply a prior median R-squared of 0.90; on twenty slopes, 0.97. Halving the scale does not fix it. The skill shows the check, explains why `bayes_R2()` silently gives the wrong answer on a prior-only fit, and points at `brms::R2D2()` as the remedy.
- **Sensitivity of the estimand rather than of the coefficients.** Where parameters are correlated in the posterior, marginal sensitivity is uninformative. The skill carries the reported quantity through `priorsense::predictions_as_draws()` and power-scales that instead.
- **Which observations drive a model comparison.** An `elpd_diff` is a sum, and sums hide their structure. The bundled script reports how concentrated the difference is and which cases carry it.
- **Population average effects in brms.** The workflow literature works these through in raw Stan `generated quantities`. The estimands skill gives the brms and `marginaleffects` equivalent, including poststratification to a target population whose composition differs from the sample.
- **Design calibration at the sample size you actually have**, reporting coverage and sign-error rate rather than only a recovery rate.

## Install

### Claude Code, as a plugin

```
/plugin marketplace add CGMoreh/bayes-workflow-r
/plugin install bayes-workflow-r@bayes-workflow-r
```

### Any agent, by copying the skill folders

```bash
git clone https://github.com/CGMoreh/bayes-workflow-r.git
mkdir -p ~/.claude/skills
cp -r bayes-workflow-r/skills/bayes-workflow-r  ~/.claude/skills/
cp -r bayes-workflow-r/skills/bayes-estimands-r ~/.claude/skills/
cp -r bayes-workflow-r/skills/bayes-reporting-r ~/.claude/skills/
```

For other agents, copy the same folders into that agent's skills directory.

## Requirements

R, with a working Stan toolchain. `cmdstanr` is recommended over `rstan`.

```r
install.packages("pak")
pak::repo_add(stan = "https://stan-dev.r-universe.dev")   # cmdstanr is not on CRAN
pak::pak(c("brms", "cmdstanr", "posterior", "loo", "priorsense", "projpred",
           "bayesplot", "tidybayes", "ggdist", "marginaleffects", "digest",
           "extraDistr"))
```

`SBC` is optional and needed only for simulation-based calibration. brms lists `digest` and `extraDistr` as optional, but its `loo()` halts without them, while the fit itself succeeds. `digest` is needed for every model, because brms uses it to hash the outcome each time `loo()` runs; `extraDistr` is needed only for the beta-binomial family, whose log-likelihood brms computes through it. `digest` usually arrives as a dependency of other packages, so its absence tends to show only in a fresh library.

## What the plugin runs

The skills are Markdown instructions and reference files read by the agent, together with eight R scripts, which the agent runs on your machine when a step of the analysis calls for one. Nothing in the plugin opens a network connection: no script downloads, uploads or calls a web service, and the links in the reference files are for a reader to follow.

| Script | Reads | Writes |
|---|---|---|
| `bw_diagnose.R`, `bw_prior_check.R`, `bw_sensitivity.R`, `bw_loo_report.R`, `bw_recovery.R` | A fitted brms model, from the R session or from a saved `.rds` file | Nothing. Each prints a report and returns an R object |
| `bw_scheme.R` | `bayes-workflow-log.md`, the banners of the R scripts in the analysis directory, and the names, not the contents, of the files in `output/`, `figures/` and `model-data/` | `WORKFLOW.md` |
| `br_appendix.R` | `bayes-workflow-log.md`, and what `bw_scheme.R` reads where the workflow skill is installed beside it | A Quarto appendix skeleton, `appendix-workflow.qmd` unless named otherwise, which it refuses to overwrite; and a temporary copy of the record in the temporary folder of the R session |
| `br_check_numbers.R` | A draft manuscript, and the sources it is given: the text files (`.txt`, `.log`, `.out`, `.md`, `.csv`, `.tsv`, `.json`, `.R`) in an output folder, one level deep, and named files such as the workflow log and the analysis scripts | Nothing. It prints its report |

Three of the scripts refit the model, and so compile and run Stan through brms on your machine: `bw_prior_check.R` for the prior-only fit, `bw_recovery.R` for its simulated replications, and `bw_kfold_grouped()` in `bw_loo_report.R` for grouped cross-validation. These refits can take a while, but they stay local. Where a package is missing, the instructions have the agent install it with `pak::pak()`, which downloads from CRAN or from the repositories configured in your R session, as far as the permission settings of your agent allow.

The plugin sends none of your data anywhere. The agent reads your data in the course of the analysis, as it would without the plugin, and what it sends to its model provider is governed by the agent and its settings.

## Relationship to the workflow literature

The workflow applied here was put forward by Andrew Gelman, Aki Vehtari and colleagues, first in the paper "Bayesian Workflow" (Gelman et al. 2020, [arXiv:2011.01808](https://arxiv.org/abs/2011.01808)) and then in the book *Bayesian Workflow* (Gelman, Vehtari, McElreath and colleagues, Chapman and Hall / CRC Press, 2026), which demonstrates it through worked case studies. The skills follow the guidelines set out by the authors rather than the text of the book, so they extend the book in places and may depart from it as the methods and the R packages develop. Where the book treats a step, `skills/bayes-workflow-r/reference/book-map.md` gives the chapter and the matching case study on the companion site maintained by the authors.

**Nothing from the book, its code or its data is reproduced here.** The book is copyright its authors and its electronic edition is licensed for non-commercial use only; the companion repository carries no licence. Every line of prose and R in this repository is original, written against the ideas rather than copied from the source, and any errors in it are mine rather than the authors'. If you find these skills useful, buy the book – it is considerably better than a summary of it could be, and it covers a great deal that these skills do not.

The authors publish their case studies at <https://avehtari.github.io/Bayesian-Workflow/>, and Osvaldo Martin maintains Python versions at <https://arviz-devs.github.io/bayesian-workflow/>.

## Licence

MIT. See [LICENSE](LICENSE).

The MIT licence permits commercial use. I have no interest in restricting that, but I would ask that anyone redistributing these skills keeps the attribution to the authors intact, since the ideas are theirs even where the words are not.

## Citing

Cite the authors, not this repository, for anything methodological:

> Gelman, A., Vehtari, A., McElreath, R., Simpson, D., Margossian, C. C., Yao, Y., Kennedy, L., Gabry, J., Bürkner, P.-C., Modrák, M., and Leos Barajas, V. (2026). *Bayesian Workflow*. Chapman and Hall/CRC.

> Gelman, A., Vehtari, A., Simpson, D., Margossian, C. C., Carpenter, B., Yao, Y., Kennedy, L., Gabry, J., Bürkner, P.-C., and Modrák, M. (2020). Bayesian workflow. arXiv:2011.01808.

If you want to cite the tooling itself, see [CITATION.cff](CITATION.cff).

## Evaluation

Two kinds of test were run, and they answer different questions. Blind case studies gave agents a whole analysis to carry out, with and without the skills, and graded the results against checks fixed in advance. An eval suite asked single targeted questions and graded each answer against written assertions. Each skill ships its eval suite in `skills/<skill>/evals/`: output-quality cases with gradeable assertions, and an activation set of prompts on which the skill should and should not fire. [evals/RESULTS.md](evals/RESULTS.md) records what the suite measured, including what it found against the skills, and [evals/README.md](evals/README.md) explains how to run it.

### Whole analyses

Each case study reanalysed a case study published with the book, on the original data, by agents that worked for hours without supervision. In the first, a model of student grades, two agents were given the same dataset and the same open question, one with the skills and one without. Of eight checks fixed in advance, seven tied, and the eighth went to the unassisted agent. Repeating the exercise with a much shorter brief produced five analyses of the same data, four of which recovered the published answer, with no ordering by whether the skills were present. In the second, a pest-control trial with three arms, every arm reached seven of the eight checks and missed the same one, and the three answers agreed to within a fifth of a standard error. Given hours and an open question, a capable model already runs most of this workflow unaided, and the wording of the brief moved the result more than the skills did.

Where the arms did differ was on whether the write-up could be checked. In the pest-control trial, both arms with the skills traced every number in their reports to saved output, while the unassisted arm left two cross-validation differences that it had derived by subtraction and never printed. The check of the draft also caught a real error there: a first draft claimed "no evidence that the treatment works differently" by building type, and the subgroup table of the same arm contradicted it. In the third case study, a sleep-restriction study with four arms, every arm reached all eight analysis checks and landed on the published answer. The three arms with the skills traced every number, the unassisted arm left one untraced, and the arm with the workflow record produced a `WORKFLOW.md` in which every stage carrying an entry maps to a script that performed it, with no stage run in order to fill a node. In the fourth, a clinical trial with two arms, the arm with the write-up skills traced every number and the unassisted arm left three untraceable. On one analysis check the arm with the skills did marginally worse: it reported an expected value without contrasting it with the far wider prediction for a single person, which the unassisted arm did.

Across four case studies and eleven blind arms, the skills never measurably changed what a capable model concluded. What they changed was what can be checked afterwards, and the order in which a reader meets things. The blind tests also produced two measurements that had not been written down anywhere before: how much a selection refitted on its own chosen predictors flatters itself against a cross-validated search, and how far `projpred::suggest_size()` moves when only the fold scheme changes. Both are in `skills/bayes-workflow-r/reference/comparison.md`.

### Single questions

The eval cases are single targeted questions: someone asks whether a prior is weakly informative, or how a sensitivity check should be reported, and acts on the reply. Each case reproduces a failure observed while running these skills against real data during development: the prior-only R-squared that silently returns 0.5, the two models compared across 2439 and 2448 different rows, the sensitivity table that printed forty-five rows of group-level deviations, the concentration measure that reported 213%.

The suite has been through two iterations, and the numbers below are the second, measured on version 0.1.0 as released on 27 August 2026. Iteration one ran 18 broad cases and found that 77 of its 87 assertions passed with and without the skill, since a strong unassisted model already handles most general Bayesian judgement, which left a delta of +0.11. Iteration two replaced the assertions that did not discriminate with checks aimed at the specific failures observed in iteration one, retired the cases that a capable model handles unaided, and added cases for newly added content. Each of its 16 cases was run twice, once with the skill and once without, on the same strong model:

| Configuration | Pass rate |
|---|---:|
| With the skill | 0.99 |
| Without the skill | 0.69 |

```markdown
| Configuration     | Pass rate |
|-------------------|----------:|
| With the skill    |      0.99 |
| Without the skill |      0.69 |

: Assertion pass rate across the 16 iteration-two eval cases, each run once with and once without the skill available. Iteration one (18 broader cases): 1.00 against 0.89.
```

Of 68 assertions, 20 passed only with the skill, one failed in both configurations (a content gap exposed by the run, fixed since), and the rest passed in both. Each cell is a single run graded against assertions written by the author, so read the delta rather than the ceiling: a case-level bootstrap puts it at 0.30 with a 95% interval of [0.19, 0.41], and twelve cases improved against none that regressed (one-sided sign test, p = 0.0002). A capable model already refuses to report persistent divergences, already catches the missing-data comparison trap, already gets the hurdle-against-zero-inflation mapping right, and already writes a decent methods paragraph. What it does not reliably do is the specific mechanical thing. In these runs the unassisted model recommended `bayes_R2()` on a prior-only fit as the check, offered a smaller coefficient scale as the remedy, measured concentration against the net rather than the absolute pointwise disagreement, power-scaled the coefficient table when the paper reports an average marginal effect, and treated a stable coefficient table as proof that a model expansion changed nothing.

On a fast question, then, the skills make a particular set of checks reliable, correct in their details and actually run, and the reference material carries numbers that someone measured rather than assumed. On a whole analysis, where there is time to re-derive what a quick answer cannot, they change what a capable model concludes much less, and the record and the write-up are where they show.

## Maintenance

These skills call packages that move. `tests/dependency-contracts.R` asserts every package behaviour on which they depend and names the file that depends on each, and a monthly GitHub Actions run executes it against current CRAN, opening an issue when something breaks. Run it yourself any time with `Rscript tests/dependency-contracts.R`.

Nothing here pins your library. The skills run inside your analysis project against whatever you have installed, so [MAINTENANCE.md](MAINTENANCE.md) records the versions last tested rather than required, lists what is most likely to break, and explains the guards that keep a script useful when it does.

## Contributing

Issues and pull requests are welcome, particularly corrections. Every numerical claim in these files was checked by running the code; if you find one that does not hold, please open an issue with the reproduction and it will be fixed or removed.
