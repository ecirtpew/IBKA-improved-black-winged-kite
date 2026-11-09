%%  清除环境变量
clear
clc
close all
addpath(genpath(pwd));

%%  算法配置
algorithms = {'IBKA', 'BKA', 'GGO', 'OOA', 'ZOA', 'DBO', 'AOA', 'WOA'}; 

%%  参数设置
number = 6;                                                   %  选定优化函数，自行替换
dim = 30;                                                     %  可选 2, 10, 30, 50, 100
[lb,ub,dim,fobj]=Get_Functions_cec2017(number,dim);           % [lb,ub,D,y]：下界、上界、维度、目标函数表达式
pop_size = 30;                                                %  种群数量 
max_iter = 500;                                               %  迭代次数
num_algo = length(algorithms);

%%  运行各算法
Best_scores = zeros(1, num_algo);
Curves = zeros(num_algo, max_iter);

for i = 1:num_algo
    algo_func = str2func(algorithms{i});
    [Best_scores(i), ~, Curves(i, :)] = algo_func(pop_size, max_iter, lb, ub, dim, fobj);
end

%%  显示结果
for i = 1:num_algo
    display([algorithms{i}, '在函数' num2str(number),'上的最优值', num2str(Best_scores(i))]);
end

%%  画图
figure1 = figure('Color',[1 1 1]);
G1=subplot(1,2,1,'Parent',figure1);
func_plot2017(number,dim)
xlabel('x')
ylabel('y')
zlabel('z')
subplot(1,2,2)
G2=subplot(1,2,2,'Parent',figure1);
CNT=20;
k=round(linspace(1,max_iter,CNT));       % 随机选CNT个点
% 注意：如果收敛曲线画出来的点很少，随机点很稀疏，说明点取少了，这时应增加取点的数量，100、200、300等，逐渐增加
% 相反，如果收敛曲线上的随机点非常密集，说明点取多了，此时要减少取点数量
iter=1:1:max_iter;

% 预设线条颜色和标记符号
colorList = {'r', 'g', 'm', 'y', 'c', 'k', 'b', [0.75, 0, 1], [0.93, 0.69, 0.13], [0, 0.45, 0.74]};
markerList = {'o', '+', '*', 'p', 'd', 's', '^', 'h', 'v', '>'};

for i = 1:num_algo
    cIdx = mod(i-1, length(colorList)) + 1;
    mIdx = mod(i-1, length(markerList)) + 1;
    c = colorList{cIdx};
    m = markerList{mIdx};
    semilogy(iter(k), Curves(i, k), ['-', m], 'Color', c, 'LineWidth', 1);
    hold on
end

grid on;
title('收敛曲线')
xlabel('迭代次数');
ylabel('适应度值');
box on
legend(algorithms, 'Location', 'best')
set(gcf,'color','w')
set (gcf,'position', [300,300,800,330])
rmpath(genpath(pwd))