################################################################################
# Title:      Prior and likelihood sensitivity of the reported effect
# Purpose:    Show whether the treatment contrast is a product of the data or of
#             the prior, by power-scaling both and by refitting under deliberately
#             tighter, wider and default priors
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(20260902)
# The rate ratio is a ratio of two sums over apartments, so it has to be formed
# inside each draw. This returns a draws-by-quantity matrix, which is what
# priorsense's derived-quantity route consumes.
# resample = TRUE is not optional here: without it the object carries importance
# weights and the draws themselves are unchanged, so every alpha prints the same
# number and the check silently reports nothing.
