# The book's interpretive register

How the authors of the workflow book turn diagnostics and results into sentences in their case-study prose. Numbers are enumerated by case-study short name or taken from one reading's count; quotations are fragments of at most ten words, attributed in parentheses. The general marks of machine prose are in prose-discipline.md.

## The register in one paragraph

The prose is a working-notebook voice that reads printed output aloud, turns each diagnostic into a decision about what to do next, and leaves the numbers in the table beside the sentence. Verdicts on plots and tables are short, perceptual and unhedged, "looks fine" (World Cup); the hedges go on the explanation of why a diagnostic behaved as it did. A passed check is the absence of a visible problem, a failed check becomes in the same sentence the name of the next model, and a model comparison is a graded comparative with the table carrying the figures. The readings of thirteen case studies record no estimate of a substantive quantity written as a number in the prose (bioassay, cat adoptions, coronavirus, dogs, movies, multiple choice, park rule, planetary motion, roaches, sharks, sleep study, student grades, World Cup); movies and multiple choice write only raw-data descriptives, and the 0.94 of student grades and the 96 per cent of roaches compare models, not effects. The whole is framed as demonstration of a workflow, which licenses fitting a model known to be wrong; a Results section borrows the moves and leaves the frame.

## How a diagnostic becomes a sentence

**Convergence.** In eleven case studies the reading records no sentence that reads R-hat or ESS (bioassay, cat adoptions, coronavirus, declining exponentials, dogs, movies, multiple choice, nabiximols, sharks, student grades, World Cup); sleep study names them only as symptoms to expect from flat priors. Where verbalised, a pass is one clause with no number, "four simulated chains have mixed well" (golf), and a failure is an intensifier plus a hand-off to a plot, "Wow, these numbers are dramatic!" (planetary motion).

**Pareto k and p_loo.** Pareto k enters a sentence in five case studies (birthdays, LOO comparison, nabiximols, planetary motion, roaches), is repaired silently in code in sleep study and unmentioned in dogs and World Cup. A high value is a prompt to act, with the action in the same clause, "Now all Pareto-k's are ok" (roaches), or the reason for not acting is written out, as when nabiximols repairs only the winning model because "the estimate is usually optimistic" (nabiximols). Roaches reads p_loo against the parameter count, about 278 against four being misspecification.

**Predictive checks.** A pass is a short clause that names no criterion, "Looks quite good." (dogs); golf limits its pass to the present data, "there are no clear problems given the current data" (golf). A failure is located rather than scored: sleep study converts an interval plot into "There are clearly some outliers." (sleep study), and that sentence alone motivates the Student-t model.

**Sensitivity.** Power-scaling appears in five case studies (coronavirus, dogs, nabiximols, roaches, sleep study). Sleep study compresses five runs into "Even completely flat priors work ok" (sleep study), attributing insensitivity to parsimony relative to the data. Where the table is read at once, the sentence restates the two quantities as a verdict, "no prior sensitivity and the likelihood is informative" (roaches); dogs turns it into a decision to stop working on priors.

**LOO comparison.** Nine case studies run one (birthdays, dogs, golf, LOO comparison, nabiximols, roaches, sleep study, student grades, World Cup). Birthdays, dogs, nabiximols, sleep study and World Cup leave the elpd difference in the table and put a comparative in the sentence, "Thus we don't examine it further" (dogs). The standard error enters the prose in three ways that disagree: dogs and golf borrow the frequentist word, "but not significantly" (dogs); LOO comparison, roaches and student grades convert it into a probability of superiority, and the first two then withdraw it, LOO comparison by doubling the standard error and appending "Collecting more data is, however, recommended." (LOO comparison); World Cup attributes the whole difference to Monte Carlo variation. A LOO win is refused as evidence of adequacy, "that doesn't mean it is a good model" (nabiximols).

## How a result is stated

What is reported is a derived, substantively scaled quantity, in the disciplinary term a marginal effect or an average predicted outcome, rather than a coefficient. Golf restates parameters in the units of the golfer, "there is a standard deviation of" (golf), and converts a scale parameter into percentage points of success rate; nabiximols refuses the coefficient because the treatment enters through an interaction, "looking at the univariate posterior marginal is not sufficient" (nabiximols); roaches reads a ratio of expected counts off a dot plot.

Where a number is written, its precision is chosen visibly. Digits states the rule, posterior mean to two significant digits and interval to one decimal, justified by the interval width, and reports a probability as a rounded lower bound, "larger than 99%" (digits), because the third digit is not settled at this effective sample size.

