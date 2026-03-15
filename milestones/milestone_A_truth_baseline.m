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

kernel_out = stage12A_truth_baseline_kernel(cfg, meta);
scan_out = stage12B_truth_case_window_scan(cfg, meta);

summary_row = scan_out.summary_table(1, :);
baseline_table = table( ...
    string(selection.case_id), string(selection.case_family), ...
    meta.theta.h_km, meta.theta.i_deg, meta.theta.P, meta.theta.T, meta.theta.F, meta.Tw_s, ...
    'VariableNames', {'baseline_case_id', 'baseline_case_family', ...
    'baseline_theta_h_km', 'baseline_theta_i_deg', 'baseline_theta_P', 'baseline_theta_T', 'baseline_theta_F', 'baseline_Tw_s'});

dominant_metric = local_pick_dominant_metric(summary_row);
is_feasible_truth = all([summary_row.DG_worst_truth, summary_row.DA_worst_truth, summary_row.DT_worst_truth] >= 1.0);

worst_table = table( ...
    string(selection.case_id), ...
    summary_row.DG_worst_truth, summary_row.DA_worst_truth, summary_row.DT_worst_truth, ...
    summary_row.t0G_star_s, summary_row.t0A_star_s, summary_row.t0T_star_s, ...
    dominant_metric, is_feasible_truth, ...
    'VariableNames', {'case_id', 'DG_worst_truth', 'DA_worst_truth', 'DT_worst_truth', ...
    't0G_star_s', 't0A_star_s', 't0T_star_s', 'dominant_metric', 'is_feasible_truth'});

curve_table = scan_out.window_table;

baseline_csv = fullfile(paths.tables, 'MA_truth_baseline_configuration_summary.csv');
worst_csv = fullfile(paths.tables, 'MA_truth_baseline_worst_window_identification.csv');
curve_csv = fullfile(paths.tables, 'MA_truth_baseline_window_level_truth_curve.csv');
milestone_common_save_table(baseline_table, baseline_csv);
milestone_common_save_table(worst_table, worst_csv);
milestone_common_save_table(curve_table, curve_csv);

plot_data = build_milestone_A_truth_plot_data(curve_table, struct( ...
    'case_id', selection.case_id, ...
    't0G_star', summary_row.t0G_star_s, ...
    't0A_star', summary_row.t0A_star_s, ...
    't0T_star', summary_row.t0T_star_s));

fig_main = plot_milestone_A_truth_scan(plot_data, style, 'main');
fig_main_path = fullfile(paths.figures, 'MA_truth_baseline_truth_window_scan.png');
milestone_common_save_figure(fig_main, fig_main_path);
close(fig_main);

fig_highlight = plot_milestone_A_truth_scan(plot_data, style, 'highlight');
fig_highlight_path = fullfile(paths.figures, 'MA_truth_baseline_worst_window_highlight.png');
milestone_common_save_figure(fig_highlight, fig_highlight_path);
close(fig_highlight);

result = struct();
result.milestone_id = meta.milestone_id;
result.title = meta.title;
result.config = cfg;
result.purpose = 'Single-layer static inverse-design truth baseline.';
result.reused_modules = meta.reuse_stages;
result.tables = struct();
result.figures = struct();
result.artifacts = struct();
result.tables.baseline_configuration_summary = string(baseline_csv);
result.tables.worst_window_identification = string(worst_csv);
result.tables.window_level_truth_curve = string(curve_csv);
result.figures.truth_window_scan = string(fig_main_path);
result.figures.worst_window_highlight = string(fig_highlight_path);
result.artifacts.truth_baseline_kernel = "stage12A_truth_baseline_kernel";
result.artifacts.truth_window_scan_kernel = "stage12B_truth_case_window_scan";

result.summary = struct( ...
    'case_id', string(selection.case_id), ...
    'theta_baseline', meta.theta, ...
    'Tw_baseline', meta.Tw_s, ...
    'DG_worst_truth', summary_row.DG_worst_truth, ...
    'DA_worst_truth', summary_row.DA_worst_truth, ...
    'DT_worst_truth', summary_row.DT_worst_truth, ...
    't0G_star', summary_row.t0G_star_s, ...
    't0A_star', summary_row.t0A_star_s, ...
    't0T_star', summary_row.t0T_star_s, ...
    'is_feasible_truth', is_feasible_truth, ...
    'dominant_metric', dominant_metric, ...
    'key_counts', struct('num_cases', height(kernel_out.case_table), 'num_tables', numel(fieldnames(result.tables)), 'num_figures', numel(fieldnames(result.figures))), ...
    'success_flags', struct('stage12A_truth_baseline_kernel', true, 'stage12B_truth_case_window_scan', true), ...
    'main_conclusion', local_make_conclusion(is_feasible_truth, dominant_metric, summary_row));

files = milestone_common_export_summary(result, paths);
result.artifacts.summary_report = files.report_md;
result.artifacts.summary_mat = files.summary_mat;
end

function dominant_metric = local_pick_dominant_metric(summary_row)
[~, idx] = min([summary_row.DG_worst_truth, summary_row.DA_worst_truth, summary_row.DT_worst_truth]);
labels = ["DG", "DA", "DT"];
dominant_metric = labels(idx);
end

function txt = local_make_conclusion(is_feasible_truth, dominant_metric, summary_row)
if is_feasible_truth
    txt = sprintf(['Baseline case remains feasible under truth criteria. ', ...
        'Worst values are DG=%.3f, DA=%.3f, DT=%.3f, with dominant metric %s.'], ...
        summary_row.DG_worst_truth, summary_row.DA_worst_truth, summary_row.DT_worst_truth, dominant_metric);
else
    txt = sprintf(['Baseline case is infeasible under truth criteria. ', ...
        'Worst values are DG=%.3f, DA=%.3f, DT=%.3f, with dominant metric %s.'], ...
        summary_row.DG_worst_truth, summary_row.DA_worst_truth, summary_row.DT_worst_truth, dominant_metric);
end
end
