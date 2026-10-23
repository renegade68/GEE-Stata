* Research QLS prototype 0.0.1, 23oct2026. Not a distribution command.
* Mean algebra adapted from local pex13; QLS independently implemented from equations.
* Parameters: cutpoints first, then Stata-sign slopes. No Mref/GV calculation.
version 16.1
mata:
struct pql20_eval {
    real scalar ok, code
    real colvector U
    real matrix B, M
}
struct pql20_fit {
    real scalar ok, code, iterations, outer, score, step, a0, rho, boundary
    real colvector b, bstage
    real matrix V, trace
    real rowvector pair, qstage
}
real scalar pql20_rank(real matrix A)
{
    real rowvector s
    real colvector v
    s=sqrt(colsum(A:^2)); s=s:+(s:==0)
    v=svdsv(A:/s)
    return(sum(v:>max(v)*1e-10))
}
real matrix pql20_C(real colvector b, real scalar q)
{
    return(exp(-abs(b[1..q]*J(1,q,1)-J(q,1,1)*b[1..q]')/2))
}
real matrix pql20_F(real matrix X, real colvector b, real scalar q)
{
    real colvector eta
    if(q>1) if(any(b[2..q]:<=b[1..q-1])) return(J(rows(X),q,.))
    eta=J(rows(X),1,0)
    if(cols(X)) eta=X*b[q+1..rows(b)]
    return(invlogit(J(rows(X),1,1)*b[1..q]':-eta))
}
struct pql20_eval scalar pql20_evaluate(real matrix X, real colvector y,
    real matrix pan, real colvector b, real scalar q, real scalar rho)
{
    struct pql20_eval scalar a
    real matrix F,C,V,D,W
    real colvector idx,ii,ff,zz,sd,h,ui
    real scalar g,t,n,d
    a.ok=0; a.code=101
    d=rows(b); a.U=J(d,1,0); a.B=J(d,d,0); a.M=a.B
    if(rho<0 | rho>=1 | missing(rho)) return(a)
    F=pql20_F(X,b,q)
    if(hasmissing(F) | min(F)<=0 | max(F)>=1) {
         a.code=102; return(a)
    }
    C=pql20_C(b,q)
    for(g=1;g<=rows(pan);g++) {
        idx=pan[g,1]::pan[g,2]; n=rows(idx)
        ff=J(n*q,1,0); zz=ff; D=J(n*q,d,0)
        for(t=1;t<=n;t++) {
            ii=((t-1)*q+1::t*q)
            ff[ii]=F[idx[t],]'; zz[ii]=(y[idx[t]]:<=(1::q))
            h=ff[ii]:*(1:-ff[ii]); D[ii,1..q]=diag(h)
            if(cols(X)) D[ii,q+1..d]=-h*X[idx[t],]
        }
        sd=sqrt(ff:*(1:-ff))
        V=(((1-rho)*I(n)+rho*J(n,n,1))#C):*(sd*sd')
        if(hasmissing(cholesky(V))) {
             a.code=103; return(a)
        }
        W=cholsolve(V,D); ui=W'*(zz-ff)
        a.U=a.U+ui; a.B=a.B+D'*W; a.M=a.M+ui*ui'
    }
    if(hasmissing(cholesky(a.B)) | pql20_rank(a.B)<d) {
         a.code=104; return(a)
    }
    a.ok=1; a.code=0
    return(a)
}
struct pql20_fit scalar pql20_fixed(real matrix X, real colvector y, real matrix pan,
    real colvector b0, real scalar q, real scalar rho, real scalar maxiter)
{
    struct pql20_fit scalar f
    struct pql20_eval scalar a,c
    real colvector b,bb,delta
    real matrix ib
    real scalar it,j,merit,cm,lambda
    f.ok=0; f.code=105; f.iterations=0; f.trace=J(0,16,.)
    b=b0; a=pql20_evaluate(X,y,pan,b,q,rho)
    if(!a.ok) {
         f.code=a.code; return(f)
    }
    for(it=0;it<=maxiter;it++) {
        delta=cholsolve(a.B,a.U)
        f.score=max(abs(a.U)); f.step=max(abs(delta))
        if(f.score<1e-8 & f.step<1e-10) {
            ib=cholsolve(a.B,I(rows(b)))
            f.b=b; f.V=ib*a.M*ib; f.V=(f.V+f.V')/2
            f.iterations=it; f.rho=rho; f.code=0; f.ok=1
            return(f)
        }
        if(it==maxiter) break
        merit=(a.U'*delta)[1]; lambda=1
        for(j=1;j<=30;j++) {
            bb=b+lambda*delta; c=pql20_evaluate(X,y,pan,bb,q,rho)
            if(c.ok) {
                cm=(c.U'*cholsolve(c.B,c.U))[1]
                if(cm<merit | max(abs(c.U))<1e-8) break
            }
            lambda=lambda/2
        }
        if(j>30) {
             f.code=106; return(f)
        }
        b=bb; a=c
    }
    return(f)
}
// One row per cluster: n, orthogonal energy O, parallel energy P.
real rowvector pql20_energy(real matrix E, real matrix C)
{
    real matrix Ec
    real rowvector m
    real scalar n,O,P,tol
    n=rows(E); m=colsum(E)/n; Ec=E:-m
    O=sum(Ec:*cholsolve(C,Ec')'); P=n*(m*cholsolve(C,m'))[1]
    tol=1e-12*(1+abs(O)+abs(P))
    if(hasmissing((O,P)) | O< -tol | P< -tol) return((n,.,.))
    if(O<0) O=0
    if(P<0) P=0
    if(n==1) O=0
    return((n,O,P))
}
real matrix pql20_energies(real matrix X, real colvector y, real matrix pan,
    real colvector b, real scalar q)
{
    real matrix F,C,H,E
    real colvector ix
    real scalar g,n
    F=pql20_F(X,b,q); C=pql20_C(b,q); H=J(rows(pan),3,.)
    if(hasmissing(F) | min(F)<=0 | max(F)>=1) return(H)
    for(g=1;g<=rows(pan);g++) {
        ix=pan[g,1]::pan[g,2]; n=rows(ix)
        E=((y[ix]*J(1,q,1):<=J(n,1,1)*(1..q))-F[ix,]):/sqrt(F[ix,]:*(1:-F[ix,]))
        H[g,]=pql20_energy(E,C)
    }
    return(H)
}
real rowvector pql20_Q(real matrix H, real scalar a)
{
    real colvector m,d,O,P
    m=H[,1]:-1; d=1:+m*a; O=H[,2]; P=H[,3]
    return((sum(O/(1-a)+P:/d),sum(O/(1-a)^2-m:*P:/d:^2),
        2*sum(O/(1-a)^3+m:^2:*P:/d:^3)))
}
// Return a, boundary, status. No hidden replacement for unidentified rho.
real rowvector pql20_update(real matrix H)
{
    real scalar lo,hi,a,k,scale
    real rowvector v
    if(hasmissing(H) | min(H[,2..3])<0) return((.,.,110))
    if(max(H[,1])<=1) return((.,.,111))
    scale=1+sum(H[,2..3])
    v=pql20_Q(H,0)
    if(v[3]<=1e-12 | hasmissing(v)) return((.,.,110))
    if(v[2]>=0) return((0,1,0))
    lo=0; hi=1-1e-8; v=pql20_Q(H,hi)
    if(hasmissing(v) | v[2]<=0) return((.,.,112))
    for(k=1;k<=100;k++) {
        a=(lo+hi)/2; v=pql20_Q(H,a)
        if(abs(v[2])/scale<1e-12 | hi-lo<1e-14) return((a,0,0))
        if(v[2]<0) lo=a
        else hi=a
    }
    return((.,.,112))
}
real scalar pql20_correct(real colvector n, real scalar a)
{
    real colvector d
    real scalar den
    if(missing(a) | a<0 | a>=1) return(.)
    d=(1:+(n:-1)*a):^2
    den=sum(n:*(n:-1):*(1:+(n:-1)*a^2):/d)
    if(den<=0) return(.)
    return(sum(n:*(n:-1)*a:*(2:+(n:-2)*a):/d)/den)
}
real rowvector pql20_pairs(real matrix X, real matrix pan, real colvector b,
    real scalar q, real scalar rho)
{
    real matrix F,C,H,P
    real colvector ix,p,r,sp,sr
    real scalar g,t,s,k,l,np,mn,bad,m
    F=pql20_F(X,b,q); C=pql20_C(b,q); np=bad=0; mn=.
    for(g=1;g<=rows(pan);g++) {
        ix=pan[g,1]::pan[g,2]
        for(t=2;t<=rows(ix);t++) for(s=1;s<t;s++) {
            p=F[ix[t],]'; r=F[ix[s],]'; sp=sqrt(p:*(1:-p)); sr=sqrt(r:*(1:-r))
            H=J(q+2,q+2,0); H[2..q+1,2..q+1]=p*r'+rho*C:*(sp*sr')
            H[2..q+1,q+2]=p; H[q+2,2..q+1]=r'; H[q+2,q+2]=1
            P=H[2..q+2,2..q+2]-H[1..q+1,2..q+2]-H[2..q+2,1..q+1]+H[1..q+1,1..q+1]
            m=min(P); np++; mn=min((mn,m)); bad=bad+(m< -1e-10)
        }
    }
    return((np,mn,bad))
}
struct pql20_fit scalar pql20_fitqls(real matrix X, real colvector y, real matrix pan,
    real colvector b0, real scalar q, real scalar maxouter, real scalar strict)
{
    struct pql20_fit scalar f,h
    real matrix H,tr
    real colvector b,ns
    real rowvector upd,v,pair
    real scalar olda,a,rho,it,db,da,kkt,scale,done,ninner,mineig
    f.ok=0; f.code=120; tr=J(0,16,.); f.trace=tr
    if(q<2 | hasmissing(b0)) {
         f.code=100; return(f)
    }
    ns=pan[,2]-pan[,1]:+1
    if(max(ns)<=1) {
         f.code=111; return(f)
    }
    b=b0; olda=0; done=0; ninner=0
    for(it=1;it<=maxouter;it++) {
        H=pql20_energies(X,y,pan,b,q); upd=pql20_update(H)
        if(upd[3]) {
             f.code=upd[3]; f.trace=tr; return(f)
        }
        a=upd[1]; h=pql20_fixed(X,y,pan,b,q,a,300)
        if(!h.ok) {
             f.code=h.code; f.trace=tr; return(f)
        }
        db=max(abs(h.b-b)); da=abs(a-olda); b=h.b; ninner=ninner+h.iterations
        H=pql20_energies(X,y,pan,b,q); v=pql20_Q(H,a); scale=1+sum(H[,2..3])
        kkt=abs(v[2])/scale
        if(a==0) kkt=max((0,-v[2]))/scale
        pair=pql20_pairs(X,pan,b,q,a); mineig=min(symeigenvalues(h.V))
        tr=tr\(1,it,a,.,h.score,h.step,v[2],v[3],pair[1],sum(ns:==1),mineig,pair[2],pair[3],db,da,h.iterations)
        if(db<1e-10 & da<1e-11 & kkt<1e-10) {
             done=1; break
        }
        olda=a
    }
    f.trace=tr
    if(!done) return(f)
    f.a0=a; f.boundary=(a==0); f.outer=it; f.bstage=b; f.qstage=v
    rho=pql20_correct(ns,a)
    if(missing(rho) | rho<0 | rho>=1) {
         f.code=113; return(f)
    }
    h=pql20_fixed(X,y,pan,b,q,rho,300)
    if(!h.ok) {
         f.code=h.code; return(f)
    }
    f.b=h.b; f.V=h.V; f.rho=rho; f.score=h.score; f.step=h.step
    f.iterations=ninner+h.iterations
    if(hasmissing(cholesky(f.V)) | pql20_rank(f.V)<rows(b)) {
         f.code=121; return(f)
    }
    f.pair=pql20_pairs(X,pan,f.b,q,rho)
    v=pql20_Q(pql20_energies(X,y,pan,f.b,q),a)
    f.trace=tr\(2,it,a,rho,h.score,h.step,v[2],v[3],f.pair[1],sum(ns:==1),min(symeigenvalues(f.V)),f.pair[2],f.pair[3],max(abs(h.b-b)),0,h.iterations)
    if(strict & f.pair[3]>0) {
         f.code=122; return(f)
    }
    f.ok=1; f.code=0
    return(f)
}
void pql20_save(string scalar path, real matrix A)
{
    real scalar fh,i
    if(fileexists(path)) unlink(path)
    fh=fopen(path,"w")
    for(i=1;i<=rows(A);i++) fput(fh,invtokens(strofreal(A[i,],"%24.17g"),","))
    fclose(fh)
}
end
