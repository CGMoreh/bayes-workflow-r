################################################################################
# Title:      Pest trial - shared analysis frame
# Purpose:    One definition of the modelling data, sourced by every later script
#             so that every fit uses identical rows and identical transformations
# Author:     analysis for BRIEF.md
# Last updated: 2026-09-02
################################################################################
# log(1 + baseline) because baseline is heavily right-skewed and the outcome model
# is multiplicative; standardised so that the slope prior is read in units of one
# standard deviation of pre-trial infestation. The centring constants are kept so
# that any covariate value can be put back on the original scale later.
# The formula every model in the sequence shares, apart from the family and the
# extra components tested against it.
