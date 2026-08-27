# Comparing and expanding models

Two claims are routinely confused, and keeping them apart is most of the work. **Coefficient
evidence** says a parameter is probably not zero. **Predictive evidence** says one model
predicts new observations better than another. They answer different questions and they can
disagree, and a paper that reports one while implying the other is overclaiming.

---

## Before anything else: were the models fitted to the same observations?

Cross-validation compares predictions of the same held-out points. If two models were
fitted to different rows, their expected log predictive densities are sums over different
things and the comparison is meaningless.

It happens constantly in survey research. brms drops rows with missing values in any variable
the model uses, so a model including a predictor with item non-response is fitted to fewer rows
than a model omitting that predictor. On a real example – a national survey of 2700
respondents, comparing a vote model with education against one without – the first model used
2439 rows and the second 2448, because education carried eleven missing values.

**What the packages catch, and what they do not.** The guard is real but partial, and knowing
where it stops is the point.

| What you do | What happens |
|---|---|
| `brms::loo(m1, m2)` on models with different row counts | Errors: "Models have different number of observations." |
| `loo_compare(loo(m1), loo(m2))`, different row counts | Errors, naming the counts: "models have inconsistent observation counts: 'm1' (2439), 'm2' (2448)" |
| `loo_compare()` on models with the **same** count but different rows | **Runs.** Returns an ordinary-looking `elpd_diff` and `se_diff`. Emits only a warning, "Not all models have the same y variable. ('yhash' attributes do not match)" |
| Subtracting the pointwise vectors by hand | Recycles the shorter against the longer, with a warning rather than an error |

So the easy case is handled and the dangerous one is not. Two models can be fitted to the same
number of different observations whenever two predictors carry equal counts of missing values,
or whenever a filtering step differs between them, and the comparison then proceeds and returns
a number. On a constructed instance of exactly this, two models fitted to 2000 rows each,
overlapping but not identical, `loo_compare()` reported an `elpd_diff` of −16.8 with a standard
error of 20.0, and nothing stopped it.

The identity of the rows is what matters, not the count:

```r
# check identity, every time
identical(rownames(m1$data), rownames(m2$data))
c(nrow(m1$data), nrow(m2$data))

# the fix: fit every model on the same complete-case subset
d_cc <- tidyr::drop_na(d, outcome, age, income, education, sex, region)
m1 <- brm(outcome ~ age + income + education + sex + (1 | region), data = d_cc, ...)
m2 <- brm(outcome ~ age + income + sex + (1 | region),             data = d_cc, ...)
```

`scripts/bw_loo_report.R` compares row names rather than counts, so it refuses the case the
packages let through, and it names the rows that differ. Behind that sits a second layer for
the case row names cannot see: dplyr filtering resets a tibble's row names, so two separately
filtered samples of equal size carry identical names over different observations, and there
the script compares loo's hash of the response vector and refuses on a mismatch.

```markdown
| What you do                                                          | What happens                                                                                                                    |
|-----------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| `brms::loo(m1, m2)` on models with different row counts              | Errors: "Models have different number of observations."                                                                          |
| `loo_compare(loo(m1), loo(m2))`, different row counts                | Errors, naming the counts: "models have inconsistent observation counts: 'm1' (2439), 'm2' (2448)"                               |
| `loo_compare()` on models with the **same** count but different rows | **Runs.** Returns an ordinary-looking `elpd_diff` and `se_diff`. Emits only a warning about mismatched `yhash` attributes |
| Subtracting the pointwise vectors by hand                            | Recycles the shorter against the longer, with a warning rather than an error                                                     |

: What loo and brms detect when models are fitted to different observations. Verified against brms 2.23.0 and loo 2.9.0.
```

## Leave-one-out cross-validation

```r
library(loo)

m1 <- add_criterion(m1, "loo")
m2 <- add_criterion(m2, "loo")

loo_compare(m1, m2)
```

Read `elpd_diff` against `se_diff`. A difference smaller than about twice its standard error is
not evidence of anything; report the models as indistinguishable in predictive terms rather
than picking a winner. The comparison is also on a log scale with no natural units, so an
`elpd_diff` of 4 means little in isolation.

