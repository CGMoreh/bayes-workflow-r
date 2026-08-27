# Evaluating these skills

Each skill carries its own eval suite in `skills/<skill>/evals/`:

| File | What it is |
|---|---|
| `evals.json` | Output-quality test cases: a prompt, a description of success, and gradeable assertions |
| `trigger_eval_set.json` | Activation test cases: prompts the skill should and should not fire on |

Both follow the [Agent Skills eval format](https://agentskills.io/skill-creation/evaluating-skills).

## Running them with skill-creator

The `skill-creator` plugin automates the loop. From inside Claude Code:

```
/plugin marketplace add anthropics/claude-plugins-official
/plugin install skill-creator@claude-plugins-official
/reload-plugins
```

Then ask it to evaluate a skill by name, for example `evaluate my bayes-workflow-r skill with
skill-creator`. It runs each case twice, once with the skill available and once without,
grades the assertions with evidence, and aggregates a benchmark comparing pass rate, tokens
and duration between the two.

Results are written to a workspace directory beside the repository, one `iteration-N/` per
pass. That directory is not committed.

## Running them by hand

If you would rather not install the plugin, the pattern is the same and needs nothing but a
fresh session per run:

1. For each case in `evals.json`, start a clean session with the skill installed, paste the
   `prompt`, and save the response.
2. Repeat in a clean session with the skill disabled. `skillOverrides` in
   `.claude/settings.local.json` turns a skill off without deleting it.
3. Grade each assertion PASS or FAIL against the two responses, recording the evidence rather
   than an opinion. Quote the response.
4. Compare. An assertion that passes in both configurations is telling you the model does this
   unaided, and the assertion should be replaced.

The context has to be clean. Grading a response produced in the session where the skill was
written measures your memory of the skill, not the skill.

## Aggregating a run

`aggregate_evals.R` in this directory turns a completed iteration into a benchmark, whichever
route produced it:

```bash
Rscript evals/aggregate_evals.R <workspace>/iteration-1
```

It reads every `grading.json` and `timing.json` under the iteration, writes `benchmark.json`
beside them, and prints the comparison: pass rate per configuration, the delta with a
case-level bootstrap interval and a one-sided sign test, and the three-way assertion split.

That split is the output that matters, and it is worth more than the pass rate. Assertions
passing in BOTH configurations are measuring the model rather than the skill and should be
replaced. Assertions failing in both are either broken or a real gap in the skill – this
repository has had one of each. Assertions only the skill passes are the whole of its
measured value, and if that list is short, the honest response is to say so rather than to
report the ceiling.

The script needs `jsonlite`, `purrr` and `dplyr`, all of which arrive with the plugin's
existing requirements; there is no dependency here beyond what running the skills already
needs, and nothing in this repository requires anything outside R.

## What these cases are for

Every case in `evals.json` comes from a failure observed while running the skills against real
data, not from imagination. The prior R-squared case exists because `bayes_R2()` silently
returns roughly 0.5 on a prior-only fit. The model-comparison case exists because two brms
models fitted to the same data frame used 2439 and 2448 rows once item non-response was
accounted for - a case loo now refuses on the count, while the same mismatch with equal
counts, or a hand subtraction of the pointwise vectors, still goes through. The design-calibration case exists because an
interval excluding zero at n = 40 says less than it appears to.

That provenance matters for maintenance. If a case starts passing without the skill, the
underlying trap has probably been fixed upstream, and the case should be retired rather than
kept for the pass rate.

## The activation problem

There are now several Bayesian skills in circulation for coding agents, at least one of them
for Python and PyMC rather than R and brms. The `should_trigger: false` half of each trigger
set is deliberately adversarial about this: it includes PyMC divergences, frequentist mixed
models, `lmer`, JAGS, propensity-score matching, and prompts that belong to a *different one of
these three skills*. A skill that fires on all of them is not selective enough to live
alongside others, whatever its pass rate on output quality.

The three-way discrimination is the harder half. Fitting and diagnosing goes to
`bayes-workflow-r`, defining and computing the reported quantity goes to `bayes-estimands-r`,
and writing it up goes to `bayes-reporting-r`. Prompts sitting on those boundaries appear in
all three sets, with opposite labels.
