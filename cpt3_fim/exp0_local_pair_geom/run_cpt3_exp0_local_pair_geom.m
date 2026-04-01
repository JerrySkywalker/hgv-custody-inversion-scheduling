function out = run_cpt3_exp0_local_pair_geom(verbose)
% 第三章实验0（修正版 v3）：
% 双传感器局部几何与 M_G 稳定域实验
%
% 本版修正：
% 1) 同时输出 fig3_stacked 与 fig3plus
% 2) fig3_stacked 的 baseline 改成 500:100:1200
% 3) fig3plus 仍用 500 / 1000 / 1200
% 4) summary / log 同步记录 stacked 与 fig3plus 两套 baseline
%
% 输出目录：
% outputs/cpt3/exp0_local_pair_geom/

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

% 清理旧输出，避免不同步
local_safe_delete(fullfile(fig_dir, '*.png'));
local_safe_delete(fullfile(tbl_dir, '*.txt'));
local_safe_delete(fullfile(log_dir, '*.txt'));
local_safe_delete(fullfile(mat_dir, '*.mat'));

%% 参数
p = local_default_params();

%% 主实验：中心点 baseline 扫描（Fig1/Fig2）
b_grid = p.baseline_grid_km(:).';
theta_num_deg = zeros(size(b_grid));
MG_center = zeros(size(b_grid));
crlb_weak_center = zeros(size(b_grid));

for i = 1:numel(b_grid)
    b = b_grid(i);

    tgt = [0; 0; p.h_tgt_ref_km];
    sat1 = [-b/2; 0; p.h_sat_km];
    sat2 = [ b/2; 0; p.h_sat_km];

    met = local_pair_metrics(tgt, sat1, sat2, p.sigma_theta_rad);

    theta_num_deg(i) = met.crossing_angle_deg;
    MG_center(i) = met.lambda_min;
    crlb_weak_center(i) = met.crlb_weak_km;
end

%% 参考锚点（用于 threshold 与正文解释）
theta_anchor_deg = p.theta_anchor_deg(:).';
b_anchor_km = 2*(p.h_sat_km - p.h_tgt_ref_km) .* tand(theta_anchor_deg/2);

%% dense baseline（用于 Fig4 与 stacked fig3）
b_anchor_dense_km = p.baseline_dense_km(:).';

%% fig3plus baseline
b_fig3plus_km = p.baseline_fig3plus_km(:).';

%% 参考锚点中心 M_G 与阈值
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

%% 局部扫描网格
xg = p.xy_grid_km(:).';
yg = p.xy_grid_km(:).';
[X, Y] = meshgrid(xg, yg);
R = hypot(X, Y);

H_list = p.h_tgt_list_km(:).';
V_list = p.v_tgt_list_kmps(:).';
Tw_list = p.Tw_list_s(:).';

%% 参考锚点：用于 trusted 统计
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

        [Mmap, RegionMap] = local_scan_MG_map(X, Y, b, ht, p.h_sat_km, p.sigma_theta_rad, MG_thr_12, MG_thr_23);

        MG_maps{ib,ih} = Mmap;
        MG_region_maps{ib,ih} = RegionMap;

        [M0, reg0, r_keep] = local_compute_center_region_and_Rgeo(Mmap, RegionMap, xg, yg, R, MG_thr_12, MG_thr_23);

        center_MG(ib,ih) = M0;
        center_region(ib,ih) = reg0;
        R_geo(ib,ih) = r_keep;
    end
end

%% dense baseline：用于 Fig4 与 stacked fig3
nBd = numel(b_anchor_dense_km);
R_geo_dense = zeros(nBd, nH);
center_region_dense = strings(nBd, nH);
MG_maps_stacked = cell(1, nBd);

for ib = 1:nBd
    b = b_anchor_dense_km(ib);

    % stacked fig3 只取 h = 40 km
    [Mmap40, ~] = local_scan_MG_map(X, Y, b, p.h_tgt_ref_km, p.h_sat_km, p.sigma_theta_rad, MG_thr_12, MG_thr_23);
    MG_maps_stacked{ib} = Mmap40;

    for ih = 1:nH
        ht = H_list(ih);

        [Mmap, RegionMap] = local_scan_MG_map(X, Y, b, ht, p.h_sat_km, p.sigma_theta_rad, MG_thr_12, MG_thr_23);
        [~, reg0, r_keep] = local_compute_center_region_and_Rgeo(Mmap, RegionMap, xg, yg, R, MG_thr_12, MG_thr_23);

        center_region_dense(ib,ih) = reg0;
        R_geo_dense(ib,ih) = r_keep;
    end
