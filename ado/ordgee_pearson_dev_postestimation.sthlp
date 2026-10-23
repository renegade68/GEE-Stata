{smcl}
{* *! documentation revision E10 23oct2026; executable version 0.2.0}{...}
{vieweralsosee "ordgee_pearson_dev" "help ordgee_pearson_dev"}{...}
{vieweralsosee "[R] predict" "help predict"}{...}
{vieweralsosee "[R] estimates" "help estimates"}{...}
{vieweralsosee "[R] lincom" "help lincom"}{...}
{viewerjumpto "Postestimation commands" "ordgee_pearson_dev_postestimation##description"}{...}
{viewerjumpto "predict" "ordgee_pearson_dev_postestimation##predict"}{...}
{viewerjumpto "estat association" "ordgee_pearson_dev_postestimation##association"}{...}
{viewerjumpto "estat candidates" "ordgee_pearson_dev_postestimation##candidates"}{...}
{viewerjumpto "Odds ratios and contrasts" "ordgee_pearson_dev_postestimation##contrasts"}{...}
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
{synopt:{help ordgee_pearson_dev_postestimation##contrasts:{bf:lincom}}}linear combinations and exponentiated contrasts{p_end}
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
The K variables returned by {opt pr} follow increasing category codes, listed
in {cmd:e(categories)}. They are individual-category probabilities, not cumulative
probabilities. {cmd:outcome(#k)} selects rank k; {cmd:outcome(value)} selects an
original numeric code. Use new variable names; existing variables are not replaced.
{p_end}

{pstd}
By default, predictions are made wherever the required covariates are available,
including observations excluded from estimation. To restrict predictions after
fitting to the estimation sample, add {cmd:if e(sample)}. For example, after
a four-category fit:
{p_end}

{phang2}
{cmd:. predict double p1 p2 p3 p4 if e(sample), pr}
{p_end}

{pstd}
New-data prediction requires the covariates and known factor levels. It does
not require outcome, ID, or time unless they enter the mean model. Supply any
variables used to construct the fitted specification, including generated
transformations or interactions. Unknown factor levels return an error before
creating output variables. For results loaded from disk, see the
{help ordgee_pearson_dev_postestimation##restore:estimation-sample note below}.
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


{marker contrasts}{...}
{title:Odds ratios and contrasts}

{pstd}
After fitting, {cmd:lincom} reports a slope or a linear combination with its
ordinary-sandwich confidence interval. Add {cmd:or} to exponentiate the estimate
and interval. For a model containing continuous {cmd:x} and {cmd:i.treatment}:
{p_end}

{phang2}
{cmd:. lincom x, or}
{p_end}

{phang2}
{cmd:. lincom 1.treatment, or}
{p_end}

{pstd}
The first command is the cumulative odds ratio for a one-unit increase in
{cmd:x}, holding other covariates fixed. The second compares treatment 1 with
the reference level; it assumes that 0 is the reference in this example.
Use the actual coefficient names and reference levels from your model.
{p_end}

{pstd}
With interactions, a main coefficient alone is generally not the comparison
at every time or covariate value. Form the appropriate linear combination; the
{help ordgee_pearson_dev##example_public:public-data example} illustrates a treatment
contrast at week 6. Cutpoints are thresholds, not covariate odds ratios.
No estimation-command {cmd:or} option or {cmd:margins} support is provided.
{p_end}


{marker restore}{...}
{title:Saving and restoring results}

{pstd}
{cmd:estimates store} and {cmd:estimates restore} keep results in memory.
{cmd:estimates save} and {cmd:estimates use} write and read a {cmd:.ster} file.
Prediction metadata, association diagnostics, and available candidate tables
are retained. Keep the command and companion files on the ado-path in a new
session. Use {cmd:ordgee_pearson_dev, level(90)} to redisplay a loaded result.
{p_end}

{pstd}
Saved estimates do not save the data. Stata sets {cmd:e(sample)} to zero after
{cmd:estimates use}; it does not automatically recover the original estimation
rows. If those rows will be needed, generate a sample indicator immediately
after fitting and save it with the data:
{p_end}

{phang2}
{cmd:. generate byte gee_sample = e(sample)}
{p_end}

{pstd}
After reloading those same data and saved results, use {cmd:if gee_sample==1}
for original-sample predictions. To set {cmd:e(sample)} explicitly, see
{help estimates_save##setting:estimates save/use and e(sample)}. On new data,
choose the intended prediction rows rather than using an old sample indicator.
{p_end}

{pstd}
Failed estimation clears {cmd:e()}. Store or save a successful fit before
trying {opt strictpairs} if you want to inspect it afterwards. Restoring an
incompatible working fit also restores its pair diagnostics; it does not make
its pair tables valid. The
{help ordgee_pearson_dev##example_public:public-data example} demonstrates this workflow.
{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
After a four-category fit:
{p_end}

{phang2}
{cmd:. predict double p1 p2 p3 p4 if e(sample), pr}
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

