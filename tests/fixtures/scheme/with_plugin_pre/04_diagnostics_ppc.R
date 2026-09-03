################################################################################
# Title:      Computation diagnostics and posterior predictive checks
# Purpose:    Establish that the sampler ran cleanly, then test each model on the
#             features of the outcome it was not fitted to reproduce - dispersion,
#             the share of zeros, the upper tail, and fit across the covariates
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(20260902)
# The summaries a count model is not fitted to match, so each of them can fail.
# The Bayesian predictive p-value: the share of replicated datasets whose summary
# is at least as large as the observed one. Values near 0 or 1 are the failures;
# 0.5 means the model reproduces that feature.
# Grouped check: does the model reproduce the average count within cells it was
# never asked to match? Baseline quintile by arm is the grouping that matters,
# because the answer is a contrast within those cells.
# A count outcome needs the randomised probability integral transform: the
# non-randomised version is discrete and cannot be uniform even under a perfectly
# calibrated model, so it would fail the test by construction.
# --- figures ------------------------------------------------------------------
