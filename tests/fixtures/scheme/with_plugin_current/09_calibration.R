################################################################################
# Title:      Pest trial - what this design can and cannot detect
# Purpose:    Simulate trials of the size actually run, with the covariate mix
#             actually observed, and ask how often an effect of a given size is
#             recovered. A check on the answer, not the answer itself
# Output:     output/09_calibration.txt
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(SEED)
# The design is resampled from the trial itself - the same skewed baseline
# distribution, the same uneven trapping windows, the same senior-only share -
# so that the recovery rate describes this design rather than a tidy one.
