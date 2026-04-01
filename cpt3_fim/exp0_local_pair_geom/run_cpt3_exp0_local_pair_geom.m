function out = run_cpt3_exp0_local_pair_geom(verbose)
% 第三章实验0（口径回正版）：
% 双传感器局部几何与 M_G 稳定域实验
%
% 口径回正内容：
% 1) 输出目录统一写入根目录 outputs/cpt3/exp0_local_pair_geom/
% 2) 不再使用 fragile / safe / wide-safe 术语
%    统一改为 low_M_G / mid_M_G / high_M_G
% 3) 在 summary 中明确说明本实验与第三章现有算例 A/B 的衔接：
%    - 本实验：局部双传感器几何 -> M_G 稳定域
%    - 算例 A：几何退化路径下 M_G(\eta) 的塌陷
%    - 算例 B：固定几何下 M_A(\alpha) 的边际递减与饱和
%
% 物理设定：
% - 卫星高度 hs = 1000 km
% - 目标高度 ht ∈ {30,40,50} km
% - 双传感器同高度、对称布局
% - bearing-only Fisher 模型
%
% 输出图：
%   Fig1: baseline vs crossing angle
%   Fig2: baseline vs lambda_min / CRLB_weak
%   Fig3: lambda_min heatmaps for low/mid/high M_G anchors
%   Fig4: empirical geometry stability radius R_geo
%   Fig5: recommended Phase08 box half-span and spatial step

if nargin < 1
    verbose = true;
end

out_root = fullfile(pwd, 'outputs', 'cpt3', 'exp0_local_pair_geom');
fig_dir  = fullfile(out_root, 'figs');
tbl_dir  = fullfile(out_root, 'tables');
mat_dir  = fullfile(out_root, 'mats');
log_dir  = fullfile(out_root, 'logs');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end

%% 参数
p = local_default_params();

%% 主实验：中心点 baseline 扫描
b_grid = p.baseline_grid_km(:).';
theta_num_deg = zeros(size(b_grid));
theta_formula_deg = zeros(size(b_grid));
MG_center = zeros(size(b_grid));
crlb_weak_center = zeros(size(b_grid));

for i = 1:numel(b_grid)
    b = b_grid(i);

    tgt = [0; 0; p.h_tgt_ref_km];
    sat1 = [-b/2; 0; p.h_sat_km];
    sat2 = [ b/2; 0; p.h_sat_km];

    met = local_pair_metrics(tgt, sat1, sat2, p.sigma_theta_rad);

    theta_num_deg(i) = met.crossing_angle_deg;
    theta_formula_deg(i) = 2*atan2d(b/2, p.h_sat_km - p.h_tgt_ref_km);
    MG_center(i) = met.lambda_min;
    crlb_weak_center(i) = met.crlb_weak_km;
end

%% 三个基线锚点：由目标交叉角反推
theta_anchor_deg = p.theta_anchor_deg(:).';
b_anchor_km = 2*(p.h_sat_km - p.h_tgt_ref_km) .* tand(theta_anchor_deg/2);

%% 计算 anchor 中心点 M_G，形成 low/mid/high M_G 分区阈值
MG_anchor = zeros(size(theta_anchor_deg));
for i = 1:numel(b_anchor_km)
    b = b_anchor_km(i);
    tgt = [0; 0; p.h_tgt_ref_km];
    sat1 = [-b/2; 0; p.h_sat_km];
    sat2 = [ b/2; 0; p.h_sat_km];
    met = local_pair_metrics(tgt, sat1, sat2, p.sigma_theta_rad);
    MG_anchor(i) = met.lambda_min;
end

MG_thr_12 = 0.5*(MG_anchor(1) + MG_anchor(2));
MG_thr_23 = 0.5*(MG_anchor(2) + MG_anchor(3));

%% 局部 (x,y) 扫描，求 M_G 稳定域
xg = p.xy_grid_km(:).';
yg = p.xy_grid_km(:).';
[X, Y] = meshgrid(xg, yg);
R = hypot(X, Y);

H_list = p.h_tgt_list_km(:).';
V_list = p.v_tgt_list_kmps(:).';
Tw_list = p.Tw_list_s(:).';

nB = numel(b_anchor_km);
nH = numel(H_list);

MG_maps = cell(nB, nH);
MG_region_maps = cell(nB, nH);
R_geo = zeros(nB, nH);
center_region = strings(nB, nH);
center_MG = zeros(nB, nH);

