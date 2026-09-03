################################################################################
# Title:      Pest trial - checks on the later models, and the quantities a
#             building manager would ask for
# Purpose:    The four models cross-validation cannot separate disagree about the
#             size of the effect, so put each of them against the arm means it
#             has to reproduce; then report the effect on the chance of catching
#             nothing and on a typical apartment, not only on the sample mean
# Output:     output/07b_checks_secondary.txt, figures/fig_ppc_arm_means.png
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(SEED)
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# The effect for one ordinary apartment, held at the median covariate profile,
# rather than averaged over a distribution the mean is not typical of.
# --- figure ----------------------------------------------------------------
