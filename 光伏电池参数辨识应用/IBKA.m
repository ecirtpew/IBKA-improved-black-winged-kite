%%  Black-winged Kite Algorithm with Dual-Distribution Perturbed Adaptive Differential Mutation
function [Best_Fitness_BKA,Best_Pos_BKA,Convergence_curve]=IBKA(pop,T,lb,ub,dim,fobj)
%% ----------------Initialize the locations of Blue Sheep------------------%
p=0.9;r=rand;
XPos=initialization(pop,dim,ub,lb);% Initial population
for i =1:pop
    XFit(i)=fobj(XPos(i,:));
end
Convergence_curve=zeros(1,T);
lb = lb.*ones(1,dim);
ub = ub.*ones(1,dim);
%% -------------------Start iteration------------------------------------%
for t=1:T
    [~,sorted_indexes]=sort(XFit);
    XLeader_Pos=XPos(sorted_indexes(1),:);
    XLeader_Fit = XFit(sorted_indexes(1));
    
    %%  改进点1：质心边界控制
    Centroid = mean(XPos, 1);
    
    %% -------------------Attacking behavior-------------------%
    for i=1:pop
        n=0.05*exp(-2*(t/T)^2);
        if p<r
            XPosNew(i,:)=XPos(i,:)+n.*(1+sin(r))*XPos(i,:);
        else
            XPosNew(i,:)=XPos(i,:).*(n*(2*rand(1,dim)-1)+1);
        end
        %%  改进点X：质心边界控制
        Flag4ub = XPosNew(i,:) > ub;
        Flag4lb = XPosNew(i,:) < lb;
        XPosNew(i, Flag4ub) = (Centroid(Flag4ub) + ub(Flag4ub)) / 2;
        XPosNew(i, Flag4lb) = (Centroid(Flag4lb) + lb(Flag4lb)) / 2;
        %% ------------ Select the optimal fitness value--------------%
        XFit_New(i)=fobj(XPosNew(i,:));
        if(XFit_New(i)<XFit(i))
            XPos(i,:) = XPosNew(i,:);
            XFit(i) = XFit_New(i);
        end
        %% -------------------Migration behavior-------------------%
        m=2*sin(r+pi/2);
        s = randi([1,pop],1);
        r_XFitness=XFit(s);
        ori_value = rand(1,dim);cauchy_value = tan((ori_value-0.5)*pi);
        k=randperm(pop,1);
        Xrandom=XPos(k,:);
        if XFit(i)< r_XFitness
            %XPosNew(i,:)=XPos(i,:)+cauchy_value(:,dim).* (XPos(i,:)-XLeader_Pos);
            %%  改进点2：双体加权融合策略
            w = rand;
            XPosNew(i,:) = XPos(i,:)+cauchy_value(:,dim).*(XLeader_Pos-(w*XPos(i,:)+(1-w)*Xrandom));
        else
            XPosNew(i,:)=XPos(i,:)+cauchy_value(:,dim).* (XLeader_Pos-m.*XPos(i,:));
        end
        %%  改进点1：质心边界控制
        Flag4ub = XPosNew(i,:) > ub;
        Flag4lb = XPosNew(i,:) < lb;
        XPosNew(i, Flag4ub) = (Centroid(Flag4ub) + ub(Flag4ub)) / 2;
        XPosNew(i, Flag4lb) = (Centroid(Flag4lb) + lb(Flag4lb)) / 2;
        %% --------------  Select the optimal fitness value---------%
        XFit_New(i)=fobj(XPosNew(i,:));
        if(XFit_New(i)<XFit(i))
            XPos(i,:) = XPosNew(i,:);
            XFit(i) = XFit_New(i);
        end
    end
    
    %%  改进点3：改进的双分布扰动自适应差分变异策略
    [~, best_idx]  = min(XFit);
    [~, worst_idx] = max(XFit);
    XBest_Pos  = XPos(best_idx, :);
    XWorst_Pos = XPos(worst_idx, :);
    R_all = zeros(pop, 1);
    for i = 1:pop
        R_all(i) = norm(XBest_Pos - XPos(i,:));
    end
    Rmax = max(R_all);
    epsilon = 1e-10;
    theta = ((sqrt(5)-1) * t * pi) / 2;
    beta = 1.5;
    sigma = (gamma(1+beta)*sin(pi*beta/2) / ...
             (gamma((1+beta)/2)*beta*2^((beta-1)/2)))^(1/beta);
    for i = 1:pop
        c = (R_all(i) * (1 + 0.4*cos(theta))) / (Rmax + epsilon);
        dist_ratio = R_all(i) / (Rmax + epsilon);
        iter_ratio = t / T;
        % Levy-probability: high when far AND early; Cauchy dominates when close or late
        prob_levy = dist_ratio * (1 - 0.5 * iter_ratio);
        candidates = setdiff(1:pop, i);
        rand_idx = candidates(randperm(length(candidates), 3));
        Xr1 = XPos(rand_idx(1), :);
        Xr2 = XPos(rand_idx(2), :);
        Xr3 = XPos(rand_idx(3), :);
        if rand < prob_levy
            r5 = rand;
            u = randn(1,dim) * sigma;
            v = randn(1,dim);
            Levy = u ./ (abs(v).^(1/beta));
            X_cand = XBest_Pos + r5 * c .* Levy .* (XBest_Pos - XPos(i,:)) + ...
                     (1 - r5) * c .* Levy .* (XBest_Pos - XWorst_Pos);
        else
            r4 = rand;
            cauchy_Y = tan((rand(1,dim) - 0.5) * pi);
            X_cand = XBest_Pos + r4 * c .* cauchy_Y .* (Xr1 - Xr2) + ...
                     (1 - r4) * c .* cauchy_Y .* (Xr3 - XPos(i,:));
        end

        %%  改进点1：质心边界控制
        Flag4ub = X_cand > ub;
        Flag4lb = X_cand < lb;
        X_cand(Flag4ub) = (Centroid(Flag4ub) + ub(Flag4ub)) / 2;
        X_cand(Flag4lb) = (Centroid(Flag4lb) + lb(Flag4lb)) / 2;
        f_cand = fobj(X_cand);

        if f_cand < XFit(i)
            XPos(i,:) = X_cand;
            XFit(i)   = f_cand;
        end
    end
    
    %% -------Update the optimal Black-winged Kite----------%
    [current_best_fit, current_best_idx] = min(XFit);
    if current_best_fit < XLeader_Fit
        Best_Fitness_BKA = current_best_fit;
        Best_Pos_BKA     = XPos(current_best_idx, :);
    else
        Best_Fitness_BKA = XLeader_Fit;
        Best_Pos_BKA     = XLeader_Pos;
    end
    Convergence_curve(t) = Best_Fitness_BKA;
end
end