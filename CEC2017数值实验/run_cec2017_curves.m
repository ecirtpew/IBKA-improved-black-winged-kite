%% 重跑CEC2017收敛曲线实验(图2数据): 29函数 x 8算法, 每函数单次运行, 固定种子
clear; clc; close all;
addpath(genpath(pwd));

algorithms = {'IBKA', 'BKA', 'GGO', 'OOA', 'ZOA', 'DBO', 'AOA', 'WOA'};
F = [1 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30];
dim = 30; pop = 30; max_iter = 500;
num_algo = numel(algorithms); num_F = numel(F);

Curves = zeros(num_F, num_algo, max_iter);
Best   = zeros(num_F, num_algo);
t0 = tic;

for fi = 1:num_F
    fn = F(fi);
    [lb, ub, ~, fhd] = Get_Functions_cec2017(fn, dim);
    for ai = 1:num_algo
        rng(20250000 + fn);   % 每算法重置为同一随机流:各算法初始种群相同,公平且可复现
        [Best(fi,ai), ~, C] = feval(algorithms{ai}, pop, max_iter, lb, ub, dim, fhd);
        Curves(fi, ai, :) = C;
    end
    fprintf('F%02d 完成, 用时 %.1f s, IBKA最优=%.3e\n', fn, toc(t0), Best(fi,1));
end

save('curves_cec2017_v5.mat', 'Curves', 'Best', 'F', 'algorithms', '-v7');
fprintf('全部完成, 总用时 %.1f s\n', toc(t0));
