################################################################################
# Title:      Pest trial - the answer, as a quantity rather than a coefficient
# Purpose:    Compute the sample-average effect of treatment on the number of
#             pests caught over a standard trapping window, as a ratio and as a
#             difference, under every model in the sequence, and break it down by
#             pre-trial infestation
# Output:     output/07_estimand.txt, output/07_estimand_table.csv,
#             figures/fig_estimand.png, figures/fig_effect_by_baseline.png
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(SEED)
# The estimand: every apartment counterfactually treated against every apartment
# counterfactually untreated, both over the STANDARD trapping window, so that the
# answer is a number of pests rather than a number of pests per unknown window.
# ---------------------------------------------------------------------------
# Does the effect depend on how infested the apartment was to begin with?
# The contrast of contrasts is the quantity that answers this; two subgroup
# intervals, one excluding 1 and one not, do not.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# The two components of the effect, where the model separates them
# ---------------------------------------------------------------------------
# --- figures ---------------------------------------------------------------
