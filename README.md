# Ordinal GEE for Stata

`ordgee_pearson_dev` fits a population-averaged proportional-odds model to
repeated ordinal responses using generalized estimating equations (GEE).
It supports independence, fixed nonnegative exchangeable association, and
estimated exchangeable Pearson working correlation using two-stage
quasi-least squares (QLS) or a generalized-variance (GV) criterion.

This is a research development command. The initial computational baseline is
**version 0.2.0**, with **E8 help documentation** dated October 23, 2026.
The command requires **Stata 16.1 or newer** and runs entirely in Stata/Mata;
no R, Python, or external solver installation is required. Verification to date
used Stata/MP 16.1 on macOS. Later revisions are identified by Git commit.

## Install and begin

Download or clone this repository. Keep **all eight files in `ado/` together**,
including the three Mata implementation `.do` files. Add that folder to the
Stata search path for the current session:

```stata
adopath ++ "/your/path/GEE-Stata/ado"
which ordgee_pearson_dev
help ordgee_pearson_dev
help ordgee_pearson_dev_postestimation
```

Replace the path with your local folder. `which` identifies the copy Stata will
use if an earlier installation is also present. Start a fresh Stata session
when switching computational versions. This repository uses a local-folder
installation and does not provide `net install` metadata. Access to a private
repository requires permission.

## Commands and examples

| Task | Command or option | Documentation |
| --- | --- | --- |
| Fit the ordinal mean model | `ordgee_pearson_dev` | [code](ado/ordgee_pearson_dev.ado) · [help](ado/ordgee_pearson_dev.sthlp) |
| Independence | `corr(independent)` | Estimation help |
| Fixed exchangeable association | `corr(exchangeable) rho(#)` | Estimation help |
| Estimated exchangeable QLS | `corr(exchangeable) rhomethod(qls)` | Estimation help |
| Estimated exchangeable GV | `corr(exchangeable) rhomethod(gv)` | Estimation help |
| Category probabilities or linear predictor | `predict` | [postestimation help](ado/ordgee_pearson_dev_postestimation.sthlp) |
| Working-association diagnostics | `estat association` | Postestimation help |
| GV profile candidates | `estat candidates` after `solver(profile)` | Postestimation help |

For existing data with outcome `y`, covariate `x`, treatment indicator
`treatment`, subject identifier `id`, and observation time `visit`:

```stata
ordgee_pearson_dev y c.x i.treatment, ///
    id(id) time(visit) corr(exchangeable) rhomethod(qls)
estat association
```

QLS must be requested explicitly. The default for estimated exchangeable
association remains GV with the alternating solver. `solver(profile)` selects
the GV profile search; it is not a QLS option. There is no automatic switch of
methods after a failed fit.

The estimation help contains two complete do-file blocks. The first generates
its own unbalanced four-category data with no download. The second downloads
the public `schiz.dta` example from
[Stata Press](https://www.stata-press.com/data/mlmus4.html), or accepts a cached
copy as an argument. Copy a whole block into the Do-file Editor and run it.
Save current work first: these examples use `clear` and replace data and
estimation results. No separate example script is needed.

## Interpret results and check assumptions

The mean model is `Pr(Y <= k | X) = invlogit(c_k - X*b)`. Positive coefficients
indicate higher categories; `exp(b)` is the population-averaged cumulative odds
ratio for `Y > k` versus `Y <= k`, common across cutpoints under proportional odds.

The working correlation is separable across visits and cumulative indicators.
`e(rho)` describes same-cutpoint indicators at different visits, not the Pearson
correlation of raw category scores. For QLS, `e(qls_a0)` is the first-stage
association; the corrected `e(rho)` is used for the final coefficients and
ordinary cluster sandwich variance.

Convergence, positive definiteness, valid single-visit probabilities, and
compatibility of implied ordinal pair tables are separate checks. Run
`estat association` and inspect `min_cell` and `bad_pairs`. The default retains
an incompatible covariance as GEE working weights and reports the violations.
`strictpairs` rejects the selected final fit with `r(498)` and clears `e()`;
it neither clips rho nor searches for a replacement. Save a result before
trying this option if it is needed for subsequent comparison.

Inference requires an adequate marginal mean, independent clusters, enough
clusters for sandwich asymptotics, suitable covariate exogeneity, and an
appropriate observation process. The variance has no finite-cluster correction.
Robust standard errors do not repair mean misspecification or outcome-dependent
dropout. A pairwise compatibility check does not establish a full joint
distribution across three or more visits. The help explains the conditions in
detail.

The current implementation does not support negative association, observation
weights, informative-cluster-size weighting, a standard error for rho, or
`margins`. Independence-GEE coefficients can agree with `ologit` under the same
mean and sample, while standard errors differ because of variance conventions.

## Validation status

The local development record includes independent equation checks, simulation
studies, public-data comparisons, prediction and saved-result checks, and
isolated installation tests. The six executable files here are unchanged from
the validated 0.2.0 baseline. E8 reorganized the help and preserved its examples
and interpretation conditions; it did not change the estimator.

In the documented `schiz` example (437 patients; 1,603 observations), QLS gives
final rho approximately .237870 and 270 incompatible pair tables out of 2,234.
GV with `solver(profile)` gives rho approximately .123674 and no incompatible
pair tables. These are diagnostics for that specification, not evidence that
one method is universally superior. Numerical checks and finite simulation
studies do not establish validity for every research design.

## Versions and feedback

Computational versions are recorded in source headers; documentation revisions
are identified separately in the help. Use a Git commit to identify the exact
combination of files.

Report issues through [GitHub Issues](https://github.com/renegade68/GEE-Stata/issues).
Include the Git commit, Stata version, `which ordgee_pearson_dev` output, complete
command, association diagnostics, and a small reproducible example with expected
and actual results. Use synthetic data when research data are confidential.

## Attribution and license

Author: Choonjoo Lee. Contact: bloom.rampike@gmail.com.

The repository retains its existing
[GNU Affero General Public License version 3](LICENSE).
See [the software notice](LICENSE_CODE.txt). Preserve author and methodological
attribution. Core references in the help include Liang and Zeger (1986), Shults,
Ratcliffe and Leonard (2007), Mitani, Kaye and Nelson (2019), and Parsons and
colleagues (2009). This command uses unweighted clusters and does not implement
the informative-cluster-size weighting studied by Mitani and colleagues.

The repository contains the command, required implementation files, and help.
Development archives, reference software, papers, datasets, simulation output,
raw Stata logs, and local review ZIP files remain outside this code repository.
