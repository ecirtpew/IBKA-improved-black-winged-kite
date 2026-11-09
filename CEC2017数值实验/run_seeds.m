%% 为6个正文重点函数补跑多种子(F1 F12 F13 F15 F19 F30), 供挑选代表性运行
clear; clc; close all;
addpath(genpath(pwd));

algorithms = {'IBKA', 'BKA', 'GGO', 'OOA', 'ZOA', 'DBO', 'AOA', 'WOA'};
Fkey = [1 12 13 15 19 30];
dim = 30; pop = 30; max_iter = 500;
num_algo = numel(algorithms); num_F = numel(Fkey); num_seed = 10;

CurvesS = zeros(num_F, num_algo, num_seed, max_iter);
BestS   = zeros(num_F, num_algo, num_seed);
t0 = tic;

for fi = 1:num_F
    fn = Fkey(fi);
    [lb, ub, ~, fhd] = Get_Functions_cec2017(fn, dim);
    for s = 1:num_seed
        for ai = 1:num_algo
            rng(77000000 + fn*100 + s);   % 每种子每算法同起点
            [BestS(fi,ai,s), ~, C] = feval(algorithms{ai}, pop, max_iter, lb, ub, dim, fhd);
            CurvesS(fi, ai, s, :) = C;
        end
    end
    fprintf('F%02d 多种子完成, 累计 %.1f s\n', fn, toc(t0));
end

save('curves_seeds_v5.mat', 'CurvesS', 'BestS', 'Fkey', 'algorithms', '-v7');
fprintf('全部完成 %.1f s\n', toc(t0));
