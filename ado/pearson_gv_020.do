* Independently written from GEE and separable working-correlation equations.
* Parsons et al. (2009): estimate alpha via generalized sandwich variance.
* No R/Python runtime dependency. Parameters: cuts, then Stata-sign slopes.
version 16.1
mata:
struct pex20_eval {
    real scalar ok
    string scalar reason
    real colvector U
    real matrix B, M, Mref
}
struct pex20_fit {
    real matrix raw_candidates
    real scalar ok, rc, profilefits, jointcandidates
    string scalar reason
    real colvector b
    real matrix V, Vref
    real scalar rho, iterations, outer, score, step, boundary, alphasc, curvature, candidates, invalid
}
real scalar pex20_rank(real matrix X)
{
    real rowvector sc
    real colvector s
    sc=sqrt(colsum(X:^2)); sc=sc:+(sc:==0)
    s=svdsv(X:/sc)
    return(sum(s:>max(s)*1e-10))
}
real matrix pex20_C(real colvector b, real scalar q)
{
    return(exp(-abs(b[1..q]*J(1,q,1)-J(q,1,1)*b[1..q]')/2))
}
real matrix pex20_F(real matrix X, real colvector b, real scalar q)
{
    real colvector eta
    if(any(b[2..q]:<=b[1..q-1])) return(J(rows(X),q,.))
    eta=J(rows(X),1,0)
    if(cols(X)) eta=X*b[q+1..rows(b)]
    return(invlogit(J(rows(X),1,1)*b[1..q]':-eta))
}
struct pex20_eval scalar pex20_evaluate(real matrix X, real colvector y,
    real matrix pan, real colvector b, real scalar q, real scalar rho)
{
    struct pex20_eval scalar a
    real matrix F,C,K,R,V,D,W,E
    real colvector idx,ii,ff,zz,sd,h,ui
    real scalar g,t,n,d
    a.ok=0; a.reason="Invalid cuts, rho or boundary probabilities"
    d=rows(b); a.U=J(d,1,0); a.B=J(d,d,0); a.M=a.B; a.Mref=a.B
    if(rho<0 | rho>=1 | missing(rho)) return(a)
    F=pex20_F(X,b,q)
    if(hasmissing(F) | min(F)<=0 | max(F)>=1) return(a)
    C=pex20_C(b,q)
    for(g=1;g<=rows(pan);g++) {
        idx=(pan[g,1]::pan[g,2]); n=rows(idx)
        ff=J(n*q,1,0); zz=ff; D=J(n*q,d,0)
        for(t=1;t<=n;t++) {
            ii=((t-1)*q+1::t*q)
            ff[ii]=F[idx[t],]'; zz[ii]=(y[idx[t]]:<=(1::q))
            h=ff[ii]:*(1:-ff[ii]); D[ii,1..q]=diag(h)
            if(cols(X)) D[ii,q+1..d]=-h*X[idx[t],]
        }
        sd=sqrt(ff:*(1:-ff))
        K=(1-rho)*I(n)+rho*J(n,n,1)
        R=K#C; V=R:*(sd*sd')
        if(hasmissing(cholesky(V))) {
            a.reason="Working covariance is not positive definite"
            return(a)
        }
        W=cholsolve(V,D); ui=W'*(zz-ff)
        a.U=a.U+ui; a.B=a.B+D'*W; a.M=a.M+ui*ui'
        // Parsons/repolr: model-implied within-observation covariance;
        // observed residual cross-products between distinct observations.
        E=(zz-ff)*(zz-ff)'
        for(t=1;t<=n;t++) {
            ii=((t-1)*q+1::t*q)
            E[ii,ii]=C:*(sd[ii]*sd[ii]')
        }
        a.Mref=a.Mref+W'*E*W
    }
    if(hasmissing(cholesky(a.B))) {
        a.reason="GEE information is singular"
        return(a)
    }
    a.ok=1
    return(a)
}
real scalar pex20_logdet(real matrix A)
{
    real matrix L
    L=cholesky(A)
    if(hasmissing(L)) return(.)
    return(2*sum(ln(diagonal(L))))
}
real scalar pex20_objective(real matrix X, real colvector y, real matrix pan,
    real colvector b, real scalar q, real scalar rho)
{
    struct pex20_eval scalar a
    a=pex20_evaluate(X,y,pan,b,q,rho)
    if(!a.ok) return(.)
    return(pex20_logdet(a.Mref)-2*pex20_logdet(a.B))
}
struct pex20_cache {
    real scalar d, constantX
    real colvector sizes
    real matrix Bperp,Bpar,Mperp,Mcross,Mpar
}
struct pex20_cache scalar pex20_makecache(real matrix X,real colvector y,
    real matrix pan,real colvector b,real scalar q)
{
    struct pex20_cache scalar c
    real matrix F,C,Ci,D,T,L,H,P,E,A
    real colvector idx,ii,jj,ff,zz,sd,h
    real scalar g,t,n,k,d,same
    d=rows(b);c.d=d;c.constantX=1
    c.sizes=uniqrows(sort(pan[,2]-pan[,1]:+1,1))
    c.Bperp=c.Mperp=J(d,d,0)
    c.Bpar=c.Mcross=c.Mpar=J(rows(c.sizes)*d,d,0)
    F=pex20_F(X,b,q);C=pex20_C(b,q);Ci=cholsolve(C,I(q))
    for(g=1;g<=rows(pan);g++) {
        idx=pan[g,1]::pan[g,2];n=rows(idx)
        k=selectindex(c.sizes:==n)[1];jj=((k-1)*d+1::k*d)
        ff=zz=J(n*q,1,0);D=J(n*q,d,0)
        same=1
        if(cols(X)) same=all(X[idx,]:==J(n,1,1)*X[idx[1],])
        c.constantX=c.constantX & same
        for(t=1;t<=n;t++) {
            ii=((t-1)*q+1::t*q)
            ff[ii]=F[idx[t],]';zz[ii]=(y[idx[t]]:<=(1::q))
            h=ff[ii]:*(1:-ff[ii]);D[ii,1..q]=diag(h)
            if(cols(X)) D[ii,q+1..d]=-h*X[idx[t],]
        }
        sd=sqrt(ff:*(1:-ff));T=D:/sd;L=(I(n)#Ci)*T
        if(same) {
            H=L;P=J(n*q,d,0)
        }
        else {
            A=J(q,d,0)
            for(t=1;t<=n;t++) A=A+L[((t-1)*q+1::t*q),]
            H=J(n,1,1)#(A/n);P=L-H
        }
        E=((zz-ff):/sd)*((zz-ff):/sd)'
        for(t=1;t<=n;t++) {
            ii=((t-1)*q+1::t*q);E[ii,ii]=C
        }
        c.Bperp=c.Bperp+T'*P;c.Bpar[jj,]=c.Bpar[jj,]+T'*H
        c.Mperp=c.Mperp+P'*E*P
        c.Mcross[jj,]=c.Mcross[jj,]+P'*E*H+H'*E*P
        c.Mpar[jj,]=c.Mpar[jj,]+H'*E*H
    }
    return(c)
}
real rowvector pex20_profile(struct pex20_cache scalar c,real scalar rho)
{
    real matrix B,Bp,Bpp,M,Mp,Mpp,iB,iM,GB,GM
    real colvector jj
    real scalar k,n,a,ap,app,den
    if(rho<0 | rho>=1 | missing(rho)) return(J(1,3,.))
    B=c.Bperp;M=c.Mperp;Bp=Bpp=Mp=Mpp=J(c.d,c.d,0)
    for(k=1;k<=rows(c.sizes);k++) {
        n=c.sizes[k];jj=((k-1)*c.d+1::k*c.d);den=1+(n-1)*rho
        if(c.constantX) {
            a=1/den;ap=-(n-1)/den^2;app=2*(n-1)^2/den^3
        }
        else {
            a=(1-rho)/den;ap=-n/den^2;app=2*n*(n-1)/den^3
        }
        B=B+a*c.Bpar[jj,];Bp=Bp+ap*c.Bpar[jj,];Bpp=Bpp+app*c.Bpar[jj,]
        M=M+a*c.Mcross[jj,]+a^2*c.Mpar[jj,]
        Mp=Mp+ap*c.Mcross[jj,]+2*a*ap*c.Mpar[jj,]
        Mpp=Mpp+app*c.Mcross[jj,]+2*(ap^2+a*app)*c.Mpar[jj,]
    }
    if(hasmissing(cholesky(B)) | hasmissing(cholesky(M))) return(J(1,3,.))
    iB=cholsolve(B,I(c.d));iM=cholsolve(M,I(c.d));GB=iB*Bp;GM=iM*Mp
    return((pex20_logdet(M)-2*pex20_logdet(B),trace(GM)-2*trace(GB),
      trace(iM*Mpp-GM*GM)-2*trace(iB*Bpp-GB*GB)))
}
real scalar pex20_stationary(struct pex20_cache scalar c, real scalar lo, real scalar hi)
{
    real scalar j,x,next
    real rowvector v
    x=(lo+hi)/2
    for(j=1;j<=60;j++) {
        v=pex20_profile(c,x)
        if(hasmissing(v)) return(.)
        if(abs(v[2])<1e-9) break
        if(v[2]<0) lo=x
        else hi=x
        next=(lo+hi)/2
        if(v[3]>0) {
            if(x-v[2]/v[3]>lo & x-v[2]/v[3]<hi) next=x-v[2]/v[3]
        }
        if(abs(next-x)<1e-12) break
        x=next
    }
    v=pex20_profile(c,x)
    if(hasmissing(v) | abs(v[2])>1e-6 | v[3]<=1e-6) return(.)
    return(x)
}
real rowvector pex20_search(struct pex20_cache scalar c)
{
    real colvector grid,valid,values
    real matrix prof,candidates
    real rowvector v,w
    real scalar j,x,best,bad
    grid=(0::100)/100*(1-1e-6); prof=J(101,3,.)
    for(j=1;j<=101;j++) prof[j,]=pex20_profile(c,grid[j])
    valid=selectindex(prof[,1]:<.); bad=101-rows(valid)
    if(rows(valid)<2) _error(498,"No adequate positive-definite region for rho estimation")
    values=prof[valid,1]
    if(max(values)-min(values)<1e-9)
        _error(498,"rho is not identified by the generalized-variance criterion; use fixed rho()")
    candidates=J(0,4,.)
    v=prof[1,]; w=pex20_profile(c,1e-5)
    if(!hasmissing(v) & !hasmissing(w)) {
        if(v[2]>=-1e-8 & (v[2]>1e-6 | v[3]>1e-6) & w[1]>=v[1]-1e-10)
            candidates=candidates\(0,v)
    }
    for(j=1;j<101;j++) {
        if(!hasmissing(prof[j,]) & !hasmissing(prof[j+1,])) {
            if(prof[j,2]<=0 & prof[j+1,2]>=0) {
                x=pex20_stationary(c,grid[j],grid[j+1])
                if(x<. & x>0 & x<1-2e-6) {
                    v=pex20_profile(c,x)
                    candidates=candidates\(x,v)
                }
            }
        }
    }
    if(!rows(candidates))
        _error(498,"No admissible rho minimum: inspect flat, boundary-seeking or non-PD objective")
    best=1
    for(j=2;j<=rows(candidates);j++) if(candidates[j,2]<candidates[best,2]) best=j
    return((candidates[best,1],rows(candidates),bad,candidates[best,4]))
}

real rowvector pex20_softsearch(struct pex20_cache scalar c)
{
    real colvector grid,valid,values
    real matrix prof,candidates
    real rowvector v,w
    real scalar j,x,best,bad
    grid=(0::100)/100*(1-1e-6); prof=J(101,3,.)
    for(j=1;j<=101;j++) prof[j,]=pex20_profile(c,grid[j])
    valid=selectindex(prof[,1]:<.); bad=101-rows(valid)
    if(rows(valid)<2) return(J(1,4,.))
    values=prof[valid,1]
    if(max(values)-min(values)<1e-9)
        return(J(1,4,.))
    candidates=J(0,4,.)
    v=prof[1,]; w=pex20_profile(c,1e-5)
    if(!hasmissing(v) & !hasmissing(w)) {
        if(v[2]>=-1e-8 & (v[2]>1e-6 | v[3]>1e-6) & w[1]>=v[1]-1e-10)
            candidates=candidates\(0,v)
    }
    for(j=1;j<101;j++) {
        if(!hasmissing(prof[j,]) & !hasmissing(prof[j+1,])) {
            if(prof[j,2]<=0 & prof[j+1,2]>=0) {
                x=pex20_stationary(c,grid[j],grid[j+1])
                if(x<. & x>0 & x<1-2e-6) {
                    v=pex20_profile(c,x)
                    candidates=candidates\(x,v)
                }
            }
        }
    }
    if(!rows(candidates))
        return(J(1,4,.))
    best=1
    for(j=2;j<=rows(candidates);j++) if(candidates[j,2]<candidates[best,2]) best=j
    return((candidates[best,1],rows(candidates),bad,candidates[best,4]))
}

struct pex20_fit scalar pex20_tryfixed(real matrix X, real colvector y, real matrix pan,
    real colvector b0, real scalar q, real scalar rho, real scalar maxiter)
{
    struct pex20_eval scalar a,c
    struct pex20_fit scalar o
    real colvector b,bb,delta
    real matrix ib
    real scalar it,j,lambda,merit,cm,done
    o.ok=0; o.profilefits=0; o.jointcandidates=0
    b=b0; done=0
    a=pex20_evaluate(X,y,pan,b,q,rho)
    if(!a.ok) {
        o.rc=498; o.reason=a.reason
        return(o)
    }
    for(it=1;it<=maxiter;it++) {
        delta=cholsolve(a.B,a.U)
        if(max(abs(a.U))<1e-8 & max(abs(delta))<1e-10) {
            done=1
            break
        }
        merit=quadcross(a.U,delta); lambda=1
        for(j=1;j<=30;j++) {
            bb=b+lambda*delta
            c=pex20_evaluate(X,y,pan,bb,q,rho)
            if(c.ok) {
                cm=quadcross(c.U,cholsolve(c.B,c.U))
                if(cm<merit | max(abs(c.U))<1e-8) break
            }
            lambda=lambda/2
        }
        if(j>30) {
            o.rc=430; o.reason="Pearson GEE backtracking failed"
            return(o)
        }
        b=bb; a=c
    }
    if(!done) {
        o.rc=430; o.reason="Pearson GEE did not converge"
        return(o)
    }
    ib=cholsolve(a.B,I(rows(b)))
    o.b=b; o.V=ib*a.M*ib; o.Vref=ib*a.Mref*ib; o.rho=rho
    o.score=max(abs(a.U)); o.step=max(abs(delta)); o.iterations=it-1
    o.outer=0; o.boundary=0; o.alphasc=.; o.curvature=.; o.candidates=.; o.invalid=.
    o.ok=1; o.rc=0
    return(o)
}
struct pex20_fit scalar pex20_fixed(real matrix X, real colvector y, real matrix pan,
    real colvector b0, real scalar q, real scalar rho, real scalar maxiter)
{
    struct pex20_fit scalar o
    o=pex20_tryfixed(X,y,pan,b0,q,rho,maxiter)
    if(!o.ok) _error(o.rc,o.reason)
    return(o)
}
struct pex20_fit scalar pex20_estimate(real matrix X, real colvector y, real colvector id,
    real colvector b0, real scalar q, real scalar fixedrho, real scalar maxiter,
    real scalar maxouter, real scalar start)
{
    struct pex20_cache scalar cache
    real rowvector search, profile
    struct pex20_fit scalar o
    real matrix pan
    real colvector b
    real scalar rho,newrho,it,nit,done,maxbad
    pan=panelsetup(id,1)
    if(fixedrho>=0) return(pex20_fixed(X,y,pan,b0,q,fixedrho,maxiter))
    b=b0; rho=start; nit=0; done=0; maxbad=0
    for(it=1;it<=maxouter;it++) {
        o=pex20_fixed(X,y,pan,b,q,rho,maxiter); nit=nit+o.iterations
        cache=pex20_makecache(X,y,pan,o.b,q)
        search=pex20_search(cache); newrho=search[1]; maxbad=max((maxbad,search[3]))
        if(newrho>=1-2e-6) _error(430,"rho optimization reached the upper numerical boundary")
        if(abs(newrho-rho)<1e-7 & max(abs(o.b-b))<1e-7) {
            done=1
            break
        }
        b=o.b; rho=(rho+newrho)/2
    }
    if(!done) _error(430,"Joint coefficient/rho iteration did not converge")
    o=pex20_fixed(X,y,pan,o.b,q,newrho,maxiter)
    o.outer=it; o.iterations=nit+o.iterations; o.boundary=(newrho==0)
    cache=pex20_makecache(X,y,pan,o.b,q)
    search=pex20_search(cache); profile=pex20_profile(cache,newrho)
    if(abs(search[1]-newrho)>1e-6 | hasmissing(profile))
        _error(430,"Final rho minimum is not stable after coefficient refit")
    if(newrho>0 & (abs(profile[2])>1e-5 | profile[3]<=1e-6))
        _error(430,"Final rho stationarity/curvature check failed")
    if(newrho==0 & profile[2]<-1e-6) _error(430,"Final lower-boundary derivative check failed")
    o.alphasc=profile[2]; o.curvature=profile[3]
    o.candidates=search[2]; o.invalid=max((maxbad,search[3]))
    return(o)
}
// Solve the joint GEE / partial-alpha score conditions by profiling beta.
// This is not minimization of f(beta(rho),rho).
real rowvector pex20_atrho(real matrix X, real colvector y, real matrix pan,
    real colvector b0, real scalar q, real scalar rho, real scalar maxiter)
{
    struct pex20_fit scalar o
    struct pex20_cache scalar c
    real rowvector v
    o=pex20_tryfixed(X,y,pan,b0,q,rho,maxiter)
    if(!o.ok) return(J(1,3+rows(b0),.))
    c=pex20_makecache(X,y,pan,o.b,q); v=pex20_profile(c,rho)
    return((v,o.b'))
}
real scalar pex20_jointcandidate(real matrix X, real colvector y, real matrix pan,
    real colvector b, real scalar q, real scalar rho, real rowvector v)
{
    struct pex20_cache scalar c
    struct pex20_eval scalar a
    real rowvector s,ev
    real matrix ib,Vr,V
    if(hasmissing(v) | rho>=1-2e-6) return(0)
    if(rho>0 & (abs(v[2])>=1e-5 | v[3]<=1e-6)) return(0)
    if(rho==0 & v[2]<-1e-6) return(0)
    c=pex20_makecache(X,y,pan,b,q); s=pex20_softsearch(c)
    if(hasmissing(s) | abs(s[1]-rho)>=1e-6) return(0)
    a=pex20_evaluate(X,y,pan,b,q,rho)
    if(!a.ok | max(abs(a.U))>=1e-8) return(0)
    ib=cholsolve(a.B,I(rows(b))); Vr=ib*a.Mref*ib
    V=ib*a.M*ib
    if(hasmissing(cholesky(V)) | pex20_rank(V)<rows(b)) return(0)
    if(hasmissing(cholesky(Vr))) return(0)
    ev=symeigenvalues((Vr+Vr')/2)
    if(min(ev)/max(ev)<=1e-8) return(0)
    return(1)
}
struct pex20_fit scalar pex20_jointprofile(real matrix X, real colvector y,
    real matrix pan, real colvector b0, real scalar q, real scalar maxiter)
{
    struct pex20_fit scalar o
    struct pex20_cache scalar c
    real colvector grid
    real matrix vals,candidates
    real rowvector v,s
    real scalar j,k,lo,hi,gl,x,valid,nfits,nroots
    grid=(0::40)/40*(1-1e-6); vals=J(41,3+rows(b0),.)
    nfits=0; nroots=0; candidates=J(0,1+3+rows(b0),.)
    for(j=1;j<=41;j++) {
        vals[j,]=pex20_atrho(X,y,pan,b0,q,grid[j],maxiter); nfits++
    }
    if(!hasmissing(vals[1,])) {
        v=vals[1,]
        if(pex20_jointcandidate(X,y,pan,v[4..cols(v)]',q,0,v[1..3]))
            candidates=candidates\(0,v)
    }
    for(j=1;j<=41;j++) {
        if(grid[j]>0 & !hasmissing(vals[j,]) & abs(vals[j,2])<1e-7) {
            v=vals[j,]
            if(pex20_jointcandidate(X,y,pan,v[4..cols(v)]',q,grid[j],v[1..3]))
                candidates=candidates\(grid[j],v)
        }
        if(j==41) continue
        if(hasmissing(vals[j,]) | hasmissing(vals[j+1,])) continue
        if(vals[j,2]*vals[j+1,2]>=0) continue
        lo=grid[j]; hi=grid[j+1]; gl=vals[j,2]; valid=1
        for(k=1;k<=60;k++) {
            x=(lo+hi)/2
            v=pex20_atrho(X,y,pan,b0,q,x,maxiter); nfits++
            if(hasmissing(v)) {
                valid=0
                break
            }
            if(abs(v[2])<1e-7 | hi-lo<1e-12) break
            if(gl*v[2]<=0) hi=x
            else {
                lo=x; gl=v[2]
            }
        }
        if(valid & pex20_jointcandidate(X,y,pan,v[4..cols(v)]',q,x,v[1..3]))
            candidates=candidates\(x,v)
    }
    if(!rows(candidates))
        _error(498,"Profile solver found no admissible joint GEE/rho candidate")
    candidates=sort(candidates,1)
    // Deduplicate candidates found both at a node and in a neighboring bracket.
    nroots=1
    for(j=2;j<=rows(candidates);j++)
        if(abs(candidates[j,1]-candidates[j-1,1])>1e-6) nroots++
    x=candidates[1,1]
    o=pex20_fixed(X,y,pan,b0,q,x,maxiter); nfits++
    c=pex20_makecache(X,y,pan,o.b,q); v=pex20_profile(c,x)
    if(!pex20_jointcandidate(X,y,pan,o.b,q,x,v))
        _error(430,"Profile candidate failed final independent refit check")
    s=pex20_softsearch(c)
    o.alphasc=v[2];o.curvature=v[3];o.candidates=s[2];o.invalid=s[3]
    o.boundary=(x==0);o.outer=0;o.profilefits=nfits;o.jointcandidates=nroots
    o.raw_candidates=candidates
    return(o)
}

real rowvector pex20_pairdiagnostic(real matrix X, real matrix pan,
    real colvector b, real scalar q, real scalar rho)
{
    real matrix F,C,H,P
    real colvector p,r,sp,sr,idx
    real scalar g,t,s,j,k,minimum,bad,np,mc
    F=pex20_F(X,b,q); C=pex20_C(b,q); minimum=.; bad=0; np=0
    for(g=1;g<=rows(pan);g++) {
        idx=pan[g,1]::pan[g,2]
        for(t=2;t<=rows(idx);t++) for(s=1;s<t;s++) {
            p=F[idx[t],]'; r=F[idx[s],]'
            sp=sqrt(p:*(1:-p)); sr=sqrt(r:*(1:-r))
            H=J(q+2,q+2,0)
            H[2..q+1,2..q+1]=p*r'+rho*C:*(sp*sr')
            H[2..q+1,q+2]=p; H[q+2,2..q+1]=r'; H[q+2,q+2]=1
            P=J(q+1,q+1,0)
            for(j=1;j<=q+1;j++) for(k=1;k<=q+1;k++)
                P[j,k]=H[j+1,k+1]-H[j,k+1]-H[j+1,k]+H[j,k]
            mc=min(P); minimum=min((minimum,mc)); bad=bad+(mc< -1e-10); np++
        }
    }
    return((np,minimum,bad))
}
// Summaries of already accepted profile candidates; no new root search or GEE fit.
void pex20_candidatetables(real matrix X, real colvector y, real matrix pan,
    struct pex20_fit scalar o, real scalar q, string scalar summaryout,
    string scalar cbout,string scalar seout,string scalar loout,string scalar hiout,
    string scalar cvout,string scalar crout)
{
    struct pex20_eval scalar a
    struct pex20_cache scalar cache
    real matrix raw,summary,cb,se,cv,cr,V,Vr,ib
    real colvector keep,b
    real rowvector check,pr,ev
    real scalar j,k,d,m,rho,z
    raw=o.raw_candidates; keep=1
    for(j=2;j<=rows(raw);j++)
        if(abs(raw[j,1]-raw[j-1,1])>1e-6) keep=keep\j
    raw=raw[keep,]; m=rows(raw);d=rows(o.b)
    if(m!=o.jointcandidates) _error(498,"Candidate count mismatch in reporting")
    summary=J(m,9,.); cb=J(m,d,.);se=cb; cv=J(m*d,d,.);cr=cv
    for(j=1;j<=m;j++) {
        rho=raw[j,1];b=raw[j,5..cols(raw)]'
        if(j==1) {
            b=o.b;rho=o.rho;V=o.V;Vr=o.Vref
        }
        else {
            a=pex20_evaluate(X,y,pan,b,q,rho)
            if(!a.ok) _error(498,"Candidate table evaluation failed")
            ib=cholsolve(a.B,I(d));V=ib*a.M*ib;Vr=ib*a.Mref*ib
        }
        a=pex20_evaluate(X,y,pan,b,q,rho)
        cache=pex20_makecache(X,y,pan,b,q);pr=pex20_profile(cache,rho)
        check=pex20_pairdiagnostic(X,pan,b,q,rho)
        ev=symeigenvalues((Vr+Vr')/2)
        summary[j,]=(j==1,rho,max(abs(a.U)),pr[2],pr[3],min(ev)/max(ev),check[2],check[3],check[1])
        cb[j,]=b';se[j,]=sqrt(diagonal(V))'
        cv[((j-1)*d+1..j*d),]=V;cr[((j-1)*d+1..j*d),]=Vr
    }
    z=invnormal(.975)
    st_matrix(summaryout,summary);st_matrix(cbout,cb);st_matrix(seout,se)
    st_matrix(loout,cb-z*se);st_matrix(hiout,cb+z*se)
    st_matrix(cvout,cv);st_matrix(crout,cr)
}

void pex20_finish(string scalar design, string scalar y, string scalar id,
    string scalar initial, real scalar q, real scalar rho, real scalar maxiter,
    real scalar maxouter,real scalar start,string scalar solver,string scalar bout,string scalar vout,string scalar refout,string scalar diagnostics,
    string scalar summaryout,string scalar cbout,string scalar seout,string scalar loout,
    string scalar hiout,string scalar cvout,string scalar crout)
{
    struct pex20_fit scalar o
    real matrix X,pan
    real colvector b,ids
    real rowvector check
    real scalar p
    X=J(st_nobs(),0,.)
    if(design!="") X=st_data(.,tokens(design))
    p=cols(X); b=st_matrix(initial)'
    if(p) b=b[p+1..p+q]\b[1..p]
    ids=st_data(.,id); pan=panelsetup(ids,1)
    if(solver=="profile") o=pex20_jointprofile(X,st_data(.,y),pan,b,q,maxiter)
    else o=pex20_estimate(X,st_data(.,y),ids,b,q,rho,maxiter,maxouter,start)
    if(hasmissing(cholesky(o.V)) | pex20_rank(o.V)<rows(b))
        _error(498,"Final cluster sandwich is rank deficient")
    if(solver=="profile") pex20_candidatetables(X,st_data(.,y),pan,o,q,
        summaryout,cbout,seout,loout,hiout,cvout,crout)
    check=pex20_pairdiagnostic(X,pan,o.b,q,o.rho)
    st_matrix(bout,o.b'); st_matrix(vout,o.V); st_matrix(refout,o.Vref)
    st_matrix(diagnostics,(rows(pan),check[1],o.outer,o.iterations,o.score,o.step,
        o.rho,o.boundary,check[2],check[3],o.alphasc,o.curvature,o.candidates,o.invalid,o.profilefits,o.jointcandidates))
}
end
