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
algorithms = {'IBKA', 'BKA', 'GGO', 'OOA', 'ZOA', 'DBO', 'AOA', 'WOA'}; 

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

    %% 绘制箱型图
    if box_pp == 1
        plot_pos = mod(func_idx - 1, 5) + 1;
        
        if plot_pos == 1
            fig_num = ceil(func_idx / 5); % 计算这是第几张大图
            figure('Name', ['箱型图 - 组 ', num2str(fig_num)], 'Color', 'w', 'Position', [300 300 1500 280]);
        end
        
        subplot(1, 5, plot_pos)
        
        mycolor = lines(num_algorithms);
        
        % 绘图
        box_figure = boxplot(box_plot_per_func', 'color', [0 0 0], 'Symbol', 'o');
        set(box_figure, 'Linewidth', 1.2);
        boxobj = findobj(gca, 'Tag', 'Box');
        
        % 倒序填充颜色以匹配boxobj的顺序
        for i = 1:num_algorithms
            patch(get(boxobj(num_algorithms - i + 1), 'XData'), get(boxobj(num_algorithms - i + 1), 'YData'), mycolor(i,:), 'FaceAlpha', 0.5, 'LineWidth', 1.1);
        end
        
        set(gca, 'XTickLabel', algorithms); % 自动设置坐标轴标签
        title(['F', num2str(func_num)])
        hold on
    end
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
    
    % Friedman平均排名柱状图
    mean_ranks = stats.meanranks;  % 各算法的平均排名
    
    % 定义柱状图颜色
    bar_colors = [
        0.20, 0.00, 0.15;   % 深紫红
        0.55, 0.80, 0.95;   % 浅蓝
        0.95, 0.55, 0.75;   % 粉色
        0.40, 0.95, 0.70;   % 薄荷绿
        0.68, 0.62, 0.85;   % 淡紫
        1.00, 0.80, 0.60;   % 杏色
        0.00, 0.80, 0.80;   % 青色
        0.50, 0.85, 0.30;   % 黄绿
    ];
    % 如果算法数量超出预设颜色，自动补充
    if num_algorithms > size(bar_colors, 1)
        extra = hsv(num_algorithms - size(bar_colors, 1));
        bar_colors = [bar_colors; extra];
    end
    
    figure('Name', 'Friedman平均排名', 'Color', 'w', 'Position', [200 200 900 500]);
    hold on;
    
    % 逐个绘制柱子以实现不同颜色
    for i = 1:num_algorithms
        bh = bar(i, mean_ranks(i), 0.65);
        set(bh, 'FaceColor', bar_colors(i, :), 'EdgeColor', [0.3 0.3 0.3], 'LineWidth', 0.8);
    end
    
    % 绘制连接曲线
    x_fine = linspace(1, num_algorithms, 200);
    y_fine = interp1(1:num_algorithms, mean_ranks, x_fine, 'pchip');
    plot(x_fine, y_fine, '-', 'Color', [0.90 0.35 0.13], 'LineWidth', 2.8);
    
    % 绘制数据点圆圈
    plot(1:num_algorithms, mean_ranks, 'o', ...
        'MarkerSize', 7, 'MarkerFaceColor', [0.90 0.35 0.13], ...
        'MarkerEdgeColor', [0.90 0.35 0.13], 'LineWidth', 1.2);
    
    % 在柱顶标注排名数值
    for i = 1:num_algorithms
        text(i, mean_ranks(i) + max(mean_ranks) * 0.03, ...
            sprintf('%.2f', mean_ranks(i)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 9, 'Color', [0.15 0.15 0.15]);
    end
    
    % 坐标轴设置
    set(gca, 'XTick', 1:num_algorithms, 'XTickLabel', algorithms, ...
        'FontSize', 11, 'FontName', 'Times New Roman', ...
        'Box', 'on', 'LineWidth', 0.8);
    xlim([0.3, num_algorithms + 0.7]);
    ylim([0, max(mean_ranks) * 1.18]);
    xlabel('Algorithm', 'FontSize', 13);
    ylabel('Average rank', 'FontSize', 13);
    hold off;
    
else
    disp('函数数量不足，无法进行Friedman检验。');
end
disp('所有计算和数据导出已完成！');