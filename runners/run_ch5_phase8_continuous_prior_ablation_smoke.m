function out = run_ch5_phase8_continuous_prior_ablation_smoke()
% Phase08-B ablation smoke
%
% 比较三种模式：
%   1) ck_only
%   2) ck_plus_fragility
%   3) ck_plus_full_prior

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase8_continuous_prior_ablation');
if ~exist(out_root, 'dir'); mkdir(out_root); end

cfg0 = default_phase8_continuous_prior_config();

cands = struct([]);

cands(1).name = 'cand_A_weak';
cands(1).score_ck = 1.00;
cands(1).lambda_geom = 0.18;
cands(1).baseline_km = 600;
cands(1).crossing_angle_deg = 35;
cands(1).Bxy_cand = 60;
cands(1).Ruse = 150;

cands(2).name = 'cand_B_mid';
cands(2).score_ck = 1.00;
cands(2).lambda_geom = 0.36;
cands(2).baseline_km = 900;
cands(2).crossing_angle_deg = 60;
cands(2).Bxy_cand = 110;
cands(2).Ruse = 210;

cands(3).name = 'cand_C_strong';
cands(3).score_ck = 1.00;
cands(3).lambda_geom = 0.52;
cands(3).baseline_km = 1100;
cands(3).crossing_angle_deg = 80;
cands(3).Bxy_cand = 150;
cands(3).Ruse = 260;

records_cell = cell(1, numel(cands) * numel(cfg0.mode_list));
k = 0;

for ic = 1:numel(cands)
    cand = cands(ic);
    for im = 1:numel(cfg0.mode_list)
        cfg = cfg0;
        cfg.mode = cfg0.mode_list{im};

        out_score = score_candidate_with_continuous_prior(cand.score_ck, cand, cfg);

        k = k + 1;
        rec = struct();
        rec.cand_name = cand.name;
        rec.mode = cfg.mode;
        rec.score_ck = out_score.score_ck;
        rec.score_total = out_score.score_total;
        rec.prior_cost_used = out_score.prior_cost_used;
        rec.prior = out_score.prior;
        rec.detail = out_score.detail;

        records_cell{k} = rec;
    end
end

records = [records_cell{1:k}];

txt_path = fullfile(out_root, 'phase8_continuous_prior_ablation_summary.txt');
fid = fopen(txt_path, 'w');
assert(fid >= 0, 'Failed to open summary file.');

fprintf(fid, '=== Phase08 Continuous Prior Ablation Smoke Summary ===\n');
fprintf(fid, 'w_prior = %.6f\n', cfg0.w_prior);
fprintf(fid, 'wf = %.6f, wb = %.6f, wr = %.6f\n', cfg0.weights.wf, cfg0.weights.wb, cfg0.weights.wr);
fprintf(fid, '\n');

for i = 1:numel(records)
    r = records(i);
    fprintf(fid, '--- %s | %s ---\n', r.cand_name, r.mode);
    fprintf(fid, 'score_ck = %.6f\n', r.score_ck);
    fprintf(fid, 'score_total = %.6f\n', r.score_total);
    fprintf(fid, 'prior_cost_used = %.6f\n', r.prior_cost_used);
    fprintf(fid, 'M_G_center = %.6f\n', r.prior.M_G_center);
    fprintf(fid, 'region_id = %s\n', char(r.prior.region_id));
    fprintf(fid, 'fragility_score = %.6f\n', r.prior.fragility_score);
    fprintf(fid, 'R_geo_est = %.6f\n', r.prior.R_geo_est);
    fprintf(fid, 'Bxy_nominal_est = %.6f\n', r.prior.Bxy_nominal_est);
    fprintf(fid, 'Jf = %.6f\n', r.detail.Jf);
    fprintf(fid, 'Jb = %.6f\n', r.detail.Jb);
    fprintf(fid, 'Jr = %.6f\n', r.detail.Jr);
    fprintf(fid, '\n');
end
fclose(fid);

mat_path = fullfile(out_root, 'phase8_continuous_prior_ablation_result.mat');
save(mat_path, 'records', 'cfg0');

disp('=== Phase08 Continuous Prior Ablation Smoke ===');
disp(['[phase8-ablation] text : ', txt_path]);
disp(['[phase8-ablation] mat  : ', mat_path]);

out = struct();
out.summary_file = txt_path;
out.mat_file = mat_path;
out.output_root = out_root;
end
