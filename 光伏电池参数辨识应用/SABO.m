%% 淘个代码 %%
% 2023/06/28 %
%微信公众号搜索：淘个代码
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%% Designed and Developed by Pavel Trojovský and Mohammad Dehghani %%%
function[Best_score,Best_pos,SABO_curve]=SABO(N,T,lo,hi,m,fitness)

%% INITIALIZATION

X = repmat(lo,N,1)+rand(N,m).* repmat((hi-lo),N,1);   % Initial population

for i =1:N
    L=X(i,:);
    fit(i)=fitness(L);
end
%%

for t=1:T  % algorithm iteration
    
    %%  update: BEST proposed solution
    [Fbest , blocation]=min(fit);
    if t==1
        xbest=X(blocation,:);                                           % Optimal location
        fbest=Fbest;                                           % The optimization objective function
    elseif Fbest<fbest
        fbest=Fbest;
        xbest=X(blocation,:);
    end
    %%
    DX=zeros(N,m);  
    for i=1:N
        %% based om Eq(4)
        for j=1:N
            I=round(1+rand+rand);
            for d=1:m
                DX(i,d)=DX(i,d)+(X(j,d)-I.*X(i,d)).*sign(fit(i)-fit(j));
            end
        end
        X_new_P1= X(i,:)+((rand(1,m).*DX(i,:))./(N));
        
        Flag4ub=X_new_P1>hi;
        Flag4lb=X_new_P1<lo;
        X_new_P1=(X_new_P1.*(~(Flag4ub+Flag4lb)))+hi.*Flag4ub+lo.*Flag4lb;
        
        
        %% update position based on Eq (5)
        L=X_new_P1;
        fit_new_P1=fitness(L);
        if fit_new_P1<fit(i)
            X(i,:) = X_new_P1;
            fit(i) = fit_new_P1;
        end
        %%            
    end% end for i=1:N
    %%
    
    best_so_far(t)=fbest;
    average(t) = mean (fit);
    
end
Best_score=fbest;
Best_pos=xbest;
SABO_curve=best_so_far;
end

