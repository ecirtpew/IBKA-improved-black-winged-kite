%%  清除环境变量
clear
clc
close all
addpath(genpath(pwd));

%%  启动并行池（如果尚未启动）
if isempty(gcp('nocreate'))
    parpool('local');
end

%%  算法配置
algorithms = {'BKA', 'IBKA_1', 'IBKA_2', 'IBKA_3', 'IBKA'}; 

%%  参数设置
pop_size = 30;                        % 种群数目
max_iter = 500;                       % 迭代次数
run = 30;                             % 每种算法独立运行次数
box_pp = 1;                           % 是否绘制箱型图 (1: 是, 0: 否)
dim = 30;                             % 维度可选 2, 10, 30, 50, 100

F = [1 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30];   %  第二个函数被删

%%  执行循环
num_algorithms = length(algorithms);  % 获取算法数量
RESULT = [];                          % 存储所有函数的统计结果 (最优值, 标准差, 平均值等)
rank_sum_RESULT = [];                 % 存储秩和检验结果 (将第一个算法与其他算法比较)
all_algorithms_results = cell(1, num_algorithms); % 存储每个算法的原始运行结果
disp(['正在统计的是维度为', num2str(dim), '的CEC2017函数集'])

% 遍历每一个测试函数
for func_idx = 1:length(F)
    func_num = F(func_idx);
    disp(['F', num2str(func_num), ' 函数计算结果：'])
    [lb, ub, ~, fhd] = Get_Functions_cec2017(func_num, dim);
   
    resu_per_func = [];        % 存储当前函数的统计结果
    rank_sum_per_func = [];    % 存储当前函数的秩和检验结果
    box_plot_per_func = [];    % 存储用于绘制箱型图的原始数据
    
    % 遍历每一个算法
    for alg_idx = 1:num_algorithms
        alg_name = algorithms{alg_idx};
        final_main = zeros(1, run);
        parfor nrun = 1:run
            [final, ~, ~] = feval(alg_name, pop_size, max_iter, lb, ub, dim, fhd);
            final_main(nrun) = final;
        end
        
        % 存储当前算法的所有运行结果，用于后续统计
        all_algorithms_results{alg_idx} = final_main;
        
        % 收集箱型图数据
        box_plot_per_func = [box_plot_per_func; final_main];
        
        % 计算统计指标
        zz = [min(final_main); std(final_main); mean(final_main); median(final_main); max(final_main)];
        resu_per_func = [resu_per_func, zz];
        
        % 显示结果
        disp([alg_name, '：最优值:', num2str(zz(1)), ' 标准差:', num2str(zz(2)), ...
            ' 平均值:', num2str(zz(3)), ' 中值:', num2str(zz(4)), ' 最差值:', num2str(zz(5))]);
    end
    
    % 计算秩和检验结果 (第一个算法 vs 其他所有算法)
    base_results = all_algorithms_results{1};
    for i = 2:num_algorithms
        compare_results = all_algorithms_results{i};
        rs = ranksum(base_results, compare_results);
        if isnan(rs) % 当两组数据完全一致时，ranksum可能返回NaN
            rs = 1;
        end
        rank_sum_per_func = [rank_sum_per_func, rs];
    end
    
    % 汇总所有函数的结果
    RESULT = [RESULT; resu_per_func];
    rank_sum_RESULT = [rank_sum_RESULT; rank_sum_per_func];
    
end

%%  结果导出区域
if exist('指标结果.xlsx', 'file')
    delete('指标结果.xlsx')
end
if exist('秩和检验结果.xlsx', 'file')
    delete('秩和检验结果.xlsx')
end
if exist('Friedman检验结果.xlsx', 'file')
    delete('Friedman检验结果.xlsx')
end

%%  导出详细指标结果到Excel
A = string();
for i = 1:length(F)
    str = string(['F', num2str(F(i))]);
    row_start = 5 * (i - 1) + 1; 
    row_end = 5 * i;
    A(row_start:row_end, 1) = repmat(str,5,1);
    A(row_start:row_end, 2) = ["最优值"; "标准差"; "平均值"; "中值"; "最差值"];
end
A = cellstr(A);
A = [A, num2cell(RESULT)];
title_stats = [{' ', '指标'}, algorithms];
A = [title_stats; A];
writetable(cell2table(A), '指标结果.xlsx', 'WriteVariableNames', false);

%%  导出秩和检验结果到Excel
B = string();
for i = 1:length(F)
    str = string(['F', num2str(F(i))]);
    B(i, 1) = str;
end
B = cellstr(B);
B = [B, num2cell(rank_sum_RESULT)];
title_ranksum = [{' '}, algorithms(2:end)]; % 第一个算法作为基准，不和自己比较
B = [title_ranksum; B];
writetable(cell2table(B), '秩和检验结果.xlsx', 'WriteVariableNames', false);
disp('所有计算和数据导出已完成！');

%%  执行并导出Friedman检验结果
% 提取所有函数的平均值结果进行检验
mean_indices = 3:6:size(RESULT, 1);
average_results = RESULT(mean_indices, :);
if size(average_results,1) > 1 % Friedman检验要求样本数大于1
    [p, tbl, stats] = friedman(average_results, 1, 'off'); % 'off' 关闭图形显示
    
    % 显示并准备导出Friedman检验结果
    disp('-----------------------------------------');
    disp('Friedman检验结果：');
    disp(['Friedman检验的p值为：', num2str(p)]);
    
    C = cell(2, num_algorithms);
    C(1, :) = algorithms;
    C(2, :) = num2cell(stats.meanranks);
    
    for i = 1:num_algorithms
        fprintf('%s 算法的Friedman检验平均排名为：%f\n', algorithms{i}, stats.meanranks(i));
    end
    
    % 将排名写入Excel
    writetable(cell2table(C'), 'Friedman检验结果.xlsx', 'WriteVariableNames', false);
else
    disp('函数数量不足，无法进行Friedman检验。');
end
disp('所有计算和数据导出已完成！');