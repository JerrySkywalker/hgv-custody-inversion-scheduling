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
task_meta = meta;
if isfield(meta, 'task_slice_settings') && isstruct(meta.task_slice_settings)
    task_meta.slice_settings = meta.task_slice_settings;
end

pool = stage12B_mb_design_pool(cfg, meta);
slice_hi = stage12C_inverse_slice_packager(pool, 'hi', meta);
slice_pt = stage12C_inverse_slice_packager(pool, 'PT', meta);
task_nominal = stage12D_task_slice_packager(pool, 'nominal', task_meta);
task_heading = stage12D_task_slice_packager(pool, 'heading', task_meta);
task_critical = stage12D_task_slice_packager(pool, 'critical', task_meta);
minimum_pack = stage12E_minimum_design_packager(pool, cfg, meta);

slice_summary_table = build_milestone_B_slice_summary({slice_hi, slice_pt});
task_summary_table = summarize_task_family_comparison({task_nominal, task_heading, task_critical});

design_pool_table = pool.design_pool_table;
feasible_domain_table = minimum_pack.full_theta_table;
minimum_design_table = minimum_pack.minimum_design_table;
near_optimal_table = minimum_pack.near_optimal_table;
design_pool_table = local_select_design_pool_columns(design_pool_table);
feasible_domain_table = local_select_feasible_domain_columns(feasible_domain_table);
minimum_design_table = local_select_minimum_design_columns(minimum_design_table);
near_optimal_table = local_select_feasible_domain_columns(near_optimal_table);

slice_summary_csv = fullfile(paths.tables, 'MB_inverse_slices_slice_grid_summary.csv');
design_pool_csv = fullfile(paths.tables, 'MB_inverse_slices_design_pool_table.csv');
feasible_csv = fullfile(paths.tables, 'MB_inverse_slices_feasible_domain_table.csv');
minimum_csv = fullfile(paths.tables, 'MB_inverse_slices_minimum_design_table.csv');
near_optimal_csv = fullfile(paths.tables, 'MB_inverse_slices_near_optimal_design_table.csv');
task_summary_csv = fullfile(paths.tables, 'MB_inverse_slices_task_slice_summary.csv');
milestone_common_save_table(slice_summary_table, slice_summary_csv);
milestone_common_save_table(design_pool_table, design_pool_csv);
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
fig2_legacy_path = fullfile(paths.figures, 'MB_inverse_slices_minimum_boundary_map.png');
milestone_common_save_figure(fig2, fig2_path);
milestone_common_save_figure(fig2, fig2_legacy_path);
close(fig2);

fig3 = plot_mb_task_family_comparison(task_summary_table, style);
fig3_path = fullfile(paths.figures, 'MB_inverse_slices_task_family_slice_comparison.png');
milestone_common_save_figure(fig3, fig3_path);
close(fig3);

result = struct();
result.milestone_id = meta.milestone_id;
result.title = meta.title;
result.config = cfg;
result.purpose = '真值静态可行域、任务侧切片比较与最小布置提取。';
result.reused_modules = {'Unified design-pool builder', 'Constellation slice packager', 'Task-side slice packager', 'Minimum-design extractor'};
result.tables = struct();
result.figures = struct();
result.artifacts = struct();
result.tables.slice_grid_summary = string(slice_summary_csv);
result.tables.design_pool_table = string(design_pool_csv);
result.tables.feasible_domain_table = string(feasible_csv);
result.tables.minimum_design_table = string(minimum_csv);
result.tables.near_optimal_design_table = string(near_optimal_csv);
result.tables.task_slice_summary = string(task_summary_csv);
result.figures.feasible_domain_map = string(fig1_path);
result.figures.minimum_design_map = string(fig2_path);
result.figures.minimum_boundary_map = string(fig2_legacy_path);
result.figures.task_family_slice_comparison = string(fig3_path);
result.artifacts.temporal_metric_note = "时序图表展示采用有界时序连续性裕度 DT_bar，闭合判定与主导失效识别继续采用标准化时序连续性裕度 DT >= 1。";

task_family_minNs = local_task_metric_map(task_summary_table, 'Ns_min_feasible');
task_family_best_margin = local_task_metric_map(task_summary_table, 'best_joint_margin');
minimum_support_sources = "";
if ~isempty(minimum_design_table) && ismember('support_sources', minimum_design_table.Properties.VariableNames)
    minimum_support_sources = strjoin(unique(string(minimum_design_table.support_sources), 'stable'), "; ");
end

