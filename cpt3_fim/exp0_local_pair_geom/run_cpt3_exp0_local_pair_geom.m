function out = run_cpt3_exp0_local_pair_geom(verbose)
% 第三章补充实验0（重设计版）：
% 双传感器局部几何稳定域实验
%
% 目标：
% 1) 扫描基线长度 b，研究中心点 crossing angle / lambda_min / CRLB；
% 2) 在 (x,y) 平面上扫描局部几何，构造几何稳定域；
% 3) 由稳定域半径反推第五章 Phase08 的参考盒尺寸；
% 4) 由局部梯度反推数据点稀疏采样的最大步长。
%
% 与旧版不同：
% - 不再使用经验安全系数 alpha；
% - 参考盒尺寸与采样步长完全由仿真结果反推。
%
% 物理设定：
% - 卫星高度 hs = 1000 km
% - 目标高度 ht ∈ {30, 40, 50} km
% - 双传感器同高度、对称布局
% - 测量模型采用简化 bearing-only Fisher 模型
%
% 输出图：
%   Fig1: baseline vs crossing angle
%   Fig2: baseline vs lambda_min / CRLB_weak
%   Fig3: lambda_min heatmap for fragile/safe/wide-safe anchors
%   Fig4: empirical geometry stability radius R_geo
%   Fig5: recommended Phase08 Bxy_half and spatial step

if nargin < 1
    verbose = true;
end

out_root = fullfile(pwd, 'cpt3_fim', 'outputs', 'exp0_local_pair_geom');
fig_dir  = fullfile(out_root, 'figs');
tbl_dir  = fullfile(out_root, 'tables');
mat_dir  = fullfile(out_root, 'mats');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end

%% 参数
p = local_default_params();

%% 主实验：中心点 baseline 扫描
b_grid = p.baseline_grid_km(:).';
theta_num_deg = zeros(size(b_grid));
theta_formula_deg = zeros(size(b_grid));
lambda_center = zeros(size(b_grid));
crlb_weak_center = zeros(size(b_grid));

for i = 1:numel(b_grid)
    b = b_grid(i);

    tgt = [0; 0; p.h_tgt_ref_km];
    sat1 = [-b/2; 0; p.h_sat_km];
    sat2 = [ b/2; 0; p.h_sat_km];

    met = local_pair_metrics(tgt, sat1, sat2, p.sigma_theta_rad);

    theta_num_deg(i) = met.crossing_angle_deg;
    theta_formula_deg(i) = 2*atan2d(b/2, p.h_sat_km - p.h_tgt_ref_km);
    lambda_center(i) = met.lambda_min;
    crlb_weak_center(i) = met.crlb_weak_km;
end

%% 三个基线锚点：由目标交叉角反推，不靠经验
theta_anchor_deg = p.theta_anchor_deg(:).';
b_anchor_km = 2*(p.h_sat_km - p.h_tgt_ref_km) .* tand(theta_anchor_deg/2);

%% 用仿真计算三个 anchor 的中心点 lambda，形成类间边界
lambda_anchor = zeros(size(theta_anchor_deg));
for i = 1:numel(b_anchor_km)
    b = b_anchor_km(i);
    tgt = [0; 0; p.h_tgt_ref_km];
    sat1 = [-b/2; 0; p.h_sat_km];
    sat2 = [ b/2; 0; p.h_sat_km];
    met = local_pair_metrics(tgt, sat1, sat2, p.sigma_theta_rad);
    lambda_anchor(i) = met.lambda_min;
end

% fragile / safe / wide-safe 的 lambda 边界，完全由仿真 anchor 中点给出
lambda_thr_12 = 0.5*(lambda_anchor(1) + lambda_anchor(2));
lambda_thr_23 = 0.5*(lambda_anchor(2) + lambda_anchor(3));

%% 局部 (x,y) 几何稳定域扫描
xg = p.xy_grid_km(:).';
yg = p.xy_grid_km(:).';
[X, Y] = meshgrid(xg, yg);
R = hypot(X, Y);

