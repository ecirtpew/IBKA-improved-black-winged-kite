function [Xmin,Xmax,nVar,fun,x_str] = select_PV_model(type)
% 该函数用以选择RTC France Cell 的 PV模型，及一些优化用的信息
% 输入：
% type-选择PV模型
% 输出：
% Xmin-下限，Xmax-上限，nVar-维数，fun-目标函数,x_str-变量名字
switch type
    case '1DM'
        %  PV model with single-diode
        Xmin = [ 0,       0,         0,       0 ,   1];
        Xmax = [ 1,  1.0e-06,   0.5,  100,  2]; % 将μA转换成A，1μA=1.0e-06A
        nVar = 5;
        fun=@PV_1DM; % 目标函数
        x_str={'I_ph','I_SD','R_s','R_sh','n'};
        
    case '2DM'
        %  PV model with double-diode
        Xmin = [ 0,   0,       0 ,         0,      1,        0 ,     1];
        Xmax = [ 1,  0.5 , 100,  1.0e-06,  2,  1.0e-06,  2];
        nVar = 7;
        fun=@PV_2DM;
        x_str={'I_ph','R_s','R_sh','I_SD1','n1','I_SD2','n2'};
        
    case '3DM'
        % PV model with three-diode
        Xmin = [ 0,   0,       0 ,         0,      1,        0 ,     1,     0 ,     1 ];
        Xmax = [ 1,  0.5 , 100,  1.0e-06,  2,  1.0e-06,  2,  1.0e-06,  2];
        nVar = 9;
        fun=@PV_3DM;
        x_str={'I_ph','R_s','R_sh','I_SD1','n1','I_SD2','n2','I_SD3','n3'};
        
    case '4DM'
        % PV model with three-diode
        Xmin = [ 0,   0,       0 ,         0,      1,        0 ,     1,     0 ,     1,           0 ,     1];
        Xmax = [ 1,  0.5 , 100,  1.0e-06,  2,  1.0e-06,  2,  1.0e-06,  2,  1.0e-06,  2];
        nVar = 11;
        fun=@PV_4DM;
        x_str={'I_ph','R_s','R_sh','I_SD1','n1','I_SD2','n2','I_SD3','n3','I_SD4','n4'};
        
    case 'PMM'
        %  PV model with module-diode
        Xmin = [ 0,          0,      0,      0 ,    1];
        Xmax = [ 2,  50.0e-06,  2,  2000,  50];
        nVar = 5;
        NS=3; % 串联管个数（可修改）
        NP=5; % 并联支路数（可修改）
        fun=@(x) PV_module(x,NS,NP);
        x_str={'I_ph','I_SD','R_s','R_sh','n'};
        
        
end
end
%%  -----------------------  PV model with single-diode ---------------------------
function [obj,Io] = PV_1DM(x)
% 1DM的目标函数
actual_data = load('cell_data.txt'); % 导入实测的 电流 电压数据
actual_V_data =  actual_data(:,1); % 实测电压数据
actual_I_data =  actual_data(:,2); % 实测电流数据
data_len = length(actual_V_data);
for j=1:data_len
    Io(j) = calculate_objective_1DM(x,actual_V_data(j), actual_I_data(j)); % 计算输出电流
end
error_value = Io-actual_I_data'; % 输出电流 与 实测电流的误差
fitness = sum(error_value.^2);
obj = sqrt(fitness/data_len); % 目标函数 RMSE

end

function  Io = calculate_objective_1DM(x,V_L,I_L)
% 计算1DM的输出
% 输入为：x-待优化的参数，V_L-实测电压数据，I_L-实测电流数据
I_ph = x(1); % photo-generated current source 光电电流源
I_SD = x(2); % saturation current 二极管的饱和电流
R_s	 = x(3); % series resistance 串联电阻
R_sh = x(4); % shunt resistance 并联电阻
n	 = x(5); % diode ideal factor 二极管理想因子
q = 1.60217646e-19; % electron charge 电子电荷 （常数）
k = 1.3806503e-23; % Boltzmann’s constant 玻尔兹曼常数（常数）
T = 273.15 + 33.0;		%  温度： 33 ， 结的温度，单位是开尔文
V_t = k * T / q; %  junction thermal voltage
% 输出电流
Io = I_ph - I_SD * ( exp( (V_L + I_L*R_s) / (V_t*n) ) - 1 ) - ( (V_L + I_L*R_s)/R_sh );
end


