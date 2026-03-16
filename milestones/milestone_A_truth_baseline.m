function result = milestone_A_truth_baseline(cfg)
%MILESTONE_A_TRUTH_BASELINE Dissertation-grade Chapter 4 Milestone A pipeline.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end

meta = cfg.milestones.MA;
paths = milestone_common_output_paths(cfg, meta.milestone_id, meta.title);
style = milestone_common_plot_style();
selection = milestone_common_case_selection(cfg, meta.milestone_id, meta);
shared_artifacts = local_attach_shared_scenarios(cfg, meta);

kernel_out = stage12A_truth_baseline_kernel(cfg, meta);
scan_out = stage12B_truth_case_window_scan(cfg, meta);

summary_row = scan_out.summary_table(1, :);
baseline_table = table( ...
    string(selection.case_id), string(selection.case_family), ...
    meta.theta.h_km, meta.theta.i_deg, meta.theta.P, meta.theta.T, meta.theta.F, meta.Tw_s, ...
    'VariableNames', {'baseline_case_id', 'baseline_case_family', ...
    'baseline_theta_h_km', 'baseline_theta_i_deg', 'baseline_theta_P', 'baseline_theta_T', 'baseline_theta_F', 'baseline_Tw_s'});

dominant_metric = classify_dominant_metric(summary_row.DG_worst_truth, summary_row.DA_worst_truth, summary_row.DT_worst_truth);
is_feasible_truth = (summary_row.DG_worst_truth >= 1) && ...
    (summary_row.DA_worst_truth >= 1) && ...
    (summary_row.DT_worst_truth >= 1);

worst_table = table( ...
    string(selection.case_id), ...
    summary_row.DG_worst_truth, summary_row.DA_worst_truth, summary_row.DT_bar_worst, summary_row.DT_worst_truth, ...
    summary_row.t0G_star_s, summary_row.t0A_star_s, summary_row.t0T_star_s, summary_row.dt_max_at_t0T_star_s, ...
    dominant_metric, is_feasible_truth, ...
    'VariableNames', {'case_id', 'DG_worst_truth', 'DA_worst_truth', 'DT_bar_worst', 'DT_worst', ...
    't0G_star_s', 't0A_star_s', 't0T_star_s', 'dt_max_at_t0T_star_s', 'dominant_metric', 'is_feasible_truth'});

curve_table = scan_out.window_table;

baseline_csv = fullfile(paths.tables, 'MA_truth_baseline_configuration_summary.csv');
worst_csv = fullfile(paths.tables, 'MA_truth_baseline_worst_window_identification.csv');
curve_csv = fullfile(paths.tables, 'MA_truth_baseline_window_level_truth_curve.csv');
milestone_common_save_table(baseline_table, baseline_csv);
milestone_common_save_table(worst_table, worst_csv);
milestone_common_save_table(curve_table, curve_csv);

plot_data = build_milestone_A_truth_plot_data(curve_table, struct( ...
    'case_id', selection.case_id, ...
    'Tw_s', meta.Tw_s, ...
    't0G_star', summary_row.t0G_star_s, ...
    't0A_star', summary_row.t0A_star_s, ...
    't0T_star', summary_row.t0T_star_s));

fig_main = plot_truth_window_scan_threepanel(plot_data, style);
fig_main_path = fullfile(paths.figures, 'MA_truth_baseline_truth_window_scan.png');
milestone_common_save_figure(fig_main, fig_main_path);
close(fig_main);

fig_highlight = plot_worst_window_marker(plot_data, style);
fig_highlight_path = fullfile(paths.figures, 'MA_truth_baseline_worst_window_highlight.png');
milestone_common_save_figure(fig_highlight, fig_highlight_path);
close(fig_highlight);

result = struct();
result.milestone_id = meta.milestone_id;
result.title = meta.title;
result.config = cfg;
result.purpose = 'Single-layer static inverse-design truth baseline.';
result.reused_modules = {'Controlled truth-baseline evaluator', 'Single-case window truth scanner'};
result.tables = struct();
result.figures = struct();
result.artifacts = struct();
result.tables.baseline_configuration_summary = string(baseline_csv);
result.tables.worst_window_identification = string(worst_csv);
result.tables.window_level_truth_curve = string(curve_csv);
result.figures.truth_window_scan = string(fig_main_path);
result.figures.worst_window_highlight = string(fig_highlight_path);
result.artifacts.baseline_evaluator = "controlled truth-baseline evaluator";
result.artifacts.window_scan_engine = "single-case window truth scanner";
if ~isempty(shared_artifacts)
    artifact_names = fieldnames(shared_artifacts);
    for k = 1:numel(artifact_names)
        result.artifacts.(artifact_names{k}) = shared_artifacts.(artifact_names{k});
    end