Check `loo(m1)$diagnostics$pareto_k`. Values above 0.7 mean the importance-sampling
approximation has failed for those observations, and the LOO estimate is unreliable until they
are dealt with:

```r
loo_moment_match(m1, loo = loo(m1))   # cheaper first resort
reloo(m1, loo = loo(m1), k_threshold = 0.7)   # actually refits, leaving out the bad points
```

## Which observations drive the comparison

An `elpd_diff` is a sum over observations, and sums hide their structure. A difference of 12
built from a uniform advantage across 400 cases means something quite different from the same
difference built from six cases where one model does badly. The second is much more common than
people expect, and it usually points at a handful of unusual observations rather than at a
general improvement.

Index the original data by the row names the model kept, never by position: after
NA-dropping, row *i* of the pointwise vector is not row *i* of the data frame.

```r
library(ggplot2)

rows <- rownames(m1$data)          # the observations the fit actually used

pw <- tibble::tibble(
  row  = rows,
  diff = loo(m1)$pointwise[, "elpd_loo"] - loo(m2)$pointwise[, "elpd_loo"],
  x    = d[rows, "key_predictor"],
  y    = d[rows, "outcome"]
)

# where does the advantage come from, and is it concentrated?
ggplot(pw, aes(x = x, y = diff, colour = factor(y))) +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  geom_point(alpha = 0.7) +
  labs(x = "Key predictor", y = "Pointwise elpd, model 1 minus model 2",
       colour = "Outcome")

# how concentrated is the disagreement?
net   <- sum(pw$diff)          # the elpd difference
gross <- sum(abs(pw$diff))     # total disagreement, ignoring direction
sum(sort(abs(pw$diff), decreasing = TRUE)[1:10]) / gross   # by magnitude, not by sign
```

**Measure concentration against the absolute disagreement, not the net.** Pointwise
differences carry both signs, so dividing the top ten by the net total can exceed 100% – it
does exactly that on the herd data below, returning 213%, which is the arithmetic telling you
the question was badly posed rather than a real result.

Two quantities are worth reading together. The net difference is the `elpd_diff`. The gross
difference, summing absolute values, is how much the models disagree case by case. Their ratio
says what kind of difference you have.

| Comparison | Cases | Net | Gross | Top 10 share of gross | Reading |
|---|---:|---:|---:|---:|---|
| Poisson against negative binomial, seizure counts | 236 | 55.1 | 120.5 | 43% | Directional and concentrated: a real difference, largely in a few high-count patients |
| Partial against complete pooling, herd infections | 56 | 7.1 | 30.6 | 55% | Mostly cancelling, and over half of what disagreement there is sits in ten herds |
| Vote model with against without education, survey | 2439 | 10.9 | 199.6 | 2% | A small, consistent, general improvement spread across the sample |

The third row is the one people misread. A net difference of 10.9 against a standard error of
5.0 looks decisive, but it is a thin residue of 199.6 points of case-by-case disagreement that
nearly cancels. That the improvement is spread evenly rather than concentrated is genuinely
good news about generality – and it is invisible in `elpd_diff` alone.

```markdown
| Comparison                                        | Cases |  Net | Gross | Top 10 share of gross | Reading                                                                   |
|---------------------------------------------------|------:|-----:|------:|----------------------:|---------------------------------------------------------------------------|
| Poisson against negative binomial, seizure counts |   236 | 55.1 | 120.5 |                   43% | Directional and concentrated: a real difference, largely in a few high-count patients |
| Partial against complete pooling, herd infections |    56 |  7.1 |  30.6 |                   55% | Mostly cancelling, and over half of what disagreement there is sits in ten herds |
| Vote model with against without education, survey |  2439 | 10.9 | 199.6 |                    2% | A small, consistent, general improvement spread across the sample         |

: Pointwise structure behind three LOO comparisons. Net is the elpd difference; gross sums absolute pointwise differences; the top-10 share selects the ten largest disagreements by magnitude.
```

If the answer to that last line is most of it, what the paper should say is that the models
differ chiefly in how they handle a small number of unusual cases, and the next question is what
is unusual about those cases.

