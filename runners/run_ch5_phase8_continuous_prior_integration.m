function out = run_ch5_phase8_continuous_prior_integration()
% Phase08 连续先验接入 smoke
%
% 当前版目标：
% 1) 打通 Stage15-H2 连续 prior 链路
% 2) 构造 prior cost
% 3) 输出 summary，供后续接入 CK 正式主流程

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase8_continuous_prior');
if ~exist(out_root, 'dir'); mkdir(out_root); end

weights = struct();
weights.wf = 1.0;
weights.wb = 0.5;
weights.wr = 1.5;
w_prior = 0.15;

% 这里先用三组代表性样本做 smoke
samples = struct([]);

samples(1).name = 'weak_geom_case';
samples(1).lambda_geom = 0.18;
samples(1).baseline_km = 600;
samples(1).crossing_angle_deg = 35;
samples(1).Bxy_cand = 60;
samples(1).Ruse = 150;

samples(2).name = 'mid_geom_case';
samples(2).lambda_geom = 0.36;
samples(2).baseline_km = 900;
samples(2).crossing_angle_deg = 60;
samples(2).Bxy_cand = 110;
samples(2).Ruse = 210;

samples(3).name = 'strong_geom_case';
samples(3).lambda_geom = 0.52;
samples(3).baseline_km = 1100;
samples(3).crossing_angle_deg = 80;
samples(3).Bxy_cand = 150;
samples(3).Ruse = 260;

records = struct([]);
for i = 1:numel(samples)
    s = samples(i);
    prior = build_stage15_continuous_prior(s.lambda_geom, s.baseline_km, s.crossing_angle_deg);
    [prior_cost, detail] = compute_stage15_continuous_prior_cost(prior, s.Bxy_cand, s.Ruse, weights);

    % 当前 smoke 版假设一个原始 CK score
    score_ck = 1.0;
    score_total = score_ck - w_prior * prior_cost;

    rec = struct();
    rec.name = s.name;
    rec.input = s;
    rec.prior = prior;
    rec.detail = detail;
    rec.score_ck = score_ck;
    rec.score_total = score_total;
    records(i) = rec;
end

txt_path = fullfile(out_root, 'phase8_continuous_prior_summary.txt');
fid = fopen(txt_path, 'w');
assert(fid >= 0, 'Failed to open summary file.');

fprintf(fid, '=== Phase08 Continuous Prior Integration Summary ===\n');
fprintf(fid, 'w_prior = %.6f\n', w_prior);
fprintf(fid, 'wf = %.6f, wb = %.6f, wr = %.6f\n', weights.wf, weights.wb, weights.wr);
fprintf(fid, '\n');

for i = 1:numel(records)
    r = records(i);
    fprintf(fid, '--- %s ---\n', r.name);
    fprintf(fid, 'lambda_geom = %.6f\n', r.input.lambda_geom);
    fprintf(fid, 'baseline_km = %.6f\n', r.input.baseline_km);
    fprintf(fid, 'crossing_angle_deg = %.6f\n', r.input.crossing_angle_deg);
    fprintf(fid, 'Bxy_cand = %.6f\n', r.input.Bxy_cand);
    fprintf(fid, 'Ruse = %.6f\n', r.input.Ruse);
    fprintf(fid, 'M_G_center = %.6f\n', r.prior.M_G_center);
    fprintf(fid, 'region_id = %s\n', char(r.prior.region_id));
    fprintf(fid, 'fragility_score = %.6f\n', r.prior.fragility_score);
    fprintf(fid, 'R_geo_est = %.6f\n', r.prior.R_geo_est);
    fprintf(fid, 'Bxy_nominal_est = %.6f\n', r.prior.Bxy_nominal_est);
    fprintf(fid, 'Bxy_conservative_est = %.6f\n', r.prior.Bxy_conservative_est);
    fprintf(fid, 'Jf = %.6f\n', r.detail.Jf);
    fprintf(fid, 'Jb = %.6f\n', r.detail.Jb);
    fprintf(fid, 'Jr = %.6f\n', r.detail.Jr);
    fprintf(fid, 'prior_cost = %.6f\n', r.detail.prior_cost);
    fprintf(fid, 'score_ck = %.6f\n', r.score_ck);
    fprintf(fid, 'score_total = %.6f\n', r.score_total);
    fprintf(fid, '\n');
end

fclose(fid);

mat_path = fullfile(out_root, 'phase8_continuous_prior_result.mat');
save(mat_path, 'records', 'weights', 'w_prior');

disp('=== Phase08 Continuous Prior Integration Smoke ===');
disp(['[phase8-cont] text : ', txt_path]);
disp(['[phase8-cont] mat  : ', mat_path]);

out = struct();
out.summary_file = txt_path;
out.mat_file = mat_path;
out.output_root = out_root;
end
