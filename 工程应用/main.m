%% 清空环境变量
warning off             % 关闭报警信息
close all               % 关闭开启的图窗
clear                   % 清空变量
clc                     % 清空命令行

%% 参数设置
Max_iteration = 500;         % 最大迭代次数
N = 30;                      % 种群规模
Run_times = 10;              % 独立运行次数
Function_name = 'F3';        % F1-F3,自由切换3个工程应用
[lb, ub, dim, fobj] = Get_Functions_details(Function_name);

%%  算法名称列表
Algorithm_names = {'IBKA', 'BKA', 'RIME', 'SABO', 'GoldSA', 'PSO'};
Num_algorithms = length(Algorithm_names);

%%  初始化结果存储矩阵法
Best_scores_all = zeros(Run_times, Num_algorithms);
Curves_all = zeros(Run_times, Max_iteration, Num_algorithms);
Best_pos_all = cell(Run_times, Num_algorithms);

%%  多次独立运行
fprintf('开始进行 %d 次独立运行...\n', Run_times);
for run = 1:Run_times
    fprintf('第 %d / %d 次运行...\n', run, Run_times);
    
    [IBKA_Best_score, IBKA_Best_pos, IBKA_Curve] = IBKA(N, Max_iteration, lb, ub, dim, fobj);
    [BKA_Best_score,  BKA_Best_pos,  BKA_Curve ] = BKA (N, Max_iteration, lb, ub, dim, fobj);
    [RIME_Best_score, RIME_Best_pos, RIME_Curve] = RIME(N, Max_iteration, lb, ub, dim, fobj);
    [SABO_Best_score, SABO_Best_pos, SABO_Curve] = SABO(N, Max_iteration, lb, ub, dim, fobj);
    [GoldSA_Best_score,  GoldSA_Best_pos,  GoldSA_Curve ] = GoldSA (N, Max_iteration, lb, ub, dim, fobj);
    [PSO_Best_score,  PSO_Best_pos,  PSO_Curve ] = PSO (N, Max_iteration, lb, ub, dim, fobj);
    
    % 保存最优适应度值
    Best_scores_all(run, :) = [IBKA_Best_score, BKA_Best_score, RIME_Best_score, ...
                                SABO_Best_score, GoldSA_Best_score, PSO_Best_score];
    
    % 保存收敛曲线(保证为行向量)
    Curves_all(run, :, 1) = IBKA_Curve(:)';
    Curves_all(run, :, 2) = BKA_Curve(:)';
    Curves_all(run, :, 3) = RIME_Curve(:)';
    Curves_all(run, :, 4) = SABO_Curve(:)';
    Curves_all(run, :, 5) = GoldSA_Curve(:)';
    Curves_all(run, :, 6) = PSO_Curve(:)';
    
    % 保存最优位置
    Best_pos_all{run, 1} = IBKA_Best_pos;
    Best_pos_all{run, 2} = BKA_Best_pos;
    Best_pos_all{run, 3} = RIME_Best_pos;
    Best_pos_all{run, 4} = SABO_Best_pos;
    Best_pos_all{run, 5} = GoldSA_Best_pos;
    Best_pos_all{run, 6} = PSO_Best_pos;
end
fprintf('所有运行完成!\n\n');

%%  统计结果计算
Best_values   = min(Best_scores_all, [], 1);    % 最优值
Worst_values  = max(Best_scores_all, [], 1);    % 最差值
Mean_values   = mean(Best_scores_all, 1);       % 平均值
Std_values    = std(Best_scores_all, 0, 1);     % 标准差
Median_values = median(Best_scores_all, 1);     % 中位数

%%  计算平均收敛曲线
Mean_curves = squeeze(mean(Curves_all, 1));   % 维度: (Max_iteration, Num_algorithms)

%%  绘制平均收敛曲线
figure;
t = 1:Max_iteration;
semilogy(t, Mean_curves(:,1), 'ro-', ...
         t, Mean_curves(:,2), 'kp-', ...
         t, Mean_curves(:,3), 'cs-', ...
         t, Mean_curves(:,4), 'm*-', ...
         t, Mean_curves(:,5), 'b^-', ...
         t, Mean_curves(:,6), 'gd-', ...
         'linewidth', 1, 'MarkerSize', 6, 'MarkerIndices', 1:50:Max_iteration);
title(['工程应用 ', Function_name, ' 平均收敛曲线']);
xlabel('迭代次数');
ylabel('平均适应度');
grid on
box on
legend(Algorithm_names, 'Location', 'best');
set(gcf, 'color', 'w')

%%  命令行显示统计结果
fprintf('========== 统计结果 (%d 次独立运行, 函数: %s) ==========\n', Run_times, Function_name);
fprintf('%-8s %-15s %-15s %-15s %-15s\n', '算法', '最优值', '平均值', '标准差', '最差值');
for i = 1:Num_algorithms
    fprintf('%-8s %-15.6e %-15.6e %-15.6e %-15.6e\n', ...
        Algorithm_names{i}, Best_values(i), Mean_values(i), Std_values(i), Worst_values(i));
end

%% 输出结果到Excel
Excel_filename = ['Results_', Function_name, '.xlsx'];
Stats_header = {'算法', '最优值', '平均值', '标准差', '最差值', '中位数'};
Stats_data = cell(Num_algorithms, 6);
for i = 1:Num_algorithms
    Stats_data{i,1} = Algorithm_names{i};
    Stats_data{i,2} = Best_values(i);
    Stats_data{i,3} = Mean_values(i);
    Stats_data{i,4} = Std_values(i);
    Stats_data{i,5} = Worst_values(i);
    Stats_data{i,6} = Median_values(i);
end
Stats_table = [Stats_header; Stats_data];
writecell(Stats_table, Excel_filename, 'Sheet', '统计结果');
fprintf('\n结果已成功保存到: %s\n', Excel_filename);