## Clustered data needs a different cross-validation

Leaving out one observation from a participant who contributed twenty is a weak test: the other
nineteen carry most of the information about that participant, so the model predicts the held
out point easily and every model looks good. When the inferential question is about
participants, or schools, or countries, leave out the whole unit.

```r
folds <- loo::kfold_split_grouped(K = 10, x = d$participant_id)
kfold(m1, folds = folds)
```

This refits the model K times, so it is genuinely expensive where LOO is nearly free. Importance
sampling does not rescue it: leaving out a whole group changes the posterior too much for
reweighting to bridge, which is exactly why the refits are necessary.

Match the cross-validation scheme to the prediction task the paper claims. A model presented as
predicting outcomes for *new participants* must be validated by leaving participants out.

## Small samples

Below roughly a hundred observations the LOO standard errors are themselves poorly estimated,
and `se_diff` understates the uncertainty in the comparison. Treat model comparison at that size
as suggestive, say so, and lean on prior sensitivity and design calibration instead
(`reference/sensitivity.md`, `reference/calibration.md`).

## Expansion is judged on the estimand

Adding a flexible term can leave every coefficient looking reasonable while inflating the
uncertainty of the quantity you actually report, because the new coefficient is correlated with
that quantity in the posterior. Check it directly:

```r
library(tidybayes)
library(ggplot2)

m_expanded |>
  spread_draws(b_x_quadratic) |>
  bind_cols(estimand = estimand_draws) |>
  ggplot(aes(x = b_x_quadratic, y = estimand)) +
  geom_point(alpha = 0.1)
```

A strong relationship means the added term is where the uncertainty in your result now lives,
and it is a good argument for putting an informative prior on that term rather than leaving it
free.

## Many correlated predictors

When there are more candidate predictors than the data can separate, `projpred` projects the
full model onto smaller ones and reports how much predictive performance a reduced set retains.
Fit the full model well first, with a prior chosen by what it implies about explained variance
(see `reference/priors.md`): the projection inherits whatever the reference model got wrong.

### Run it in two passes, and cap the expensive one

`validate_search = TRUE` is the default and should stay that way for anything you report: it
repeats the whole forward search inside every fold, so a term found only because of this
particular sample shows up as a term the folds disagree about. It is also what makes the run
expensive - a validated search over 26 candidate predictors at n = 407 takes tens of minutes,
against about two for the unvalidated one.

So run it twice. The first pass is cheap and exists only to tell you where to cap the second.

```r
library(projpred)

# pass 1, cheap: the search runs ONCE on the full data and only the scoring is
# cross-validated, so the search itself can overfit and the submodel curve can
# climb ABOVE the reference model. Read this for the shape and for where the
# curve flattens. Never quote a performance figure from it.
vs_fast <- cv_varsel(m_full, method = "forward", validate_search = FALSE)
plot(vs_fast, stats = "elpd")

# pass 2, the run you report. nterms_max comes from pass 1 - searching to 26
# terms when the curve flattened by 8 spends most of the cost on sizes nobody
# will report. nloo subsamples the LOO folds used for the search; 50 is
# workable at a few hundred observations and is what the book's case study uses.
vs <- cv_varsel(m_full, method = "forward", validate_search = TRUE,
                nterms_max = 10, nloo = 50)
```

### Reading the result

```r
suggest_size(vs)                            # a starting point, not an answer
rk <- ranking(vs, nterms_max = suggest_size(vs))
rk[["fulldata"]]                            # the terms, in relevance order
cv_proportions(rk)                          # how often each entered, across folds
```

`ranking()` takes `nterms_max`, not `nterms`. R's partial argument matching means `nterms =`
silently works, which is worth knowing only so that seeing it in someone else's code does not
mislead you.

The relevance ordering is the stable part. The size rule and the stability table are not, and
both move with the cross-validation scheme. Here is the same reference model and the same
validated forward search on the book's student-grades case, scored three ways:

