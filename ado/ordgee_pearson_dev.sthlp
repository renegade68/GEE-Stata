{smcl}
{* *! documentation revision E10 23oct2026; executable version 0.2.0}{...}
{vieweralsosee "ordgee_pearson_dev postestimation" "help ordgee_pearson_dev_postestimation"}{...}
{vieweralsosee "[R] ologit" "help ologit"}{...}
{vieweralsosee "[XT] xtgee" "help xtgee"}{...}
{viewerjumpto "Syntax" "ordgee_pearson_dev##syntax"}{...}
{viewerjumpto "Description" "ordgee_pearson_dev##description"}{...}
{viewerjumpto "Data requirements" "ordgee_pearson_dev##data"}{...}
{viewerjumpto "Troubleshooting" "ordgee_pearson_dev##troubleshooting"}{...}
{viewerjumpto "Options" "ordgee_pearson_dev##options"}{...}
{viewerjumpto "Remarks" "ordgee_pearson_dev##remarks"}{...}
{viewerjumpto "Examples" "ordgee_pearson_dev##examples"}{...}
{viewerjumpto "Stored results" "ordgee_pearson_dev##results"}{...}
{viewerjumpto "References" "ordgee_pearson_dev##references"}{...}
{viewerjumpto "Author" "ordgee_pearson_dev##author"}{...}
help for {bf:ordgee_pearson_dev}{right:Research version 0.2.0}
{hline}

{p2colset 1 24 26 2}{...}
{p2col:{bf:ordgee_pearson_dev} {hline 2}}Ordinal GEE with separable Pearson working correlation{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 23 2}
{cmd:ordgee_pearson_dev} {depvar} [{indepvars}] {ifin}{cmd:,}
{opt id(idvar)} {opt time(timevar)} {opt corr(corrtype)}
[{it:options}]
{p_end}