end

%% fig3plus：b=500/1000/1200, h=40 km
nBp = numel(b_fig3plus_km);
MG_maps_fig3plus = cell(1, nBp);
for ib = 1:nBp
    b = b_fig3plus_km(ib);
    [Mmap, ~] = local_scan_MG_map(X, Y, b, p.h_tgt_ref_km, p.h_sat_km, p.sigma_theta_rad, MG_thr_12, MG_thr_23);
    MG_maps_fig3plus{ib} = Mmap;
end

%% Phase08 推荐：仅用中/高 M_G 区
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

%% ---------------- 作图 ----------------

% Fig1: 单曲线 + 锚点标注
f1 = figure('Name','exp0_fig1_baseline_vs_crossing');
plot(b_grid, theta_num_deg, 'LineWidth', 2); hold on; grid on;
plot(b_anchor_km, theta_anchor_deg, 'o', 'MarkerSize', 8, 'LineWidth', 1.5);
for i = 1:numel(b_anchor_km)
    text(b_anchor_km(i)+20, theta_anchor_deg(i)+1.0, ...
        sprintf('(%.0f km, %.0f^\\circ)', b_anchor_km(i), theta_anchor_deg(i)), ...
        'FontSize', 10);
end
xlabel('Baseline length b (km)');
ylabel('Crossing angle \theta (deg)');
title('Baseline length vs crossing angle');
saveas(f1, fullfile(fig_dir, 'exp0_fig1_baseline_vs_crossing.png'));
close(f1);

% Fig2
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
close(f2);

% Fig3_stacked: dense baseline = 500:100:1200, h=40 km
Mmin_stack = inf;
Mmax_stack = -inf;
for k = 1:nBd
    Mtmp = MG_maps_stacked{k};
    Mmin_stack = min(Mmin_stack, min(Mtmp, [], 'all'));
    Mmax_stack = max(Mmax_stack, max(Mtmp, [], 'all'));
end

f3s = figure('Name','exp0_fig3_stacked_MG_heatmaps');
hold on;
[Xs, Ys] = meshgrid(xg, yg);
z_stack = 1:nBd;
for k = 1:nBd
    Zplane = z_stack(k) * ones(size(Xs));
    C = MG_maps_stacked{k};
    surf(Xs, Zplane, Ys, C, 'EdgeColor', 'none', 'FaceColor', 'interp');
end
colormap(parula);
caxis([Mmin_stack, Mmax_stack]);
cb = colorbar;
cb.Label.String = 'M_G';

xlabel('x (km)');
ylabel('Baseline slice index');
zlabel('y (km)');
yticks(z_stack);
yticklabels(compose('b=%.0f km', b_anchor_dense_km));
title('Stacked M_G heatmaps at h=40 km');
view(85,20);
set(gcf,'unit','normalized','position',[0.08 0.15 0.84 0.42]);
saveas(f3s, fullfile(fig_dir, 'exp0_fig3_stacked_MG_heatmaps.png'));
close(f3s);

% Fig3_plus: 1x3, 正方形, 统一色标, 两条等值线
Mmin = inf;
Mmax = -inf;
for k = 1:nBp
    Mtmp = MG_maps_fig3plus{k};
    Mmin = min(Mmin, min(Mtmp, [], 'all'));
    Mmax = max(Mmax, max(Mtmp, [], 'all'));
end

f3p = figure('Name','exp0_fig3plus_MG_contours');
tiledlayout(1,3,'Padding','compact','TileSpacing','compact');
for k = 1:nBp
    nexttile;
    Mmap = MG_maps_fig3plus{k};

    imagesc(xg, yg, Mmap);
    set(gca, 'YDir', 'normal');
    axis equal;
    axis square;
    hold on;

    contour(xg, yg, Mmap, [MG_thr_12 MG_thr_12], 'w--', 'LineWidth', 1.5);
    contour(xg, yg, Mmap, [MG_thr_23 MG_thr_23], 'r-', 'LineWidth', 1.5);

    xlabel('x (km)');
    ylabel('y (km)');
    title(sprintf('M_G map, b=%.0f km, h=40km', b_fig3plus_km(k)));
    caxis([Mmin, Mmax]);
