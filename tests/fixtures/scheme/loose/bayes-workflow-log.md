# Notes on the sleep study

## first look at the data
Plotted reaction time by day. Strong upward trend, some subjects flat.

## m1 - random intercepts only [fit, ppc]
Fitted with default priors because I was in a hurry. pp_check looks fine on the mean but
the spread by subject is wrong.
Next: add varying slopes for Days.

## 2026-09-03: m2 and m3, varying slopes
m2 varying slopes, m3 also correlates them. 3 divergences in m3. LOO prefers m3 by 4.1 (se 2.8).
Output: `output/03_compare.txt`, `figures/ppc_m3.png`.

## thoughts
Not sure the Gaussian is right; residuals heavy-tailed.
