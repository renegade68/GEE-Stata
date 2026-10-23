*! Pearson research prediction 0.1.1 22oct2026; interface reused from LOR 0.2.1
program define ordgee_pearson_dev_p
    version 16.1
    if "`e(cmd)'"!="ordgee_pearson_dev" error 301
    if e(predict_version)!=1 {
        di as error "Refit with ordgee_pearson_dev 0.1.1 or later to store prediction metadata"
        exit 498
    }
    local requested_type : word 1 of `0'
    syntax newvarlist(min=1) [if] [in] [, PR XB OUTcome(string)]
    local n : word count `varlist'
    * One leading storage type applies to all requested predictions.
    if inlist("`requested_type'","float","double") {
        local typlist
        forvalues j=1/`n' {
            local typlist `typlist' `requested_type'
        }
    }
    local K=e(k_cat)
    local q=`K'-1
    foreach typ of local typlist {
        if !inlist("`typ'","float","double") {
            di as error "Prediction variables must be float or double"
            exit 198
        }
    }
    if "`xb'"!="" & ("`pr'"!="" | "`outcome'"!="" | `n'!=1) {
        di as error "xb requires one new variable and cannot be combined with pr or outcome()"
        exit 198
    }
    local first=1
    local last=`K'
    if "`xb'"!="" local last=1
    else if `n'==1 {
        if "`outcome'"=="" local outcome #1
        if substr("`outcome'",1,1)=="#" {
            local rank=substr("`outcome'",2,.)
            capture confirm integer number `rank'
            if _rc {
                di as error "outcome(#j) requires an integer category rank"
                exit 198
            }
            if missing(`rank') | `rank'<1 | `rank'>`K' {
                di as error "Category rank is outside the fitted outcome range"
                exit 198
            }
            local first=`rank'
        }
        else {
            capture confirm number `outcome'
            if _rc {
                di as error "outcome() requires an observed numeric outcome code or #rank"
                exit 198
            }
            local first=0
            forvalues j=1/`K' {
                if `outcome'==e(categories)[1,`j'] local first=`j'
            }
            if `first'==0 {
                di as error "Outcome code was not observed in the estimation sample"
                exit 198
            }
        }
        local last=`first'
    }
    else if `n'!=`K' | "`outcome'"!="" {
        di as error "Specify one variable with outcome(), or exactly `K' variables for all probabilities"
        exit 198
    }
    marksample touse, novarlist
    tempname b
    matrix `b'=e(b)
    local names : colnames `b'
    local terms
    local d=colsof(`b')
    if `d'>`q' {
        forvalues j=`K'/`d' {
            local term : word `j' of `names'
            local terms `terms' `term'
        }
    }
    * Only covariates are required; y/id/time are unnecessary unless in the mean model.
    if "`terms'"!="" {
        quietly fvrevar `terms', list
        markout `touse' `r(varlist)'
    }
    if "`e(factors)'"!="" markout `touse' `e(factors)'
    local j=0
    foreach f in `e(factors)' {
        local ++j
        tempvar known
        quietly gen byte `known'=0
        forvalues k=1/`=colsof(e(factor_levels`j'))' {
            quietly replace `known'=1 if `f'==e(factor_levels`j')[1,`k']
        }
        quietly count if `touse' & !`known'
        if r(N)>0 {
            di as error "`f' contains a factor level not observed in the estimation sample"
            exit 498
        }
    }
    tempvar eta
    quietly gen double `eta'=0 if `touse'
    local j=`q'
    foreach term of local terms {
        local ++j
        quietly fvrevar `term' if `touse'
        local x `r(varlist)'
        quietly replace `eta'=`eta'+`b'[1,`j']*`x' if `touse'
    }
    quietly count if `touse' & missing(`eta')
    if r(N)>0 {
        di as error "Nonfinite linear prediction; check covariate magnitudes"
        exit 498
    }
    * Compute temporary outputs first; leave no partial user outputs on failure.
    local outputs
    local nout=0
    forvalues j=`first'/`last' {
        local ++nout
        local typ : word `nout' of `typlist'
        tempvar out
        if "`xb'"!="" {
            quietly gen `typ' `out'=`eta' if `touse'
            label variable `out' "Linear prediction (cutpoints excluded)"
        }
        else {
            if `j'==1 quietly gen `typ' `out'=invlogit(`b'[1,1]-`eta') if `touse'
            else if `j'==`K' quietly gen `typ' `out'=invlogit(`eta'-`b'[1,`q']) if `touse'
            else {
                local prev=`j'-1
                tempname gap attenuation
                scalar `gap'=`b'[1,`j']-`b'[1,`prev']
                * Stable form of F(c_j-eta)-F(c_(j-1)-eta), also in the tails.
                scalar `attenuation'=cond(`gap'<1e-5, ///
                    `gap'*(1-`gap'/2+`gap'^2/6-`gap'^3/24),1-exp(-`gap'))
                quietly gen `typ' `out'=invlogit(`b'[1,`j']-`eta')* ///
                    invlogit(`eta'-`b'[1,`prev'])*`attenuation' if `touse'
            }
            local code : display %24.16g e(categories)[1,`j']
            local code=strtrim("`code'")
            label variable `out' "Pr(`e(depvar)'==`code')"
        }
        local outputs `outputs' `out'
    }
    rename (`outputs') (`varlist')
end
