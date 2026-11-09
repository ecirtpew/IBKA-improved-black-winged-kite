%% 第六版: E4 光伏 5模型 x 6算法 x 30次 (修正版: 经函数句柄计算I-V曲线)
clear; clc; close all;
addpath(genpath(pwd));

models={'1DM','2DM','3DM','4DM','PMM'};
algs={'IBKA','BKA','RIME','SABO','GoldSA','PSO'};
pop=30; T=100; R=30;
numM=numel(models); numA=numel(algs);

BestPV=zeros(numM,numA,R);
AllCurves=zeros(numM,R,T,numA);
BestXs=cell(numM,numA);
t0=tic;
for mi=1:numM
    [lb,ub,dim,fobj,~]=select_PV_model(models{mi});
    for ai=1:numA
        bestf=inf;
        for r=1:R
            rng(66600000+mi*1000+r);
            [f,x,c]=feval(algs{ai},pop,T,lb,ub,dim,fobj);
            BestPV(mi,ai,r)=f;
            AllCurves(mi,r,:,ai)=c;
            if f<bestf, bestf=f; BestXs{mi,ai}=x; end
        end
    end
    fprintf('E4 %s done %.1fs\n',models{mi},toc(t0));
end
MeanCurves=mean(AllCurves,1);   % (numM,1,T,numA)

% 1DM IBKA 最优参数的 I-V / P-V 曲线数据(图4) —— 经select_PV_model返回的句柄调用
[~,~,~,fun1dm,~]=select_PV_model('1DM');
[obj,Io]=fun1dm(BestXs{1,1});
data=load('cell_data.txt'); Vm=data(:,1); Im=data(:,2);
Io=Io(:); Po=Vm.*Io;

save('e4_pv30_v6.mat','BestPV','AllCurves','MeanCurves','BestXs','Vm','Im','Io','Po','models','algs','-v7');
fprintf('===== E4 done %.1fs =====\n',toc(t0));