end

result.summary = struct( ...
    'case_id', string(selection.case_id), ...
    'theta_baseline', meta.theta, ...
    'Tw_baseline', meta.Tw_s, ...
    'DT_bar_worst', summary_row.DT_bar_worst, ...
    'DT_worst', summary_row.DT_worst_truth, ...
    'DG_worst_truth', summary_row.DG_worst_truth, ...
    'DA_worst_truth', summary_row.DA_worst_truth, ...
    'DT_worst_truth', summary_row.DT_worst_truth, ...
    't0G_star', summary_row.t0G_star_s, ...
    't0A_star', summary_row.t0A_star_s, ...
    't0T_star', summary_row.t0T_star_s, ...
    'dt_max_at_worst', summary_row.dt_max_at_t0T_star_s, ...
    'is_feasible_truth', is_feasible_truth, ...
    'dominant_metric', dominant_metric, ...
    'key_counts', struct('num_cases', height(kernel_out.case_table), 'num_tables', numel(fieldnames(result.tables)), 'num_figures', numel(fieldnames(result.figures))), ...
    'success_flags', struct('baseline_evaluator', true, 'window_scan_engine', true), ...
    'main_conclusion', local_make_conclusion(is_feasible_truth, dominant_metric, summary_row));
result.artifacts.temporal_display_note = "图形展示采用有界时序连续性裕度 DT_bar；闭合判定采用标准化时序连续性裕度 DT >= 1。";
result.artifacts.temporal_panel_note = "基线真值窗口扫描的第三面板展示 \\bar{D}_T，显示阈值为 0.5；真值可行性仍按 D_T^{worst} >= 1 判定。";

files = milestone_common_export_summary(result, paths);
result.artifacts.summary_report = files.report_md;
result.artifacts.summary_mat = files.summary_mat;
end

function shared_artifacts = local_attach_shared_scenarios(cfg, meta)
shared_artifacts = struct();
if ~isfield(meta, 'attach_shared_scenarios') || ~meta.attach_shared_scenarios
    return;
end

availability = check_walkerDelta_availability();
if ~availability.is_available
    shared_artifacts.shared_scenario_note = string(availability.message);
    return;
end

ss1_fig = fullfile(cfg.paths.root, 'output', 'shared_scenarios', 'SS1', 'figures', 'SS1_defense_zone_2d_overview.png');
ss2_fig = fullfile(cfg.paths.root, 'output', 'shared_scenarios', 'SS2', 'figures', 'SS2_earth_walker_defense_zone_3d.png');

need_build = cfg.shared_scenarios.enable_auto_build && ...
    (~isfile(ss1_fig) || ~isfile(ss2_fig));
if need_build
    try
        run_all_shared_scenarios(cfg);
    catch ME
        shared_artifacts.shared_scenario_note = "共享场景自动构建失败：" + string(ME.message);
        return;
    end
end

if isfile(ss1_fig)
    shared_artifacts.shared_scenario_SS1 = string(ss1_fig);
end
if isfile(ss2_fig)
    shared_artifacts.shared_scenario_SS2 = string(ss2_fig);
end
if ~isempty(fieldnames(shared_artifacts))
    shared_artifacts.shared_scenario_note = "共享场景 SS1/SS2 用于补充第四章与第五章共用的防区与 Earth-Walker 空间关系说明。";
end
end

function txt = local_make_conclusion(is_feasible_truth, dominant_metric, summary_row)
if is_feasible_truth
    txt = sprintf(['基线设计在真值判定下可行。图中时序曲线展示为有界时序连续性裕度 \\bar{D}_T，显示阈值取 0.5；', ...
        '闭合判定仍按标准化时序连续性裕度 D_T = 2\\bar{D}_T 且 D_T^{worst} \\ge 1 执行。', ...
        '当前 DG=%.3f，DA=%.3f，D_T=%.3f，\\bar{D}_T=%.3f，主导指标为 %s。'], ...
        summary_row.DG_worst_truth, summary_row.DA_worst_truth, summary_row.DT_worst_truth, summary_row.DT_bar_worst, dominant_metric);
else
    txt = sprintf(['基线设计在真值判定下不可行。图中时序曲线展示为有界时序连续性裕度 \\bar{D}_T，显示阈值取 0.5；', ...
        '闭合判定仍按标准化时序连续性裕度 D_T = 2\\bar{D}_T 且 D_T^{worst} \\ge 1 执行。', ...
        '当前 DG=%.3f，DA=%.3f，D_T=%.3f，\\bar{D}_T=%.3f，主导指标为 %s。'], ...
        summary_row.DG_worst_truth, summary_row.DA_worst_truth, summary_row.DT_worst_truth, summary_row.DT_bar_worst, dominant_metric);
end
end
