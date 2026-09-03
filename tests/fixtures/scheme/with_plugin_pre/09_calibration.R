################################################################################
# Title:      Design calibration on the reported quantity
# Purpose:    Two questions the comparison cannot answer. Can 262 apartments,
#             with counts this dispersed, recover an average rate ratio of the
#             size estimated - and what does the obvious simpler model report when
#             the selected model is the truth?
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(20260902)
# One posterior draw generates one dataset, and the average rate ratio implied by
# that same draw is the truth for it. Truth and estimate are then on identical
# footing, which a fixed hand-chosen truth would not be.