{synoptset 28 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Required}
{synopt:{opth id(varname)}}subject identifier; numeric or string{p_end}
{synopt:{opth time(varname)}}numeric observation-time variable{p_end}
{synopt:{opt corr(corrtype)}}{cmd:independent} or {cmd:exchangeable}{p_end}
{syntab:Association}
{synopt:{opt rhomethod(method)}}{cmd:gv} (default) or {cmd:qls}; estimated exchangeable rho only{p_end}
{synopt:{opt rho(#)}}fix rho in [0,1); omit to estimate exchangeable rho{p_end}
{synopt:{opt strictpairs}}reject a selected fit with incompatible ordinal pair tables{p_end}
{syntab:Computation}
{synopt:{opt solver(solver)}}GV {cmd:alternating} (default) or {cmd:profile}{p_end}
{synopt:{opt start(#)}}starting rho for alternating GV; default is {cmd:.2}{p_end}
{synopt:{opt iterate(#)}}coefficient-iteration limit; default is {cmd:300}; not allowed with QLS{p_end}
{synopt:{opt associterate(#)}}outer-iteration limit: {cmd:100} for GV, {cmd:300} for QLS{p_end}
{synopt:{opt inititerate(#)}}ordered-logit initialization limit; default is {cmd:100}{p_end}
{syntab:Reporting}
{synopt:{opt level(#)}}confidence level for displayed coefficient intervals{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
{it:indepvars} may contain {help fvvarlist:factor variables and interactions}.
Weights are not supported. {opt id()}, {opt time()}, and {opt corr()} are required.
{p_end}

{p 4 6 2}
For predictions, association diagnostics, candidate tables, and result restoration, see
{help ordgee_pearson_dev_postestimation:{bf:ordgee_pearson_dev postestimation}}.
{p_end}

{p 4 6 2}
Redisplay the current results: {cmd:ordgee_pearson_dev} [{cmd:,} {opt level(#)}].
{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ordgee_pearson_dev} fits a marginal proportional-odds model to repeated ordinal
responses using generalized estimating equations (GEE). It uses all cumulative
indicators and a separable Pearson working correlation. Estimated exchangeable
association can be obtained by two-stage quasi-least squares (QLS) or by the
generalized-variance (GV) criterion.
{p_end}

{pstd}
This is a research development command for Stata 16.1 or later. It runs in
Stata/Mata; R and Python are not runtime requirements. Under
{cmd:corr(exchangeable)} without {opt rho()}, the default is GV with the
alternating solver. QLS must be requested explicitly. There is no automatic
change of method after a failure.
{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opth id(varname)} identifies subjects. The identifier may be numeric or string. Subjects form the independent clusters for the sandwich variance.
{p_end}

{phang}
{opth time(varname)} specifies numeric observation times. ID-time pairs must be unique. Irregular times and unequal numbers of observations per subject are allowed. This option identifies visits; it does not add a time effect to the mean model. Include time or its functions among the covariates when required. Exchangeable correlation does not decay with time gaps.
{p_end}

{phang}
{opt corr(corrtype)} specifies {cmd:independent} or {cmd:exchangeable}. Independence fixes rho at zero. Exchangeable association is estimated unless {opt rho()} is supplied. Negative correlations are not implemented.
{p_end}

{dlgtab:Association}

{phang}
{opt rhomethod(method)} selects {cmd:gv} (the default) or {cmd:qls}. This option requires estimated exchangeable association; it cannot accompany {cmd:corr(independent)} or {opt rho()}. See {help ordgee_pearson_dev##qls:Two-stage QLS} and {help ordgee_pearson_dev##gv:GV computation}.
{p_end}

{phang}
{opt rho(#)} fixes rho at a value in [0,1). With {cmd:corr(independent)}, only {cmd:rho(0)} is permitted. A fixed rho does not estimate association.
{p_end}

{phang}
{opt strictpairs} rejects the selected final fit if any fitted ordinal pair table has a cell below -1e-10. The default reports these violations and retains the covariance as GEE working weights. Rejection returns r(498) and clears e(); it does not clip rho or select another fit. See {help ordgee_pearson_dev##pairs:Pair compatibility}.
{p_end}

{dlgtab:Computation}

{phang}
{opt solver(solver)} selects {cmd:alternating} or {cmd:profile} for GV. The default is {cmd:alternating}. {cmd:solver(profile)} requires estimated exchangeable GV and cannot accompany {opt start()}, {opt associterate()}, or {opt rho()}. QLS does not allow {opt solver()}.
{p_end}

{phang}
{opt start(#)} sets the starting rho for alternating GV; default .2, with 0 <= # < 1. It is not allowed with QLS or the profile solver.
{p_end}

{phang}
{opt iterate(#)} sets the coefficient-iteration limit for non-QLS fits; default 300. QLS rejects this option and uses a fixed limit of 300 for each inner fit.
{p_end}

{phang}
{opt associterate(#)} sets the outer-iteration limit: default 100 for alternating GV or 300 for QLS stage one. It is not allowed with {cmd:solver(profile)}.
{p_end}

{phang}
{opt inititerate(#)} sets the iteration limit for ordered-logit initialization; default 100. Iteration limits must be positive integers.
{p_end}

{dlgtab:Reporting}

{phang}
{opt level(#)} sets the confidence level for displayed coefficient intervals, using Stata's current confidence-level setting by default. Standard errors are clustered by the ID variable automatically; no {opt vce()} option is required or supported. The variance is the ordinary cluster sandwich; see {help ordgee_pearson_dev##variance:Variance and interpretation}.
{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
Remarks are presented under the following headings:
{p_end}

{phang2}
{help ordgee_pearson_dev##data:Data requirements}
{p_end}

{phang2}
{help ordgee_pearson_dev##mean:Mean model and interpretation}
{p_end}

{phang2}
{help ordgee_pearson_dev##qls:Two-stage QLS}
{p_end}

{phang2}
{help ordgee_pearson_dev##gv:GV computation}
{p_end}

{phang2}
{help ordgee_pearson_dev##variance:Variance and conditions for inference}
{p_end}

{phang2}
{help ordgee_pearson_dev##pairs:Pair compatibility}
{p_end}

{phang2}
{help ordgee_pearson_dev##diagnostics:Reading association diagnostics}
{p_end}

{phang2}
{help ordgee_pearson_dev##troubleshooting:Troubleshooting}
{p_end}


{marker data}{...}
{title:Data requirements}

{pstd}
Use long data: one row per subject and visit, with one ordinal outcome variable.
{opt id()} may be numeric or string; {opt time()} must be numeric. ID-time pairs
must be unique within the estimation sample. No {cmd:xtset} declaration is required.
{p_end}

{pstd}
The outcome must be numeric, with at least three observed categories in the
estimation sample. Categories are ordered by their numeric values; value labels
do not determine the order. Codes need not be consecutive. Recode a string
outcome deliberately into its substantive order; alphabetical encoding may give
the wrong order. Inspect the codes with {cmd:tabulate y, nolabel missing}.
{p_end}

{pstd}
Unequal cluster sizes, singleton clusters, factor variables, interactions, and
irregular time values are supported. Nonzero exchangeable association requires
repeated observations. The number of clusters must exceed the number of fitted
slopes plus cutpoints; this numerical requirement is not a guarantee that there
are enough clusters for reliable inference.
{p_end}

{pstd}
{opt time()} identifies visits but does not automatically enter the mean model.
To model a time trend, include time or its functions among the covariates; for
example, add {cmd:c.visit}. Exchangeable association uses the same between-visit
parameter for all time gaps. AR(1) and unstructured association are not implemented.
{p_end}

{pstd}
Rows with missing outcome, required covariates, ID, or time are excluded within
the {cmd:if}/{cmd:in} scope; {cmd:e(N_excluded)} reports their number. A subject
can therefore contribute its remaining complete rows. {cmd:e(N)} and {cmd:e(N_g)}
report observations and subjects used. This exclusion does not correct informative
missingness. Caller data and row order are preserved.
{p_end}

{pstd}
For example, with variables named {cmd:id}, {cmd:visit}, and {cmd:y}, check
the intended analysis data before fitting:
{p_end}

{phang2}
{cmd:. isid id visit}
{p_end}

{phang2}
{cmd:. tabulate y, nolabel missing}
{p_end}


{marker mean}{...}
{title:Mean model and interpretation}

{pstd}
Pr(Y_it <= k | X_it) = invlogit(c_k - X_it*b).
Positive b means higher categories are more likely.
exp(b) is the population-averaged cumulative odds ratio for Y > k versus
Y <= k, common across cutpoints under the proportional-odds model.
{p_end}

{pstd}
All K-1 cumulative indicators 1(Y_it <= k) enter the GEE.
Their within-observation correlation is
C_kl = exp(-abs(c_k-c_l)/2).
The working correlation is R_i = K_i(rho) # C, where # denotes
the Kronecker product and K_i has off-diagonal entries rho.
Thus rho describes same-cutpoint indicators at different visits.
Different-cutpoint, different-visit correlations equal rho*C_kl.
It is not the Pearson correlation of the raw ordinal category scores.
{p_end}


{marker qls}{...}
{title:Two-stage QLS}

{pstd}
{cmd:rhomethod(qls)} alternates coefficient GEE fits with conditional
quasi-least-squares minimization until the first-stage coefficients and
correlation a0 converge. It then applies one second-stage correlation
correction using the observed cluster sizes, holds that corrected rho fixed,
and refits the coefficient GEE. {cmd:e(qls_a0)} is the first-stage value;
{cmd:e(rho)} is the corrected value used for the final coefficients and variance.
They generally differ. This implementation uses cluster weights w_i=1.
{p_end}

{pstd}
{cmd:associterate(#)} limits first-stage outer iterations; its QLS default is 300.
Each inner coefficient fit has a fixed limit of 300 iterations.
QLS therefore rejects {cmd:iterate()}, {cmd:start()}, and {cmd:solver()}.
{cmd:inititerate(#)} still controls ordered-logit initialization.
The lower boundary a0=0 is permitted. Degenerate energies, unidentified
correlation, nonconvergence, an invalid correction, or a rank-deficient
ordinary sandwich return errors; no hidden fallback or clipping of rho is used.
{p_end}

{pstd}
QLS does not use the GV reference sandwich as an acceptance gate.
{cmd:e(V_repolr)} and GV candidate matrices are absent for QLS.
GV-specific scalars such as {cmd:e(alpha_score)} and
{cmd:e(rho_curvature)} are missing.
{cmd:e(qls_kkt)} is the normalized first-stage KKT violation at
{cmd:e(b_stage1)}, not a condition that must hold at the final refitted coefficients.
{p_end}


{marker gv}{...}
{title:GV computation}

{pstd}
GV uses the Parsons/repolr-type generalized-variance criterion
logdet(Mref)-2*logdet(B).
Mref replaces within-observation residual products by model-implied covariances
and retains empirical products between distinct observations.
{p_end}

{pstd}
The default {cmd:solver(alternating)} alternates coefficient fits with
half-damped rho updates and a grid search for conditional minima.
The lowest criterion among detected admissible conditional minima is chosen.
{cmd:start(#)} defaults to .2; {cmd:associterate(#)} defaults to 100.
{cmd:iterate(#)} defaults to 300 per coefficient fit.
Different starts may reach different solutions.
{p_end}

{pstd}
{cmd:solver(profile)} fits the coefficient GEE at 41 rho nodes in [0,1-1e-6],
brackets zeros of the partial rho derivative, and refines joint GEE/rho solutions.
It does not minimize the total function f(b(rho),rho) along the coefficient path.
Candidates must pass conditional-minimum, coefficient-refit, and covariance
checks, including a reference-covariance eigenvalue ratio above 1e-8.
The smallest rho among detected admissible joint candidates is selected.
A finite grid may miss candidates.
{p_end}

{pstd}
{cmd:solver(profile)} requires estimated exchangeable GV and cannot accompany
{cmd:start()}, {cmd:associterate()}, {cmd:rho()}, or {cmd:corr(independent)}.
The upper numerical boundary is not accepted.
Flat criteria, no admissible candidate, and nonconvergence return errors.
For equal cluster sizes with covariates constant within each cluster, GV can
be structurally flat even when the mean coefficients are estimable.
{p_end}


{marker variance}{...}
{title:Variance and conditions for inference}

{pstd}
All methods display the ordinary cluster sandwich
B^(-1) [sum_i U_i U_i'] B^(-1), with no finite-cluster correction.
This is {cmd:e(V)}. GV/fixed/independent fits additionally store the
reference sandwich as {cmd:e(V_repolr)}; it does not determine displayed SEs.
QLS does not calculate that extra matrix.
{p_end}

{pstd}
Independence-GEE coefficients agree with ordered logit under the same model
and sample. Finite-sample standard errors need not equal
{cmd:ologit, vce(cluster id)}: the GEE uses expected-derivative bread and no
finite-cluster multiplier, whereas the native likelihood calculation uses
its own bread and scaling. These variance conventions should be distinguished.
{p_end}

{pstd}
Inference requires an adequate marginal proportional-odds mean, independent
clusters, and enough clusters for sandwich asymptotics.
Nonindependence weighting with time-varying covariates requires suitable
cross-time mean/exogeneity conditions. Robust SEs do not repair endogenous
covariates or an outcome-dependent observation process.
This unweighted command supplies no inverse-probability weighting, imputation,
informative-cluster-size weighting, proportional-odds test, or SE for rho.
{cmd:margins} is not supported.
{p_end}

{pstd}
In a simulation study (10 conditions, 1,000 datasets each; 50 or 150
clusters; four categories; up to four visits), QLS coverage for the two primary
slope coefficients ranged from 92.9% to 96.1% for nominal 95% intervals.
This is conditional simulation evidence, not a universal coverage guarantee.
Negative correlations, very few clusters, sparse many-category outcomes, and
outcome-dependent dropout require further study.
{p_end}


{marker pairs}{...}
{title:Pair compatibility}

{pstd}
Convergence, positive definiteness, and pair compatibility are distinct conditions.
After fitting, implied ordinal pair tables are checked for cells below -1e-10.
The default reports violations and retains the matrix as GEE working weights.
{cmd:strictpairs} rejects the selected final fit if any pair violates that check.
It does not search for a different candidate and does not truncate negative cells.
{p_end}

{pstd}
Passing the pair check establishes the checked pairwise margins, not a full
joint distribution over three or more observations.
A valid data-generating joint distribution can still yield incompatible fitted
working pair tables under a misspecified separable correlation model.
{p_end}


{marker diagnostics}{...}
{title:Reading association diagnostics}

{pstd}
After a successful fit, run {cmd:estat association}. Read the fields together:
{cmd:rho} is the final working correlation used for the reported coefficients
and ordinary sandwich; {cmd:N_pairs} counts pairs of distinct observed visits
within subjects; {cmd:min_cell} is the smallest cell across their fitted ordinal
pair tables; {cmd:bad_pairs} counts tables with at least one cell below -1e-10.
It does not count negative cells or independent sampling units.
{p_end}

{pstd}
For QLS, the separately displayed {cmd:a0} is the first-stage correlation,
before the second-stage correction. The reported KKT diagnostic applies to
that first-stage fit. Neither a small KKT value nor {cmd:e(converged)==1}
certifies pair compatibility at the final fit.
{p_end}

{pstd}
In the public {cmd:schiz} example below, QLS gives a0=.111580 and final
rho=.237870. It converges, but 270 of 2,234 fitted ordinal pair tables have
a negative cell; the smallest cell is approximately -.002677.
All individual-visit category predictions remain nonnegative and sum to one.
The incompatible object is the two-visit joint table, not those marginal
predictions. These values describe this data and mean model, not a general
property of every QLS fit.
{p_end}

{pstd}
The default retains the fitted covariance as GEE working weights and reports
the pair violations. If pair compatibility is required for the intended
interpretation, use {cmd:strictpairs}; it rejects this QLS fit with r(498)
and clears e(). Save a fit with {cmd:estimates store} before trying this option
if you want to inspect it afterwards. Restoring it restores its diagnostics
too; it does not make an incompatible pair model valid.
{p_end}

{pstd}
For comparison, GV with {cmd:solver(profile)} gives rho=.123674 and no pair
violations in this example. This is a separately specified fit, not an
automatic fallback. Passing this check does not establish a full joint
distribution or show that GV has better inferential performance.
Report the method, final rho, sample, and pair diagnostics; do not silently
clip rho or discard negative cells. The mean and observation-process
conditions stated above remain necessary for inference using working weights.
{p_end}


{marker troubleshooting}{...}
{title:Troubleshooting}

{phang}
{bf:Command or companion file not found}. Keep all eight files in the repository
{cmd:ado/} folder together, including the three Mata {cmd:.do} files. Add that
folder with {cmd:adopath ++ "/your/path/GEE-Stata/ado"} and run
{cmd:which ordgee_pearson_dev}. Restart Stata after replacing an older version.
{p_end}

{phang}
{bf:Duplicate ID-time values or too few outcome categories}. Check the intended
analysis sample, missing values, and category coding. Resolve duplicates according
to the study design; do not discard records merely to make the command run.
{p_end}

{phang}
{bf:Option not allowed}. QLS requires {cmd:corr(exchangeable) rhomethod(qls)}
and rejects {opt rho()}, {opt solver()}, {opt start()}, and {opt iterate()}.
Use {opt associterate()} for its outer-iteration limit. Odds ratios are obtained
after fitting with {cmd:lincom}, not an estimation-command {cmd:or} option.
Robust standard errors by ID are automatic; {opt vce()} is not supported.
{p_end}

{phang}
{bf:Initialization, rank, or convergence failure}. Inspect sparse categories,
separation, redundant covariates, empty interaction cells, and the number of
clusters. Review the mean specification. Appropriate iteration limits may help
a converging calculation, but cannot resolve nonidentification. For GV,
different starts may reach different solutions and a flat criterion may be
unidentified; see {help ordgee_pearson_dev##gv:GV computation}.
{p_end}

{phang}
{bf:strictpairs rejection}. The selected fit has incompatible ordinal pair
tables. This is a distinct issue from iteration limits. Save any successful
working fit before refitting; report the violations and assess whether that
working-covariance interpretation suits the analysis. Do not silently clip rho
or present another method as an automatic repair.
{p_end}

{phang}
{bf:Reading the error message}. Several input, rank, and pair checks use
{cmd:r(498)}. Read the accompanying message rather than interpreting the code
alone. Failed estimation clears {cmd:e()}. Restore a saved result before further
postestimation commands; see {help ordgee_pearson_dev_postestimation##restore:Saving and restoring results}.
{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
{help ordgee_pearson_dev##example_generated:1. Generated data; no external data required}
{break}{help ordgee_pearson_dev##example_public:2. Public data; QLS pair diagnostics}
{p_end}


{marker example_generated}{...}
{title:Example 1: Generated data}

{pstd}
Save open data before {cmd:clear}. The following block generates an unbalanced
four-category example locally. The common-uniform mixture has same-cutpoint
Pearson correlation .35 before sampling variability; .35 is a generation
parameter, not a fixed fitted value. Copy the whole block into a do-file.
{p_end}

{cmd}
    version 16.1
    clear
    set more off
    set seed 20261023
    set obs 120
    gen long id=_n
    gen double x=rnormal()
    gen byte treatment=runiform()<.5
    gen byte shared=runiform()<.35
    gen double common_u=runiform()
    gen byte visits=1+mod(id,4)
    expand 4
    bysort id: gen byte visit=_n
    keep if visit<=visits
    gen double u=cond(shared,common_u,runiform())
    gen double latent=.6*x+.4*treatment+logit(u)
    gen byte y=1+(latent>-1)+(latent>.2)+(latent>1.3)
    ordgee_pearson_dev y c.x i.treatment, ///
        id(id) time(visit) corr(exchangeable) ///
        rhomethod(qls) strictpairs
    estat association
    predict double p1 p2 p3 p4 if e(sample), pr
    lincom x, or
    display "Stage-one a0: " e(qls_a0) "   Corrected rho: " e(rho)
    estimates store demo_qls
    ordgee_pearson_dev y c.x i.treatment, ///
        id(id) time(visit) corr(exchangeable) ///
        rhomethod(gv) solver(profile) strictpairs
    estat candidates
    estimates restore demo_qls
{txt}

{pstd}
For this generated example, QLS uses 300 observations from 120 subjects,
with final rho approximately .348720 and zero pair-table violations. The
coefficient for {cmd:x} is approximately .360096, giving a cumulative odds
ratio of about 1.43 for a one-unit increase, holding treatment fixed. The
confidence interval is reported by {cmd:lincom x, or}. These are reproducibility
values for this example, not population parameters. The optional GV comparison
fits a separately specified association method; the final line restores QLS.
{p_end}


{marker example_public}{...}
{title:Example 2: Public data and pair diagnostics}

{pstd}
This example uses {cmd:schiz.dta} from
{browse "https://www.stata-press.com/data/mlmus4.html":Multilevel and Longitudinal Modeling Using Stata, Fourth Edition}.
The outcome grouping and square-root-time interaction follow the official
Chapter 11 example. All 1,603 available observations from 437 patients enter
the model. Retaining all available rows does not establish complete follow-up
or noninformative dropout. Higher outcome categories mean worse symptoms.
{p_end}

{pstd}
Copy the whole block into a do-file; save open data first. It downloads the
public data by default. To run offline, pass a cached copy of the same
{cmd:schiz.dta} as the do-file's argument. The companion command and help files must be available on the ado-path. The earlier generated-data example
requires no external data and remains available above.
{p_end}

{pstd}
The week-6 contrast is b_treatment + sqrt(6)*b_interaction, not b_treatment
alone. Its exponent is the treatment/control odds ratio for higher severity,
common across cutpoints under proportional odds; it is not a probability ratio.
The QLS estimate is approximately .145401, with an ordinary-sandwich 95% interval
of [.091983, .229839]. This is an illustrative working-fit summary subject to
the stated mean, observation-process, and pair-interpretation conditions.
{p_end}

{cmd}
    version 16.1
    clear
    set more off
    * Optional argument: a cached copy of the same public schiz.dta.
    args datafile
    local site "https://www.stata-press.com/data/mlmus4"
    if "`datafile'"=="" local datafile "`site'/schiz.dta"
    use "`datafile'", clear
    generate double impso=imps
    recode impso (-9=.) (1/2.4=1) (2.5/4.4=2) (4.5/5.4=3) (5.5/7=4)
    generate double weeksqrt=sqrt(week)
    generate double interaction=weeksqrt*treatment
    keep if !missing(impso,weeksqrt,treatment,id,week)
    sort id week
    
    ordgee_pearson_dev impso weeksqrt treatment interaction, ///
        id(id) time(week) corr(exchangeable) rhomethod(qls)
    estat association
    display "Stage-one a0: " e(qls_a0)
    display "Final rho: " e(rho)
    estimates store schiz_qls
    
    * Week-6 OR for higher severity.
    * Individual-visit probabilities remain valid.
    local week6=sqrt(6)
    lincom treatment + `week6'*interaction, or
    predict double p1 p2 p3 p4, pr
    assert abs(p1+p2+p3+p4-1)<1e-12
    assert min(p1,p2,p3,p4)>=0 & max(p1,p2,p3,p4)<=1
    
    * Expected r(498): 270/2234 pair tables have a negative cell.
    capture noisily ordgee_pearson_dev ///
        impso weeksqrt treatment interaction, ///
        id(id) time(week) corr(exchangeable) ///
        rhomethod(qls) strictpairs
    local strict_rc=_rc
    display "QLS strictpairs return code: " `strict_rc'
    assert `strict_rc'==498
    assert "`e(cmd)'"==""
    
    * A separate, explicitly chosen comparison.
    ordgee_pearson_dev impso weeksqrt treatment interaction, ///
        id(id) time(week) corr(exchangeable) ///
        rhomethod(gv) solver(profile) strictpairs
    estat association
    estimates store schiz_gv
    
    * Restore the original QLS working fit and its pair diagnostics.
    estimates restore schiz_qls
    estat association
{txt}

{pstd}
The {cmd:capture} above handles the expected {cmd:strictpairs} rejection only
so that the demonstration can continue; the return-code and empty-e()
assertions make that rejection explicit. The last two commands deliberately
restore and display the original QLS result and its 270 pair violations.
The separate GV fit is retained as {cmd:schiz_gv}.
For a comparison with {cmd:ologit, vce(cluster id)}, also distinguish the
variance conventions described above; their standard errors need not match
even when independence-GEE coefficients agree.
{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:ordgee_pearson_dev} stores the following in {cmd:e()}. Some method-specific
scalars are missing when they do not apply; method-specific matrices are
present only for the corresponding fits.
{p_end}

{synoptset 29 tabbed}{...}
{p2col 5 29 32 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations used{p_end}
{synopt:{cmd:e(N_g)}}number of subjects{p_end}
{synopt:{cmd:e(N_excluded)}}rows excluded for missing required values within the if/in scope{p_end}
{synopt:{cmd:e(k_cat)}}number of observed ordered categories{p_end}
{synopt:{cmd:e(N_pairs)}}number of within-subject pairs of distinct visits{p_end}
{synopt:{cmd:e(rho)}}final working correlation{p_end}
{synopt:{cmd:e(rho_boundary)}}estimated lower-boundary flag{p_end}
{synopt:{cmd:e(min_pair_cell)}}smallest implied ordinal pair cell{p_end}
{synopt:{cmd:e(pair_violations)}}number of pair tables with a cell below -1e-10{p_end}
{synopt:{cmd:e(converged)}}1 on a successful fit{p_end}
{synopt:{cmd:e(score)}}maximum absolute final GEE score{p_end}
{synopt:{cmd:e(next_step)}}maximum absolute final coefficient step{p_end}
{synopt:{cmd:e(iterations)}}coefficient-iteration count; interpretation depends on solver{p_end}
{synopt:{cmd:e(association_iterations)}}association-iteration count{p_end}
{synopt:{cmd:e(rho_start)}}starting rho; missing for profile and QLS{p_end}
{synopt:{cmd:e(alpha_score)}}GV partial rho derivative; missing for QLS{p_end}
{synopt:{cmd:e(rho_curvature)}}GV conditional curvature; missing for QLS{p_end}
{synopt:{cmd:e(rho_candidates)}}GV conditional candidate count{p_end}
{synopt:{cmd:e(rho_invalid_grid)}}GV invalid-grid count{p_end}
{synopt:{cmd:e(profile_fits)}}profile coefficient-fit attempts{p_end}
{synopt:{cmd:e(joint_candidates)}}accepted profile roots{p_end}
{p2colreset}{...}

{synoptset 29 tabbed}{...}
{p2col 5 29 32 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}ordgee_pearson_dev{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}outcome variable{p_end}
{synopt:{cmd:e(idvar)}}subject identifier{p_end}
{synopt:{cmd:e(timevar)}}observation-time variable{p_end}
{synopt:{cmd:e(corr)}}independent or exchangeable{p_end}
{synopt:{cmd:e(rhomethod)}}qls, gv, fixed, or independent{p_end}
{synopt:{cmd:e(rho_method)}}legacy association-method label{p_end}
{synopt:{cmd:e(solver)}}alternating, profile, or two_stage{p_end}
{synopt:{cmd:e(package_version)}}executable version{p_end}
{synopt:{cmd:e(vce)}}robust{p_end}
{synopt:{cmd:e(vcetype)}}Robust{p_end}
{synopt:{cmd:e(predict)}}prediction program{p_end}
{synopt:{cmd:e(estat_cmd)}}postestimation program{p_end}
{synopt:{cmd:e(factors)}}factor variables used for prediction{p_end}
{p2colreset}{...}

{synoptset 29 tabbed}{...}
{p2col 5 29 32 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}cutpoints and slope coefficients{p_end}
{synopt:{cmd:e(V)}}ordinary cluster sandwich{p_end}
{synopt:{cmd:e(categories)}}observed category codes in increasing order{p_end}
{synopt:{cmd:e(times)}}observed time values{p_end}
{synopt:{cmd:e(association)}}final rho{p_end}
{synopt:{cmd:e(V_repolr)}}reference sandwich; absent for QLS{p_end}
{synopt:{cmd:e(factor_levels#)}}stored factor levels for new-data prediction{p_end}
{p2colreset}{...}

{synoptset 29 tabbed}{...}
{p2col 5 29 32 2: Additional QLS results}{p_end}
{synopt:{cmd:e(qls_a0)}}first-stage correlation{p_end}
{synopt:{cmd:e(qls_kkt)}}normalized first-stage KKT violation{p_end}
{synopt:{cmd:e(qls_Q)}}first-stage QLS criterion{p_end}
{synopt:{cmd:e(qls_stage1_boundary)}}first-stage lower-boundary flag{p_end}
{synopt:{cmd:e(b_stage1)}}first-stage coefficient vector{p_end}
{synopt:{cmd:e(qls_trace)}}stage-one iterations followed by the stage-two refit{p_end}
{p2colreset}{...}

{synoptset 29 tabbed}{...}
{p2col 5 29 32 2: Additional GV profile matrices}{p_end}
{synopt:{cmd:e(candidate_summary)}}candidate diagnostics, ordered by rho{p_end}
{synopt:{cmd:e(candidate_b)}}candidate coefficients{p_end}
{synopt:{cmd:e(candidate_se)}}ordinary-sandwich standard errors{p_end}
{synopt:{cmd:e(candidate_ll95)}}lower 95% limits{p_end}
{synopt:{cmd:e(candidate_ul95)}}upper 95% limits{p_end}
{synopt:{cmd:e(V_candidate#)}}ordinary covariance for candidate #{p_end}
{synopt:{cmd:e(V_repolr_candidate#)}}reference covariance for candidate #{p_end}
{p2colreset}{...}

{pstd}
QLS: {cmd:e(qls_a0)}, {cmd:e(qls_kkt)}, {cmd:e(qls_Q)},
{cmd:e(qls_stage1_boundary)}, {cmd:e(b_stage1)}, {cmd:e(qls_trace)}.
Trace columns are stage, outer, a0, rho, score, step, Q_deriv, Q_curv,
N_pairs, singletons, min_V_eigen, min_pair, bad_pairs, delta_b, delta_a, inner_iters.
Stage 1 rows precede the single stage 2 row. Stage 1 rho is missing.
Q derivatives on the stage 2 row are evaluated at the refitted coefficients
and the saved a0; they are not the reported first-stage KKT.
{cmd:e(iterations)} sums coefficient iterations across both QLS stages.
{p_end}

{pstd}
GV profile: {cmd:e(candidate_summary)} columns are selected, rho, gee_score,
alpha_score, curvature, eigen_ratio, min_cell, bad_pairs, N_pairs.
{cmd:e(candidate_b)}, {cmd:e(candidate_se)}, {cmd:e(candidate_ll95)},
{cmd:e(candidate_ul95)} have one row per candidate.
{cmd:e(V_candidate1)}, ... and {cmd:e(V_repolr_candidate1)}, ... store full covariances.
Stored intervals are always 95%; {cmd:estat candidates, level()} changes its
returned/displayed table only. It returns {cmd:r(table)}, {cmd:r(summary)},
{cmd:r(candidates)}, and {cmd:r(level)}.
For profile fits {cmd:e(iterations)} counts the final coefficient refit,
{cmd:e(profile_fits)} counts attempts, and {cmd:e(joint_candidates)} counts accepted roots.
{p_end}

{synoptset 29 tabbed}{...}
{p2col 5 29 32 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the estimation sample{p_end}
{p2colreset}{...}

{pstd}
For commands that return {cmd:r()} results and for stored-result restoration,
see {help ordgee_pearson_dev_postestimation##results:postestimation stored results}.
{p_end}


{marker references}{...}
{title:References}

{phang}
Liang, K. Y., and S. L. Zeger. 1986. Longitudinal data analysis using generalized
linear models. Biometrika 73:13-22.
{browse "https://doi.org/10.1093/biomet/73.1.13":doi:10.1093/biomet/73.1.13}.
{p_end}

{phang}
Shults, J., S. J. Ratcliffe, and M. Leonard. 2007.
Improved generalized estimating equation analysis via xtqls for quasi-least
squares in Stata. Stata Journal 7:147-166.
{browse "https://www.stata-journal.com/article.html?article=st0122":Stata Journal st0122}.
{p_end}

{phang}
Mitani, A. A., E. K. Kaye, and K. P. Nelson. 2019.
Marginal analysis of ordinal clustered longitudinal data with informative
cluster size. Biometrics 75:938-949.
{browse "https://doi.org/10.1111/biom.13050":doi:10.1111/biom.13050}.
The present implementation uses unweighted clusters; it does not implement
that paper's informative-cluster-size weighting.
{p_end}

{phang}
Parsons, N. R., M. L. Costa, J. Achten, and N. Stallard. 2009.
Repeated measures proportional odds logistic regression analysis of ordinal
score data in the statistical software package R.
Computational Statistics & Data Analysis 53:632-641.
{browse "https://doi.org/10.1016/j.csda.2008.08.004":doi:10.1016/j.csda.2008.08.004}.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Choonjoo Lee
{break}Contact: {browse "mailto:bloom.rampike@gmail.com":bloom.rampike@gmail.com}
{break}{browse "https://github.com/renegade68/GEE-Stata":GEE-Stata: source, installation, and issue reports}.
{p_end}

