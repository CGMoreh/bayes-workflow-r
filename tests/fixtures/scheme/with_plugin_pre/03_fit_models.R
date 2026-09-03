################################################################################
# Title:      The model sequence for the pest trial
# Purpose:    Fit the family and functional-form candidates, each motivated by a
#             feature of the outcome the previous rung cannot express
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(20260902)
# --- rung 1: the Poisson, kept only as the deliberate first step -------------
# --- rung 2: overdispersion admitted -----------------------------------------
# --- functional form of the baseline covariate -------------------------------
# --- the zeros: two different substantive claims about where they come from --
# --- does the effect vary? ----------------------------------------------------
# --- is trap_period really an exposure? --------------------------------------
# The offset asserts a coefficient of exactly 1 on log(trap_period). Freeing it
# turns that assertion into something the data can contradict.
