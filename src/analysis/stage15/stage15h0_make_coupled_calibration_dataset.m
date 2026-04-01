function out = stage15h0_make_coupled_calibration_dataset()
% Stage15-H0:
% 基于第三章实验0口径，构造 deterministic coupled calibration dataset。
%
% 每个 sample 同时包含：
% 1) 第三章口径 M_G = lambda_min(J)
% 2) Stage15 口径 lambda_min_geom
%
% 目标：
% 为后续 cross-scale mapping 提供“同一样本、双量纲”的标定数据。

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'crossscale_dataset');
fig_dir = fullfile(out_root, 'figs');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

% -------------------------
% 固定参数（与第三章实验0一致）
% -------------------------
h_sat_km = 1000;
sigma_theta_rad = 10 / 206265;

baseline_anchor_km = [514.462, 1108.513, 1611.071];
baseline_dense_km = 500:100:1200;
baseline_all_km = unique(sort([baseline_dense_km, baseline_anchor_km]));

h_tgt_grid_km = [30, 40, 50];
radius_grid_km = [0, 50, 100, 150, 200, 250, 300];
azimuth_grid_deg = 0:45:315;

height_ref_km = 1000;
center_z_km = 30;

% 第三章阈值
MG_thr_12 = 115.411378;
MG_thr_23 = 198.489832;

% -------------------------
% 生成样本
% -------------------------
dataset = struct([]);
sid = 0;

for ib = 1:numel(baseline_all_km)
    b = baseline_all_km(ib);

    sat1 = [-b/2, 0, h_sat_km, 0, 0, 0];
    sat2 = [ b/2, 0, h_sat_km, 0, 0, 0];

    for ih = 1:numel(h_tgt_grid_km)
        h_tgt = h_tgt_grid_km(ih);

        for ir = 1:numel(radius_grid_km)
            rr = radius_grid_km(ir);

            if rr == 0
                az_list = 0;
            else
                az_list = azimuth_grid_deg;
            end

            for ia = 1:numel(az_list)
                az = az_list(ia);

                x = rr * cosd(az);
                y = rr * sind(az);

                target_state = [x, y, h_tgt, 0, 0, 0];

                sid = sid + 1;
                rec = struct();
                rec.sample_id = sprintf('CC%04d', sid);

                rec.baseline_km = b;
                rec.target_height_km = h_tgt;
                rec.radius_km = rr;
                rec.azimuth_deg = az;

                rec.sat1_state = sat1;
                rec.sat2_state = sat2;
                rec.target_state = target_state;

                [xi, eta, kappa2] = local_stage15_pair_kernel_3d(target_state, sat1, sat2, height_ref_km, center_z_km);
                MG_cpt3 = local_compute_cpt3_MG(target_state, sat1, sat2, sigma_theta_rad);

                rec.xi = xi;
                rec.eta = eta;
                rec.kappa2 = kappa2;
                rec.MG_cpt3 = MG_cpt3;

                if MG_cpt3 <= MG_thr_12
                    rec.MG_region = "low_M_G";
                elseif MG_cpt3 <= MG_thr_23
                    rec.MG_region = "mid_M_G";
                else
                    rec.MG_region = "high_M_G";
                end

                dataset = [dataset, rec]; %#ok<AGROW>
            end
        end
    end
end

% -------------------------
% summary
% -------------------------
n = numel(dataset);
lambda_geom = zeros(1,n);
MG_cpt3 = zeros(1,n);

low_n = 0; mid_n = 0; high_n = 0;

for i = 1:n
    lambda_geom(i) = dataset(i).kappa2.lambda_min_geom;
    MG_cpt3(i) = dataset(i).MG_cpt3;
    switch char(dataset(i).MG_region)
        case 'low_M_G'
            low_n = low_n + 1;
        case 'mid_M_G'
            mid_n = mid_n + 1;
        otherwise
            high_n = high_n + 1;
    end
end

% 图1：lambda_geom vs MG_cpt3
f1 = figure('Name','stage15h0_lambda_vs_MG');
scatter(lambda_geom, MG_cpt3, 18, 'filled');
grid on;
xlabel('lambda\_min\_geom (stage15 scale)');
ylabel('M\_G (cpt3 scale)');
title('Stage15-H0: coupled calibration pairs');
saveas(f1, fullfile(fig_dir, 'stage15h0_lambda_vs_MG.png'));
close(f1);

% 图2：不同 baseline 的 MG_cpt3 中位数
bvals = unique([dataset.baseline_km]);
MG_med = zeros(size(bvals));
for k = 1:numel(bvals)
    mask = abs([dataset.baseline_km] - bvals(k)) < 1e-9;
    MG_med(k) = median([dataset(mask).MG_cpt3]);
end

f2 = figure('Name','stage15h0_baseline_vs_MGmedian');
plot(bvals, MG_med, '-o', 'LineWidth', 1.5);
grid on;
xlabel('baseline b (km)');
ylabel('median M\_G (cpt3 scale)');
title('Stage15-H0: baseline vs median M\_G');
saveas(f2, fullfile(fig_dir, 'stage15h0_baseline_vs_MGmedian.png'));
close(f2);

txt_path = fullfile(out_root, 'stage15h0_coupled_calibration_dataset_summary.txt');
fid = fopen(txt_path, 'w');
assert(fid >= 0, 'Failed to open summary file.');