%%  -----------------------  PV model with double-diode ---------------------------
function [obj,Io] = PV_2DM(x)
% 2DM的目标函数
a = load('cell_data.txt');% 导入实测的 电流 电压数据
actual_V_data =  a(:,1);% 实测电压数据
actual_I_data =  a(:,2);% 实测电流数据
data_len = length(actual_V_data);
for j=1:data_len
    Io(j) = calculate_objective_2DM(x,actual_V_data(j), actual_I_data(j));
end
error_value = Io-actual_I_data'; % 输出电流 与 实测电流的误差
fitness = sum(error_value.^2);
obj = sqrt(fitness/data_len); % 目标函数 RMSE
end

function  Io = calculate_objective_2DM(x,V_L,I_L)
% 计算2DM的输出
% 输入为：x-待优化的参数，V_L-实测电压数据，I_L-实测电流数据
I_ph	= x(1);% photo-generated current source 光电电流源
R_s		= x(2);% series resistance 串联电阻
R_sh	= x(3);% shunt resistance 并联电阻
I_SD1  = x(4); % saturation current 二极管1的饱和电流
n1		= x(5);% diode ideal factor 二极管1的理想因子
I_SD2	= x(6);% saturation current 二极管2的饱和电流
n2		= x(7);% diode ideal factor 二极管2的理想因子

q = 1.60217646e-19;% electron charge 电子电荷 （常数）
k = 1.3806503e-23;% Boltzmann’s constant 玻尔兹曼常数（常数）
T = 273.15 + 33.0;		%  the temperature is set as 33 centi-degree 结的温度，单位是开尔文

% 输出电流
Io = I_ph - I_SD1 * ( exp( (q*(V_L + I_L*R_s)) / (n1*k*T) ) -1.0 ) - I_SD2 * ( exp( (q*(V_L + I_L*R_s)) / (n2*k*T) ) -1.0 ) - ( (V_L + I_L*R_s)/R_sh );

end


%%  -----------------------  PV model with three-diode ---------------------------
function [obj,Io] = PV_3DM(x)
% 3DM的目标函数
actual_data = load('cell_data.txt');% 导入实测的 电流 电压数据
actual_V_data =  actual_data(:,1);% 实测电压数据
actual_I_data =  actual_data(:,2);% 实测电流数据
data_len = length(actual_V_data);
for j=1:data_len
    Io(j) = calculate_objective_3DM(x,actual_V_data(j), actual_I_data(j));
end
error_value = Io-actual_I_data'; % 输出电流 与 实测电流的误差
fitness = sum(error_value.^2);
obj = sqrt(fitness/data_len); % 目标函数 RMSE
end

function  Io = calculate_objective_3DM(x,V_L,I_L)
% 计算3DM的输出
% 输入为：x-待优化的参数，V_L-实测电压数据，I_L-实测电流数据
I_ph	= x(1);% photo-generated current source 光电电流源
R_s		= x(2);% series resistance 串联电阻
R_sh	= x(3);% shunt resistance 并联电阻
I_SD1  = x(4); % saturation current 二极管1的饱和电流
n1		= x(5);% diode ideal factor 二极管1的理想因子
I_SD2	= x(6);% saturation current 二极管2的饱和电流
n2		= x(7);% diode ideal factor 二极管2的理想因子
I_SD3	= x(8);% saturation current 二极管3的饱和电流
n3		= x(9);% diode ideal factor 二极管3的理想因子

q = 1.60217646e-19;% electron charge 电子电荷 （常数）
k = 1.3806503e-23;% Boltzmann’s constant 玻尔兹曼常数（常数）
T = 273.15 + 33.0;		%   温度： 33 ， 结的温度，单位是开尔文

% 输出电流
Io = I_ph - I_SD1 * ( exp( (q*(V_L + I_L*R_s)) / (n1*k*T) ) -1.0 ) - ...
    I_SD2 * ( exp( (q*(V_L + I_L*R_s)) / (n2*k*T) ) -1.0 ) -...
    I_SD3* ( exp( (q*(V_L + I_L*R_s)) / (n3*k*T) ) -1.0 )-( (V_L + I_L*R_s)/R_sh );

end