result.summary = struct( ...
    'slice_axes', {{'h-i', 'P-T'}}, ...
    'num_unique_grid_points', height(pool.design_pool_table), ...
    'num_unique_feasible_points', height(pool.feasible_theta_table_joint), ...
    'num_grid_points', height(minimum_pack.full_theta_table), ...
    'num_feasible_points', height(minimum_pack.feasible_theta_table), ...
    'minimum_design_count', height(minimum_design_table), ...
    'minimum_design_Ns', local_first_value(minimum_design_table, 'Ns'), ...
    'minimum_design_support_sources', minimum_support_sources, ...
    'minimum_design', minimum_pack.minimum_design, ...
    'near_optimal_region_size', height(near_optimal_table), ...
    'task_family_minNs', task_family_minNs, ...
    'task_family_best_margin', task_family_best_margin, ...
    'slice_anchor_hi', local_struct_to_string(slice_hi.view_anchor), ...
    'slice_anchor_pt', local_struct_to_string(slice_pt.view_anchor), ...
    'slice_anchor_used_for_hi_view', local_struct_to_string(slice_hi.view_anchor), ...
    'slice_anchor_used_for_pt_view', local_struct_to_string(slice_pt.view_anchor), ...
    'dominant_constraint_distribution', minimum_pack.dominant_constraint_distribution, ...
    'key_counts', struct('num_tables', numel(fieldnames(result.tables)), 'num_figures', numel(fieldnames(result.figures))), ...
    'success_flags', struct('constellation_slice_packager', true, 'task_slice_packager', true, 'minimum_design_extractor', true), ...
    'main_conclusion', local_make_conclusion(pool, minimum_pack, task_summary_table));

files = milestone_common_export_summary(result, paths);
result.artifacts.summary_report = files.report_md;
result.artifacts.summary_mat = files.summary_mat;
end

function txt = local_make_conclusion(pool, minimum_pack, task_summary_table)
task_text = local_task_conclusion(task_summary_table);
if isempty(minimum_pack.minimum_design_table)
    txt = sprintf(['当前 MB 统一 design pool 含 %d 个 unique design，其中 %d 个满足 joint truth feasible。', ...
        '当前统一 feasible domain 中未提取到可行最小布置。', ...
        '任务族切片比较结果为 %s。'], ...
        height(pool.design_pool_table), height(minimum_pack.feasible_theta_table), task_text);
else
    txt = sprintf(['当前 MB 统一 design pool 含 %d 个 unique design，其中 %d 个满足 joint truth feasible。', ...
        '最小布置对应 N_s=%g，unique minimum design 数为 %d。', ...
        '任务族切片比较结果为 %s。'], ...
        height(pool.design_pool_table), height(minimum_pack.feasible_theta_table), minimum_pack.minimum_design_table.Ns(1), ...
        height(minimum_pack.minimum_design_table), task_text);
end
end

function T = local_select_design_pool_columns(T)
if isempty(T)
    return;
end
want = {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'slice_source', 'support_sources', 'num_support_sources'};
keep = intersect(want, T.Properties.VariableNames, 'stable');
T = T(:, keep);
end

function T = local_select_feasible_domain_columns(T)
if isempty(T)
    return;
end
want = {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'DG_worst', 'DA_worst', 'DT_bar_worst', 'DT_worst', 'joint_margin', 'feasible_flag', 'dominant_fail_tag', 'slice_source', 'support_sources', 'num_support_sources'};
keep = intersect(want, T.Properties.VariableNames, 'stable');
T = T(:, keep);
end

function T = local_select_minimum_design_columns(T)
if isempty(T)
    return;
end
want = {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'objective_value', 'dominant_constraint', 'has_near_optimal_alternatives', 'joint_margin', 'DG_worst', 'DA_worst', 'DT_bar_worst', 'DT_worst', 'slice_source', 'support_sources', 'num_support_sources'};
keep = intersect(want, T.Properties.VariableNames, 'stable');
T = T(:, keep);
end

function out = local_task_metric_map(task_summary_table, metric_name)
out = struct();
if isempty(task_summary_table) || ~ismember(metric_name, task_summary_table.Properties.VariableNames)
    return;
end
for k = 1:height(task_summary_table)
    key = matlab.lang.makeValidName(char(string(task_summary_table.family_name(k))));
    out.(key) = task_summary_table.(metric_name)(k);
end
end

function txt = local_struct_to_string(S)
if isempty(S) || ~isstruct(S)
    txt = "";
    return;
end
fields = fieldnames(S);
parts = strings(numel(fields), 1);
for k = 1:numel(fields)
    value = S.(fields{k});
    if isnumeric(value) && isscalar(value)
        value_txt = num2str(value);
    else
        value_txt = char(string(value));
    end
    parts(k) = sprintf('%s=%s', fields{k}, value_txt);
end
txt = strjoin(parts, ', ');
end

function txt = local_task_conclusion(task_summary_table)
if isempty(task_summary_table)
    txt = '任务族切片尚无可用统计。';
    return;
end

parts = strings(height(task_summary_table), 1);
for k = 1:height(task_summary_table)
    family_name = string(task_summary_table.family_name(k));
    feasible_ratio = task_summary_table.feasible_ratio(k);
    min_ns = task_summary_table.Ns_min_feasible(k);
    best_margin = task_summary_table.best_joint_margin(k);
    parts(k) = sprintf('%s: feasible_ratio=%.2f, min_Ns=%g, best_margin=%.3f', ...
        family_name, feasible_ratio, min_ns, best_margin);
end
txt = strjoin(parts, '; ');
end

function value = local_first_value(T, field_name)
value = NaN;
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    return;
end
value = T.(field_name)(1);
end
