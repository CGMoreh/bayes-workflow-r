# Where each step is treated in the book

This plugin follows the workflow set out in Gelman, Vehtari, McElreath and colleagues,
*Bayesian Workflow* (Chapman and Hall / CRC Press, 2026). The book is the source of the
argument; the R translations, prose and code in this plugin are original, and none of the
book's text, code or data is reproduced here.

The authors publish the case studies and their code freely at
<https://avehtari.github.io/Bayesian-Workflow/>. When a step below is easier to understand from
a worked example than from a description, follow the link and read theirs. Osvaldo Martin
maintains Python versions at <https://arviz-devs.github.io/bayesian-workflow/>.

## How to cite

```bibtex
@book{GelmanEtAl2026BayesianWorkflow,
  title     = {Bayesian Workflow},
  author    = {Andrew Gelman and Aki Vehtari and Richard McElreath and Daniel Simpson and
               Charles C. Margossian and Yuling Yao and Lauren Kennedy and Jonah Gabry and
               Paul-Christian B\"urkner and Martin Modr\'ak and Vianey Leos Barajas},
  year      = {2026},
  publisher = {Chapman and Hall/CRC}
}
```

Cite the book once, at the point where the methods section says the estimates are the product
of a workflow rather than of a single regression. Cite a chapter when referring to a specific
case study, in the form used by the authors: (Gelman et al., 2026, Ch 24 code).

---

## Step to chapter

| Workflow step in this plugin | Book | Worked example |
|---|---|---|
| The loop as a whole, and why it is a loop | Ch 2, Ch 4 | [Multiple choice exam](https://avehtari.github.io/Bayesian-Workflow/multiple_choice/multiple_choice.html) |
| Building the first model | Ch 5 | [Movie ratings](https://avehtari.github.io/Bayesian-Workflow/movies/movies.html) |
| Priors, and what they jointly imply | Ch 5, Ch 8.5 | [Sleep study](https://avehtari.github.io/Bayesian-Workflow/sleep_study/sleep_study.html), [Student grades](https://avehtari.github.io/Bayesian-Workflow/variable_selection/variable_selection.html) |
| Simulating to capture uncertainty | Ch 6 | [Movie ratings](https://avehtari.github.io/Bayesian-Workflow/movies/movies.html) |
| Estimands, generalisation, causal effects | Ch 7 | – |
| Displaying and checking the fit | Ch 8.1–8.3 | [Dogs (brms)](https://avehtari.github.io/Bayesian-Workflow/dogs/dogs.html) |
| Influence of individual observations | Ch 8.4 | [Roaches](https://avehtari.github.io/Bayesian-Workflow/roaches/roaches.html) |
| Prior and likelihood sensitivity | Ch 8.5 | [Sleep study](https://avehtari.github.io/Bayesian-Workflow/sleep_study/sleep_study.html), [Clinical trial](https://avehtari.github.io/Bayesian-Workflow/nabiximols/nabiximols.html) |
| Comparing and improving models | Ch 9 | [Model selection](https://avehtari.github.io/Bayesian-Workflow/loo_comparison/loo_comparison.html), [Roaches](https://avehtari.github.io/Bayesian-Workflow/roaches/roaches.html), [Golf putting](https://avehtari.github.io/Bayesian-Workflow/golf/golf.html) |
| Statistical inference against scientific inference | Ch 10 | – |
| Fitting | Ch 11 | [Iterations and digits](https://avehtari.github.io/Bayesian-Workflow/digits/digits.html) |
| Diagnosing and fixing fitting problems | Ch 12 | [Problematic posteriors](https://avehtari.github.io/Bayesian-Workflow/problems/problems.html), [Declining exponentials](https://avehtari.github.io/Bayesian-Workflow/declining_exponentials/declining_exponentials.html), [World Cup](https://avehtari.github.io/Bayesian-Workflow/world_cup/world_cup.html) |
| Approximate algorithms and approximate models | Ch 13 | – |
| Simulation-based calibration | Ch 14, Ch 31 | [SBC](https://avehtari.github.io/Bayesian-Workflow/sbc/sbc.html) |
| Modelling as software development | Ch 15 | [Black cat adoptions](https://avehtari.github.io/Bayesian-Workflow/cat_adoptions/cat_adoptions.html) |
| Decision analysis from a fitted model | Ch 7.3, Ch 20 | [Time series competition](https://avehtari.github.io/Bayesian-Workflow/timeseries/timeseries.html) |
| Hierarchical model building | Ch 19 | [Coronavirus testing](https://avehtari.github.io/Bayesian-Workflow/coronavirus/coronavirus.html) |
| Latent variables and sampling problems | Ch 26, Ch 29 | [Animal movement](https://avehtari.github.io/Bayesian-Workflow/sharks/sharks.html), [No vehicles in the park](https://avehtari.github.io/Bayesian-Workflow/park_rule/park_rule.html) |
| Multimodality | Ch 30 | [Planetary motion](https://avehtari.github.io/Bayesian-Workflow/planetary_motion/planetary_motion.html) |
| Time-series decomposition | Ch 27 | [Birthdays](https://avehtari.github.io/Bayesian-Workflow/birthdays/birthdays.html) |

The two case studies most useful to an applied social scientist starting out are the sleep
study, which is the clearest treatment of prior specification and sensitivity in a mixed model,
and roaches, which is the clearest treatment of what LOO comparison does and does not tell you.
The dogs case study exists in a brms version as well as a Stan one, which makes it the natural
entry point for readers of this plugin.

## Methods sources behind the tools

Cite these alongside the book where the specific method carries the argument.

| Tool | Source |
|---|---|
| brms | Bürkner (2017), *Journal of Statistical Software* |
| Stan | Carpenter et al. (2017), *Journal of Statistical Software* |
| PSIS-LOO, `loo` | Vehtari, Gelman and Gabry (2017), *Statistics and Computing* |
| Power-scaling, `priorsense` | Kallioinen, Paananen, Bürkner and Vehtari (2024), *Statistics and Computing* |
| Projection predictive selection, `projpred` | Piironen, Paasiniemi and Vehtari (2020) |
| R2D2 prior | Zhang et al. (2022); Aguilar and Bürkner (2023) |
| Bayesian R² | Gelman, Goodrich, Gabry and Vehtari (2019), *The American Statistician* |
| Visualisation in Bayesian workflow | Gabry, Simpson, Vehtari, Betancourt and Gelman (2019), *JRSS A* |
| Simulation-based calibration | Talts, Betancourt, Simpson, Vehtari and Gelman (2018); Modrák et al. (2023) |

## A note on scope

The book covers considerably more than this plugin does: approximate algorithms, decision
analysis, latent-variable and state-space models, and the treatment of modelling as software
development are all present in the book and only touched on here. Where a problem goes beyond
what these skills cover, the chapter reference above is the place to go, and the case study
usually has runnable code for it.
