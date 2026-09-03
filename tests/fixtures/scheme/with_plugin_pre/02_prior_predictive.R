################################################################################
# Title:      Prior predictive simulation for the pest-trial count model
# Purpose:    Check what the priors imply about counts of pests and about the
#             treatment rate ratio, before the likelihood is allowed to speak
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(20260902)
# Read in outcome units. The intercept is the log expected count per standard
# window for an untreated apartment at the mean of log baseline in a mixed
# building; normal(2, 1.5) covers roughly 0.4 to 150 pests, which spans the
# whole observed range without asserting where in it the answer sits.
# The comparison priors exist so that the prior predictive table can show what
# tightening and loosening the slope scale actually buys.
# The estimand under a log link with no interaction is exp(b_treated), so the
# prior on the reported quantity can be read straight off the draws.
# What counts does the prior consider possible? Predict per standard window so
# the numbers are comparable with the observed distribution of caught.
