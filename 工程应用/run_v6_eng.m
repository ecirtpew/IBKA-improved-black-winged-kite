%% 第六版: E3 约束工程 3问题 x 6算法 x 30次
clear; clc; close all;
addpath(genpath(pwd));

probs={'F1','F2','F3'};
algs={'IBKA','BKA','RIME','SABO','GoldSA','PSO'};
pop=30; T=500; R=30;

BestE=zeros(3,6,R);
BestX=cell(3,6);
t0=tic;
for pp=1:3
    [lb,ub,dim,fobj]=Get_Functions_details(probs{pp});
    for ai=1:6
        bestf=inf;
        for r=1:R
            rng(77700000+pp*1000+r);
            [f,x]=feval(algs{ai},pop,T,lb,ub,dim,fobj);
            BestE(pp,ai,r)=f;
            if f<bestf, bestf=f; BestX{pp,ai}=x; end
        end
    end
    fprintf('E3 %s done %.1fs\n',probs{pp},toc(t0));
end
save('e3_eng30_v6.mat','BestE','BestX','probs','algs','-v7');
fprintf('===== E3 done %.1fs =====\n',toc(t0));
