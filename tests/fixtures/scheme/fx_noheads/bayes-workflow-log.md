# Notes on the survey model

Started with a logistic regression of vote choice on education and age, normal(0, 1) on the
slopes. The prior predictive put 95% of turnout between 3% and 97%, which is fine.

Fitted m1 with 4 chains; three divergences, all in the varying-intercept sd. The PPC on
region-level rates fails badly for the north. Next: a varying slope for education by region.
