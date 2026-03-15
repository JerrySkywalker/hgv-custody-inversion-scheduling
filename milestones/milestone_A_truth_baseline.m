function result = milestone_A_truth_baseline(cfg)
%MILESTONE_A_TRUTH_BASELINE Chapter 4 Milestone A truth baseline wrapper.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end

meta = cfg.milestones.MA;
paths = milestone_common_output_paths(cfg, meta.milestone_id, meta.title);
style = milestone_common_plot_style();

result = struct();
result.milestone_id = meta.milestone_id;
result.title = meta.title;
result.config = cfg;
result.purpose = 'Truth baseline for single-layer static inverse design.';
result.reused_modules = meta.reuse_stages;
result.tables = struct();
result.figures = struct();
result.artifacts = struct();

summary = struct( ...
    'case_id', string(meta.case_id), ...
    'theta_baseline', meta.theta, ...
    'Tw_baseline', meta.Tw_s, ...
    'DG_worst_truth', NaN, ...
    'DA_worst_truth', NaN, ...
    'DT_worst_truth', NaN, ...
    't0G_star', NaN, ...
    't0A_star', NaN, ...
    't0T_star', NaN, ...
    'is_feasible_truth', false, ...
    'dominant_metric', "unavailable", ...
    'key_counts', struct('num_cases', 0, 'num_tables', 0, 'num_figures', 0), ...
    'success_flags', struct('stage09_validate_single_design', false), ...
    'main_conclusion', "Milestone A scaffold executed.");

case_selection = milestone_common_case_selection(cfg, meta.milestone_id);
baseline_table = local_make_baseline_config_table(meta, case_selection);
baseline_table_path = fullfile(paths.tables, 'MA_truth_baseline_configuration_summary.csv');
milestone_common_save_table(baseline_table, baseline_table_path);
result.tables.baseline_configuration_summary = string(baseline_table_path);

worst_table = table(string(meta.case_id), NaN, NaN, NaN, false, ...
    'VariableNames', {'case_id', 'DG_worst_truth', 'DA_worst_truth', 'DT_worst_truth', 'is_feasible_truth'});
metric_table = table(["DG"; "DA"; "DT"], [NaN; NaN; NaN], [NaN; NaN; NaN], ...
    'VariableNames', {'metric', 'worst_value', 'worst_t0_s'});

try
    cfg_stage = cfg;
    cfg_stage.stage09.run_tag = 'milestoneA';
    cfg_stage.stage09.search_domain.h_grid_km = meta.theta.h_km;
    cfg_stage.stage09.search_domain.i_grid_deg = meta.theta.i_deg;
    cfg_stage.stage09.search_domain.P_grid = meta.theta.P;
    cfg_stage.stage09.search_domain.T_grid = meta.theta.T;
    cfg_stage.stage09.search_domain.F_fixed = meta.theta.F;

    out_validate = stage09_validate_single_design(cfg_stage);
    row = out_validate.summary_table(1, :);
    summary.DG_worst_truth = row.DG_rob;
    summary.DA_worst_truth = row.DA_rob;
    summary.DT_worst_truth = row.DT_rob;
    summary.is_feasible_truth = logical(row.feasible_flag);
    summary.dominant_metric = string(row.dominant_fail_tag);
    summary.success_flags.stage09_validate_single_design = true;
    summary.key_counts.num_cases = height(out_validate.case_table);
    summary.main_conclusion = local_make_conclusion(summary);

    worst_table = local_build_worst_case_table(out_validate);
    metric_table = local_build_metric_summary_table(summary);
    result.artifacts.stage09_validation_cache = string(out_validate.files.cache_file);
    result.artifacts.stage09_validation_cases = string(out_validate.files.case_csv);
catch ME
    result.artifacts.stage09_validation_error = string(ME.message);
    summary.main_conclusion = "Milestone A completed with placeholder truth summary because stage09 validation could not be reused.";
end

worst_table_path = fullfile(paths.tables, 'MA_truth_baseline_worst_window_identification.csv');
metric_table_path = fullfile(paths.tables, 'MA_truth_baseline_three_metric_summary.csv');
milestone_common_save_table(worst_table, worst_table_path);
milestone_common_save_table(metric_table, metric_table_path);
result.tables.worst_window_identification = string(worst_table_path);
result.tables.three_metric_truth_summary = string(metric_table_path);

fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
bar(ax, [summary.DG_worst_truth, summary.DA_worst_truth, summary.DT_worst_truth], 'FaceColor', style.colors(1, :));
set(ax, 'XTickLabel', {'DG', 'DA', 'DT'}, 'FontSize', style.font_size);
ylabel(ax, 'Worst-case value');
title(ax, 'Milestone A Truth Window Scan');
grid(ax, 'on');
fig_path = fullfile(paths.figures, 'MA_truth_baseline_truth_window_scan.png');
milestone_common_save_figure(fig, fig_path);
close(fig);
result.figures.truth_window_scan = string(fig_path);

summary.key_counts.num_tables = numel(fieldnames(result.tables));
summary.key_counts.num_figures = numel(fieldnames(result.figures));
result.summary = summary;

files = milestone_common_export_summary(result, paths);
result.artifacts.summary_report = files.report_md;
result.artifacts.summary_mat = files.summary_mat;
end

function T = local_make_baseline_config_table(meta, selection)
theta = meta.theta;
T = table( ...
    string(selection.case_id), string(selection.case_family), meta.Tw_s, ...
    theta.h_km, theta.i_deg, theta.P, theta.T, theta.F, ...
    'VariableNames', {'case_id', 'case_family', 'Tw_s', 'h_km', 'i_deg', 'P', 'T', 'F'});
end

function T = local_build_worst_case_table(out_validate)
row = out_validate.summary_table(1, :);

T = table( ...
    string(row.worst_case_id_DG), string(row.worst_case_id_DA), string(row.worst_case_id_DT), ...
    row.DG_rob, row.DA_rob, row.DT_rob, logical(row.feasible_flag), ...
    'VariableNames', {'worst_case_id_DG', 'worst_case_id_DA', 'worst_case_id_DT', ...
    'DG_worst_truth', 'DA_worst_truth', 'DT_worst_truth', 'is_feasible_truth'});
end

function T = local_build_metric_summary_table(summary)
T = table( ...
    ["DG"; "DA"; "DT"], ...
    [summary.DG_worst_truth; summary.DA_worst_truth; summary.DT_worst_truth], ...
    [summary.t0G_star; summary.t0A_star; summary.t0T_star], ...
    'VariableNames', {'metric', 'worst_value', 'worst_t0_s'});
end

function txt = local_make_conclusion(summary)
if summary.is_feasible_truth
    txt = sprintf('Baseline design remains feasible under truth metrics; dominant tag=%s.', summary.dominant_metric);
else
    txt = sprintf('Baseline design is infeasible under truth metrics; dominant tag=%s.', summary.dominant_metric);
end
end