for ib = 1:nB
    b = b_anchor_km(ib);

    for ih = 1:nH
        ht = H_list(ih);

        Mmap = zeros(size(X));
        RegionMap = strings(size(X));

        for ix = 1:size(X,1)
            for iy = 1:size(X,2)
                tgt = [X(ix,iy); Y(ix,iy); ht];
                sat1 = [-b/2; 0; p.h_sat_km];
                sat2 = [ b/2; 0; p.h_sat_km];

                met = local_pair_metrics(tgt, sat1, sat2, p.sigma_theta_rad);
                Mmap(ix,iy) = met.lambda_min;

                if met.lambda_min <= MG_thr_12
                    RegionMap(ix,iy) = "low_M_G";
                elseif met.lambda_min <= MG_thr_23
                    RegionMap(ix,iy) = "mid_M_G";
                else
                    RegionMap(ix,iy) = "high_M_G";
                end
            end
        end

        MG_maps{ib,ih} = Mmap;
        MG_region_maps{ib,ih} = RegionMap;

        [~, cx] = min(abs(xg - 0));
        [~, cy] = min(abs(yg - 0));
        M0 = Mmap(cy, cx);
        reg0 = RegionMap(cy, cx);

        center_MG(ib,ih) = M0;
        center_region(ib,ih) = reg0;

        switch char(reg0)
            case 'low_M_G'
                gap = MG_thr_12 - M0;
            case 'mid_M_G'
                gap = min(M0 - MG_thr_12, MG_thr_23 - M0);
            otherwise
                gap = M0 - MG_thr_23;
        end
        gap = max(gap, eps);

        stable_mask = (RegionMap == reg0) & (abs(Mmap - M0) <= gap);

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
    end
end

%% Phase08 盒尺寸反推：只使用中/高 M_G 区
trusted_mask = center_region ~= "low_M_G";
R_geo_trusted = R_geo(trusted_mask);
R_geo_trusted = R_geo_trusted(isfinite(R_geo_trusted) & R_geo_trusted > 0);

Bxy_rec_nominal = zeros(numel(V_list), numel(Tw_list));
Bxy_rec_conservative = zeros(numel(V_list), numel(Tw_list));

for iv = 1:numel(V_list)
    v = V_list(iv);
    for it = 1:numel(Tw_list)
        Tw = Tw_list(it);
        motion_half = v * Tw / 2;

        B_nom = median(max(R_geo_trusted - motion_half, 0));
        B_con = min(max(R_geo_trusted - motion_half, 0));

        Bxy_rec_nominal(iv,it) = B_nom;
        Bxy_rec_conservative(iv,it) = B_con;
    end
end

Bz_rec_half = 0.5 * (max(H_list) - min(H_list));

%% 空间步长：边界保持步长
step_xy_candidates = R_geo_trusted / p.N_resolve;
step_xy_rec_nominal = median(step_xy_candidates);
step_xy_rec_conservative = min(step_xy_candidates);

%% 作图
f1 = figure('Name','exp0_fig1_baseline_vs_crossing');
plot(b_grid, theta_num_deg, 'LineWidth', 2); hold on; grid on;
plot(b_grid, theta_formula_deg, '--', 'LineWidth', 1.5);
xline(b_anchor_km(1), '--'); xline(b_anchor_km(2), '--'); xline(b_anchor_km(3), '--');
xlabel('Baseline length b (km)');
ylabel('Crossing angle \theta (deg)');
legend({'Numerical','Analytical'}, 'Location','best');
title('Baseline length vs crossing angle');
saveas(f1, fullfile(fig_dir, 'exp0_fig1_baseline_vs_crossing.png'));

f2 = figure('Name','exp0_fig2_baseline_vs_MG_crlb');
yyaxis left
plot(b_grid, MG_center, 'LineWidth', 2); hold on; grid on;
ylabel('M_G = \lambda_{min}(J)');
yyaxis right
plot(b_grid, crlb_weak_center, '--', 'LineWidth', 2);
ylabel('Weak-direction CRLB std bound (km)');
xlabel('Baseline length b (km)');
title('Baseline length vs M_G / CRLB');
saveas(f2, fullfile(fig_dir, 'exp0_fig2_baseline_vs_MG_crlb.png'));

f3 = figure('Name','exp0_fig3_MG_heatmaps');
for k = 1:3
    subplot(1,3,k);
    imagesc(xg, yg, MG_maps{k,2}); % h = 40 km
    set(gca, 'YDir', 'normal');
    xlabel('x (km)');
    ylabel('y (km)');
    title(sprintf('M_G map, b=%.0f km, h=40km', b_anchor_km(k)));
    colorbar;