H_list = p.h_tgt_list_km(:).';
V_list = p.v_tgt_list_kmps(:).';
Tw_list = p.Tw_list_s(:).';

nB = numel(b_anchor_km);
nH = numel(H_list);

lambda_maps = cell(nB, nH);
label_maps = cell(nB, nH);
R_geo = zeros(nB, nH);
step_xy_max = zeros(nB, nH);
center_label = strings(nB, nH);
center_lambda = zeros(nB, nH);

for ib = 1:nB
    b = b_anchor_km(ib);

    for ih = 1:nH
        ht = H_list(ih);

        Lmap = zeros(size(X));
        Mlabel = strings(size(X));

        for ix = 1:size(X,1)
            for iy = 1:size(X,2)
                tgt = [X(ix,iy); Y(ix,iy); ht];
                sat1 = [-b/2; 0; p.h_sat_km];
                sat2 = [ b/2; 0; p.h_sat_km];

                met = local_pair_metrics(tgt, sat1, sat2, p.sigma_theta_rad);
                Lmap(ix,iy) = met.lambda_min;

                if met.lambda_min <= lambda_thr_12
                    Mlabel(ix,iy) = "geometry_fragile";
                elseif met.lambda_min <= lambda_thr_23
                    Mlabel(ix,iy) = "safe";
                else
                    Mlabel(ix,iy) = "wide_safe";
                end
            end
        end

        lambda_maps{ib,ih} = Lmap;
        label_maps{ib,ih} = Mlabel;

        % 中心点索引
        [~, cx] = min(abs(xg - 0));
        [~, cy] = min(abs(yg - 0));
        lam0 = Lmap(cy, cx);
        lab0 = Mlabel(cy, cx);

        center_lambda(ib,ih) = lam0;
        center_label(ib,ih) = lab0;

        % 类间裕度：由当前中心点到最近边界的 lambda 距离给出
        switch char(lab0)
            case 'geometry_fragile'
                gap = lambda_thr_12 - lam0;
            case 'safe'
                gap = min(lam0 - lambda_thr_12, lambda_thr_23 - lam0);
            otherwise % wide_safe
                gap = lam0 - lambda_thr_23;
        end
        gap = max(gap, eps);

        % 稳定域：标签不变，且 lambda 偏离不超过类间裕度
        stable_mask = (Mlabel == lab0) & (abs(Lmap - lam0) <= gap);

        % 几何稳定半径 R_geo：最大 r，使得半径<=r 的所有采样点都稳定
        radii = unique(sort(R(:), 'ascend'));
        r_keep = 0;
        for ir = 1:numel(radii)
            rr = radii(ir);
            inside = (R <= rr + 1e-12);
            if all(stable_mask(inside), 'all')
                r_keep = rr;
            else
                break;
            end
        end
        R_geo(ib,ih) = r_keep;

        % 中心梯度 -> 最大允许步长（由仿真结果直接反推）
        dx = xg(2) - xg(1);
        dy = yg(2) - yg(1);

        if cx > 1 && cx < numel(xg) && cy > 1 && cy < numel(yg)
            dLdx = (Lmap(cy, cx+1) - Lmap(cy, cx-1)) / (2*dx);
            dLdy = (Lmap(cy+1, cx) - Lmap(cy-1, cx)) / (2*dy);
            grad_norm = sqrt(dLdx^2 + dLdy^2);
        else
            grad_norm = NaN;
        end

        if isnan(grad_norm) || grad_norm < eps
            step_xy_max(ib,ih) = inf;
        else
            step_xy_max(ib,ih) = gap / grad_norm;
        end
    end
end

%% 由 R_geo 反推 Phase08 参考盒大小：不再使用 alpha
% 以窗口中心为 atlas 样本时刻，则目标在半窗口内最大运动距离约为 v*Tw/2
Bxy_rec_nominal = zeros(numel(V_list), numel(Tw_list));
Bxy_rec_conservative = zeros(numel(V_list), numel(Tw_list));

R_geo_all = R_geo(:);
R_geo_all = R_geo_all(isfinite(R_geo_all));