%%  -----------------------  PV model with four-diode ---------------------------
function [obj,Io] = PV_4DM(x)
% 4DM的目标函数
actual_data = load('cell_data.txt');% 导入实测的 电流 电压数据
actual_V_data =  actual_data(:,1);% 实测电压数据
actual_I_data =  actual_data(:,2);% 实测电流数据
data_len = length(actual_V_data);
for j=1:data_len
    Io(j) = calculate_objective_4DM(x,actual_V_data(j), actual_I_data(j));
end
error_value = Io-actual_I_data'; % 输出电流 与 实测电流的误差
fitness = sum(error_value.^2);
obj = sqrt(fitness/data_len); % 目标函数 RMSE
end

function  Io = calculate_objective_4DM(x,V_L,I_L)
% 计算4DM的输出
% 输入为：x-待优化的参数，V_L-实测电压数据，I_L-实测电流数据
I_ph	= x(1);% photo-generated current source 光电电流源
R_s		= x(2);% series resistance 串联电阻
R_sh	= x(3);% shunt resistance 并联电阻
I_SD1  = x(4); % saturation current 二极管1的饱和电流
n1		= x(5);% diode ideal factor 二极管1的理想因子
I_SD2	= x(6);% saturation current 二极管2的饱和电流
n2		= x(7);% diode ideal factor 二极管2的理想因子
I_SD3	= x(8);% saturation current 二极管3的饱和电流
n3		= x(9);% diode ideal factor 二极管3的理想因子
I_SD4	= x(10);% saturation current 二极管4的饱和电流
n4		= x(11);% diode ideal factor 二极管4的理想因子

q = 1.60217646e-19;% electron charge 电子电荷 （常数）
k = 1.3806503e-23;% Boltzmann’s constant 玻尔兹曼常数（常数）
T = 273.15 + 33.0;		%   温度： 33 ， 结的温度，单位是开尔文

% 输出电流
Io = I_ph - I_SD1 * ( exp( (q*(V_L + I_L*R_s)) / (n1*k*T) ) -1.0 ) - ...
    I_SD2 * ( exp( (q*(V_L + I_L*R_s)) / (n2*k*T) ) -1.0 ) -...
    I_SD3* ( exp( (q*(V_L + I_L*R_s)) / (n3*k*T) ) -1.0 )-...
    I_SD4* ( exp( (q*(V_L + I_L*R_s)) / (n4*k*T) ) -1.0 ) - ( (V_L + I_L*R_s)/R_sh );

end

%%  -------------------------  PV module ----------------------------------
function [obj,Io] = PV_module(x,NS,NP)
% 计算module的输出
actual_data = load('pvmodule_data.txt');% 导入实测的 电流 电压数据
actual_V_data =  actual_data(:,1);% 实测电压数据
actual_I_data =  actual_data(:,2);% 实测电流数据
data_len = length(actual_V_data);
for j=1:data_len
    Io(j) = calculate_objective_module(x,actual_V_data(j), actual_I_data(j),NS,NP);% 计算输出电流
end
error_value = Io-actual_I_data'; % 输出电流 与 实测电流的误差
fitness = sum(error_value.^2);
obj = sqrt(fitness/data_len); % 目标函数 RMSE

end

function  Io = calculate_objective_module(x,V_L,I_L,NS,NP)%%%
% 计算module的输出
% 输入为：x-待优化的参数，V_L-实测电压数据，I_L-实测电流数据,NS-串联的管，NP-并联支路数
I_ph = x(1);% photo-generated current source 光电电流源
I_SD = x(2);% saturation current 二极管的饱和电流
R_s	 = x(3);% series resistance 串联电阻
R_sh = x(4);% shunt resistance 并联电阻
n	 = x(5);% diode ideal factor 二极管理想因子
q = 1.60217646e-19;% electron charge 电子电荷 （常数）
k = 1.3806503e-23;% Boltzmann’s constant 玻尔兹曼常数（常数）
T = 273.15 + 45.0;		%  %  温度： 45， 结的温度，单位是开尔文
V_t = k * T / q;%  junction thermal voltage
% 输出电流
Io = NP*I_ph - NP*I_SD * ( exp( (V_L/NS + (I_L*R_s/NP)) / (V_t*n) ) - 1.0 ) - ( NP*(V_L/NS + (I_L*R_s/NP))/R_sh );

end




