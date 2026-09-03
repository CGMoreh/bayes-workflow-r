################################################################################
# Title:      Pest trial - model comparison by cross-validation
# Purpose:    Compare the model sequence on out-of-sample predictive accuracy,
#             read elpd differences against their standard errors and against the
#             Pareto k that say whether the estimate can be trusted, and fall back
#             to K-fold on a shared split where importance sampling has failed
# Output:     output/05_compare.txt, model-data/kfold_*.rds
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(SEED)
