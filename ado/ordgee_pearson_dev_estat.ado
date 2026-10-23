*! Pearson diagnostics and candidate reporting 0.2.0 23oct2026
program define ordgee_pearson_dev_estat, rclass
    version 16.1
    if "`e(cmd)'"!="ordgee_pearson_dev" error 301
    gettoken key rest : 0, parse(", ")
    if "`key'"=="association" {
        local 0 `rest'
        syntax
        tempname summary
        matrix `summary'=(e(rho),e(rho_boundary),e(N_pairs),e(min_pair_cell),e(pair_violations))
        matrix colnames `summary'=rho lower_boundary N_pairs min_cell bad_pairs
        di as text "Association method: " as result "`e(rhomethod)'"
        matlist `summary', format(%12.6g)
        if "`e(rhomethod)'"=="qls" {
            di as text "QLS stage-one a0 = " as result %12.8g e(qls_a0)
            di as text "Normalized stage-one KKT violation = " as result %12.4g e(qls_kkt)
            return scalar a0=e(qls_a0)
            return scalar kkt=e(qls_kkt)
        }
        di as text "PD, numerical convergence, and pair compatibility are distinct checks."
        return matrix summary=`summary'
        return local method "`e(rhomethod)'"
        exit
    }
    if "`key'"!="candidates" {
        estat_default `0'
        return add
        exit
    }
    local 0 `rest'
    syntax [, Level(cilevel)]
    if "`e(solver)'"!="profile" {
        di as error "Candidate tables require a fit with solver(profile)"
        exit 321
    }
    capture confirm matrix e(candidate_b)
    if _rc {
        di as error "Refit with ordgee_pearson_dev 0.1.3 or later to store candidate tables"
        exit 321
    }
    tempname table summary one
    matrix `summary'=e(candidate_summary)
    mata: _pex13_report("`table'",`level')
    matrix colnames `table'=candidate selected rho b se ll ul
    di as text "Detected admissible profile candidates (smallest rho selected)"
    di as text "Intervals: `level'% normal approximation, ordinary cluster sandwich"
    local d=colsof(e(candidate_b))
    forvalues j=1/`=e(joint_candidates)' {
        local selected
        if `summary'[`j',1]==1 local selected " (selected)"
        di as text "Candidate `j'`selected': rho = " as result %9.6f `summary'[`j',2]
        di as text "  Pair-table violations = " as result %9.0g `summary'[`j',8] as text " / " as result %9.0g `summary'[`j',9]
        local first=(`j'-1)*`d'+1
        local last=`j'*`d'
        matrix `one'=`table'[`first'..`last',4..7]
        matlist `one', format(%10.5g)
    }
    di as text "Candidate numbers follow increasing rho; selected=1 marks e(b)."
    di as text "Finite-grid search may miss candidates; pair-table diagnostics remain relevant."
    return matrix table=`table'
    return matrix summary=`summary'
    return scalar level=`level'
    return scalar candidates=e(joint_candidates)
end

mata:
void _pex13_report(string scalar tablename,real scalar level)
{
    real matrix B,S,H,T
    real scalar z,m,d,j
    real colvector ix
    string matrix stripe,names
    B=st_matrix("e(candidate_b)");S=st_matrix("e(candidate_se)")
    H=st_matrix("e(candidate_summary)");z=invnormal(.5+level/200)
    m=rows(B);d=cols(B);T=J(m*d,7,.)
    stripe=J(m*d,2,"");names=st_matrixcolstripe("e(candidate_b)")
    for(j=1;j<=m;j++) {
        ix=((j-1)*d+1::j*d)
        T[ix,]=(J(d,1,j),J(d,1,H[j,1]),J(d,1,H[j,2]),B[j,]',S[j,]',B[j,]'-z*S[j,]',B[j,]'+z*S[j,]')
        stripe[ix,]=names
    }
    st_matrix(tablename,T);st_matrixrowstripe(tablename,stripe)
}
end
