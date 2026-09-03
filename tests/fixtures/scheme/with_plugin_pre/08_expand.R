################################################################################
# Title:      Resolving the disagreement between the hurdle and the interaction
# Purpose:    m6 (a hurdle with the treatment acting on the zeros) and m8 (a plain
#             negative binomial where the treatment effect shrinks as the baseline
#             count rises) may be two descriptions of one feature of the data, and
#             they imply different answers. Fit the models that contain both, and
#             make the leave-one-out comparison reliable by moment matching
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(20260902)
