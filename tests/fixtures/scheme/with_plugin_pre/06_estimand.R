################################################################################
# Title:      The estimand: the treatment contrast on the count scale
# Purpose:    Turn the fitted model into the two numbers the brief asks for - the
#             proportional and the absolute change in pests caught - averaged over
#             the 262 apartments as observed, with the averaging done inside draws
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(20260902)
# Every apartment is put on the standard trapping window, so the contrast is in
# pests per standard window rather than in a mixture of window lengths. Without
# this the absolute difference would be an average over exposure times as well as
# over apartments, which is not a quantity anyone can act on.
# --- figure: the posterior of the reported quantity ---------------------------