for iv = 1:numel(V_list)
    v = V_list(iv);
    for it = 1:numel(Tw_list)
        Tw = Tw_list(it);
        motion_half = v * Tw / 2;

        B_nom = median(max(R_geo_all - motion_half, 0));
        B_con = min(max(R_geo_all - motion_half, 0));

        Bxy_rec_nominal(iv,it) = B_nom;
        Bxy_rec_conservative(iv,it) = B_con;
    end
end

% 垂向盒：由目标高度带宽直接反推
Bz_rec_half = 0.5 * (max(H_list) - min(H_list));

%% 由仿真结果给出采样稀疏程度建议
step_all = step_xy_max(:);
step_all = step_all(isfinite(step_all) & step_all > 0);

step_xy_rec_nominal = median(step_all);
step_xy_rec_conservative = min(step_all);

%% 作图
% Fig1
f1 = figure('Name','exp0_fig1_baseline_vs_crossing');
plot(b_grid, theta_num_deg, 'LineWidth', 2); hold on; grid on;
plot(b_grid, theta_formula_deg, '--', 'LineWidth', 1.5);
xline(b_anchor_km(1), '--'); xline(b_anchor_km(2), '--'); xline(b_anchor_km(3), '--');
xlabel('Baseline length b (km)');
ylabel('Crossing angle \theta (deg)');
legend({'Numerical','Analytical'}, 'Location','best');
title('Baseline length vs crossing angle');
saveas(f1, fullfile(fig_dir, 'exp0_fig1_baseline_vs_crossing.png'));

% Fig2
f2 = figure('Name','exp0_fig2_baseline_vs_lambda_crlb');
yyaxis left
plot(b_grid, lambda_center, 'LineWidth', 2); hold on; grid on;
ylabel('\lambda_{min}(J)');
yyaxis right
plot(b_grid, crlb_weak_center, '--', 'LineWidth', 2);
ylabel('Weak-direction CRLB std bound (km)');
xlabel('Baseline length b (km)');
title('Baseline length vs weakest-direction information / CRLB');
saveas(f2, fullfile(fig_dir, 'exp0_fig2_baseline_vs_lambda_crlb.png'));

% Fig3: fragile/safe/wide-safe 三张热图
f3 = figure('Name','exp0_fig3_lambda_heatmaps');
for k = 1:3
    subplot(1,3,k);
    imagesc(xg, yg, lambda_maps{k,2});  % 取 h=40km 中间层
    set(gca, 'YDir', 'normal');
    xlabel('x (km)');
    ylabel('y (km)');
    title(sprintf('lambda map, b=%.0f km, h=40km', b_anchor_km(k)));
    colorbar;
end
saveas(f3, fullfile(fig_dir, 'exp0_fig3_lambda_heatmaps.png'));

% Fig4: R_geo
f4 = figure('Name','exp0_fig4_Rgeo');
hold on; grid on;
for ih = 1:nH
    plot(1:nB, R_geo(:,ih), '-o', 'LineWidth', 2, 'DisplayName', sprintf('h=%dkm', round(H_list(ih))));
end
set(gca, 'XTick', 1:nB, 'XTickLabel', compose('b=%.0f', b_anchor_km));
xlabel('Baseline anchor');
ylabel('Empirical geometry stability radius R_{geo} (km)');
title('Geometry stability radius from simulation');
legend('Location','best');
saveas(f4, fullfile(fig_dir, 'exp0_fig4_Rgeo.png'));

% Fig5: Phase08 box and step
f5 = figure('Name','exp0_fig5_phase08_box_step');
subplot(1,2,1);
hold on; grid on;
for iv = 1:numel(V_list)
    plot(Tw_list, Bxy_rec_nominal(iv,:), '-o', 'LineWidth', 2, 'DisplayName', sprintf('nominal, v=%.1f', V_list(iv)));
    plot(Tw_list, Bxy_rec_conservative(iv,:), '--s', 'LineWidth', 1.5, 'DisplayName', sprintf('cons., v=%.1f', V_list(iv)));
