################################################################################
# Title:      Prior predictive check for the pest-trial count model
# Purpose:    Decide the priors by what they imply about observable pest counts
#             and about the treatment rate ratio, before the likelihood is used
# Output:     output/02_prior_check.txt, figures/fig_prior_predictive.png
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(SEED)
# Three candidate prior sets, all on the log-rate scale. The comparison is the
# point: "weakly informative" is a claim about implied outcomes, not about the
# number written next to normal().
# What the priors imply about the quantity actually reported: the ratio of expected
# counts under treatment to expected counts without it, averaged over the sample.
# --- figure ----------------------------------------------------------------
