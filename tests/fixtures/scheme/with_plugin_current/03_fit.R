################################################################################
# Title:      Pest trial - the model sequence
# Purpose:    Fit the sequence of count models, each one motivated by what the
#             previous model failed to reproduce, and cache every fit
# Output:     model-data/*.rds, output/03_fit.txt
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
set.seed(SEED)
# The zero component. With no formula on it brms treats the mixing weight as a
# single probability, and beta(1, 1) declines to assert whether structural zeros
# are rare or common. Once the component gets predictors it moves to the logit
# scale, where normal(0, 1.5) on the intercept spans probabilities of roughly
# 0.05 to 0.95 and normal(0, 1) on a slope is a factor of about 2.7 in the odds.
# 1. The simplest defensible model. Counts over unequal windows, so an offset.
#    Fitted knowing the variance-to-mean ratio is 101, so that the failure is
#    measured rather than asserted.
# 2. Overdispersion given its own parameter.
# 3 and 4. Two different substantive claims about the 36% of apartments that
#    caught nothing. Zero inflation: some apartments could never register a catch,
#    the rest could and did not. Hurdle: catching anything at all is a separate
#    process from how much is caught once catching starts.
# 5. Does the treatment work by creating structural zeros, or by lowering the rate?
#    Letting the zero component depend on treatment turns that into an estimate.
# 6. Does the treatment do more in heavily infested apartments than in clean ones?
# 7. The design check. If assignment was random, dropping the covariates should
#    move the answer little. This model is the comparison, not a candidate.
# 8. Baseline as a smooth function rather than a fixed log-linear term, in case
#    the log transformation is doing something the data would not endorse.