end
xlabel('Window length T_w (s)');
ylabel('Recommended B_{xy}^{rec} half-span (km)');
title('Phase08 box half-span from simulation');
legend('Location','best');

subplot(1,2,2);
bar([step_xy_rec_conservative, step_xy_rec_nominal]);
set(gca, 'XTickLabel', {'\Deltas_{xy}'});
ylabel('Recommended spatial step (km)');
title('Spatial sparsity bound from simulation');
saveas(f5, fullfile(fig_dir, 'exp0_fig5_phase08_box_step.png'));

%% 文本总结
txt_path = fullfile(tbl_dir, 'exp0_local_pair_geom_summary.txt');
fid = fopen(txt_path, 'w');
assert(fid >= 0, 'Failed to open summary file.');

fprintf(fid, '=== Chapter 3 Experiment 0: Local Pair Geometry Stability Summary ===\n');
fprintf(fid, 'h_sat_km = %.3f\n', p.h_sat_km);
fprintf(fid, 'h_tgt_ref_km = %.3f\n', p.h_tgt_ref_km);
fprintf(fid, 'delta_h_ref_km = %.3f\n', p.h_sat_km - p.h_tgt_ref_km);
fprintf(fid, 'sigma_theta_rad = %.8e\n', p.sigma_theta_rad);
fprintf(fid, '\n');

fprintf(fid, '--- Baseline anchors from target crossing angles ---\n');
for i = 1:numel(theta_anchor_deg)
    fprintf(fid, 'theta = %.1f deg -> baseline = %.3f km, lambda_anchor = %.6f\n', ...
        theta_anchor_deg(i), b_anchor_km(i), lambda_anchor(i));
end
fprintf(fid, 'lambda_thr_12 = %.6f\n', lambda_thr_12);
fprintf(fid, 'lambda_thr_23 = %.6f\n', lambda_thr_23);
fprintf(fid, '\n');

fprintf(fid, '--- Empirical geometry stability radius R_geo (km) ---\n');
for ib = 1:nB
    for ih = 1:nH
        fprintf(fid, 'b=%.3f km, h=%g km -> label=%s, R_geo=%.3f km, step_xy_max=%.3f km\n', ...
            b_anchor_km(ib), H_list(ih), char(center_label(ib,ih)), R_geo(ib,ih), step_xy_max(ib,ih));
    end
end
fprintf(fid, '\n');

fprintf(fid, '--- Recommended Phase08 local box half-span (km) ---\n');
for iv = 1:numel(V_list)
    for it = 1:numel(Tw_list)
        fprintf(fid, 'v=%.1f km/s, Tw=%d s -> nominal Bxy_half=%.3f km, conservative Bxy_half=%.3f km\n', ...
            V_list(iv), round(Tw_list(it)), Bxy_rec_nominal(iv,it), Bxy_rec_conservative(iv,it));
    end
end
fprintf(fid, 'Recommended Bz_half = %.3f km\n', Bz_rec_half);
fprintf(fid, '\n');

fprintf(fid, '--- Recommended spatial sampling step ---\n');
fprintf(fid, 'step_xy_rec_conservative = %.3f km\n', step_xy_rec_conservative);
fprintf(fid, 'step_xy_rec_nominal = %.3f km\n', step_xy_rec_nominal);
fprintf(fid, '\n');

fprintf(fid, '--- Suggested Stage15-F4 anchors ---\n');
fprintf(fid, 'baseline anchors (km): %.1f, %.1f, %.1f\n', b_anchor_km(1), b_anchor_km(2), b_anchor_km(3));
fprintf(fid, 'target altitude anchors (km): ');
fprintf(fid, '%.1f ', H_list);
fprintf(fid, '\n');
fprintf(fid, 'target speed anchors (km/s): ');
fprintf(fid, '%.1f ', V_list);
fprintf(fid, '\n');
fprintf(fid, 'coarse xy step should not exceed nominal %.1f km; boundary refinement may use conservative %.1f km.\n', ...
    step_xy_rec_nominal, step_xy_rec_conservative);

