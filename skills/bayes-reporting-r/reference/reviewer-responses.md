# Answering the standard objections

Three objections account for most of what Bayesian analyses receive in review. Each section
gives the objection in the reviewer's words, the evidence to generate, the response-memo
text, and the manuscript change that goes with it – because a response that changes nothing
in the paper invites the same objection from the next reader.

The two Generate snippets below call scripts bundled with the sibling `bayes-workflow-r`
skill; the README's install commands place the two side by side, but a reporting-only install
needs that skill added (or the equivalent priorsense and simulation calls written inline).

The pattern throughout: produce evidence, then write one paragraph around the evidence.
Arguing that the priors were reasonable is assertion; showing the posterior does not move
when the priors are perturbed is measurement, and measurement ends the exchange.

---

## 1. "The priors are doing the work"

> With a sample this small, the priors are doing the work, and the reported effect is an
> artefact of the prior specification.

**Generate.** Power-scale the *reported quantity*, not the coefficient table – if the paper
claims an average marginal effect, that is what has to be shown insensitive. The route is a
predict function whose return IS the effect, one column, so the power-scaling applies to the
averaged contrast rather than to per-row predictions:

```r
source("${CLAUDE_SKILL_DIR}/../bayes-workflow-r/scripts/bw_sensitivity.R")

# draws x 1: the average marginal effect of the treatment itself
ame_fn <- function(object, newdata = NULL, ...) {
  d1 <- d0 <- object$data
  d1$treat <- 1
  d0$treat <- 0
  eff <- brms::posterior_epred(object, newdata = d1) -
         brms::posterior_epred(object, newdata = d0)
  matrix(rowMeans(eff), ncol = 1)
}

bw_sensitivity(fit, newdata = data.frame(placeholder = 1),
               predict_fn = ame_fn, quantity_names = "ame")
```

(`newdata` must be non-NULL to reach the derived-quantity branch; `ame_fn` ignores it. For
per-row predicted values instead, pass real rows and one name per row.)

If the diagnostic is clean, refit under one visibly different prior anyway – twice the
scale, or a different family on the variance components – and tabulate the reported
quantity under both. Reviewers trust a two-row table more than a diagnostic they have not
met, and the two together are stronger than either.

**Response memo.**

> We agree the concern is warranted at this sample size, and we have addressed it by
> measurement rather than assertion. Power-scaling sensitivity analysis (Kallioinen et al.
> 2024) perturbs the prior and the likelihood and measures the movement in the posterior of
> the reported quantity. The average marginal effect of [X] is insensitive to perturbation
> of the prior and sensitive to perturbation of the likelihood, which is the signature of
> an estimate driven by the data. Refitting under [alternative priors] moves the estimate
> from [a] to [b], within [fraction] of its posterior interval. Revised section [S] now
> reports both checks.

**Manuscript change.** The sensitivity sentence moves into the main text at the point the
estimate is first claimed; the two-prior table goes to the appendix with a pointer.

**When the objection is right.** If the diagnostic flags a strong prior and weak
likelihood, the reviewer has found something true, and the response is to reclassify the
finding, not to defend it: the parameter is undetermined, the text should say so, and the
memo should thank the reviewer and show the revised wording. Conceding a finding you
cannot support costs one result; defending it costs the paper.

## 2. "n is too small for this to mean anything"

> The authors draw conclusions from [N] cases. No analysis, Bayesian or otherwise, can
> support these claims at this sample size.

**Generate.** Design calibration at the real sample size and structure:

```r
source("${CLAUDE_SKILL_DIR}/../bayes-workflow-r/scripts/bw_recovery.R")
bw_recovery(fit, simulate_fn, truth = <literature effect>, parameter = "b_x", n_sims = 200)
```

Four numbers come out – recovery rate, interval coverage, sign-error rate, exaggeration
factor – and they replace the argument about whether the sample is "too small" with a
statement of what this design can and cannot do.

**Response memo.**

> Rather than argue in general terms, we simulated the design at exactly our sample size
> and structure, with a true effect of the size this literature reports, refitting [S]
> times. The design recovers the effect in [x]% of runs, interval coverage is [y]% at a
> nominal [width]%, the sign comes out wrong in [z]% of runs, and estimates that clear the
> threshold overstate the truth by [m] on average. We have added these figures to the
> methods and rewritten the discussion to claim direction more firmly than magnitude,
> which is what the calibration supports.

**Manuscript change.** The four numbers enter the methods; the discussion's strength of
claim is re-graded against them. If recovery is poor, the paper's contribution is
re-framed around what survives – often the interval itself, as a constraint future work
can build on, rather than the point estimate.

## 3. "Why is this Bayesian at all?"

> The authors provide no justification for the Bayesian approach. A standard logistic
> regression would give the same answer without the added machinery.

**Generate.** Nothing – this one is answered by argument, but the argument must name what
the estimation does that the alternative cannot, anchored to the specific analysis. The
legitimate warrants, from strongest to weakest:

- partial pooling where cells are sparse: the model produces stable estimates for
  [groups] with as few as [n] cases, where separate estimation returns noise;
- posterior uncertainty on derived quantities: the paper reports [variance shares /
  poststratified estimates / contrasts of contrasts], whose uncertainty maximum likelihood
  does not naturally provide;
- a measurement model the outcome requires: [ordinal / bounded-with-boundary-mass]
  outcomes fitted as they were generated;
- principled stabilisation at small N, with the priors shown (objection 1) not to drive
  the result.

**Response memo.**

> The choice is practical rather than philosophical. Our estimates of [quantity] require
> [warrant from the list], which [the frequentist alternative] does not provide without
> ad-hoc additions; the remaining machinery – prior checks, sensitivity analysis – is the
> cost of making that choice accountable, and section [S] now states this in one sentence
> rather than leaving the choice implicit.

**What not to write.** That Bayesian inference is "more intuitive", that p-values are
flawed, or that the posterior "quantifies uncertainty directly" – each invites a
philosophy debate the paper does not need and cannot win in a response memo. The warrant is
always what this analysis needed, never what inference in general ought to be.

---

## The memo's mechanics

One numbered item per objection, the reviewer's point restated fairly in one sentence, the
evidence, the change, the location of the change. Where a check was already in the paper
and the reviewer missed it, the fault is placement: move it toward the claim it defends and
say "we have made this more prominent" rather than "this was already in the appendix",
which is true, unhelpful, and remembered.
