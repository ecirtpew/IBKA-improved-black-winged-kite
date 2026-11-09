function [Results]=Cal_stats(Optimal_results)
% 输出：Results：
%          平均收敛曲线
%          最差值worst
%          最优值best
%          标准差值std 
%          均值mean 
%          中值median
%          friedman_p_value： friedman检验
%% 统计值-结果保存在Results中
for k=1:size(Optimal_results, 2)
    Results{1,k} = Optimal_results{1,k};    Results{2,k} = mean(Optimal_results{2,k},1);  % 平均收敛曲线，Optimal_results第2行保存的是收敛曲线
    Results{3,k} = max(Optimal_results{3,k});    % 最差值worst，Optimal_results第3行保存的是最优值
    Results{4,k} = min(Optimal_results{3,k});    % 最优值best，Optimal_results第3行保存的是最优值
    Results{5,k} = std(Optimal_results{3,k});      % 标准差值 std  ，Optimal_results第3行保存的是最优值
    Results{6,k} = mean(Optimal_results{3,k});     % 平均值 mean，Optimal_results第3行保存的是最优值
    Results{7,k} = median(Optimal_results{3,k});     % 中值   median，Optimal_results第3行保存的是最优值
end

%% friedman test p_value<0.05即为显著
% test_mat = []; % 待测矩阵
% for i=1:size(Results,2) % 其他算法
%     test_mat =cat(1,test_mat,Results{2,i}); % Results第2行保存的是平均收敛曲线
% end
% [friedman_p_value,table,friedman_stats]=friedman(test_mat); % 调用friedman检验
% if friedman_p_value<0.05
%     disp(['Friedman Test值为' num2str(friedman_p_value) '<0.05，具有显著性差别'])
% end
end