end
cb = colorbar;
cb.Layout.Tile = 'east';
cb.Label.String = 'M_G';
saveas(f3p, fullfile(fig_dir, 'exp0_fig3plus_MG_contours.png'));
close(f3p);

% Fig4: dense baseline = 500:100:1200
f4 = figure('Name','exp0_fig4_Rgeo_dense');
hold on; grid on;
for ih = 1:nH
    plot(b_anchor_dense_km, R_geo_dense(:,ih), '-o', 'LineWidth', 2, ...
        'DisplayName', sprintf('h=%dkm', round(H_list(ih))));
end
xlabel('Baseline length b (km)');
ylabel('Empirical geometry stability radius R_{geo} (km)');
title('M_G stability radius from simulation');
legend('Location','best');
saveas(f4, fullfile(fig_dir, 'exp0_fig4_Rgeo_dense.png'));
close(f4);

% Fig5
f5 = figure('Name','exp0_fig5_phase08_box_step');
subplot(1,2,1);
hold on; grid on;
for iv = 1:numel(V_list)
    plot(Tw_list, Bxy_rec_nominal(iv,:), '-o', 'LineWidth', 1.6, ...
        'DisplayName', sprintf('nominal, v=%.2f', V_list(iv)));
    plot(Tw_list, Bxy_rec_conservative(iv,:), '--', 'LineWidth', 1.1, ...
        'HandleVisibility', 'off');
end
xlabel('Window length T_w (s)');
ylabel('Recommended B_{xy}^{rec} half-span (km)');
title('Phase08 box half-span from simulation');
legend('Location','eastoutside');

subplot(1,2,2);
bar([step_xy_rec_conservative, step_xy_rec_nominal]);
set(gca, 'XTickLabel', {'\Delta s_{xy}'});
ylabel('Recommended spatial step (km)');
title('Boundary-preserving spatial step');
saveas(f5, fullfile(fig_dir, 'exp0_fig5_phase08_box_step.png'));
close(f5);

%% summary
txt_path = fullfile(tbl_dir, 'exp0_local_pair_geom_summary.txt');
fid = fopen(txt_path, 'w');
assert(fid >= 0, 'Failed to open summary file.');

