################################################################################
# Title:      Design-based anchors, and a second overdispersion structure
# Purpose:    The count models disagree about the magnitude, so compare them with
#             a summary that assumes almost nothing - the observed comparison of
#             arms, resampled - and with a model whose overdispersion enters in a
#             different place, to find out which parts of the answer are the data
#             and which are the mean-variance assumption
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(20260902)
# The Bayesian bootstrap draws Dirichlet weights over apartments, so the only
# assumption is that the 262 apartments are exchangeable draws from whatever
# population they came from. No count model, no link function, no offset
# assumption beyond dividing by the trapping window.
    # exposure-weighted: total caught per unit trapping time, the incidence rate
    # apartment-weighted: the average apartment-level rate, which is the empirical
    # counterpart of averaging the model's fitted mean over apartments
# Overdispersion put somewhere else. The negative binomial ties the variance to
# mu + mu^2/shape; a Poisson with one varying intercept per apartment ties it to
# a lognormal spread around the rate instead. They are different claims about how
# the counts were generated, and if the answer is the same under both then the
# answer is not an artefact of either.
