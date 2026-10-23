{smcl}
{* *! documentation revision E8 23oct2026; executable version 0.2.0}{...}
{vieweralsosee "ordgee_pearson_dev" "help ordgee_pearson_dev"}{...}
{vieweralsosee "[R] predict" "help predict"}{...}
{vieweralsosee "[R] estimates" "help estimates"}{...}
{vieweralsosee "[R] lincom" "help lincom"}{...}
{viewerjumpto "Postestimation commands" "ordgee_pearson_dev_postestimation##description"}{...}
{viewerjumpto "predict" "ordgee_pearson_dev_postestimation##predict"}{...}
{viewerjumpto "estat association" "ordgee_pearson_dev_postestimation##association"}{...}
{viewerjumpto "estat candidates" "ordgee_pearson_dev_postestimation##candidates"}{...}
{viewerjumpto "Saving and restoring results" "ordgee_pearson_dev_postestimation##restore"}{...}
{viewerjumpto "Examples" "ordgee_pearson_dev_postestimation##examples"}{...}
{viewerjumpto "Stored results" "ordgee_pearson_dev_postestimation##results"}{...}
help for {bf:ordgee_pearson_dev postestimation}{right:Research version 0.2.0}
{hline}

{p2colset 1 24 26 2}{...}
{p2col:{bf:ordgee_pearson_dev} {hline 2}}Postestimation tools{p_end}
{p2colreset}{...}


{marker description}{...}
{title:Postestimation commands}

{pstd}
The following commands are available after {helpb ordgee_pearson_dev}:
{p_end}

