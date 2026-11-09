function [Fgbest,Xgbest,Convergence_curve,Kk] = PSO(pop,M,lb,ub,dim,fobj)
c1 = 1.49445;
c2 = 1.49445;
Vmax = 2;   %速度的范围，超过则用边界值。
Vmin = -2;
V=rand(pop,dim)*(Vmax-Vmin)+Vmin;
POS=zeros(pop,dim);
Fit=zeros(1,pop);
Fgbest=inf;
while Fgbest==inf
    for i=1:pop
        POS(i,:)=rand(1,dim).*(ub-lb)+lb;
        Fit(i)=fobj(POS(i,:));
        if Fit(i)<Fgbest
            Xgbest=POS(i,:);
            Fgbest=Fit(i);
        end
    end
end
Pbest=POS;%个体最优
PbestFit=Fit;
tic
for t=1:M
    for i=1:pop
        V(i,:)=V(i,:)+c1.*rand(1,dim).*(Pbest(i,:)-POS(i,:))+c2.*rand(1,dim).*(Xgbest-POS(i,:));
        V(i,:)=max(V(i,:),Vmin);
        V(i,:)=min(V(i,:),Vmax);
        POS(i,:)=POS(i,:)+V(i,:);
        POS(i,:)=max(POS(i,:),lb);
        POS(i,:)=min(POS(i,:),ub);
        Fit(i)=fobj(POS(i,:));
    if Fit(i)<Fgbest
        Xgbest=POS(i,:);
        Fgbest=Fit(i);
    end  
     if Fit(i)<PbestFit(i)
        Pbest(i,:)=POS(i,:);
        PbestFit(i)=Fit(i);
    end  
    end
    Convergence_curve(t)=Fgbest;
end
Kk=toc;
end