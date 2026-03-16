function result = milestone_B_inverse_slices(cfg)
%MILESTONE_B_INVERSE_SLICES Dissertation-grade Chapter 4 Milestone B pipeline.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end

meta = cfg.milestones.MB;
paths = milestone_common_output_paths(cfg, meta.milestone_id, meta.title);
style = milestone_common_plot_style();

slice_hi = stage12C_inverse_slice_packager(cfg, 'hi', meta);
slice_pt = stage12C_inverse_slice_packager(cfg, 'PT', meta);
task_nominal = stage12D_task_slice_packager(cfg, 'nominal', meta);
task_heading = stage12D_task_slice_packager(cfg, 'heading', meta);
task_critical = stage12D_task_slice_packager(cfg, 'critical', meta);
minimum_pack = stage12E_minimum_design_packager( ...
    {slice_hi, slice_pt, task_nominal, task_heading, task_critical}, cfg, meta);

slice_summary_table = build_milestone_B_slice_summary({slice_hi, slice_pt});
task_summary_table = table( ...
    ["nominal"; "heading"; "critical"], ...
    [task_nominal.summary.num_grid_points; task_heading.summary.num_grid_points; task_critical.summary.num_grid_points], ...
    [task_nominal.summary.num_feasible_points; task_heading.summary.num_feasible_points; task_critical.summary.num_feasible_points], ...
    [task_nominal.summary.feasible_ratio; task_heading.summary.feasible_ratio; task_critical.summary.feasible_ratio], ...
    'VariableNames', {'task_slice_id', 'num_grid_points', 'num_feasible_points', 'feasible_ratio'});

feasible_domain_table = minimum_pack.full_theta_table;
minimum_design_table = minimum_pack.minimum_design_table;
near_optimal_table = minimum_pack.near_optimal_table;
feasible_domain_table = local_select_feasible_domain_columns(feasible_domain_table);
minimum_design_table = local_select_minimum_design_columns(minimum_design_table);
near_optimal_table = local_select_feasible_domain_columns(near_optimal_table);

slice_summary_csv = fullfile(paths.tables, 'MB_inverse_slices_slice_grid_summary.csv');
feasible_csv = fullfile(paths.tables, 'MB_inverse_slices_feasible_domain_table.csv');
minimum_csv = fullfile(paths.tables, 'MB_inverse_slices_minimum_design_table.csv');
near_optimal_csv = fullfile(paths.tables, 'MB_inverse_slices_near_optimal_design_table.csv');
task_summary_csv = fullfile(paths.tables, 'MB_inverse_slices_task_slice_summary.csv');
milestone_common_save_table(slice_summary_table, slice_summary_csv);
milestone_common_save_table(feasible_domain_table, feasible_csv);
milestone_common_save_table(minimum_design_table, minimum_csv);
milestone_common_save_table(near_optimal_table, near_optimal_csv);
milestone_common_save_table(task_summary_table, task_summary_csv);

fig1 = plot_mb_feasible_domain_map(slice_hi.view_table, slice_pt.view_table, minimum_design_table, style);
fig1_path = fullfile(paths.figures, 'MB_inverse_slices_feasible_domain_map.png');
milestone_common_save_figure(fig1, fig1_path);
close(fig1);

fig2 = plot_mb_minimum_design_map(minimum_pack.feasible_theta_table, minimum_design_table, near_optimal_table, style);
fig2_path = fullfile(paths.figures, 'MB_inverse_slices_minimum_design_map.png');
milestone_common_save_figure(fig2, fig2_path);
close(fig2);

fig3 = plot_milestone_B_task_slice_compare(task_summary_table, style);
fig3_path = fullfile(paths.figures, 'MB_inverse_slices_task_family_slice_comparison.png');
milestone_common_save_figure(fig3, fig3_path);
close(fig3);

result = struct();
result.milestone_id = meta.milestone_id;
result.title = meta.title;
result.config = cfg;
result.purpose = '真值静态可行域、任务侧切片比较与最小布置提取。';
result.reused_modules = {'Constellation slice packager', 'Task-side slice packager', 'Minimum-design extractor'};
result.tables = struct();
result.figures = struct();
result.artifacts = struct();
result.tables.slice_grid_summary = string(slice_summary_csv);
result.tables.feasible_domain_table = string(feasible_csv);
result.tables.minimum_design_table = string(minimum_csv);
result.tables.near_optimal_design_table = string(near_optimal_csv);
result.tables.task_slice_summary = string(task_summary_csv);
result.figures.feasible_domain_map = string(fig1_path);
result.figures.minimum_design_map = string(fig2_path);
result.figures.minimum_boundary_map = string(fig2_path);
result.figures.task_family_slice_comparison = string(fig3_path);
result.artifacts.temporal_metric_note = "时序图表展示采用有界时序连续性裕度 DT_bar，闭合判定与主导失效识别继续采用标准化时序连续性裕度 DT >= 1。";

result.summary = struct( ...
    'slice_axes', {{'h-i', 'P-T'}}, ...
    'num_grid_points', height(minimum_pack.full_theta_table), ...
    'num_feasible_points', height(minimum_pack.feasible_theta_table), ...
    'minimum_design', minimum_pack.minimum_design, ...
    'near_optimal_region_size', height(near_optimal_table), ...
    'dominant_constraint_distribution', minimum_pack.dominant_constraint_distribution, ...
    'key_counts', struct('num_tables', numel(fieldnames(result.tables)), 'num_figures', numel(fieldnames(result.figures))), ...
    'success_flags', struct('constellation_slice_packager', true, 'task_slice_packager', true, 'minimum_design_extractor', true), ...
    'main_conclusion', local_make_conclusion(minimum_pack, task_summary_table));

files = milestone_common_export_summary(result, paths);
result.artifacts.summary_report = files.report_md;
result.artifacts.summary_mat = files.summary_mat;
end

function txt = local_make_conclusion(minimum_pack, task_summary_table)
task_text = sprintf('nominal=%.2f, heading=%.2f, critical=%.2f', ...
    task_summary_table.feasible_ratio(1), task_summary_table.feasible_ratio(2), task_summary_table.feasible_ratio(3));
if isempty(minimum_pack.minimum_design_table)
    txt = sprintf(['真值静态可行域中未提取到可行最小布置。任务侧切片可行比例为 %s。', ...
        '时序约束采用标准化有界时序裕度进行闭合判定，图表展示采用有界时序连续性裕度。'], task_text);
else
    txt = sprintf(['真值静态可行域给出的最小布置对应 N_s=%g。任务侧切片可行比例为 %s。', ...
        '最小布置边界与主导失效识别均使用标准化时序连续性裕度 D_T。'], ...
        minimum_pack.minimum_design_table.Ns(1), task_text);
end
end

function T = local_select_feasible_domain_columns(T)
if isempty(T)
    return;
end
want = {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'DG_worst', 'DA_worst', 'DT_bar_worst', 'DT_worst', 'feasible_flag', 'dominant_fail_tag', 'slice_source'};
keep = intersect(want, T.Properties.VariableNames, 'stable');
T = T(:, keep);
end

function T = local_select_minimum_design_columns(T)
if isempty(T)
    return;
end
want = {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'objective_value', 'dominant_constraint', 'has_near_optimal_alternatives', 'DG_worst', 'DA_worst', 'DT_bar_worst', 'DT_worst', 'slice_source'};
keep = intersect(want, T.Properties.VariableNames, 'stable');
T = T(:, keep);
end
