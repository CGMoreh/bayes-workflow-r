################################################################################
# Title:      Pest trial - two models the earlier checks asked for
# Purpose:    m5 showed the treatment acting on the zero component as well as on
#             the rate, and m6 showed the rate effect varying with baseline
#             infestation. Neither model contains both, so fit the combinations
#             and score them on the same ten folds as everything else
# Output:     model-data/m9*.rds, model-data/m10*.rds, output/06_extra.txt
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(SEED)
# 9. Both mechanisms at once: treatment shifts the chance of a structural zero
#    and shifts the rate, and the rate shift depends on how infested the
#    apartment was to begin with.
# 10. The hurdle reading of the same structure. "Caught nothing at all" is its
#     own outcome with its own equation, and the count model describes only the
#     apartments that caught something.
# 12. The interaction in m6 changes the answer, so it has to be shown not to be an
#     artefact of forcing baseline in as a straight line on the log scale. A
#     separate smooth per arm lets the two dose-response curves take any shape,
#     and the interaction survives only if the curves genuinely diverge.
# 13. The offset asserts that catches accumulate in exact proportion to how long
#     the traps were out. That is an assumption about the design, and it is
#     testable: let log(trap_period) in as a free coefficient and see whether the
#     posterior puts it at 1.
