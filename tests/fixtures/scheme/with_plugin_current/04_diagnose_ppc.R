################################################################################
# Title:      Pest trial - computational diagnosis and posterior predictive checks
# Purpose:    Confirm the sampler can be believed, then put each model against the
#             features of the data it was not fitted to reproduce - the zeros, the
#             dispersion, the tail, and above all the mean count in each trial arm
# Output:     output/04_diagnose_ppc.txt, figures/fig_ppc_*.png
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(SEED)
# Test statistics the models were not fitted to match. Each has to be able to
# fail: the proportion of zeros, the spread, the largest count, and the mean in
# each arm, which is the summary the answer is a statement about.
      # posterior predictive p: the fraction of replicates at least as extreme.
      # Values near 0 or 1 mark a feature the model cannot reproduce.
# --- figures ---------------------------------------------------------------
# density overlay on the log scale, where the shape of the outcome is visible