end
saveas(f3, fullfile(fig_dir, 'exp0_fig3_MG_heatmaps.png'));

f4 = figure('Name','exp0_fig4_Rgeo');
hold on; grid on;
for ih = 1:nH
    plot(1:nB, R_geo(:,ih), '-o', 'LineWidth', 2, 'DisplayName', sprintf('h=%dkm', round(H_list(ih))));
end
set(gca, 'XTick', 1:nB, 'XTickLabel', compose('b=%.0f', b_anchor_km));
xlabel('Baseline anchor');
ylabel('Empirical geometry stability radius R_{geo} (km)');
title('M_G stability radius from simulation');
legend('Location','best');
saveas(f4, fullfile(fig_dir, 'exp0_fig4_Rgeo.png'));

f5 = figure('Name','exp0_fig5_phase08_box_step');
subplot(1,2,1);
hold on; grid on;
for iv = 1:numel(V_list)
    plot(Tw_list, Bxy_rec_nominal(iv,:), '-o', 'LineWidth', 2, 'DisplayName', sprintf('nominal, v=%.1f', V_list(iv)));
    plot(Tw_list, Bxy_rec_conservative(iv,:), '--s', 'LineWidth', 1.5, 'DisplayName', sprintf('cons., v=%.1f', V_list(iv)));
end
xlabel('Window length T_w (s)');
ylabel('Recommended B_{xy}^{rec} half-span (km)');
title('Phase08 box half-span from M_G stability domain');
legend('Location','best');

subplot(1,2,2);
bar([step_xy_rec_conservative, step_xy_rec_nominal]);
set(gca, 'XTickLabel', {'\Deltas_{xy}'});
ylabel('Recommended spatial step (km)');
title('Boundary-preserving spatial step');
saveas(f5, fullfile(fig_dir, 'exp0_fig5_phase08_box_step.png'));

%% summary
txt_path = fullfile(tbl_dir, 'exp0_local_pair_geom_summary.txt');
fid = fopen(txt_path, 'w');
assert(fid >= 0, 'Failed to open summary file.');

fprintf(fid, '=== Chapter 3 Experiment 0: Local Pair Geometry and M_G Stability Summary ===\n');
fprintf(fid, 'output_root = %s\n', out_root);
fprintf(fid, 'h_sat_km = %.3f\n', p.h_sat_km);
fprintf(fid, 'h_tgt_ref_km = %.3f\n', p.h_tgt_ref_km);
fprintf(fid, 'delta_h_ref_km = %.3f\n', p.h_sat_km - p.h_tgt_ref_km);
fprintf(fid, 'sigma_theta_rad = %.8e\n', p.sigma_theta_rad);
fprintf(fid, '\n');

fprintf(fid, '--- Relation to Chapter 3 existing experiments ---\n');
fprintf(fid, 'Experiment 0: local pair geometry -> center-point M_G -> local M_G stability radius R_geo\n');
fprintf(fid, 'Case A: generalized geometry-degeneration path -> M_G(eta) collapse and condition-number spike\n');
fprintf(fid, 'Case B: fixed geometry -> M_A(alpha) marginal saturation and Supply_w interpretation\n');
fprintf(fid, '\n');

fprintf(fid, '--- Reference baseline anchors and corresponding center-point M_G levels ---\n');
for i = 1:numel(theta_anchor_deg)
    fprintf(fid, 'theta = %.1f deg -> baseline = %.3f km, center_M_G = %.6f\n', ...
        theta_anchor_deg(i), b_anchor_km(i), MG_anchor(i));
end
fprintf(fid, 'M_G_thr_12 = %.6f\n', MG_thr_12);
fprintf(fid, 'M_G_thr_23 = %.6f\n', MG_thr_23);
fprintf(fid, '\n');

fprintf(fid, '--- Empirical M_G stability radius R_geo (km) ---\n');
for ib = 1:nB
    for ih = 1:nH
        fprintf(fid, 'b=%.3f km, h=%g km -> region=%s, R_geo=%.3f km\n', ...
            b_anchor_km(ib), H_list(ih), char(center_region(ib,ih)), R_geo(ib,ih));
    end
end
fprintf(fid, '\n');

