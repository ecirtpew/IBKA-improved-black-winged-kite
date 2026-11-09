%% 补跑: E1b曲线 + E2敏感性 (E1已完成)
clear; clc; close all;
addpath(genpath(pwd));

algorithms = {'IBKA','BKA','GGO','OOA','ZOA','DBO','RIME','SABO'};
F = [1 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30];
dim=30; pop=30; T=500; R=30;
numF=numel(F);
t0=tic;

%% E1b: RIME/SABO收敛曲线(与v5图2种子一致)
CurvesRS = zeros(numF,2,T);
for fi=1:numF
    fn=F(fi);
    [lb,ub,~,fhd]=Get_Functions_cec2017(fn,dim);
    rng(20250000+fn); [~,~,C]=RIME(pop,T,lb,ub,dim,fhd); CurvesRS(fi,1,:)=C;
    rng(20250000+fn); [~,~,C]=SABO(pop,T,lb,ub,dim,fhd); CurvesRS(fi,2,:)=C;
    fprintf('E1b F%02d %.1fs\n',fn,toc(t0));
end
Fkey=[1 12 13 15 19 30]; numS=10;
CurvesRS_S=zeros(numel(Fkey),2,numS,T); BestRS_S=zeros(numel(Fkey),2,numS);
for k=1:numel(Fkey)
    fn=Fkey(k);
    [lb,ub,~,fhd]=Get_Functions_cec2017(fn,dim);
    for s=1:numS
        rng(77000000+fn*100+s); [f1,~,C1]=RIME(pop,T,lb,ub,dim,fhd);
        rng(77000000+fn*100+s); [f2,~,C2]=SABO(pop,T,lb,ub,dim,fhd);
        CurvesRS_S(k,1,s,:)=C1; CurvesRS_S(k,2,s,:)=C2;
        BestRS_S(k,1,s)=f1; BestRS_S(k,2,s)=f2;
    end
    fprintf('E1b-seed F%02d %.1fs\n',fn,toc(t0));
end
save('e1b_curves_rs_v6.mat','CurvesRS','CurvesRS_S','BestRS_S','Fkey','-v7');
fprintf('===== E1b done %.1fs =====\n',toc(t0));

%% E2: 参数敏感性
settings = [1.5 0.4 0.5; 1.2 0.4 0.5; 1.8 0.4 0.5; 1.5 0.2 0.5; 1.5 0.6 0.5; 1.5 0.4 0.3; 1.5 0.4 0.7];
S=size(settings,1);
BestS=zeros(numF,S,R);
for fi=1:numF
    fn=F(fi);
    [lb,ub,~,fhd]=Get_Functions_cec2017(fn,dim);
    for r=1:R
        for s=1:S
            rng(55500000+fn*1000+r);
            BestS(fi,s,r)=IBKA_p(pop,T,lb,ub,dim,fhd,settings(s,1),settings(s,2),settings(s,3));
        end
    end
    fprintf('E2 F%02d %.1fs\n',fn,toc(t0));
end
save('e2_sens_v6.mat','BestS','settings','F','-v7');
fprintf('===== E2 done %.1fs =====\n',toc(t0));