| Scheme | `suggest_size()` | Cumulative fold proportion by size 4 |
|---|---:|---|
| Subsampled LOO, `nloo = 50` | 4 | `failures` 1.0, `schoolsup` 1.0, `Medu` 1.0, `goout` 1.0 |
| 10-fold | 3 | `failures` 1.0, `schoolsup` 1.0, `Medu` 1.0, `goout` 0.5 |
| 5-fold | 8 | `failures` 1.0, `schoolsup` 1.0, `Medu` 0.8, `goout` 0.0 |

```markdown
| Scheme                      | `suggest_size()` | Cumulative fold proportion by size 4                        |
|-----------------------------|-----------------:|-------------------------------------------------------------|
| Subsampled LOO, `nloo = 50` |                4 | failures 1.0, schoolsup 1.0, Medu 1.0, goout 1.0             |
| 10-fold                     |                3 | failures 1.0, schoolsup 1.0, Medu 1.0, goout 0.5             |
| 5-fold                      |                8 | failures 1.0, schoolsup 1.0, Medu 0.8, goout 0.0             |

: One reference model, one validated forward search, three cross-validation schemes. The full-data relevance order is identical in all three; the size rule and the stability table are not.
```

Two things follow, and they pull in opposite directions.

**Few folds break the size rule.** Five folds gave 8 here and 17 on the same data analysed by a
different reference model. Fold-wise elpd differences get larger and noisier as folds get
coarser, and a stopping rule reading a noisier curve stops later. If `suggest_size()` returns
something implausibly large, suspect the fold count before blaming the rule.

**Leave-one-out flatters the stability table.** Each LOO fold's search sees 406 observations of
407, so it very nearly reproduces the full-data search, and proportions of 1.00 are closer to
structural than to evidential. The 1.00 on `goout` above becomes 0.5 at ten folds. Read a
column of 1.00s from a LOO run as "the ordering did not change", not as "this predictor would
survive a different sample".

So use subsampled LOO for the size, and look at a K-fold run before claiming a predictor is
found reliably. Where the two disagree - as they do on `goout` here - the reportable statement
is that three predictors are found in every fold under every scheme and the fourth is not, which
is more informative than either number alone.

### Do not price the selection by refitting the winner

The tempting last step is to refit the selected predictors as a model in their own right and
`loo_compare()` it against the full model, to show the reduced set loses nothing. That
comparison scores the subset on the data that chose it, so it flatters the subset, and the
amount by which it does is not something the output tells you.

Measured on the book's student-grades case, comparing its four selected predictors against all
26:

| How the four-predictor model is scored | elpd against all 26 | se |
|---|---:|---:|
| The cross-validated column from `cv_varsel` | −2.46 | 4.20 |
| Refitted and passed to `loo_compare()` | −1.55 | 4.41 |

```markdown
| How the four-predictor model is scored      | elpd against all 26 |   se |
|---------------------------------------------|--------------------:|-----:|
| The cross-validated column from `cv_varsel`  |               -2.46 | 4.20 |
| Refitted and passed to `loo_compare()`       |               -1.55 | 4.41 |

: What refitting a selected subset hides, on the book's student-grades case. Both figures are for the same four predictors against the same 26.
```

Here the refit flatters the four by 0.91 elpd - real, in the direction theory predicts, and small
enough that the conclusion survives it. Do not read that as a general licence. The size of the
gap depends on how many candidates the search ran through and how hard the selection had to
work, and nothing in the refit-and-compare output signals when it is large. The figure to quote
is the one from the cross-validated column, which has already paid for the search.

### What not to do with it

Use `projpred` to show that a minimal set carries the predictive content, as a robustness
argument. Do not select a model with it and then report that model's coefficients as though the
selection had not happened: the selection consumed information from the same data, and the
resulting intervals are too narrow. If you need coefficients for the reduced set, either use the
projected posterior that `project()` returns, or refit and say in the write-up that the
variables were chosen on these data.

---

Source: Gelman, Vehtari, McElreath et al., *Bayesian Workflow* (CRC Press, 2026), chapters 8 and
9, and the case studies on cross-validation comparison and on variable selection. The `loo`
package and the PSIS-LOO method are due to Vehtari, Gelman and Gabry. See `reference/book-map.md`.