fprintf(fid, '--- Trusted radii used for Phase08 recommendation ---\n');
fprintf(fid, 'Only middle/high M_G regions are used.\n');
fprintf(fid, 'trusted_count = %d\n', numel(R_geo_trusted));
fprintf(fid, 'trusted_R_geo_min = %.3f km\n', min(R_geo_trusted));
fprintf(fid, 'trusted_R_geo_median = %.3f km\n', median(R_geo_trusted));
fprintf(fid, 'trusted_R_geo_max = %.3f km\n', max(R_geo_trusted));
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
fprintf(fid, 'N_resolve = %d points from center to boundary\n', p.N_resolve);
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

log_path = fullfile(log_dir, 'exp0_local_pair_geom_log.txt');
fid = fopen(log_path, 'w');
assert(fid >= 0, 'Failed to open log file.');
fprintf(fid, '[INFO] Experiment 0 output root: %s\n', out_root);
fprintf(fid, '[INFO] trusted_count = %d\n', numel(R_geo_trusted));
fprintf(fid, '[INFO] trusted_R_geo_range = [%.3f, %.3f] km\n', min(R_geo_trusted), max(R_geo_trusted));
fprintf(fid, '[INFO] Bxy_nominal_range = [%.3f, %.3f] km\n', min(Bxy_rec_nominal, [], 'all'), max(Bxy_rec_nominal, [], 'all'));
fprintf(fid, '[INFO] Bxy_conservative_range = [%.3f, %.3f] km\n', min(Bxy_rec_conservative, [], 'all'), max(Bxy_rec_conservative, [], 'all'));
fprintf(fid, '[INFO] step_xy = [%.3f, %.3f] km\n', step_xy_rec_conservative, step_xy_rec_nominal);
fclose(fid);

mat_path = fullfile(mat_dir, 'exp0_local_pair_geom.mat');
save(mat_path, 'p', 'b_grid', 'theta_num_deg', 'theta_formula_deg', ...
    'MG_center', 'crlb_weak_center', 'theta_anchor_deg', 'b_anchor_km', ...
    'MG_anchor', 'MG_thr_12', 'MG_thr_23', ...
    'xg', 'yg', 'X', 'Y', 'R', 'MG_maps', 'MG_region_maps', ...
    'R_geo', 'center_region', 'center_MG', 'R_geo_trusted', ...
    'H_list', 'V_list', 'Tw_list', 'Bxy_rec_nominal', 'Bxy_rec_conservative', ...
    'Bz_rec_half', 'step_xy_candidates', 'step_xy_rec_conservative', 'step_xy_rec_nominal');

if verbose
    disp('=== Chapter 3 Experiment 0 Summary ===')
    fprintf('baseline anchors for theta=[30,60,80] deg -> [%.3f, %.3f, %.3f] km\n', ...
        b_anchor_km(1), b_anchor_km(2), b_anchor_km(3));
    fprintf('trusted R_geo range (middle/high M_G only) = [%.3f, %.3f] km\n', ...
        min(R_geo_trusted), max(R_geo_trusted));
    fprintf('recommended Bxy_half nominal range (km): [%.3f, %.3f]\n', ...
        min(Bxy_rec_nominal, [], 'all'), max(Bxy_rec_nominal, [], 'all'));
    fprintf('recommended Bxy_half conservative range (km): [%.3f, %.3f]\n', ...
        min(Bxy_rec_conservative, [], 'all'), max(Bxy_rec_conservative, [], 'all'));
    fprintf('recommended Bz_half = %.3f km\n', Bz_rec_half);
    fprintf('recommended xy step (cons., nom.) = [%.3f, %.3f] km\n', ...
        step_xy_rec_conservative, step_xy_rec_nominal);
    disp(['[exp0] figs : ', fig_dir]);
    disp(['[exp0] text : ', txt_path]);
    disp(['[exp0] log  : ', log_path]);
    disp(['[exp0] mat  : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.fig_dir = fig_dir;
out.table_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
end

function p = local_default_params()
p = struct();

p.h_sat_km = 1000;
p.h_tgt_ref_km = 40;
p.h_tgt_list_km = [30, 40, 50];

p.sigma_theta_rad = 10 / 206265;

p.baseline_grid_km = 200:100:2000;
p.theta_anchor_deg = [30, 60, 80];

p.xy_grid_km = -800:50:800;

p.v_tgt_list_kmps = [4.0, 4.5, 5.0];
p.Tw_list_s = [20, 30, 40];

p.N_resolve = 4;
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
