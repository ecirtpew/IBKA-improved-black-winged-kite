function [Vm,Im,Pm,Io,Po,IIAE,IRE,PIAE,PRE]=Cal_models(x,pv_type)
% 输出：
% Io-估计电流值
% Po-估计功率值
% Vm-实测电压数据
% Im-实测电流数据
% Pm-由Vm和Im计算的实测功率
% IIAE-电流的absolute error
% IRE-电流的relative error
% PIAE-功率的absolute error
% PRE-功率的absolute error
%%

switch pv_type
    case '1DM'
        %  PV model with single-diode
        actual_data = load('cell_data.txt');% 导入实测的 电流 电压数据
        Vm =  actual_data(:,1);% 实测电压数据
        Im =  actual_data(:,2);% 实测电流数据
        x_str={'I_ph','I_SD','R_s','R_sh','n'};
        [~,~,~,fun,~] = select_PV_model(pv_type);
        [fobj,Io]=fun(x);
        Io=Io';
        IIAE=abs(Io-Im); % 电流的absolute error
        IRE=(Im-Io)./Im; % 电流的relative error
        Pm=Vm.*Im;%由Vm和Im计算的实测功率
        Po=Vm.*Io; %估计功率值
        PIAE=abs(Pm-Po);% 功率的absolute error
        PRE=(Pm-Po)./Pm;% 功率的absolute error
        
    case '2DM'
        %  PV model with double-diode
        actual_data = load('cell_data.txt');% 导入实测的 电流 电压数据
        Vm =  actual_data(:,1);% 实测电压数据
        Im =  actual_data(:,2);% 实测电流数据
        x_str={'I_ph','R_s','R_sh','I_SD1','n1','I_SD2','n2'};
        [~,~,~,fun,~] = select_PV_model(pv_type);
        [fobj,Io]=fun(x);
        Io=Io';
        IIAE=abs(Io-Im); % 电流的absolute error
        IRE=(Im-Io)./Im; % 电流的relative error
        Pm=Vm.*Im;%由Vm和Im计算的实测功率
        Po=Vm.*Io; %估计功率值
        PIAE=abs(Pm-Po);% 功率的absolute error
        PRE=(Pm-Po)./Pm;% 功率的absolute error
        
    case '3DM'
        % PV model with three-diode
        actual_data = load('cell_data.txt');% 导入实测的 电流 电压数据
        Vm =  actual_data(:,1);% 实测电压数据
        Im =  actual_data(:,2);% 实测电流数据
        x_str={'I_ph','R_s','R_sh','I_SD1','n1','I_SD2','n2','I_SD3','n3'};
        [~,~,~,fun,~] = select_PV_model(pv_type);
        [fobj,Io]=fun(x);
        Io=Io';
        IIAE=abs(Io-Im); % 电流的absolute error
        IRE=(Im-Io)./Im; % 电流的relative error
        Pm=Vm.*Im;%由Vm和Im计算的实测功率
        Po=Vm.*Io; %估计功率值
        PIAE=abs(Pm-Po);% 功率的absolute error
        PRE=(Pm-Po)./Pm;% 功率的absolute error
        
    case '4DM'
        % PV model with three-diode
        actual_data = load('cell_data.txt');% 导入实测的 电流 电压数据
        Vm =  actual_data(:,1);% 实测电压数据
        Im =  actual_data(:,2);% 实测电流数据
        x_str={'I_ph','R_s','R_sh','I_SD1','n1','I_SD2','n2','I_SD3','n3','I_SD4','n4'};
        [~,~,~,fun,~] = select_PV_model(pv_type);
        [fobj,Io]=fun(x);
        Io=Io';
        IIAE=abs(Io-Im); % 电流的absolute error
        IRE=(Im-Io)./Im; % 电流的relative error
        Pm=Vm.*Im;%由Vm和Im计算的实测功率
        Po=Vm.*Io; %估计功率值
        PIAE=abs(Pm-Po);% 功率的absolute error
        PRE=(Pm-Po)./Pm;% 功率的absolute error
        
    case 'PMM'
        %  PV model with module-diode
        actual_data = load('pvmodule_data.txt');% 导入实测的 电流 电压数据
        Vm =  actual_data(:,1);% 实测电压数据
        Im =  actual_data(:,2);% 实测电流数据
        x_str={'I_ph','I_SD','R_s','R_sh','n'};
        [~,~,~,fun,~] = select_PV_model(pv_type);
        [fobj,Io]=fun(x);
        Io=Io';
        IIAE=abs(Io-Im); % 电流的absolute error
        IRE=(Im-Io)./Im; % 电流的relative error
        Pm=Vm.*Im;%由Vm和Im计算的实测功率
        Po=Vm.*Io; %估计功率值
        PIAE=abs(Pm-Po);% 功率的absolute error
        PRE=(Pm-Po)./Pm;% 功率的absolute error
        
end



end