fclose(fid);

%% 保存 mat
mat_path = fullfile(mat_dir, 'exp0_local_pair_geom.mat');
save(mat_path, 'p', 'b_grid', 'theta_num_deg', 'theta_formula_deg', ...
    'lambda_center', 'crlb_weak_center', 'theta_anchor_deg', 'b_anchor_km', ...
    'lambda_anchor', 'lambda_thr_12', 'lambda_thr_23', ...
    'xg', 'yg', 'X', 'Y', 'R', 'lambda_maps', 'label_maps', ...
    'R_geo', 'step_xy_max', 'center_label', 'center_lambda', ...
    'H_list', 'V_list', 'Tw_list', 'Bxy_rec_nominal', 'Bxy_rec_conservative', ...
    'Bz_rec_half', 'step_xy_rec_conservative', 'step_xy_rec_nominal');

if verbose
    disp('=== Chapter 3 Experiment 0 Summary ===')
    fprintf('baseline anchors for theta=[30,60,80] deg -> [%.3f, %.3f, %.3f] km\n', ...
        b_anchor_km(1), b_anchor_km(2), b_anchor_km(3));
    fprintf('recommended Bxy_half nominal range (km): [%.3f, %.3f]\n', ...
        min(Bxy_rec_nominal, [], 'all'), max(Bxy_rec_nominal, [], 'all'));
    fprintf('recommended Bxy_half conservative range (km): [%.3f, %.3f]\n', ...
        min(Bxy_rec_conservative, [], 'all'), max(Bxy_rec_conservative, [], 'all'));
    fprintf('recommended Bz_half = %.3f km\n', Bz_rec_half);
    fprintf('recommended xy step (cons., nom.) = [%.3f, %.3f] km\n', ...
        step_xy_rec_conservative, step_xy_rec_nominal);
    disp(['[exp0] figs : ', fig_dir]);
    disp(['[exp0] text : ', txt_path]);
    disp(['[exp0] mat  : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.fig_dir = fig_dir;
out.table_file = txt_path;
out.mat_file = mat_path;
end

function p = local_default_params()
p = struct();

% 固定物理参数
p.h_sat_km = 1000;
p.h_tgt_ref_km = 40;
p.h_tgt_list_km = [30, 40, 50];

% 角度测量精度（10 arcsec）
p.sigma_theta_rad = 10 / 206265;

% 基线主扫描
p.baseline_grid_km = 200:100:2000;

% 三个交叉角锚点，对应 fragile/safe/wide-safe
p.theta_anchor_deg = [30, 60, 80];

% 局部平面探索域：直接继承第三章原始点扫范围，避免拍盒子
p.xy_grid_km = -800:50:800;

% 第五章窗口/速度取值
p.v_tgt_list_kmps = [4.0, 4.5, 5.0];
p.Tw_list_s = [20, 30, 40];
end

function met = local_pair_metrics(tgt, sat1, sat2, sigma_theta_rad)
J = zeros(3,3);

[Ji1, u1, rho1] = local_single_sensor_fim(tgt, sat1, sigma_theta_rad);
[Ji2, u2, rho2] = local_single_sensor_fim(tgt, sat2, sigma_theta_rad);

J = Ji1 + Ji2;

e = sort(real(eig(J)), 'ascend');
lambda_min = max(e(1), eps);
crlb_weak_km = sqrt(1 / lambda_min);

cosang = max(-1, min(1, dot(u1, u2)));
theta_deg = acosd(cosang);

met = struct();
met.J = J;
met.lambda_min = lambda_min;
met.crlb_weak_km = crlb_weak_km;
met.crossing_angle_deg = theta_deg;
met.rho1_km = rho1;
met.rho2_km = rho2;
end

function [Ji, u, rho] = local_single_sensor_fim(tgt, sat, sigma_theta_rad)
r = tgt - sat;
rho = norm(r);
u = r / max(rho, eps);
Ji = (eye(3) - u*u.') / (sigma_theta_rad^2 * rho^2);
end
