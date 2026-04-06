function out = run_ch5r_phase8_6c_counterfactual_test_fullwindow()
%RUN_CH5R_PHASE8_6C_COUNTERFACTUAL_TEST_FULLWINDOW

cfg = default_ch5r_params(true);
cfg = default_ch5r_r85_li_methods_params(cfg);

cfg.r85f2.parallel.enable = true;
cfg.r85f2.logging.enable = true;
cfg.r85f2.logging.every_k = 240;

cfg.r85f4a.danger_weighted_gain.eta_switch = 1e6;
cfg.r85f4a.danger_weighted_gain.lookahead_steps = 60;
cfg.r85f4a.danger_weighted_gain.alpha_cross = 1e5;
cfg.r85f4a.danger_weighted_gain.beta_margin = 1;
cfg.r85f4a.danger_weighted_gain.eps_margin = 1e-6;

li_case = build_r85_li_case_from_current_case(cfg);
ch5case = li_case.base_case;

run_pta = run_online_policy_from_pair_bank(cfg, ch5case, 'pta');
run_obs = run_online_policy_from_pair_bank(cfg, ch5case, 'observability_family');
run_dwg = run_online_policy_from_pair_bank(cfg, ch5case, 'danger_weighted_gain');

k1 = 620;
k2 = 700;

cf = {};
cf{end+1} = local_eval_cf(ch5case, run_pta.selection_trace, run_obs.selection_trace, k1, k2, 'PTA_online', 'observability_family_online', 'PTA_with_obs_mid');
cf{end+1} = local_eval_cf(ch5case, run_dwg.selection_trace, run_obs.selection_trace, k1, k2, 'danger_weighted_gain_online', 'observability_family_online', 'DWG_with_obs_mid');
cf{end+1} = local_eval_cf(ch5case, run_obs.selection_trace, run_pta.selection_trace, k1, k2, 'observability_family_online', 'PTA_online', 'OBS_with_pta_mid');
cf{end+1} = local_eval_cf(ch5case, run_obs.selection_trace, run_dwg.selection_trace, k1, k2, 'observability_family_online', 'danger_weighted_gain_online', 'OBS_with_dwg_mid');

rows = [];
for i = 1:numel(cf)
    c = cf{i};
    rows = [rows; struct( ...
        'counterfactual_case', string(c.new_tag), ...
        'base_policy', string(c.base_tag), ...
        'patch_policy', string(c.patch_tag), ...
        'k1', c.k1, ...
        'k2', c.k2, ...
        'bubble_steps_base', c.m_base.summary.bubble_steps, ...
        'bubble_steps_cf', c.m_cf.summary.bubble_steps, ...
        'delta_bubble_steps', c.m_cf.summary.bubble_steps - c.m_base.summary.bubble_steps, ...
        'min_lambda_base', c.m_base.summary.min_lambda_min_window, ...
        'min_lambda_cf', c.m_cf.summary.min_lambda_min_window, ...
        'delta_min_lambda', c.m_cf.summary.min_lambda_min_window - c.m_base.summary.min_lambda_min_window)]; %#ok<AGROW>
end

summary_table = struct2table(rows);

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phaseR8_6c_counterfactual_test_fullwindow');
if ~exist(out_dir, 'dir'); mkdir(out_dir); end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
csv_file = fullfile(out_dir, ['phaseR8_6c_counterfactual_test_fullwindow_' stamp '.csv']);
mat_file = fullfile(out_dir, ['phaseR8_6c_counterfactual_test_fullwindow_' stamp '.mat']);

writetable(summary_table, csv_file);
save(mat_file, 'summary_table');

disp(' ')
disp('=== [ch5r:R8.6c_fullwindow] summary ===')
disp(summary_table)

out = struct();
out.summary_table = summary_table;
out.paths = struct('csv_file', csv_file, 'mat_file', mat_file, 'output_dir', out_dir);
out.ok = true;
end

function c = local_eval_cf(ch5case, trace_base, trace_patch, k1, k2, base_tag, patch_tag, new_tag)
trace_cf = splice_selection_trace_local(trace_base, trace_patch, k1, k2, new_tag);
c = struct();
c.k1 = k1;
c.k2 = k2;
c.base_tag = base_tag;
c.patch_tag = patch_tag;
c.new_tag = new_tag;
c.m_base = compute_worst_window_metrics_fullwindow(ch5case, trace_base, base_tag);
c.m_cf = compute_worst_window_metrics_fullwindow(ch5case, trace_cf, new_tag);
end
