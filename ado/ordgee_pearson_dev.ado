*! Pearson working-correlation research prototype 0.2.0 23oct2026
program define ordgee_pearson_dev, eclass
    version 16.1
    if replay() {
        if "`e(cmd)'"!="ordgee_pearson_dev" error 301
        syntax [, Level(cilevel)]
        ereturn display, level(`level')
        exit
    }
    capture noisily _ordgee_pearson_dev_impl `0'
    local rc=_rc
    if `rc' {
        ereturn clear
        exit `rc'
    }
end

program define _ordgee_pearson_dev_impl, eclass
    version 16.1
    local cmdline `"ordgee_pearson_dev `0'"'
    syntax varlist(numeric fv min=1) [if] [in], ID(varname) TIME(varname numeric) ///
        CORR(string) [RHO(string) RHOMethod(string) ITERate(string) INITIterate(integer 100) ASSOCIterate(string) STRICTPairs START(string) SOLVER(string) Level(cilevel)]
    if "`rhomethod'"!="" & ("`corr'"!="exchangeable" | "`rho'"!="") {
        di as error "rhomethod() requires estimated exchangeable rho; omit rho()"
        exit 198
    }
    if "`rhomethod'"=="" local rhomethod gv
    if !inlist("`rhomethod'","gv","qls") {
        di as error "rhomethod() must be gv or qls"
        exit 198
    }
    if "`rhomethod'"=="qls" & ("`solver'"!="" | "`start'"!="" | "`iterate'"!="") {
        di as error "QLS uses two stages and 300 inner iterations; omit solver(), start(), and iterate()"
        di as error "Use associterate() to limit QLS stage-one outer iterations"
        exit 198
    }
    if "`iterate'"=="" local iterate 300
    capture confirm integer number `iterate'
    if _rc exit 198
    if "`solver'"=="" local solver alternating
    if !inlist("`solver'","alternating","profile") {
        di as error "solver() must be alternating or profile"
        exit 198
    }
    if "`solver'"=="profile" & ("`start'"!="" | "`associterate'"!="" | "`rho'"!="" | "`corr'"!="exchangeable") {
        di as error "solver(profile) requires estimated exchangeable rho; start() and associterate() are alternating-only"
        exit 198
    }
    if "`start'"=="" local start .2
    capture confirm number `start'
    if _rc exit 198
    if "`associterate'"=="" local associterate=cond("`rhomethod'"=="qls",300,100)
    capture confirm integer number `associterate'
    if _rc exit 198
    if !inlist("`corr'","independent","exchangeable") {
        di as error "corr() must be independent or exchangeable"
        exit 198
    }
    if "`rho'"=="" local rho=-1
    else {
        capture confirm number `rho'
        if _rc {
            di as error "rho() must be numeric"
            exit 198
        }
        if missing(`rho') | `rho'<0 | `rho'>=1 {
            di as error "rho() must lie in [0,1); omit it to estimate nonnegative rho"
            exit 198
        }
    }
    if "`corr'"=="independent" & !inlist(`rho',-1,0) {
        di as error "independent cannot be combined with a nonzero rho()"
        exit 198
    }
    if "`corr'"=="independent" local rho=0
    if missing(`iterate',`inititerate',`associterate') | min(`iterate',`inititerate',`associterate')<1 {
        di as error "Iteration limits must be positive integers"
        exit 198
    }
    if missing(`start') | `start'<0 | `start'>=1 {
        di as error "start() must lie in [0,1)"
        exit 198
    }
    if "`rhomethod'"=="qls" local solver two_stage
    gettoken depvar rhs : varlist
    _fv_check_depvar `depvar'
    marksample scope, novarlist
    marksample touse
    markout `touse' `time'
    markout `touse' `id', strok
    ereturn clear
    quietly count if `scope'
    local N_scope=r(N)
    quietly count if `touse'
    local N=r(N)
    if `N'==0 error 2000
    tempname b V Vref cats times assoc diagnostics csum cb cse clo chi cv cr qdiag qb qtrace
    capture mata: assert(findexternal("pex20_finish()")!=NULL)
    if _rc {
        quietly findfile pearson_gv_020.do
        quietly do "`r(fn)'"
    }
    if "`rhomethod'"=="qls" {
        capture mata: assert(findexternal("pql20_fitqls()")!=NULL)
        if _rc {
            quietly findfile pearson_qls_020.do
            quietly do "`r(fn)'"
        }
        capture mata: assert(findexternal("pui20_qlsfinish()")!=NULL)
        if _rc {
            quietly findfile pearson_ui_020.do
            quietly do "`r(fn)'"
        }
    }
    preserve
    capture noisily _ordgee_pearson_dev_work `depvar' `rhs', touse(`touse') ///
        id(`id') time(`time') rho(`rho') rhomethod(`rhomethod') start(`start') solver(`solver') `strictpairs' iterate(`iterate') ///
        inititerate(`inititerate') associterate(`associterate') ///
        b(`b') v(`V') vref(`Vref') cats(`cats') times(`times') assoc(`assoc') diagnostics(`diagnostics') ///
        csum(`csum') cb(`cb') cse(`cse') clo(`clo') chi(`chi') cv(`cv') cr(`cr') qdiag(`qdiag') qb(`qb') qtrace(`qtrace')
    local rc=_rc
    restore
    if `rc' {
        ereturn clear
        exit `rc'
    }
    ereturn post `b' `V', esample(`touse') obs(`N') depname(`depvar')
    if "`rhomethod'"!="qls" ereturn matrix V_repolr=`Vref'
    if "`rhomethod'"=="qls" {
        ereturn scalar qls_a0=`qdiag'[1,1]
        ereturn scalar qls_kkt=`qdiag'[1,2]
        ereturn scalar qls_stage1_boundary=`qdiag'[1,3]
        ereturn scalar qls_Q=`qdiag'[1,4]
        ereturn matrix b_stage1=`qb'
        matrix colnames `qtrace'=stage outer a0 rho score step Q_deriv Q_curv N_pairs singletons min_V_eigen min_pair bad_pairs delta_b delta_a inner_iters
        ereturn matrix qls_trace=`qtrace'
    }
    ereturn scalar N_g=`diagnostics'[1,1]
    ereturn scalar k_cat=colsof(`cats')
    ereturn scalar N_excluded=`N_scope'-`N'
    ereturn scalar N_pairs=`diagnostics'[1,2]
    ereturn scalar association_iterations=`diagnostics'[1,3]
    ereturn scalar rho=`diagnostics'[1,7]
    ereturn scalar rho_boundary=`diagnostics'[1,8]
    ereturn scalar min_pair_cell=`diagnostics'[1,9]
    ereturn scalar pair_violations=`diagnostics'[1,10]
    ereturn scalar alpha_score=`diagnostics'[1,11]
    ereturn scalar rho_curvature=`diagnostics'[1,12]
    ereturn scalar rho_candidates=`diagnostics'[1,13]
    ereturn scalar rho_invalid_grid=`diagnostics'[1,14]
    ereturn local solver "`solver'"
    ereturn scalar profile_fits=`diagnostics'[1,15]
    ereturn scalar joint_candidates=`diagnostics'[1,16]
    if "`solver'"=="profile" {
        local cnames : colfullnames e(b)
        local rn
        forvalues j=1/`=rowsof(`csum')' {
            local rn `rn' candidate`j'
        }
        matrix colnames `csum'=selected rho gee_score alpha_score curvature eigen_ratio min_cell bad_pairs N_pairs
        matrix rownames `csum'=`rn'
        ereturn matrix candidate_summary=`csum'
        foreach item in cb cse clo chi {
            matrix colnames ``item''=`cnames'
            matrix rownames ``item''=`rn'
        }
        ereturn matrix candidate_b=`cb'
        ereturn matrix candidate_se=`cse'
        ereturn matrix candidate_ll95=`clo'
        ereturn matrix candidate_ul95=`chi'
        local d=colsof(e(b))
        tempname vv vrr
        forvalues j=1/`=e(joint_candidates)' {
            local first=(`j'-1)*`d'+1
            local last=`j'*`d'
            matrix `vv'=`cv'[`first'..`last',1...]
            matrix `vrr'=`cr'[`first'..`last',1...]
            if `j'==1 {
                matrix `vv'=e(V)
                matrix `vrr'=e(V_repolr)
            }
            matrix colnames `vv'=`cnames'
            matrix rownames `vv'=`cnames'
            matrix colnames `vrr'=`cnames'
            matrix rownames `vrr'=`cnames'
            ereturn matrix V_candidate`j'=`vv'
            ereturn matrix V_repolr_candidate`j'=`vrr'
        }
    }
    ereturn local estat_cmd "ordgee_pearson_dev_estat"
    ereturn scalar rho_start=`start'
    if inlist("`solver'","profile","two_stage") ereturn scalar rho_start=.
    ereturn scalar iterations=`diagnostics'[1,4]
    ereturn scalar score=`diagnostics'[1,5]
    ereturn scalar next_step=`diagnostics'[1,6]
    ereturn scalar converged=1
    ereturn matrix categories=`cats'
    ereturn matrix times=`times'
    ereturn matrix association=`assoc'
    ereturn local depvar "`depvar'"
    ereturn local idvar "`id'"
    ereturn local timevar "`time'"
    ereturn local corr "`corr'"
    ereturn local rho_method "fixed"
    if `rho'==-1 ereturn local rho_method "admissible_local_minimum_repolr"
    if "`rhomethod'"=="qls" ereturn local rho_method "two_stage_qls"
    ereturn local rhomethod "`rhomethod'"
    if `rho'>=0 ereturn local rhomethod "fixed"
    if "`corr'"=="independent" ereturn local rhomethod "independent"
    ereturn local package_version "0.2.0"
    ereturn local cmdline `"`cmdline'"'
    ereturn local vce "robust"
    ereturn local vcetype "Robust"
    ereturn local cmd "ordgee_pearson_dev"
    * Persist categorical domains, including baseline levels, for new-data prediction.
    tempvar prediction_sample
    quietly gen byte `prediction_sample'=e(sample)
    local factors
    if "`rhs'"!="" {
        quietly fvexpand `rhs' if `prediction_sample'
        local expanded `r(varlist)'
        foreach term of local expanded {
            quietly _ms_parse_parts `term'
            if "`r(type)'"=="factor" local factors `factors' `r(name)'
            if "`r(type)'"=="interaction" {
                forvalues j=1/`r(k_names)' {
                    if !missing(r(level`j')) local factors `factors' `r(name`j')'
                }
            }
        }
    }
    local factors : list uniq factors
    local j=0
    foreach f of local factors {
        local ++j
        tempname levels
        mata: st_matrix("`levels'",uniqrows(sort(st_data(.,"`f'","`prediction_sample'"),1))')
        ereturn matrix factor_levels`j'=`levels'
    }
    ereturn local factors "`factors'"
    ereturn scalar predict_version=1
    ereturn local predict "ordgee_pearson_dev_p"
    ereturn local marginsnotok "_ALL"
    di as text "Research ordinal GEE: separable Pearson working correlation"
    di as text "Association method: " as result "`e(rhomethod)'"
    di as text "rho = " as result %9.6f e(rho) as text " (same-cutpoint indicators across visits)"
    if e(pair_violations)>0 {
        di as error "Note: implied pair tables have negative cells in " e(pair_violations) " observation pairs."
        di as error "This is a working covariance, not a valid pairwise distribution; use strictpairs to reject."
    }
    if "`solver'"=="profile" & e(joint_candidates)>1 {
        di as text e(joint_candidates) " admissible joint candidates detected; the smallest rho is selected."
        di as text "Type {stata estat candidates} to inspect candidate coefficients and intervals."
    }
    ereturn display, level(`level')
end

program define _ordgee_pearson_dev_work
    version 16.1
    syntax varlist(numeric fv min=1), TOUSE(varname) ID(varname) TIME(varname) ///
        RHO(real) RHOMethod(string) START(real) SOLVER(string) ITERate(integer) INITIterate(integer) ASSOCIterate(integer) ///
        B(name) V(name) VREF(name) CATS(name) TIMES(name) ASSOC(name) DIAGNOSTICS(name) CSUM(name) CB(name) CSE(name) CLO(name) CHI(name) CV(name) CR(name) QDIAG(name) QB(name) QTRACE(name) [STRICTPairs]
    gettoken depvar rhs : varlist
    keep if `touse'
    capture isid `id' `time'
    if _rc {
        di as error "Duplicate id-time observations in the estimation sample"
        exit 459
    }
    tempvar gid yy tt
    egen long `gid'=group(`id')
    egen long `yy'=group(`depvar')
    egen long `tt'=group(`time')
    quietly summarize `yy', meanonly
    local K=r(max)
    if `K'<3 {
        di as error "At least three observed outcome categories are required"
        exit 498
    }
    quietly summarize `tt', meanonly
    local T=r(max)
    quietly summarize `gid', meanonly
    local G=r(max)
    if `G'<2 {
        di as error "At least two independent clusters are required"
        exit 498
    }
    mata: st_matrix("`cats'",uniqrows(sort(st_data(.,"`depvar'"),1))')
    mata: st_matrix("`times'",uniqrows(sort(st_data(.,"`time'"),1))')
    local design
    local terms
    if "`rhs'"!="" {
        quietly fvexpand `rhs'
        local expanded `r(varlist)'
        foreach term of local expanded {
            quietly _ms_parse_parts `term'
            if r(omit) continue
            quietly fvrevar `term'
            local design `design' `r(varlist)'
            local terms `terms' `term'
        }
    }
    local P : word count `design'
    tempname rk initial counts phi assob
    scalar `rk'=1
    if `P'>0 mata: st_numscalar("`rk'",pex20_rank((st_data(.,tokens("`design'")),J(st_nobs(),1,1))))
    if `rk'!=`P'+1 {
        di as error "Rank-deficient design: redundant covariates or empty interaction cells"
        exit 498
    }
    if `G'<=`P'+`K'-1 {
        di as error "Too few clusters for a full-rank cluster sandwich"
        exit 498
    }
    sort `gid' `tt'
    capture quietly ologit `yy' `design', iterate(`inititerate') tolerance(1e-12) nrtolerance(1e-10)
    local rc=_rc
    if `rc' {
        di as error "Ordered-logit initialization failed"
        exit `rc'
    }
    if !e(converged) {
        di as error "Ordered-logit initialization did not converge"
        exit 430
    }
    quietly count if !e(sample)
    if r(N)>0 {
        di as error "Initialization dropped observations; separation or sample change"
        exit 498
    }
    matrix `initial'=e(b)
    tempvar repeated_n
    by `gid': gen long `repeated_n'=_N
    quietly count if `repeated_n'>1
    if r(N)==0 & `rho'!=0 {
        di as error "Exchangeable association requires at least one repeated cluster"
        exit 498
    }
    if "`rhomethod'"=="qls" {
        mata: pui20_qlsfinish("`design'","`yy'","`gid'","`initial'",`K'-1,`associterate',"`b'","`v'","`diagnostics'","`qdiag'","`qb'","`qtrace'")
    }
    else {
        mata: pex20_finish("`design'","`yy'","`gid'","`initial'",`K'-1,`rho',`iterate',`associterate',`start',"`solver'","`b'","`v'","`vref'","`diagnostics'","`csum'","`cb'","`cse'","`clo'","`chi'","`cv'","`cr'")
    }
    if "`strictpairs'"!="" & `diagnostics'[1,10]>0 {
        di as error "strictpairs: the working correlations imply negative pair-table cells"
        exit 498
    }
    matrix `assoc'=(`diagnostics'[1,7])
    local names
    forvalues j=1/`=`K'-1' {
        local names `names' cut`j':_cons
    }
    foreach term of local terms {
        local names `names' `depvar':`term'
    }
    matrix colnames `b'=`names'
    matrix colnames `v'=`names'
    matrix rownames `v'=`names'
    if "`rhomethod'"!="qls" {
        matrix colnames `vref'=`names'
        matrix rownames `vref'=`names'
    }
    else matrix colnames `qb'=`names'
    matrix colnames `assoc'=rho
end

