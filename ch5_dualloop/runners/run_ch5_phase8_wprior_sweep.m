function out = run_ch5_phase8_wprior_sweep(case_name)
%RUN_CH5_PHASE8_WPRIOR_SWEEP
% Sweep w_prior over several values for Phase08 continuous prior integration.
%
% Outputs:
%   outputs/cpt5/phase8_wprior_sweep/<case_name>/
%       summary.txt
%       summary.mat
%       each run keeps its own candidate_diff csv under phase8_candidate_diff

if nargin < 1 || isempty(case_name)
    case_name = 'ref128';
end

w_list = [0.15, 0.50, 1.00];

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase8_wprior_sweep', char(case_name));
if ~exist(out_root, 'dir'); mkdir(out_root); end

records_cell = cell(1, numel(w_list));

for i = 1:numel(w_list)
    w = w_list(i);

    cfg = default_ch5_params(case_name);
    cfg.ch5.continuous_prior_enable = true;
    cfg.ch5.continuous_prior_mode = 'ck_plus_fragility';
    cfg.ch5.continuous_prior_w_prior = w;

    debug_root = fullfile(pwd, 'outputs', 'cpt5', 'phase8_candidate_diff', char(case_name), sprintf('ck_plus_fragility_wp_%0.2f', w));
    if ~exist(debug_root, 'dir'); mkdir(debug_root); end
    cfg.ch5.continuous_prior_debug_enable = true;
    cfg.ch5.continuous_prior_debug_csv = fullfile(debug_root, 'candidate_diff.csv');

    if exist(cfg.ch5.continuous_prior_debug_csv, 'file')
        delete(cfg.ch5.continuous_prior_debug_csv);
    end

    base_out = run_ch5_phase7A_dualloop_ck(cfg, true);
    S = load(base_out.mat_file);

    rec = struct();
    rec.case_name = case_name;
    rec.w_prior = w;
    rec.phase7a_mat = base_out.mat_file;
    rec.phase7a_text = base_out.text_file;
    rec.phase7a_fig = base_out.fig_file;
    rec.phase7a_log = base_out.log_file;
    rec.candidate_diff_csv = cfg.ch5.continuous_prior_debug_csv;

    rec.q_worst_window = S.custodyCK.q_worst_window;
    rec.q_worst_point = S.custodyCK.q_worst_point;
    rec.q_worst = S.custodyCK.q_worst;
    rec.phi_mean = S.custodyCK.phi_mean;
    rec.outage_ratio = S.custodyCK.outage_ratio;
    rec.longest_outage_steps = S.custodyCK.longest_outage_steps;
    rec.sc_ratio = S.custodyCK.sc_ratio;
    rec.dc_ratio = S.custodyCK.dc_ratio;
    rec.loc_ratio = S.custodyCK.loc_ratio;

    rec.coverage_ratio_ge1 = S.trackingStatsCK.coverage_ratio_ge1;
    rec.coverage_ratio_ge2 = S.trackingStatsCK.coverage_ratio_ge2;
    rec.mean_rmse = S.trackingStatsCK.mean_rmse;
    rec.max_rmse = S.trackingStatsCK.max_rmse;

    records_cell{i} = rec;
end

records = [records_cell{:}];

txt_path = fullfile(out_root, 'phase8_wprior_sweep_summary.txt');
fid = fopen(txt_path, 'w');
assert(fid >= 0, 'Failed to open summary file.');

fprintf(fid, '=== Phase08 w_prior Sweep Summary ===\n');
fprintf(fid, 'case_name = %s\n\n', char(case_name));

for i = 1:numel(records)
    r = records(i);
    fprintf(fid, '--- w_prior = %.2f ---\n', r.w_prior);
    fprintf(fid, 'q_worst_window = %.12f\n', r.q_worst_window);
    fprintf(fid, 'q_worst_point = %.12f\n', r.q_worst_point);
    fprintf(fid, 'q_worst = %.12f\n', r.q_worst);
    fprintf(fid, 'phi_mean = %.12f\n', r.phi_mean);
    fprintf(fid, 'outage_ratio = %.12f\n', r.outage_ratio);
    fprintf(fid, 'longest_outage_steps = %d\n', r.longest_outage_steps);
    fprintf(fid, 'sc_ratio = %.12f\n', r.sc_ratio);
    fprintf(fid, 'dc_ratio = %.12f\n', r.dc_ratio);
    fprintf(fid, 'loc_ratio = %.12f\n', r.loc_ratio);
    fprintf(fid, 'coverage_ratio_ge1 = %.12f\n', r.coverage_ratio_ge1);
    fprintf(fid, 'coverage_ratio_ge2 = %.12f\n', r.coverage_ratio_ge2);
    fprintf(fid, 'mean_rmse = %.12f\n', r.mean_rmse);
    fprintf(fid, 'max_rmse = %.12f\n', r.max_rmse);
    fprintf(fid, 'phase7a_mat = %s\n', r.phase7a_mat);
    fprintf(fid, 'phase7a_text = %s\n', r.phase7a_text);
    fprintf(fid, 'phase7a_fig = %s\n', r.phase7a_fig);
    fprintf(fid, 'phase7a_log = %s\n', r.phase7a_log);
    fprintf(fid, 'candidate_diff_csv = %s\n', r.candidate_diff_csv);
    fprintf(fid, '\n');
end
fclose(fid);

mat_path = fullfile(out_root, 'phase8_wprior_sweep_summary.mat');
save(mat_path, 'records');

disp('=== Phase08 w_prior sweep ===');
disp(['[phase8-wsweep] text : ', txt_path]);
disp(['[phase8-wsweep] mat  : ', mat_path]);

out = struct();
out.summary_file = txt_path;
out.mat_file = mat_path;
out.output_root = out_root;
out.records = records;
end