A posterior probability of direction carries the effect in nabiximols (90 per cent for a new individual, 99 per cent for the expectation, the only numeric effect statements in that file), digits and birthdays. Elsewhere posterior mass is located in words, "clearly away from zero" (roaches), and precision is attributed to the data instead of reported, "Weekday effects are easy to estimate as" (birthdays).

## How model progression is narrated

Twelve case studies have a step prompted by a failure that a sentence names (birthdays, declining exponentials, dogs, golf, LOO comparison, nabiximols, park rule, planetary motion, roaches, SBC, sleep study, student grades), and the failures are specific: underdispersion (roaches); a missing intercept found by simulation-based calibration (SBC); "These parameters are not well identified alone." (park rule); an improper posterior (declining exponentials); implausible posterior spread, "super high, indicating a bad model" (birthdays). World Cup names only the omitted Jacobian; its other steps are headings. Six name no failure behind any step (bioassay, cat adoptions, coronavirus, movies, multiple choice, sharks): a heading states the remedy without the fault, "Add priors" (multiple choice), and where a reason appears (cat adoptions, coronavirus, sharks) it names a rationale or a caveat, not a fault. Digits fits one model; time series moves for reasons that are not failures. The join from diagnostic to claim is 'indicate', twelve tokens in roaches and eight in park rule; 'suggests' never appears in either, and planetary motion reserves 'suggest' for the one case where grid confirmation is unavailable.

A losing model is dropped in a fixed formula with its reason (dogs); set aside with a time marker, "we drop this model at the moment" (birthdays), and reinstated once the fault is localised elsewhere; or kept on stage on purpose: roaches runs the covariate comparison under the misspecified Poisson, "For demonstration, we show what would happen" (roaches), and World Cup shows the comparison without the Jacobian before the corrected one. Seven close without presenting the final model as unique (birthdays, dogs, LOO comparison, nabiximols, roaches, time series, World Cup); park rule calls the lme4 result adequate for most purposes, and student grades picks one of three similar priors for convenience.

## What the prose refuses to claim

Refusal counts per case study run from zero (movies, multiple choice) to 40 (birthdays); 20 of the 40 are one parenthetical marking each quick result as provisional. The rest are of five kinds.

Withdrawing a diagnostic just reported: roaches retracts p_worse in the paragraph that introduced it; golf offers "hinting that likelihood would be weakly informative on these" (golf) and corrects it by the bivariate plot; park rule states "There is no indication of funnel." (park rule) and overturns it because the wrong parameter was plotted.

Naming what a check cannot see: "the same ESS doesn't lead to the same MCSE" (digits); "LOO-PIT can't see discrepancy from the data" (roaches) with finite data.

Disclaiming substance: "no really practical use for the result" (birthdays); "Actually we'd want data from the Census." (coronavirus); "the data at hand do not identify the parameters" (declining exponentials).

Refusing to rank: "there is no clear preference for either model" (dogs); "we can't know which model has better predictive" (roaches) once thick tails corrupt the comparison columns; a tie explained by the outcome lying far from zero (sleep study).

The inverse refusal, declining to act on a warning with the reason in the same clause: "a warning which we can ignore" (nabiximols); "don't need to fix the LOO computation" (birthdays).

## Stance and lexis

The voice is the first person plural in 20 of the 21 case studies; movies has no first person at all. Single-authored notebooks write in the plural too (birthdays 139 tokens of 'we', SBC 117, roaches 76). 'I' is rare: 14 tokens in nabiximols marking individual decisions, two authorial in time series, one in SBC.

Hedges attach to the explanation of a diagnostic and to generalisation, and the verdict is flat. The roaches reading finds its 23 hedge tokens almost exclusively on why tails are thick or why Pareto k is high; park rule confines its four to causal explanations; LOO comparison puts its twelve on the calibration of the normal approximation rather than on the effects. Verdict sentences are short, "There are divergences." (SBC), "Nope, still no good" (time series).

Terms are glossed by consequence rather than definition: R-hat as chains having mixed (golf); 'improper' as a posterior from which no simulation can be drawn (declining exponentials); PIT in a short paragraph on why uniformity is the target (roaches). The qualifier is a 'but' inside the sentence, "is the best, but not much better than" (World Cup).

## Where an assistant goes wrong in this register

Hedging the verdict and asserting the mechanism. The corpus does the reverse: a calibration plot gets "Looks quite good." (dogs) and the reason for a null gets 'probably'.

Reading a pass as confirmation. A pass is the absence of a visible problem; the strongest positive statement is an improbability, "highly unlikely there is some big bug lurking" (SBC).

