# bayes-workflow-r

Agent skills for doing Bayesian analysis in R following the workflow literature – specifically Gelman et al.'s (2026) *Bayesian Workflow* book (CRC Press) – and for efficient explicit reporting on the workflow in academic writing.

It is built for [Claude Code](https://claude.com/claude-code), but compatible with any agent that
implements the [Agent Skills specification](https://agentskills.io/specification).

## What this is for

Most Bayesian tooling stops at the fit. You get a model, some diagnostics, and a coefficient
table. The parts that decide whether the result is any good happen before and after that: what
the priors actually claim, whether the computation succeeded for reasons or by chance, which
observations a model comparison rests on, whether the design could have detected the effect at
all, and how any of it should be described in a methods section.

These skills cover that surrounding work, in R, with brms and Stan, for people who have to
publish the analysis rather than only run it.

## The three skills

| Skill | What it does |
|---|---|
| **bayes-workflow-r** | The loop. Priors and what they imply, prior predictive simulation, treating MCMC failure as a modelling problem, posterior predictive checks that name the next model, LOO comparison with pointwise attribution, power-scaling sensitivity, design calibration by simulation, and a workflow record (`WORKFLOW.md`) generated from the log and the files beside it, never edited by hand |
| **bayes-estimands-r** | The quantity the analysis is about. Stating the estimand before fitting, sample against population average effects, poststratifying posterior draws to a target population, causal contrasts by simulating counterfactual assignment, direct and indirect effects through a mediator |
| **bayes-reporting-r** | The write-up. The methods section stage by stage, wording for priors and sensitivity, reporting posteriors without significance thresholds, what belongs in the text against the supplement, building a workflow appendix from the analysis log, checking a finished draft's numbers against the output behind them |

Each works on its own. Install one, two or all three.

## A few things you will not find elsewhere

- **The prior on R², computed properly.** Independent `normal(0, 1)` priors on five standardised
  slopes imply a prior median R² of 0.90; on twenty slopes, 0.97. Halving the scale does not fix
  it. The skill shows the check, explains why `bayes_R2()` silently gives the wrong answer on a
  prior-only fit, and points at `brms::R2D2()` as the remedy.
- **Sensitivity of the estimand, not of the coefficients.** Where parameters are correlated in
  the posterior, marginal sensitivity is uninformative. The skill carries the reported quantity
  through `priorsense::predictions_as_draws()` and power-scales that instead.
- **Which observations drive a model comparison.** An `elpd_diff` is a sum, and sums hide their
  structure. The bundled script reports how concentrated the difference is and which cases carry
  it.
- **Population average effects in brms.** The workflow literature works these through in raw
  Stan `generated quantities`. The estimands skill gives the brms and `marginaleffects`
  equivalent, including poststratification to a target population whose composition differs from
  the sample.
- **Design calibration at the sample size you actually have**, reporting coverage and sign-error
  rate rather than only a recovery rate.
- **A check on the draft, not only on the analysis.** Every number in a write-up should trace
  to a value in the output behind it, and the sentences that quantify without giving a number –
  "no other predictor reaches half the folds" – are the ones that can contradict the table
  printed above them and still read as consistent. The reporting skill checks the first
  mechanically and lists the second for reading.

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
pak::pak(c("brms", "cmdstanr", "posterior", "loo", "priorsense", "projpred",
           "bayesplot", "tidybayes", "ggdist", "marginaleffects", "extraDistr"))
```

`SBC` is optional and needed only for simulation-based calibration. `extraDistr` is needed
only for the beta-binomial family, whose log-likelihood brms computes through it; without
it the fit succeeds and the first `loo()` halts.

## Relationship to the book

These skills follow the workflow set out in Gelman, Vehtari, McElreath and colleagues,
*Bayesian Workflow* (Chapman and Hall / CRC Press, 2026). The book is the source of the argument
and is cited throughout; `skills/bayes-workflow-r/reference/book-map.md` maps every stage to its
chapter and to the matching case study on the authors' companion site.

**Nothing from the book, its code or its data is reproduced here.** The book is copyright its
authors and its electronic edition is licensed for non-commercial use only; the companion
repository carries no licence. Every line of prose and R in this repository is original, written
against the ideas rather than copied from the source, and any errors in it are mine rather than
the book's. If you find these skills useful, buy the book – it is considerably better than a
summary of it could be, and it covers a great deal that these skills do not.

The authors publish their case studies at <https://avehtari.github.io/Bayesian-Workflow/>, and
Osvaldo Martin maintains Python versions at <https://arviz-devs.github.io/bayesian-workflow/>.

## Licence

MIT. See [LICENSE](LICENSE).

The MIT licence permits commercial use. I have no interest in restricting that, but I would ask
that anyone redistributing these skills keeps the attribution to the book intact, since the ideas
are the authors' even where the words are not.

## Citing

Cite the book, not this repository, for anything methodological:

> Gelman, A., Vehtari, A., McElreath, R., Simpson, D., Margossian, C. C., Yao, Y., Kennedy, L.,
> Gabry, J., Bürkner, P.-C., Modrák, M., and Leos Barajas, V. (2026). *Bayesian Workflow*.
> Chapman and Hall/CRC.

If you want to cite the tooling itself, see [CITATION.cff](CITATION.cff).

## Evaluation, and what it actually showed

Each skill ships an eval suite in `skills/<skill>/evals/` – output-quality cases with gradeable
assertions, and an activation set of prompts the skill should and should not fire on.
[evals/RESULTS.md](evals/RESULTS.md) records what two iterations measured, including what the
evaluation found against the skills; [evals/README.md](evals/README.md) explains how to run them.

The cases are not hypothetical. Each one reproduces a failure observed while running these
skills against real data during development: the prior-only R² that silently returns 0.5, the
two models compared across 2439 and 2448 different rows, the sensitivity table that printed
forty-five rows of group-level deviations, the concentration measure that reported 213%.

**The suite has been through two iterations, and the numbers below are the second.**
Iteration one ran 18 broad cases and found that 77 of its 87 assertions passed with and
without the skill – a strong unassisted model already handles most general Bayesian
judgement – leaving a delta of +0.11. Iteration two replaced the non-discriminating
assertions with checks aimed at the specific failures iteration one observed, retired the
cases a capable model handles unaided, and added cases for newly added content. Running each
of its 16 cases twice, once with the skill and once without, on the same strong model:

| Configuration | Pass rate |
|---|---:|
| With the skill | 0.99 |
| Without the skill | 0.69 |

Of 68 assertions, 20 passed only with the skill, one failed in both configurations (a
content gap the run exposed, fixed since), and the rest passed in both. Each cell is a
single run graded against author-written assertions, so read the delta rather than the
ceiling: a case-level bootstrap puts it at 0.30 with a 95% interval of [0.19, 0.41], and
twelve cases improved against none that regressed (one-sided sign test, p = 0.0002). A capable
model already refuses to report persistent divergences, already catches the missing-data
comparison trap, already gets the hurdle-against-zero-inflation mapping right, and already
writes a decent methods paragraph. What it does not reliably do is the specific mechanical
thing: in these runs the unassisted model recommended `bayes_R2()` on a prior-only fit as
the check, offered a smaller coefficient scale as the remedy, measured concentration against
the net rather than the absolute pointwise disagreement, power-scaled the coefficient table
when the paper reports an average marginal effect, and treated a stable coefficient table as
proof that a model expansion changed nothing.

So the claim these skills can defend is not that they supply knowledge the model lacks. It is that they
make a particular set of checks reliable, correct in their details, and actually run – and that
the reference material carries numbers someone measured rather than numbers someone assumed.

```markdown
| Configuration     | Pass rate |
|-------------------|----------:|
| With the skill    |      0.99 |
| Without the skill |      0.69 |

: Assertion pass rate across the 16 iteration-two eval cases, each run once with and once without the skill available. Iteration one (18 broader cases): 1.00 against 0.89.
```

### What that number does and does not cover

The eval cases are single targeted questions – someone asks whether a prior is weakly
informative, or how a sensitivity check should be reported, and acts on the reply. That is the
situation +0.30 describes, and it is the situation these skills are built for.

A second test put them somewhere else. Two agents were given the same dataset and the same open
question, one with the skills and one without, and worked for hours without supervision; eight
checks were fixed in advance, graded against a published case study rerun on the same machine.
Seven tied, and the eighth went to the unassisted agent. Repeating the exercise with a much
shorter brief produced five analyses of the same data, four of which recovered the published
answer, with no ordering by whether the skills were present. Given hours and an open question, a
capable model already runs most of this workflow unaided, and the wording of the brief moved the
result more than the skills did.

Both findings hold at once, because they describe different situations. Reference material that
is correct in its details changes a fast answer, where there is no time to re-derive anything,
and changes an unhurried analysis much less. What that blind test did produce, and what a fast
answer now benefits from, are two measurements that were not previously written down anywhere:
how much a selection refitted on its own chosen predictors flatters itself against a
cross-validated search, and how far `projpred::suggest_size()` moves when only the fold scheme
changes. Both are in `skills/bayes-workflow-r/reference/comparison.md`.

## Maintenance

These skills call packages that move. `tests/dependency-contracts.R` asserts every package
behaviour they depend on and names the file that depends on each, and a monthly GitHub
Actions run executes it against current CRAN, opening an issue when something breaks. Run it
yourself any time with `Rscript tests/dependency-contracts.R`.

Nothing here pins your library. The skills run inside your analysis project against whatever
you have installed, so [MAINTENANCE.md](MAINTENANCE.md) records the versions last tested
rather than required, lists what is most likely to break, and explains the guards that keep a
script useful when it does.

## Contributing

Issues and pull requests are welcome, particularly corrections. Every numerical claim in these
files was checked by running the code; if you find one that does not hold, please open an issue
with the reproduction and it will be fixed or removed.
