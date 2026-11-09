%%  闲鱼：深度学习与智能算法
%%  唯一官方店铺：https://mbd.pub/o/autSFOAr-aWWbm3BtZw==
%%  微信公众号：强盛机器学习，关注公众号获得更多免费代码！
function [Best_score, Best_pos, Convergence_curve] = GGO(SearchAgents_no, Max_iter, lb, ub, dim, fobj)
%___________________________________________________________________%
% Greylag Goose Optimization (GGO) Algorithm                       %
% 基于论文: "Greylag Goose Optimization: Nature-inspired           %
% optimization algorithm for solving optimization problems"        %

% 初始化参数
a = 2; % 控制参数a，从2线性递减到0
c = 2; % 常数参数
b = 1; % 螺旋常数

% 初始化种群
X = initialization(SearchAgents_no, dim, ub, lb);

% 计算初始适应度
fitness = zeros(1, SearchAgents_no);
for i = 1:SearchAgents_no
    fitness(i) = fobj(X(i, :));
end

% 找到最优解
[Best_score, best_idx] = min(fitness);
Best_pos = X(best_idx, :);

% 初始化收敛曲线
Convergence_curve = zeros(1, Max_iter);

% 初始化探索和开发组
n1 = round(SearchAgents_no * 0.5); % 探索组初始大小
n2 = SearchAgents_no - n1;         % 开发组初始大小

% 记录最优解未改善的次数
no_improvement_count = 0;
prev_best_score = Best_score;

% 主循环
for t = 1:Max_iter
    % 更新控制参数
    a = 2 - t * (2 / Max_iter); % a从2线性递减到0
    
    % 更新z参数（指数递减）
    z = 1 - (t / Max_iter)^2;
    
    % 随机打乱种群以交换角色
    rand_indices = randperm(SearchAgents_no);
    X = X(rand_indices, :);
    fitness = fitness(rand_indices);
    
    % 更新探索组 (前n1个个体)
    for i = 1:n1
        % 计算A和C向量
        r1 = rand(); r2 = rand(); r3 = rand(); r4 = rand(); r5 = rand();
        A = 2 * a * r1 - a;
        C = 2 * r2;
        
        % 更新权重参数
        w1 = 2 * rand(); w2 = 2 * rand(); w3 = 2 * rand(); w4 = 2 * rand();
        
        if mod(t, 2) == 0
            if r3 < 0.5
                if abs(A) < 1
                    % 向最优解移动
                    X(i, :) = Best_pos - A .* abs(C .* Best_pos - X(i, :));
                else
                    % 使用三个随机代理更新位置
                    paddle_indices = randperm(SearchAgents_no, 3);
                    X_paddle1 = X(paddle_indices(1), :);
                    X_paddle2 = X(paddle_indices(2), :);
                    X_paddle3 = X(paddle_indices(3), :);
                    
                    X(i, :) = w1 * X_paddle1 + z * w2 * (X_paddle2 - X_paddle3) + ...
                             (1 - z) * w3 * (X(i, :) - X_paddle1);
                end
            else
                % 螺旋更新
                l = 2 * rand() - 1; % l在[-1,1]之间
                X(i, :) = w4 * abs(Best_pos - X(i, :)) .* exp(b * l) .* cos(2 * pi * l) + ...
                         (2 * w1 * (r4 + r5)) * Best_pos;
            end
        else
            % 在最优解周围搜索
            D = rand(1, dim);
            w = rand();
            X_flock1 = X(randi(SearchAgents_no), :);
            X(i, :) = X(i, :) + D .* (1 + z) * w .* (X(i, :) - X_flock1);
        end
    end
    

    [~, sorted_indices] = sort(fitness);
    indices_of_min3 = sorted_indices(1:3);
    

    % 更新开发组 (后n2个个体)
    for i = (n1 + 1):SearchAgents_no
        if mod(t, 2) == 0
            % 选择三个哨兵
            X_sentry1 = X(indices_of_min3(1), :);
            X_sentry2 = X(indices_of_min3(2), :);
            X_sentry3 = X(indices_of_min3(3), :);
            
            % 计算A和C向量
            r1_1 = rand(); r1_2 = rand(); r1_3 = rand();
            r2_1 = rand(); r2_2 = rand(); r2_3 = rand();
            
            A1 = 2 * a * r1_1 - a;
            A2 = 2 * a * r1_2 - a;
            A3 = 2 * a * r1_3 - a;
            C1 = 2 * r2_1;
            C2 = 2 * r2_2;
            C3 = 2 * r2_3;
            
            % 计算三个位置
            X1 = X_sentry1 - A1 .* abs(C1 .* X_sentry1 - X(i, :));
            X2 = X_sentry2 - A2 .* abs(C2 .* X_sentry2 - X(i, :));
            X3 = X_sentry3 - A3 .* abs(C3 .* X_sentry3 - X(i, :));
            
            % 更新位置（三个位置的平均值）
            X(i, :) = (X1 + X2 + X3) / 3;
        else
            % 在最优解周围搜索
            D = rand(1, dim);
            w = rand();
            X_flock1 = X(indices_of_min3(1), :);
            X(i, :) = X(i, :) + D .* (1 + z) * w .* (X(i, :) - X_flock1);
        end
    end
    
    % 边界检查
    for i = 1:SearchAgents_no
        X(i, :) = max(X(i, :), lb);
        X(i, :) = min(X(i, :), ub);
    end
    
    % 重新计算适应度
    for i = 1:SearchAgents_no
        fitness(i) = fobj(X(i, :));
    end
    
    % 更新最优解
    [current_best, best_idx] = min(fitness);
    if current_best < Best_score
        Best_score = current_best;
        Best_pos = X(best_idx, :);
    end
    
    % 动态调整探索和开发组大小
    if abs(Best_score - prev_best_score) < 1e-10
        no_improvement_count = no_improvement_count + 1;
    else
        no_improvement_count = 0;
    end
    
    % 如果连续3次迭代没有改善，增加探索组大小
    if no_improvement_count >= 3
        n1 = min(n1 + 1, SearchAgents_no - 1);
        n2 = SearchAgents_no - n1;
        no_improvement_count = 0;
    else
        % 否则逐渐减少探索组，增加开发组
        if n1 > 1
            n1 = max(1, n1 - 1);
            n2 = SearchAgents_no - n1;
        end
    end
    
    prev_best_score = Best_score;
    
    % 记录收敛曲线
    Convergence_curve(t) = Best_score;
end
end

function X = initialization(SearchAgents_no, dim, ub, lb)
%初始化种群
Boundary_no = size(ub, 2); % 边界数量

% 如果边界是标量，扩展为向量
if Boundary_no == 1
    X = rand(SearchAgents_no, dim) .* (ub - lb) + lb;
else
    for i = 1:dim
        ub_i = ub(i);
        lb_i = lb(i);
        X(:, i) = rand(SearchAgents_no, 1) .* (ub_i - lb_i) + lb_i;
    end
end
end

%%  闲鱼：深度学习与智能算法
%%  唯一官方店铺：https://mbd.pub/o/autSFOAr-aWWbm3BtZw==
%%  微信公众号：强盛机器学习，关注公众号获得更多免费代码！