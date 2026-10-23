* Adapter only: E3 QLS algorithm and acceptance gates are unchanged.
version 16.1
mata:
void pui20_qlsfinish(string scalar design,string scalar y,string scalar id,
    string scalar initial,real scalar q,real scalar maxouter,
    string scalar bout,string scalar vout,string scalar diagnostics,
    string scalar qdiag,string scalar bstage,string scalar traceout)
{
    struct pql20_fit scalar f
    real matrix X,pan,H
    real colvector b
    real scalar p,kkt,rc
    string scalar reason
    X=J(st_nobs(),0,.)
    if(design!="") X=st_data(.,tokens(design))
    p=cols(X);b=st_matrix(initial)'
    if(p) b=b[p+1..p+q]\b[1..p]
    pan=panelsetup(st_data(.,id),1)
    f=pql20_fitqls(X,st_data(.,y),pan,b,q,maxouter,0)
    if(!f.ok) {
        reason="QLS failed; internal diagnostic code "+strofreal(f.code)
        if(f.code==105) reason="QLS coefficient GEE reached its 300-iteration limit"
        if(f.code==106) reason="QLS coefficient GEE backtracking failed"
        if(f.code==110) reason="QLS energy/curvature is invalid or degenerate"
        if(f.code==111) reason="QLS association requires repeated observations"
        if(f.code==112) reason="QLS has no accepted interior association solution"
        if(f.code==113) reason="QLS stage-two correction is outside [0,1)"
        if(f.code==120) reason="QLS stage-one outer iteration did not converge"
        if(f.code==121) reason="QLS final ordinary sandwich is not full-rank positive definite"
        rc=498
        if(any(f.code:==(105,106,120))) rc=430
        _error(rc,reason)
    }
    H=pql20_energies(X,st_data(.,y),pan,f.bstage,q)
    kkt=abs(f.qstage[2])/(1+sum(H[,2..3]))
    if(f.a0==0) kkt=max((0,-f.qstage[2]))/(1+sum(H[,2..3]))
    st_matrix(bout,f.b');st_matrix(vout,f.V)
    st_matrix(diagnostics,(rows(pan),f.pair[1],f.outer,f.iterations,f.score,f.step,
        f.rho,f.boundary,f.pair[2],f.pair[3],J(1,6,.)))
    st_matrix(qdiag,(f.a0,kkt,f.boundary,f.qstage[1]))
    st_matrix(bstage,f.bstage');st_matrix(traceout,f.trace)
}
end
