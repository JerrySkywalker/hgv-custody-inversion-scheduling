function result = milestone_A_extension_baseline_neighbor(cfg)
%MILESTONE_A_EXTENSION_BASELINE_NEIGHBOR Export the fixed MA extension case.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end

paths = local_build_paths(cfg);
baseline = local_load_baseline(paths.source_ma);
stage13 = local_load_stage13(paths.source_stage13);
candidate_tag = "dt_first_probe_P6T4F0";

candidate_row = stage13.summary(strcmp(string(stage13.summary.case_tag), candidate_tag), :);
if isempty(candidate_row)
    error('MA extension source candidate is missing from Stage13 summary: %s', candidate_tag);
end

baseline_curve = readtable(paths.source_stage13.baseline_curve_csv);
candidate_curve = readtable(fullfile(paths.source_stage13.data, sprintf('stage13_curve_%s.csv', candidate_tag)));
compare_figure = local_prepare_compare_figure(paths, baseline_curve, candidate_curve, candidate_tag);

summary_table = table( ...
    string(baseline.case_id), candidate_tag, ...
    baseline.DG_worst_truth, baseline.DA_worst_truth, baseline.DT_bar_worst, baseline.DT_worst, ...
    candidate_row.D_G_worst, candidate_row.D_A_worst, local_safe_dt_bar(candidate_curve), candidate_row.D_T_worst, ...
    string(baseline.dominant_metric), string(candidate_row.active_constraint), ...
    'VariableNames', {'baseline_case_id', 'extension_case_tag', ...
    'baseline_DG_worst', 'baseline_DA_worst', 'baseline_DT_bar_worst', 'baseline_DT_worst', ...
    'extension_DG_worst', 'extension_DA_worst', 'extension_DT_bar_worst', 'extension_DT_worst', ...
    'baseline_dominant_metric', 'extension_active_constraint'});
summary_csv = fullfile(paths.tables, 'MA_extension_dt_first_probe_P6T4F0_summary.csv');
milestone_common_save_table(summary_table, summary_csv);

result = struct();
result.milestone_id = "MA_extension";
result.title = "baseline_neighbor";
result.config = cfg;
result.purpose = "Formal MA extension export for the fixed baseline-neighborhood control case.";
result.reused_modules = { ...
    'Milestone A truth-baseline outputs', ...
    'Stage13 dt_first_probe baseline-vs-candidate comparison outputs'};
result.tables = struct('baseline_neighbor_summary', string(summary_csv));
result.figures = struct('baseline_vs_dt_first_probe', string(compare_figure));
result.artifacts = struct();
result.artifacts.source_ma_summary = string(paths.source_ma.summary_md);
result.artifacts.source_stage13_summary = string(paths.source_stage13.summary_md);
result.artifacts.source_stage13_export = string(paths.source_stage13.export_md);
result.summary = struct( ...
    'baseline_case_id', string(baseline.case_id), ...
    'extension_case_tag', candidate_tag, ...
    'recommended_for_MA', candidate_tag, ...
    'backup_for_MB_or_defense', "dg_micro_07", ...
    'development_only', "dg_first_probe_3", ...
    'baseline_dominant_metric', string(baseline.dominant_metric), ...
    'extension_active_constraint', string(candidate_row.active_constraint), ...
    'paper_ready_statement', local_build_paper_statement(candidate_row));

files = local_write_summary(result, paths);
result.artifacts.summary_report = files.report_md;
result.artifacts.summary_mat = files.summary_mat;
result.artifacts.export_summary_md = files.export_md;
end

function paths = local_build_paths(cfg)
root_dir = fullfile(cfg.paths.milestones, 'MA_extension');
paths = struct();
paths.root = root_dir;
paths.data = fullfile(root_dir, 'data');
paths.figures = fullfile(root_dir, 'figures');
paths.tables = fullfile(root_dir, 'tables');
paths.reports = fullfile(root_dir, 'reports');
paths.summary_report = fullfile(paths.reports, 'MA_extension_summary.md');
paths.export_report = fullfile(paths.reports, 'MA_extension_export_summary.md');
paths.summary_mat = fullfile(paths.data, 'MA_extension_baseline_neighbor_summary.mat');

paths.source_ma = struct();
paths.source_ma.root = fullfile(cfg.paths.milestones, 'MA');
paths.source_ma.worst_csv = fullfile(paths.source_ma.root, 'tables', 'MA_truth_baseline_worst_window_identification.csv');
paths.source_ma.summary_md = fullfile(paths.source_ma.root, 'reports', 'MA_summary.md');

paths.source_stage13 = struct();
paths.source_stage13.root = cfg.paths.stage13;
paths.source_stage13.tables = fullfile(cfg.paths.stage13, 'tables');
paths.source_stage13.figures = fullfile(cfg.paths.stage13, 'figures');
paths.source_stage13.data = fullfile(cfg.paths.stage13, 'data');
paths.source_stage13.summary_csv = fullfile(paths.source_stage13.tables, 'stage13_candidate_summary.csv');
paths.source_stage13.summary_md = fullfile(cfg.paths.stage13, 'reports', 'stage13_summary.md');
paths.source_stage13.export_md = fullfile(cfg.paths.stage13, 'reports', 'stage13_dissertation_export.md');
paths.source_stage13.baseline_curve_csv = fullfile(paths.source_stage13.data, 'stage13_curve_dt_first_probe_baseline.csv');
paths.source_stage13.compare_png = fullfile(paths.source_stage13.figures, 'stage13_case_dt_first_probe_P6T4F0_vs_baseline.png');

