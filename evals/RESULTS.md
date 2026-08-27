# Evaluation results

Two iterations, each running every case twice in a fresh agent context – once with the skill
directory readable, once deliberately unassisted – and grading the responses against written
assertions. This file is the record the README's numbers refer to.

The short version: against a strong unassisted model, these skills buy a measured +0.30 in
assertion pass rate, and that gain sits almost entirely in specific mechanical checks rather
than in general Bayesian judgement.

---

## The numbers

| | Iteration 1 | Iteration 2 |
|---|---|---|
| Cases | 18 | 16 |
| Assertions | 87 | 68 |
| Pass rate, with the skill | 1.00 | 0.99 |
| Pass rate, unassisted | 0.89 | 0.69 |
| Delta | +0.115 | +0.297 |
| Bootstrap 95% interval | [0.04, 0.19] | [0.19, 0.41] |
| Cases improved / regressed | 7 / 0 | 12 / 0 |
| One-sided sign test | p = 0.008 | p = 0.0002 |
| Assertions passing in both | 77 | 47 |
| Assertions the skill alone passes | 10 | 20 |
| Assertions failing in both | 0 | 1 |

```markdown
|                                    | Iteration 1  | Iteration 2   |
|------------------------------------|--------------|---------------|
| Cases                              | 18           | 16            |
| Assertions                         | 87           | 68            |
| Pass rate, with the skill          | 1.00         | 0.99          |
| Pass rate, unassisted              | 0.89         | 0.69          |
| Delta                              | +0.115       | +0.297        |
| Bootstrap 95% interval             | [0.04, 0.19] | [0.19, 0.41]  |
| Cases improved / regressed         | 7 / 0        | 12 / 0        |
| One-sided sign test                | p = 0.008    | p = 0.0002    |
| Assertions passing in both         | 77           | 47            |
| Assertions the skill alone passes  | 10           | 20            |
| Assertions failing in both         | 0            | 1             |

: Eval results across two iterations. Reproduce with Rscript evals/aggregate_evals.R <iteration-directory>.
```

Reproduce either row with `Rscript evals/aggregate_evals.R <iteration-directory>`, which
recomputes the pass rates, the bootstrap and the sign test from the grading files.

## Why the delta tripled, and why that is not the skill improving

Iteration 1 asked broad questions and found that 77 of its 87 assertions passed with and
without the skill. That is a finding about the unassisted model, not a flaw in it: a capable
model already refuses to report persistent divergences, already names funnel geometry, already
catches the missing-data comparison trap in its opening sentence, and already writes a
creditable methods paragraph.

Iteration 2 therefore replaced those assertions with checks aimed at the failures iteration 1
had actually observed, retired the cases the model handled unaided, and added cases for content
added since. The delta rose because the instrument changed, not because the skills got three
times better. Both figures are accurate; the second is the more informative one, because it
measures what the skills are for.

## Where the value sits

The twenty assertions that only the skill passed in iteration 2 cluster tightly. In these runs
the unassisted model:

- recommended `bayes_R2()` on a prior-only fit as the check on implied priors, in one case
  attaching a decision threshold to a statistic that returns roughly 0.5 whatever the priors
  say; and, where it did reach a workable remedy, reached it without saying why choosing a
  coefficient scale by eye is not one, which is the mistake a reader is most likely to repeat
  unaided;
- measured how concentrated a model comparison is against the net difference rather than the
  total absolute pointwise disagreement, a ratio that is unbounded and returned 213% on real
  data during development;
- power-scaled the coefficient table when the paper reports an average marginal effect, on a
  model whose coefficients are correlated and individually uninterpretable;
- cited the Type M and Type S literature for a small-sample claim without describing any
  computation that would produce a recovery or exaggeration figure;
- read a stable coefficient table as evidence that a model expansion had changed nothing,
  rather than checking the estimand's uncertainty;
- rested a reply to "why Bayesian at all" on the philosophy of confidence intervals, which is
  the argument least likely to end that exchange.

None of this is ignorance. Asked directly whether `bayes_R2()` works on a prior-only fit, the
same unassisted model diagnosed the problem completely and traced it through the package
source. The skill's contribution is retrieval and reliability: making the check happen, and
making its details right, when the question that prompts it is a general one.

## What the evaluation found against the skills

Two findings ran the other way, and both were fixed.