{synoptset 24}{...}
{synopthdr:command}
{synoptline}
{synopt:{help ordgee_pearson_dev_postestimation##predict:{bf:predict}}}category probabilities or linear predictor{p_end}
{synopt:{help ordgee_pearson_dev_postestimation##association:{bf:estat association}}}working-correlation and pair diagnostics{p_end}
{synopt:{help ordgee_pearson_dev_postestimation##candidates:{bf:estat candidates}}}GV profile candidates and ordinary-sandwich intervals{p_end}
{synopt:{help estimates:{bf:estimates}}}store, save, and restore estimation results{p_end}
{synopt:{help lincom:{bf:lincom}}}linear combinations and exponentiated contrasts{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{cmd:margins} is not supported. The command does not provide likelihood-based
postestimation or a standard error for rho. See the
{help ordgee_pearson_dev##variance:conditions for inference} in the estimation help.
{p_end}


{marker predict}{...}
{title:predict}

{p 8 16 2}
{cmd:predict} [{it:type}] {it:{help newvarlist}} {ifin}
[{cmd:,} {opt pr} {opt outcome(outcome)}]
{p_end}

{p 8 16 2}
{cmd:predict} [{it:type}] {newvar} {ifin}{cmd:,} {opt xb}
{p_end}

{synoptset 24}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt pr}}category probabilities; the default{p_end}
{synopt:{opt outcome(outcome)}}one observed numeric code or {cmd:#} followed by a category rank{p_end}
{synopt:{opt xb}}linear predictor X*b, excluding cutpoints{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{it:type} may be {cmd:float} or {cmd:double}. Specify exactly K new variables
for all K probabilities, or one variable for a selected outcome. With one
variable and no {opt outcome()}, the lowest category is selected.
{opt xb} requires one variable and cannot accompany {opt pr} or {opt outcome()}.
{p_end}

{pstd}
{cmd:predict double p1 ... pK, pr} returns all category probabilities.
One variable with {cmd:outcome(#k)} selects a category rank;
{cmd:outcome(value)} selects its original numeric code.
One variable without an outcome option defaults to the lowest category.
{cmd:predict double eta, xb} excludes cutpoints.
New-data prediction needs the covariates and known factor levels; it does not
need outcome, ID, or time unless these also enter the mean model.
Unknown factor levels return an error before creating output variables.
{p_end}


{marker association}{...}
{title:estat association}

{p 8 16 2}
{cmd:estat association}
{p_end}

{pstd}
{cmd:estat association} reports rho, the estimated lower-boundary flag, pair count,
minimum implied cell, and violating-pair count.
For QLS it also reports first-stage a0 and KKT.
It returns {cmd:r(summary)} and {cmd:r(method)}, and for QLS
{cmd:r(a0)} and {cmd:r(kkt)}.
{p_end}

{pstd}
Use {help ordgee_pearson_dev##diagnostics:Reading association diagnostics} to distinguish
first-stage a0, final rho, convergence, and pair compatibility. A successful
fit can still have incompatible ordinal pair tables.
{help ordgee_pearson_dev##pairs:{bf:strictpairs}} rejects such a selected fit; it does not
search for another candidate.
{p_end}


{marker candidates}{...}
{title:estat candidates}

{p 8 16 2}
{cmd:estat candidates} [{cmd:,} {opt level(#)}]
{p_end}

{pstd}
After GV {cmd:solver(profile)}, {cmd:estat candidates, level(90)} reports detected
candidates with coefficients and ordinary-sandwich normal intervals.
It neither refits nor changes {cmd:e(b)}.
Rows follow increasing rho; candidate 1 remains selected.
Intervals include no adjustment for few clusters or candidate selection.
QLS, fixed, independent, and alternating fits do not provide candidate tables.
{p_end}

{pstd}
This command requires a GV fit with {cmd:solver(profile)}. The coefficient
and covariance matrices for each candidate are retained in {cmd:e()}.
Stored interval matrices contain 95% limits; {opt level()} changes only the
returned and displayed table. A finite grid may miss candidates.
{p_end}


{marker restore}{...}
{title:Saving and restoring results}

{pstd}
Saved estimates retain prediction metadata, QLS diagnostics, and available
candidate tables across {cmd:estimates store/save} and restoration, including
a fresh Stata session with the companion ado files on the adopath.
A failed estimation clears e(), preventing stale successful results from being used.
{cmd:ordgee_pearson_dev, level(90)} replays an existing result.
{p_end}

{pstd}
After a failed estimation, {cmd:e()} is empty. Save a fit before trying
{opt strictpairs} if you want to inspect it afterwards. Restoring an
incompatible working fit restores its pair diagnostics; it does not make
the fitted pair tables valid. The public-data example in the
{help ordgee_pearson_dev##example_public:estimation help} illustrates this workflow.
{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
After a four-category fit:
{p_end}

{phang2}
{cmd:. predict double p1 p2 p3 p4, pr}
{p_end}

{phang2}
{cmd:. predict double eta, xb}
{p_end}

{phang2}
{cmd:. predict double lowest, outcome(#1)}
{p_end}

{phang2}
{cmd:. estat association}
{p_end}

{pstd}
After a GV profile fit:
{p_end}

{phang2}
{cmd:. estat candidates, level(90)}
{p_end}

{pstd}
For complete data generation and fitting commands, see
{help ordgee_pearson_dev##examples:Examples} in the estimation help.
{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:estat association} stores the following in {cmd:r()}:
{p_end}

{synoptset 29 tabbed}{...}
{p2col 5 29 32 2: Scalars (QLS only)}{p_end}
{synopt:{cmd:r(a0)}}first-stage correlation{p_end}
{synopt:{cmd:r(kkt)}}normalized first-stage KKT violation{p_end}
{p2colreset}{...}

{synoptset 29 tabbed}{...}
{p2col 5 29 32 2: Macros}{p_end}
{synopt:{cmd:r(method)}}association method{p_end}
{p2colreset}{...}

{synoptset 29 tabbed}{...}
{p2col 5 29 32 2: Matrices}{p_end}
{synopt:{cmd:r(summary)}}rho, lower_boundary, N_pairs, min_cell, bad_pairs{p_end}
{p2colreset}{...}

{pstd}
{cmd:estat candidates} stores the following in {cmd:r()}:
{p_end}

{synoptset 29 tabbed}{...}
{p2col 5 29 32 2: Scalars}{p_end}
{synopt:{cmd:r(candidates)}}number of reported candidates{p_end}
{synopt:{cmd:r(level)}}confidence level for returned intervals{p_end}
{p2colreset}{...}

{synoptset 29 tabbed}{...}
{p2col 5 29 32 2: Matrices}{p_end}
{synopt:{cmd:r(summary)}}candidate diagnostics from e(candidate_summary){p_end}
{synopt:{cmd:r(table)}}candidate, selected, rho, b, se, ll, ul; one row per parameter per candidate{p_end}
{p2colreset}{...}

{pstd}
Neither command changes the active {cmd:e(b)} or {cmd:e(V)}.
See {help ordgee_pearson_dev##results:Stored results} in the estimation help for the
complete estimation results.
{p_end}