ensure_dir(root_dir);
ensure_dir(paths.data);
ensure_dir(paths.figures);
ensure_dir(paths.tables);
ensure_dir(paths.reports);
end

function baseline = local_load_baseline(source_ma)
if ~isfile(source_ma.worst_csv)
    error('Milestone A baseline output is missing: %s', source_ma.worst_csv);
end

worst_table = readtable(source_ma.worst_csv);
row = worst_table(1, :);
baseline = struct();
baseline.case_id = string(row.case_id);
baseline.DG_worst_truth = row.DG_worst_truth;
baseline.DA_worst_truth = row.DA_worst_truth;
baseline.DT_bar_worst = row.DT_bar_worst;
baseline.DT_worst = row.DT_worst;
baseline.dominant_metric = string(row.dominant_metric);
end

function stage13 = local_load_stage13(source_stage13)
if ~isfile(source_stage13.summary_csv)
    error('Stage13 candidate summary is missing: %s', source_stage13.summary_csv);
end
stage13 = struct();
stage13.summary = readtable(source_stage13.summary_csv);
end

function out_path = local_prepare_compare_figure(paths, baseline_curve, candidate_curve, candidate_tag)
out_path = fullfile(paths.figures, sprintf('MA_extension_%s_vs_baseline.png', candidate_tag));
if isfile(paths.source_stage13.compare_png)
    copyfile(paths.source_stage13.compare_png, out_path);
    return;
end

style = milestone_common_plot_style();
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [120 80 980 860]);
tl = tiledlayout(fig, 3, 1, 'Padding', 'compact', 'TileSpacing', 'compact');
metrics = { ...
    'DG_window', 'D_G', 1.0; ...
    'DA_window', 'D_A', 1.0; ...
    'DT_bar_window', 'D_{T,bar}', 0.5};
for i = 1:size(metrics, 1)
    ax = nexttile(tl);
    hold(ax, 'on');
    plot(ax, baseline_curve.t0_s, baseline_curve.(metrics{i, 1}), '-', 'LineWidth', 1.8, 'Color', style.colors(1, :), 'DisplayName', 'baseline');
    plot(ax, candidate_curve.t0_s, candidate_curve.(metrics{i, 1}), '--', 'LineWidth', 1.8, 'Color', style.colors(2, :), 'DisplayName', char(candidate_tag));
    yline(ax, metrics{i, 3}, ':', 'Color', style.threshold_color, 'LineWidth', 1.2, 'DisplayName', 'threshold');
    ylabel(ax, metrics{i, 2}, 'Interpreter', 'tex');
    grid(ax, 'on');
    if i == 1
        title(ax, sprintf('MA extension: baseline vs %s', char(candidate_tag)), 'Interpreter', 'tex');
        legend(ax, 'Location', 'best', 'Interpreter', 'tex');
    end
    if i == size(metrics, 1)
        xlabel(ax, 'window start t_0 (s)', 'Interpreter', 'tex');
    end
end
apply_dissertation_plot_style(fig, style);
milestone_common_save_figure(fig, out_path);
close(fig);
end

function value = local_safe_dt_bar(curve_table)
if isempty(curve_table) || ~ismember('DT_bar_window', curve_table.Properties.VariableNames)
    value = NaN;
    return;
end
value = min(curve_table.DT_bar_window);
end

function txt = local_build_paper_statement(candidate_row)
txt = sprintf([ ...
    'For the MA writing layer, %s is the only formal baseline-neighborhood extension case. ', ...
    'It is retained to support the conclusion that the baseline neighborhood should be discussed through temporal-margin sensitivity, ', ...
    'while DG refined cases remain backup-only. Current Stage13 signature: active_constraint=%s, D_G^{worst}=%.3f, D_A^{worst}=%.3f, D_T^{worst}=%.3f.'], ...
    string(candidate_row.case_tag), string(candidate_row.active_constraint), ...
    candidate_row.D_G_worst, candidate_row.D_A_worst, candidate_row.D_T_worst);
end

function files = local_write_summary(result, paths)
save(paths.summary_mat, 'result', '-v7.3');

fid = fopen(paths.export_report, 'w');
if fid < 0
    error('Failed to open MA extension export summary: %s', paths.export_report);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '# MA extension export summary\n\n');
fprintf(fid, '- recommended_for_MA: `%s`\n', result.summary.recommended_for_MA);
fprintf(fid, '- backup_for_MB_or_defense: `%s`\n', result.summary.backup_for_MB_or_defense);
fprintf(fid, '- development_only: `%s`\n', result.summary.development_only);
fprintf(fid, '- statement: %s\n', result.summary.paper_ready_statement);

files = milestone_common_export_summary(result, paths);
files.export_md = string(paths.export_report);
end
