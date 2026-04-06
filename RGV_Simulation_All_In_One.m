%% RGV_Simulation_All_In_One.m
% 实验目标：生成两组对照轨迹 (平衡直线、蛇形飞行)
% 修改说明：取消 subplot 合并，将 (a) 和 (b) 拆分为独立图片保存

clear; clc; close all;

%% 1. 全局配置与环境
T_max = 1200; t_trigger = 200;
sim_cfg.atmos_mode = 'US76_Manual'; 

p.Re = 6378137; p.mu = 3.986e14; p.g0 = 9.80665;
p.m = 907.2; p.S = 0.4839;
p.coef_L = [0.0301, 2.2992, 1.2287, -1.3001e-4, 0.2047, -6.1460e-2];
p.coef_D = [0.0100, -0.1748, 2.7247, 4.5781e-4, 0.3591, -6.9440e-2];

st_init.v0 = 5500; st_init.h0 = 50000;
y0 = [st_init.v0, 0, 0, 0, 0, p.Re + st_init.h0];

%% 2. 定义控制律
% Exp 1: 平衡直线 (Balance)
c1_nom.alpha = @(t) 11; c1_nom.gamma = @(t) 0;
c1_man.alpha = @(t) (t < t_trigger) * 11 + (t >= t_trigger) * 20; 
c1_man.gamma = @(t) (t < t_trigger) * 0  + (t >= t_trigger) * 45;

% Exp 2: 蛇形飞行 (Weaving) - 减小波动幅度至 5 度
c2_nom.alpha = @(t) 6; 
c2_nom.gamma = @(t) (80 - 0.123*t) + 5 * sin(0.04*t); 
c2_man.alpha = @(t) c2_nom.alpha(t) + (t >= t_trigger) * 9;
c2_man.gamma = @(t) c2_nom.gamma(t) + (t >= t_trigger) * 45;

Exp_Names = {'Balance', 'Weaving'};
Exp_Ctrls = {c1_nom, c1_man; c2_nom, c2_man};
ExpData = struct();

%% 3. 执行仿真与独立绘图保存
options = odeset('RelTol', 1e-6, 'AbsTol', 1e-6, 'Events', @(t,y) events_landing(t,y,p));

for i = 1:2
    fprintf('正在生成 %s 场景仿真数据...\n', Exp_Names{i});
    [Tn, Yn] = ode45(@(t,y) dynamics_cavh(t,y,Exp_Ctrls{i,1},p), [0 T_max], y0, options);
    [Tm, Ym] = ode45(@(t,y) dynamics_cavh(t,y,Exp_Ctrls{i,2},p), [0 T_max], y0, options);
    
    [Dn, ~] = process_sim(Tn, Yn, Exp_Ctrls{i,1}, p);
    [Dm, ~] = process_sim(Tm, Ym, Exp_Ctrls{i,2}, p);
    ExpData(i).Nominal = Dn; ExpData(i).Maneuver = Dm; ExpData(i).Name = Exp_Names{i};

    % --- (a) 独立保存：3D 轨迹图 ---
    figure('Color', 'w', 'Name', [Exp_Names{i} '_3D_Traj']);
    plot3(Dn.lon, Dn.lat, Dn.h, 'k--', 'LineWidth', 1.2); hold on;
    plot3(Dm.lon, Dm.lat, Dm.h, 'b-', 'LineWidth', 1.2);
    grid on; axis square; view(225, 25);
    xlabel('Longitude (\circ)'); ylabel('Latitude (\circ)'); zlabel('Height (km)');
    legend('Nominal', 'Maneuver', 'Location', 'best');
    title(['3D Trajectory - ' Exp_Names{i}]);
    
    save_traj = ['Scenario_' Exp_Names{i} '_Traj_a.png'];
    exportgraphics(gcf, save_traj, 'Resolution', 300);
    fprintf('轨迹图已保存: %s\n', save_traj);

    % --- (b) 独立保存：控制律曲线 (alpha & gamma) ---
    figure('Color', 'w', 'Name', [Exp_Names{i} '_Control_History']);
    yyaxis left
    plot(Dn.t, Dn.alpha_deg, 'k:', 'LineWidth', 1); hold on;
    plot(Dm.t, Dm.alpha_deg, 'b-', 'LineWidth', 1.5);
    ylabel('Attack Angle \alpha (deg)');
    ylim([-120, 120]);
    
    yyaxis right
    plot(Dn.t, Dn.gamma_deg, 'k--', 'LineWidth', 1); hold on;
    plot(Dm.t, Dm.gamma_deg, 'r-', 'LineWidth', 1.5);
    ylabel('Bank Angle \gamma (deg)');
    ylim([-120, 120]);
    
    grid on; xlabel('Time (s)');
    title(['Control History (\alpha & \gamma) - ' Exp_Names{i}]);
    legend('\alpha Nominal', '\alpha Maneuver', '\gamma Nominal', '\gamma Maneuver', ...
           'Location', 'southoutside', 'Orientation', 'horizontal');

    save_ctrl = ['Scenario_' Exp_Names{i} '_Control_b.png'];
    exportgraphics(gcf, save_ctrl, 'Resolution', 300);
    fprintf('控制律图已保存: %s\n', save_ctrl);