Using a threshold as a certificate. Thresholds are quoted, Pareto k above 0.7 (birthdays, LOO comparison), ESS above 400 (digits), p_loo against N/5 (roaches), and each triggers an action or a caveat.

Opening Results with a diagnostics checklist. Convergence goes unread in eleven case studies and is one sentence in LOO comparison and time series; where it is narrated at length (birthdays, golf, park rule, planetary motion, SBC), it changed a decision, "There is poor convergence" (golf) followed by "Now the convergence looks fine" (golf).

Withholding the number. Thirteen case studies write no substantive estimate in prose because the table sits beside the sentence; a paper reader has no printout. Keep the precision rule of digits and the probability-of-direction form of nabiximols, drop the bare comparative.

Borrowed 'significantly'. Dogs and golf use it for elpd differences; follow roaches and LOO comparison instead, through the withdrawal.

Sensitivity as a certificate. The corpus reads the power-scaling table as two quantities (roaches), conditions insensitivity on parsimony (sleep study), refuses to call prior-data conflict a defect (nabiximols), and moves the check to the estimand (nabiximols, roaches).

Staging. Exclamations and 'Wow' belong to the demonstration frame; take the plain headings and leave them.

Inventing the reasoning behind a step. Six case studies name no failure behind any step; the model for supplying one is the nabiximols chain from plot feature to distributional property to structural omission, never a generic phrase about improving fit.

## Translating it for a sociology readership

The test: a term that would appear undefined in *Sociological Methods and Research*, the *American Sociological Review* or the *European Sociological Review* is used plainly; a statistics-only term is defined once, by consequence, at first use and then used by name. These lists are a register judgement, not a corpus finding.

Used plainly: posterior, prior, credible interval, posterior predictive check, convergence, chains, R-hat and effective sample size, hierarchical or multilevel model, varying intercept and slope, partial pooling, shrinkage, cross-validation, overdispersion, identification, specification, covariate, treatment effect, sensitivity analysis, weakly informative prior, estimand, counterfactual, marginal effect and average marginal effect, predicted probability, expected count, probability that an effect is positive, Bayes factor. The percentage points of golf, the ratio of expected counts in roaches and the predictive-scale effect of nabiximols are marginal effects and should be named as such.

Defined once, with the gloss the corpus supplies:

- Monte Carlo standard error: the variation that would appear if the estimation were repeated (digits); it decides how many digits to report.
- Divergences, treedepth, funnel, centred and non-centred parameterisation: sampler geometry for an appendix; Results say only that the sampler had trouble and the model was reparameterised (park rule).
- elpd and LOO: out-of-sample predictive accuracy from leaving each observation out in turn; the difference between models is stated with its standard error (LOO comparison).
- Pareto k, p_loo, moment matching, reloo, K-fold: k checks the reliability of the leave-one-out approximation and p_loo flags a model too flexible for it (roaches); remedies belong in Methods.
- Calibration in the predictive sense, LOO-PIT, reliability diagram, rootogram: whether observed values fall where the predictive distributions of the model say they should (roaches); the verdict is intervals too narrow or too wide (sleep study, nabiximols).
- Power-scaling: whether the result moves when the prior is strengthened or weakened, and whether the data or the prior is doing the work (dogs, roaches).
- Simulation-based calibration: recovery of known parameters from simulated data, a check on the implementation (SBC).

Translate the moves rather than the words. The perceptual pass verdict becomes: state the check, say what a failure would have looked like, say that it did not appear, with the scope golf attaches. The withdrawal move becomes one sentence carrying the reason (LOO comparison, roaches). The refusal to rank becomes a statement that two models cannot be distinguished at this sample size and that the estimate is the same under both (LOO comparison). The provisional marker of birthdays has no place in a paper; what survives is the rule of nabiximols that the effect was examined "only after we trusted that there is no" (nabiximols) misfit.

## Provenance

Twenty-one companion case studies were read, one reading each. Short names map to book chapters or sections: bioassay (3.5), birthdays (27), cat adoptions (22), coronavirus (19), declining exponentials (12.4), digits (11.4 and 11.6), dogs (21), golf (25), LOO comparison (9.4), movies (16), multiple choice (4), nabiximols (18), park rule (29), planetary motion (30), roaches (24), SBC (31), sharks (26), sleep study (17), student grades (28), time series (20), World Cup (23). The prose-line tallies of the readings sum to 6,211 lines. Boundary kept: every quotation is at most ten words, in double quotes, attributed by short name and taken from the fragment fields of the readings; no two fragments are joined, no sentence that a reading flagged as distinctive is reused, and nothing else from the case studies is reproduced.