fprintf(fid, '=== Stage15-H0 Coupled Calibration Dataset Summary ===\n');
fprintf(fid, 'num_samples = %d\n', n);
fprintf(fid, '\n');

fprintf(fid, 'baseline_anchor_km = ');
fprintf(fid, '%.3f ', baseline_anchor_km);
fprintf(fid, '\n');

fprintf(fid, 'baseline_dense_km = ');
fprintf(fid, '%.3f ', baseline_dense_km);
fprintf(fid, '\n');

fprintf(fid, 'baseline_all_km = ');
fprintf(fid, '%.3f ', baseline_all_km);
fprintf(fid, '\n');

fprintf(fid, 'h_tgt_grid_km = ');
fprintf(fid, '%.1f ', h_tgt_grid_km);
fprintf(fid, '\n');

fprintf(fid, 'radius_grid_km = ');
fprintf(fid, '%.1f ', radius_grid_km);
fprintf(fid, '\n');

fprintf(fid, 'azimuth_grid_deg = ');
fprintf(fid, '%.1f ', azimuth_grid_deg);
fprintf(fid, '\n\n');

fprintf(fid, '--- MG region histogram (cpt3 scale) ---\n');
fprintf(fid, 'low_M_G = %d\n', low_n);
fprintf(fid, 'mid_M_G = %d\n', mid_n);
fprintf(fid, 'high_M_G = %d\n', high_n);
fprintf(fid, '\n');

fprintf(fid, '--- value ranges ---\n');
fprintf(fid, 'lambda_geom_min = %.12f\n', min(lambda_geom));
fprintf(fid, 'lambda_geom_median = %.12f\n', median(lambda_geom));
fprintf(fid, 'lambda_geom_max = %.12f\n', max(lambda_geom));
fprintf(fid, 'MG_cpt3_min = %.12f\n', min(MG_cpt3));
fprintf(fid, 'MG_cpt3_median = %.12f\n', median(MG_cpt3));
fprintf(fid, 'MG_cpt3_max = %.12f\n', max(MG_cpt3));
fprintf(fid, '\n');

fprintf(fid, '--- first 20 samples ---\n');
fprintf(fid, 'sample_id,baseline_km,h_tgt_km,radius_km,azimuth_deg,lambda_geom,MG_cpt3,MG_region\n');
m = min(20, n);
for i = 1:m
    fprintf(fid, '%s,%.3f,%.1f,%.1f,%.1f,%.12f,%.12f,%s\n', ...
        dataset(i).sample_id, dataset(i).baseline_km, dataset(i).target_height_km, ...
        dataset(i).radius_km, dataset(i).azimuth_deg, ...
        dataset(i).kappa2.lambda_min_geom, dataset(i).MG_cpt3, char(dataset(i).MG_region));
end

fclose(fid);

mat_path = fullfile(out_root, 'stage15h0_coupled_calibration_dataset.mat');
save(mat_path, 'dataset');

out = struct();
out.output_root = out_root;
out.summary_file = txt_path;
out.mat_file = mat_path;
end

function [xi, eta, kappa2] = local_stage15_pair_kernel_3d(target_state, sat1_state, sat2_state, height_ref_km, center_z_km)
tgt = target_state(1:3).';
sat1 = sat1_state(1:3).';
sat2 = sat2_state(1:3).';

x = tgt(1); y = tgt(2); z = tgt(3);

r_xy = hypot(x, y);
xi = struct();
xi.r_norm_xy = r_xy / height_ref_km;
xi.z_norm = (z - center_z_km) / height_ref_km;
xi.bearing_rad = atan2(y, x);
xi.heading_xy_rad = 0;
xi.speed_norm = 0;

eta = struct();
eta.radial_rate_norm = 0;
eta.vertical_rate_norm = 0;
eta.turn_proxy = 0;

r1 = tgt - sat1;
r2 = tgt - sat2;
rho1 = norm(r1);
rho2 = norm(r2);
u1 = r1 / max(rho1, eps);
u2 = r2 / max(rho2, eps);

Jgeom = (eye(3) - u1*u1.') + (eye(3) - u2*u2.');
e = sort(real(eig(Jgeom)), 'ascend');

kappa2 = struct();
kappa2.rho1_norm = rho1 / height_ref_km;
kappa2.rho2_norm = rho2 / height_ref_km;
kappa2.delta_h1_norm = (tgt(3) - sat1(3)) / height_ref_km;
kappa2.delta_h2_norm = (tgt(3) - sat2(3)) / height_ref_km;
kappa2.crossing_angle_deg = acosd(max(-1, min(1, dot(u1, u2))));
kappa2.lambda_min_geom = max(e(1), eps);
kappa2.rank_proxy = rank(Jgeom, 1e-10);
end

function MG = local_compute_cpt3_MG(target_state, sat1_state, sat2_state, sigma_theta_rad)
tgt = target_state(1:3).';
sat1 = sat1_state(1:3).';
sat2 = sat2_state(1:3).';

J1 = local_single_sensor_fim(tgt, sat1, sigma_theta_rad);
J2 = local_single_sensor_fim(tgt, sat2, sigma_theta_rad);
J = J1 + J2;

e = sort(real(eig(J)), 'ascend');
MG = max(e(1), eps);
end

function Ji = local_single_sensor_fim(tgt, sat, sigma_theta_rad)
r = tgt - sat;
rho = norm(r);
u = r / max(rho, eps);
Ji = (eye(3) - u*u.') / (sigma_theta_rad^2 * rho^2);
end
