################################################################################
# Title:      Pest trial - is the answer the data's or the prior's?
# Purpose:    Power-scale prior and likelihood for the model parameters and, more
#             to the point, for the reported quantity itself; then refit under a
#             deliberately tighter and a deliberately wider prior and check that
#             the answer does not move
# Output:     output/08_sensitivity.txt, figures/fig_sensitivity.png
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(SEED)
# The number the report claims, as a one-column draws matrix, so that priorsense
# power-scales the answer rather than a coefficient that is not the answer.
  # the tight set that was examined before the data were used, in 02_prior_check
  # tighter than anything the prior predictive check endorsed, included to find
  # out how much shrinkage it takes to move the answer
# --- figure ----------------------------------------------------------------