Iteration 1 graded a case whose with-skill run scored full marks while exposing a false
positive in `bw_prior_check.R`: the script warned whenever the implied prior R² exceeded 0.7,
but on a repeated-measures design the posterior conditional R² is itself near 0.8, so the
warning fired on a defensible prior. The script now judges the upper tail against a ceiling and
gives multilevel models their own message.

Iteration 2 produced the single assertion that failed in *both* configurations: neither run
constructed a poststratification frame from census counts, because `poststratification.md`
itself began from a ready-made table. The recipe now builds the frame and states the
joint-counts-against-margins constraint as part of the method.

## A corrected assertion, and the case re-run

Validating the skills against the book's own case studies turned up an error in this suite.
One assertion required a response to say that reducing the coefficient scale "does not solve
the problem", and had accordingly marked an unassisted run wrong for proposing a slope prior
scaled as `sqrt(0.3/k)*sd(y)`. That is the book's own second option in its variable-selection
chapter, and measured on the skill's own example it works: the implied prior median moves to
the target and stays there as predictors are added. `reference/priors.md` carried the same
over-claim, having been written from a test that only halved the scale arbitrarily.

Both were corrected. The reference file now separates three things that the earlier wording ran
together – rescaling by eye, which barely moves the implied prior; scaling to a target, which
controls its centre but not its upper tail; and putting the prior on R^2^ directly, which
controls the whole distribution. The assertion now asks for that distinction rather than for
the over-claim.

The case was then re-run. Because the with-skill response had been produced from the superseded
reference file, that arm was resampled against the corrected one; the unassisted response does
not depend on the skill, so it was re-graded rather than re-sampled, which keeps the assertion
change from being confounded with run-to-run variation. Both were graded blind, by a grader
given the two responses as A and B with no access to the skills or to any record of how either
was produced.

The marks did not move: 4 of 4 with the skill, 1 of 4 without, and the suite's aggregate is
unchanged at +0.297 with a bootstrap interval of [0.19, 0.41]. What moved is what the mark
measures. The assertion now discriminates on defensible grounds – the unassisted response
reached a workable scaling but never conveyed that hand-picking a scale is not one – rather
than rewarding the skill for reciting something that was not true. The re-run lives in the
development workspace rather than here, since the published record is the corrected suite
itself.

## Activation

Separately from output quality, two rounds tested whether the three descriptions route a query
to the right skill and, more importantly, refuse queries belonging to other tools.

| Round | Prompts | Correct |
|---|---:|---|
| 1 | 53 | 52 (98%) |
| 2 | 59 | 59 (100%) |

```markdown
| Round | Prompts | Correct   |
|-------|--------:|-----------|
| 1     |      53 | 52 (98%)  |
| 2     |      59 | 59 (100%) |

: Activation accuracy, judged from the skill descriptions alone.
```

Round 1's single error was a false positive: the estimands description offered bare "weighting"
as a hook and fired on a design-based `survey` package query with no posterior in it. That
clause now requires posterior estimates and a target population. No prompt naming a competing
framework – PyMC, BayesFlow, `lmer`, JAGS, MatchIt, DoWhy, tidymodels – has ever attracted any
of the three skills; the exclusion is carried by the opening "in R with brms and Stan" in each
description, which is the phrase to preserve in any rewrite.

## How to read these numbers, and how not to

Each cell is a **single run**. There is no within-case variance estimate, which is why the
bootstrap resamples cases rather than runs and why the interval is the quantity to cite rather
than the pass rate.

The **assertions were written by the skills' author** after seeing what the skills do. That
biases the suite toward the skills, and the control for it is the "passes in both"
column: an assertion the unassisted model also satisfies is not measuring the skill, and 47 of
68 fell into that category even after the rewrite.

**Grading was done by the same model family** that produced the responses, by separate agents
instructed to require quoted evidence and to favour neither configuration.

The **1.00 and 0.99 are ceilings**, not precision. They mean the suite is not hard enough to
separate good from excellent with the skill in hand, which is a limitation of the instrument.

**Baselines shared the machine's ambient configuration** but were instructed not to read any
skill file, which is the closest available approximation to an unassisted run.

## The full record

Response transcripts, per-assertion grading files with quoted evidence, timings, the
per-iteration `benchmark.json`, and analyst notes on both trigger rounds live in a workspace
directory beside this repository. They are not committed: 68 full transcripts serve no user of
the plugin, and the aggregator regenerates every number above from the grading files. If you
want to audit a specific claim, the case identifiers here map directly onto the directories
there.