end

%% 4. 辅助函数
function dydt = dynamics_cavh(t, y, ctrl, p)
    v = y(1); th = y(2); r = y(6);
    h = r - p.Re; if h <= 0, dydt=zeros(6,1); return; end
    [rho, a_s] = atmosphere_US76_manual(h);
    Ma = v / a_s; alpha = deg2rad(ctrl.alpha(t)); gamma = deg2rad(ctrl.gamma(t));
    CL = p.coef_L(1) + p.coef_L(2)*alpha + p.coef_L(3)*alpha^2 + p.coef_L(4)*Ma + p.coef_L(5)*exp(p.coef_L(6)*Ma);
    CD = p.coef_D(1) + p.coef_D(2)*alpha + p.coef_D(3)*alpha^2 + p.coef_D(4)*Ma + p.coef_D(5)*exp(p.coef_D(6)*Ma);
    Q = 0.5 * rho * v^2 * p.S; L = Q * CL; D = Q * CD;
    dv = -D/p.m - p.mu/r^2 * sin(th);
    dth = (L*cos(gamma) - p.m*p.g0*cos(th) + p.m*v^2/r*cos(th)) / (p.m*v);
    dsi = -(L*sin(gamma)) / (p.m*v*cos(th)) + (v/r)*cos(th)*sin(y(3))*tan(y(4));
    dph = v*cos(th)*cos(y(3)) / r; dla = -v*cos(th)*sin(y(3)) / (r*cos(y(4))); dr = v*sin(th);
    dydt = [dv; dth; dsi; dph; dla; dr];
end

function [Data, Params] = process_sim(T, Y, ctrl, p)
    Data.t = T; Data.lat = rad2deg(Y(:,4)); Data.lon = rad2deg(Y(:,5));
    Data.h = (Y(:,6) - p.Re)/1000; 
    Data.gamma_deg = arrayfun(ctrl.gamma, T);
    Data.alpha_deg = arrayfun(ctrl.alpha, T); 
    Params = []; 
end

function [rho, a] = atmosphere_US76_manual(h)
    h_km = h/1000;
    if h_km < 11, T = 288.15 - 6.5*h_km; P = 101325 * (T/288.15)^5.256;
    elseif h_km < 20, T = 216.65; P = 22632 * exp(-0.1577*(h_km-11));
    elseif h_km < 32, T = 216.65 + (h_km-20); P = 5474.9 * (216.65/T)^34.163;
    elseif h_km < 47, T = 228.65 + 2.8*(h_km-32); P = 868.02 * (228.65/T)^12.201;
    elseif h_km < 51, T = 270.65; P = 110.91 * exp(-0.1262*(h_km-47));
    elseif h_km < 71, T = 270.65 - 2.8*(h_km-51); P = 66.939 * (T/270.65)^12.201;
    else, T = 214.65 - 2.0*(h_km-71); P = 3.9564 * (T/214.65)^17.082;
    end
    rho = P / (287.05 * T); a = sqrt(1.4 * 287.05 * T);
end

function [v, is, di] = events_landing(t, y, p), v = y(6)-p.Re; is = 1; di = -1; end