fprintf(fid, '=== Chapter 3 Experiment 0: Local Pair Geometry and M_G Stability Summary ===\n');
fprintf(fid, 'output_root = %s\n', out_root);
fprintf(fid, 'run_timestamp = %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
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

fprintf(fid, '--- Stacked Fig3 baseline anchors ---\n');
fprintf(fid, 'baseline_fig3_stacked_km = ');
fprintf(fid, '%.1f ', b_anchor_dense_km);
fprintf(fid, '\n');

fprintf(fid, '--- Fig3_plus baseline anchors ---\n');
fprintf(fid, 'baseline_fig3plus_km = ');
fprintf(fid, '%.1f ', b_fig3plus_km);
fprintf(fid, '\n\n');

fprintf(fid, '--- Empirical M_G stability radius R_geo (reference anchors) ---\n');
for ib = 1:nB
    for ih = 1:nH
        fprintf(fid, 'b=%.3f km, h=%g km -> region=%s, R_geo=%.3f km\n', ...
            b_anchor_km(ib), H_list(ih), char(center_region(ib,ih)), R_geo(ib,ih));
    end
end
fprintf(fid, '\n');

fprintf(fid, '--- Dense baseline R_geo curves ---\n');
for ib = 1:nBd
    fprintf(fid, 'b=%.1f km -> ', b_anchor_dense_km(ib));
    for ih = 1:nH
        fprintf(fid, 'h=%g km: R_geo=%.3f km ', H_list(ih), R_geo_dense(ib,ih));
    end
    fprintf(fid, '\n');
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
fprintf(fid, 'Tw_list_s = ');
fprintf(fid, '%d ', Tw_list);
fprintf(fid, '\n');
fprintf(fid, 'V_list_kmps = ');
fprintf(fid, '%.2f ', V_list);
fprintf(fid, '\n');
for iv = 1:numel(V_list)
    for it = 1:numel(Tw_list)
        fprintf(fid, 'v=%.2f km/s, Tw=%d s -> nominal Bxy_half=%.3f km, conservative Bxy_half=%.3f km\n', ...
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
fprintf(fid, '%.2f ', V_list);
fprintf(fid, '\n');
fprintf(fid, 'coarse xy step should not exceed nominal %.1f km; boundary refinement may use conservative %.1f km.\n', ...
    step_xy_rec_nominal, step_xy_rec_conservative);

fclose(fid);

log_path = fullfile(log_dir, 'exp0_local_pair_geom_log.txt');
fid = fopen(log_path, 'w');
assert(fid >= 0, 'Failed to open log file.');
fprintf(fid, '[INFO] run_timestamp = %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(fid, '[INFO] Experiment 0 output root: %s\n', out_root);
fprintf(fid, '[INFO] baseline_fig3_stacked_km = ');
fprintf(fid, '%.1f ', b_anchor_dense_km);
fprintf(fid, '\n');
fprintf(fid, '[INFO] baseline_fig3plus_km = ');
fprintf(fid, '%.1f ', b_fig3plus_km);
fprintf(fid, '\n');
fprintf(fid, '[INFO] trusted_count = %d\n', numel(R_geo_trusted));
fprintf(fid, '[INFO] trusted_R_geo_range = [%.3f, %.3f] km\n', min(R_geo_trusted), max(R_geo_trusted));
fprintf(fid, '[INFO] Bxy_nominal_range = [%.3f, %.3f] km\n', min(Bxy_rec_nominal, [], 'all'), max(Bxy_rec_nominal, [], 'all'));
fprintf(fid, '[INFO] Bxy_conservative_range = [%.3f, %.3f] km\n', min(Bxy_rec_conservative, [], 'all'), max(Bxy_rec_conservative, [], 'all'));
fprintf(fid, '[INFO] step_xy = [%.3f, %.3f] km\n', step_xy_rec_conservative, step_xy_rec_nominal);
fclose(fid);

mat_path = fullfile(mat_dir, 'exp0_local_pair_geom.mat');
save(mat_path, 'p', 'b_grid', 'theta_num_deg', ...
    'MG_center', 'crlb_weak_center', 'theta_anchor_deg', 'b_anchor_km', ...
    'b_anchor_dense_km', 'b_fig3plus_km', ...
    'MG_anchor', 'MG_thr_12', 'MG_thr_23', ...
    'xg', 'yg', 'X', 'Y', 'R', 'MG_maps', 'MG_region_maps', ...
    'R_geo', 'center_region', 'center_MG', 'R_geo_trusted', ...
    'MG_maps_stacked', 'MG_maps_fig3plus', 'R_geo_dense', 'center_region_dense', ...
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

function [Mmap, RegionMap] = local_scan_MG_map(X, Y, b, ht, h_sat_km, sigma_theta_rad, MG_thr_12, MG_thr_23)
Mmap = zeros(size(X));
RegionMap = strings(size(X));

for ix = 1:size(X,1)
    for iy = 1:size(X,2)
        tgt = [X(ix,iy); Y(ix,iy); ht];
        sat1 = [-b/2; 0; h_sat_km];
        sat2 = [ b/2; 0; h_sat_km];

        met = local_pair_metrics(tgt, sat1, sat2, sigma_theta_rad);
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
end

function [M0, reg0, r_keep] = local_compute_center_region_and_Rgeo(Mmap, RegionMap, xg, yg, R, MG_thr_12, MG_thr_23)
[~, cx] = min(abs(xg - 0));
[~, cy] = min(abs(yg - 0));
M0 = Mmap(cy, cx);
reg0 = RegionMap(cy, cx);

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
end

function local_safe_delete(pattern)
files = dir(pattern);
for i = 1:numel(files)
    delete(fullfile(files(i).folder, files(i).name));
end
end

function p = local_default_params()
p = struct();

p.h_sat_km = 1000;
p.h_tgt_ref_km = 40;
p.h_tgt_list_km = [30, 40, 50];

p.sigma_theta_rad = 10 / 206265;

% Fig1 / Fig2
p.baseline_grid_km = 200:100:2000;

% 参考锚点（用于 threshold 与 trusted set）
p.theta_anchor_deg = [30, 60, 80];

% Fig3_stacked / Fig4
p.baseline_dense_km = 500:100:1200;

% Fig3_plus
p.baseline_fig3plus_km = [500, 1000, 1200];

p.xy_grid_km = -800:50:800;

% Fig5
p.v_tgt_list_kmps = 4.0:0.25:5.0;
p.Tw_list_s = 10:10:60;

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
