# Ordinal GEE for Stata

`ordgee_pearson_dev` fits a population-averaged proportional-odds model for
repeated ordinal outcomes. It estimates nonnegative exchangeable Pearson
working correlation using two-stage quasi-least squares (QLS) or a
generalized-variance (GV) method. Independence and fixed correlation are also
available.

Requires **Stata 16.1 or newer**. No R, Python, or external solver is needed.
This is research software, version **0.2.0**, tested in Stata/MP 16.1 on macOS.
Check the model assumptions and diagnostics before interpreting results.

## Install

Use GitHub's **Code → Download ZIP**, extract it, and keep all eight files in
`ado/` together, including the three `.do` files. In Stata, replace the path below:

```stata
adopath ++ "/your/path/GEE-Stata/ado"
which ordgee_pearson_dev
help ordgee_pearson_dev
```

The path setting applies to this session; include it in your analysis do-file
for future sessions. After downloading an update, replace the whole `ado/`
folder and restart Stata. `which` helps identify an older copy taking precedence.
Installation uses this local folder; `ssc install` and `net install` are not
provided for this repository.

## Prepare your data

Use **one row per subject and visit**. The outcome must have at least three
observed numeric categories, in the intended ascending order. Labels do not
determine that order. IDs can be numeric or string; time must be numeric, with
unique ID-time pairs. Unequal visit counts and irregular times are allowed.
You do not need to `xtset` the data.

`time(visit)` identifies visits; it does not add a time effect to the mean model.
Include `c.visit`, time indicators, or other justified time terms among the
covariates if needed. Exchangeable association does not decay with time gaps.
Rows missing required variables are excluded; inspect `e(N_excluded)` after
fitting. This does not correct outcome-dependent missingness.

## Run a complete example

The following creates its own four-category data. Save current work first:
the block clears the data and changes the random seed and estimation results.

```stata
clear
set seed 20261023
set obs 120
generate long id = _n
generate double x = rnormal()
generate byte treatment = runiform()<.5
generate byte shared = runiform()<.35
generate double common_u = runiform()
generate byte visits = 1+mod(id,4)
expand 4
bysort id: generate byte visit = _n
keep if visit<=visits
generate double u = cond(shared,common_u,runiform())
generate double latent = .6*x+.4*treatment+logit(u)
generate byte y = 1+(latent>-1)+(latent>.2)+(latent>1.3)

ordgee_pearson_dev y c.x i.treatment, ///
    id(id) time(visit) corr(exchangeable) rhomethod(qls) strictpairs
estat association
lincom x, or
predict double p1 p2 p3 p4 if e(sample), pr
```

Expected results are 300 observations, 120 subjects, final rho about **0.348720**,
and **zero pair-table violations**. The slope for `x` is about **0.360096**:
its cumulative odds ratio is approximately **1.43** per unit, holding treatment
fixed. `lincom` reports the confidence interval. `p1` through `p4` are the
probabilities of the four individual categories.

## Choose the association method

| Choice | Options after the mean-model variables |
| --- | --- |
| Estimated QLS, as above | `corr(exchangeable) rhomethod(qls)` |
| Estimated GV | `corr(exchangeable) rhomethod(gv)` |
| GV profile search | `corr(exchangeable) rhomethod(gv) solver(profile)` |
| Fixed correlation, for example .2 | `corr(exchangeable) rho(.2)` |
| Independence | `corr(independent)` |

QLS must be explicit: omitting `rhomethod()` for estimated exchangeable
association uses GV with the alternating solver. QLS does not accept `solver()`,
`start()`, or `iterate()`; see the help for its iteration controls. Choose a
method for the analysis and examine sensitivity; the command does not switch
methods automatically.

## Interpret and diagnose

Positive coefficients indicate higher categories. `exp(b)` is the cumulative
odds ratio for `Y > k` versus `Y <= k`, common across cutpoints under proportional
odds. With interactions, form the appropriate contrast rather than interpreting
a main effect alone. Standard errors are clustered by ID automatically, with
no finite-cluster correction; a `vce()` option is not supported.

`rho` measures association between same-cutpoint cumulative indicators at
different visits, not raw category scores. QLS reports both first-stage `a0`
and corrected final `rho`; the latter is used in the reported coefficient fit.

Run `estat association`. Numerical convergence and valid single-visit
probabilities do not ensure valid implied two-visit tables. The default reports
negative pair cells and retains the matrix as GEE working weights. `strictpairs`
rejects such a selected fit and clears the active results. Store a successful fit
before trying it if you need to return to that result. Passing the pair check
does not establish a full joint distribution over three or more visits.

Inference needs a suitable proportional-odds mean, independent clusters,
sufficient clusters, appropriate covariate exogeneity, and a suitable observation
process. Robust SEs do not correct a misspecified mean or informative dropout.
Negative, AR(1), and unstructured association, observation weights, a standard
error for rho, and `margins` are not implemented.

Checks include comparisons with reference equations, simulation studies, and
worked examples. The help describes the methods and validation limits; those
checks do not establish performance for every study design.

## Help and problem solving

- [Estimation help](ado/ordgee_pearson_dev.sthlp): syntax, data preparation,
  assumptions, troubleshooting, and complete generated- and public-data examples.
- [Postestimation help](ado/ordgee_pearson_dev_postestimation.sthlp): category
  prediction, odds ratios, diagnostics, and saving or restoring results.

Type `help ordgee_pearson_dev_postestimation` in Stata for formatted help.
The public-data example downloads Stata Press `schiz.dta`, with an offline
option. It illustrates a converged QLS working fit whose pair tables fail
`strictpairs`, so that rejection is expected in that example.

If a command or Mata file is missing, check the complete `ado/` folder and
`which` output. For a failed fit, read the error text: `r(498)` has several
causes. Check duplicate visits, category coding, sparse cells, redundant
covariates, and cluster counts. Increasing iterations cannot fix every failure.
The help provides method-specific guidance.

For feedback, use [GitHub Issues](https://github.com/renegade68/GEE-Stata/issues).
Include the Git commit, Stata version, `which` output, complete command, diagnostic
output, and a small reproducible example. Synthetic data are welcome.

## Author and license

Choonjoo Lee — bloom.rampike@gmail.com.
Licensed under the [GNU Affero General Public License version 3](LICENSE);
see [the software notice](LICENSE_CODE.txt). Preserve author and method references.
The help cites the underlying GEE, QLS, and ordinal-association literature.
