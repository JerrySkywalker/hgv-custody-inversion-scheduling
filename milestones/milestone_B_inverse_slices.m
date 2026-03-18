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
export_paths = local_mb_export_paths(paths);
style = milestone_common_plot_style();
write_figures = cfg.milestones.save_figures && ~(isfield(meta, 'preflight_mode') && logical(meta.preflight_mode));
write_supplementary = local_write_supplementary(meta);
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

fig1_path = "";
fig2_path = "";
fig2_legacy_path = "";
fig3_path = "";
if write_figures
    fig1 = plot_mb_feasible_domain_map(slice_hi.view_table, slice_pt.view_table, minimum_design_table, style);
    fig1_path = fullfile(paths.figures, 'MB_inverse_slices_feasible_domain_map.png');
    milestone_common_save_figure(fig1, fig1_path);
    milestone_common_save_figure(fig1, fullfile(export_paths.supplementary.figures, 'MB_feasible_domain_map.png'));
    close(fig1);

    fig2 = plot_mb_minimum_design_map(minimum_pack.feasible_theta_table, minimum_design_table, near_optimal_table, style, pool.baseline_theta);
    fig2_path = fullfile(paths.figures, 'MB_inverse_slices_minimum_design_map.png');
    fig2_legacy_path = fullfile(paths.figures, 'MB_inverse_slices_minimum_boundary_map.png');
    milestone_common_save_figure(fig2, fig2_path);
    milestone_common_save_figure(fig2, fig2_legacy_path);
    milestone_common_save_figure(fig2, fullfile(export_paths.core.figures, 'MB_minimum_design_and_near_optimal_region.png'));
    close(fig2);

    fig3 = plot_mb_task_family_comparison(task_summary_table, style);
    fig3_path = fullfile(paths.figures, 'MB_inverse_slices_task_family_slice_comparison.png');
    milestone_common_save_figure(fig3, fig3_path);
    milestone_common_save_figure(fig3, fullfile(export_paths.supplementary.figures, 'MB_task_family_slice_comparison.png'));
    close(fig3);
end

supplementary = local_build_supplementary_exports(cfg, meta, paths, style, pool, minimum_pack, write_figures, write_supplementary);

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
result.tables = local_merge_struct_fields(result.tables, supplementary.tables);
result.figures = local_merge_struct_fields(result.figures, supplementary.figures);
result.artifacts.temporal_metric_note = "时序图表展示采用有界时序连续性裕度 DT_bar，闭合判定与主导失效识别继续采用标准化时序连续性裕度 DT >= 1。";
result.artifacts.execution_mode = string(local_execution_mode(meta));
if isfield(meta, 'preflight_mode') && logical(meta.preflight_mode)
    result.artifacts.preflight_note = "Preflight mode enabled: figures were intentionally skipped while truth tables and summary artifacts were preserved.";
end
result.artifacts.timing_note = local_timing_note(pool.summary.timing, pool.summary.joint_eval_timing);
result.artifacts.supplementary_enabled = write_supplementary;
result.artifacts.thesis_core_dir = string(export_paths.core.root);
result.artifacts.supplementary_dir = string(export_paths.supplementary.root);
result.artifacts.debug_dir = string(export_paths.debug.root);
if isfield(supplementary.summary, 'near_optimal_shell_check')
    result.artifacts.near_optimal_shell_conclusion = supplementary.summary.near_optimal_shell_check.conclusion;
end

task_family_minNs = local_task_metric_map(task_summary_table, 'Ns_min_feasible');
task_family_best_margin = local_task_metric_map(task_summary_table, 'best_joint_margin');
task_family_feasible_ratio = local_task_metric_map(task_summary_table, 'feasible_ratio');
minimum_support_sources = "";
if ~isempty(minimum_design_table) && ismember('support_sources', minimum_design_table.Properties.VariableNames)
    minimum_support_sources = strjoin(unique(string(minimum_design_table.support_sources), 'stable'), "; ");
end

result.summary = struct( ...
    'slice_axes', {{'h-i', 'P-T'}}, ...
    'execution_mode', local_execution_mode(meta), ...
    'fast_mode', isfield(meta, 'fast_mode') && logical(meta.fast_mode), ...
    'preflight_mode', isfield(meta, 'preflight_mode') && logical(meta.preflight_mode), ...
    'write_figures', write_figures, ...
    'preflight_note', local_preflight_note(meta), ...
    'num_unique_grid_points', height(pool.design_pool_table), ...
    'num_unique_feasible_points', height(pool.feasible_theta_table_joint), ...
    'num_grid_points', height(minimum_pack.full_theta_table), ...
    'num_feasible_points', height(minimum_pack.feasible_theta_table), ...
    'minimum_design_count', height(minimum_design_table), ...
    'minimum_design_Ns', local_first_value(minimum_design_table, 'Ns'), ...
    'minimum_design_active_constraint_mode', local_mode_text(minimum_design_table, 'dominant_constraint'), ...
    'minimum_design_support_sources', minimum_support_sources, ...
    'minimum_design', minimum_pack.minimum_design, ...
    'near_optimal_region_size', height(near_optimal_table), ...
    'task_family_feasible_ratio', task_family_feasible_ratio, ...
    'task_family_minNs', task_family_minNs, ...
    'task_family_best_margin', task_family_best_margin, ...
    'timing', pool.summary.timing, ...
    'timing_digest', local_timing_note(pool.summary.timing, pool.summary.joint_eval_timing), ...
    'joint_eval_timing', pool.summary.joint_eval_timing, ...
    'checkpoint', local_checkpoint_summary(pool.summary.joint_eval_timing), ...
    'supplementary_enabled', write_supplementary, ...
    'near_optimal_shell_check', supplementary.summary.near_optimal_shell_check, ...
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

function mode_txt = local_execution_mode(meta)
if isfield(meta, 'preflight_mode') && logical(meta.preflight_mode)
    mode_txt = "preflight";
else
    mode_txt = "full";
end
end

function txt = local_preflight_note(meta)
if isfield(meta, 'preflight_mode') && logical(meta.preflight_mode)
    txt = "Truth evaluation, family derivation, summary export, and timing diagnostics were executed without plotting.";
else
    txt = "";
end
end

function txt = local_timing_note(pool_timing, joint_timing)
parts = strings(0, 1);
if isstruct(pool_timing) && isfield(pool_timing, 'total_pipeline_s')
    parts(end + 1) = sprintf('Total MB pipeline time %.1fs.', pool_timing.total_pipeline_s);
end
if isstruct(joint_timing) && isfield(joint_timing, 'design_eval_total_s')
    parts(end + 1) = sprintf('Joint truth evaluation consumed %.1fs total with %.2fs per design on average.', ...
        joint_timing.design_eval_total_s, joint_timing.design_eval_mean_s);
end
if isstruct(joint_timing) && isfield(joint_timing, 'checkpoint_save_count') && joint_timing.checkpoint_save_count > 0
    parts(end + 1) = sprintf('Checkpointing saved %d snapshots and spent %.1fs on checkpoint writes.', ...
        joint_timing.checkpoint_save_count, joint_timing.checkpoint_save_total_s);
end
txt = strjoin(cellstr(parts), ' ');
end

function tf = local_write_supplementary(meta)
tf = isfield(meta, 'export_supplementary_figures') && logical(meta.export_supplementary_figures) && ...
    ~(isfield(meta, 'preflight_mode') && logical(meta.preflight_mode));
end

function export_paths = local_mb_export_paths(paths)
export_paths = struct();
export_paths.core = struct();
export_paths.supplementary = struct();
export_paths.debug = struct();

export_paths.core.root = fullfile(paths.milestone_root, 'core');
export_paths.core.figures = fullfile(export_paths.core.root, 'figures');
export_paths.core.tables = fullfile(export_paths.core.root, 'tables');
export_paths.supplementary.root = fullfile(paths.milestone_root, 'supplementary');
export_paths.supplementary.figures = fullfile(export_paths.supplementary.root, 'figures');
export_paths.supplementary.tables = fullfile(export_paths.supplementary.root, 'tables');
export_paths.debug.root = fullfile(paths.milestone_root, 'debug');
export_paths.debug.figures = fullfile(export_paths.debug.root, 'figures');
export_paths.debug.tables = fullfile(export_paths.debug.root, 'tables');

dirs = { ...
    export_paths.core.root, export_paths.core.figures, export_paths.core.tables, ...
    export_paths.supplementary.root, export_paths.supplementary.figures, export_paths.supplementary.tables, ...
    export_paths.debug.root, export_paths.debug.figures, export_paths.debug.tables};
for idx = 1:numel(dirs)
    ensure_dir(dirs{idx});
end
end

function supplementary = local_build_supplementary_exports(cfg, meta, paths, style, pool, minimum_pack, write_figures, write_supplementary)
supplementary = struct('tables', struct(), 'figures', struct(), 'summary', struct('near_optimal_shell_check', struct()));
if ~write_supplementary
    return;
end

shell_check = stage12H_mb_near_optimal_shell_check(cfg, pool, minimum_pack.minimum_design_table, minimum_pack.near_optimal_table, meta);
shell_summary_csv = fullfile(paths.tables, 'MB_near_optimal_shell_check_summary.csv');
shell_candidates_csv = fullfile(paths.tables, 'MB_near_optimal_shell_candidates.csv');
milestone_common_save_table(shell_check.summary_table, shell_summary_csv);
milestone_common_save_table(shell_check.candidate_table, shell_candidates_csv);
supplementary.tables.near_optimal_shell_check_summary = string(shell_summary_csv);
supplementary.tables.near_optimal_shell_candidates = string(shell_candidates_csv);
supplementary.figures.near_optimal_shell_phasecurve = string(shell_check.figure_path);
supplementary.summary.near_optimal_shell_check = shell_check.summary;

surface_hi = build_mb_requirement_surface(pool.full_theta_table_joint, 'i_deg', 'h_km');
surface_ip_joint = build_mb_requirement_surface(pool.full_theta_table_joint, 'P', 'i_deg');
surface_ip_nominal = build_mb_requirement_surface(pool.full_theta_table_nominal, 'P', 'i_deg');
surface_ip_heading = build_mb_requirement_surface(pool.full_theta_table_heading, 'P', 'i_deg');
surface_hi_csv = fullfile(paths.tables, 'MB_requirement_heatmap_hi.csv');
surface_ip_csv = fullfile(paths.tables, 'MB_requirement_heatmap_iP.csv');
milestone_common_save_table(surface_hi.surface_table, surface_hi_csv);
milestone_common_save_table(surface_ip_joint.surface_table, surface_ip_csv);
supplementary.tables.requirement_heatmap_hi = string(surface_hi_csv);
supplementary.tables.requirement_heatmap_iP = string(surface_ip_csv);

if write_figures
    fig_hi = plot_mb_requirement_heatmap_hi(surface_hi, minimum_pack.minimum_design_table, style);
    fig_hi_path = fullfile(paths.figures, 'MB_requirement_heatmap_hi.png');
    milestone_common_save_figure(fig_hi, fig_hi_path);
    close(fig_hi);
    supplementary.figures.requirement_heatmap_hi = string(fig_hi_path);

    fig_ip = plot_mb_requirement_heatmap_iP(surface_ip_joint, minimum_pack.minimum_design_table, style);
    fig_ip_path = fullfile(paths.figures, 'MB_requirement_heatmap_iP.png');
    milestone_common_save_figure(fig_ip, fig_ip_path);
    close(fig_ip);
    supplementary.figures.requirement_heatmap_iP = string(fig_ip_path);
end

[fig_joint_pass, joint_pass_table] = plot_mb_passratio_phasecurve_by_i(pool.full_theta_table_joint, 'joint', [], style);
[fig_heading_pass, heading_pass_table] = plot_mb_passratio_phasecurve_by_i(pool.full_theta_table_heading, 'heading', [], style);
joint_pass_csv = fullfile(paths.tables, 'MB_passratio_phasecurve_joint.csv');
heading_pass_csv = fullfile(paths.tables, 'MB_passratio_phasecurve_heading.csv');
milestone_common_save_table(joint_pass_table, joint_pass_csv);
milestone_common_save_table(heading_pass_table, heading_pass_csv);
supplementary.tables.passratio_phasecurve_joint = string(joint_pass_csv);
supplementary.tables.passratio_phasecurve_heading = string(heading_pass_csv);
if write_figures
    fig_joint_pass_path = fullfile(paths.figures, 'MB_passratio_phasecurve_joint.png');
    fig_heading_pass_path = fullfile(paths.figures, 'MB_passratio_phasecurve_heading.png');
    milestone_common_save_figure(fig_joint_pass, fig_joint_pass_path);
    milestone_common_save_figure(fig_heading_pass, fig_heading_pass_path);
    supplementary.figures.passratio_phasecurve_joint = string(fig_joint_pass_path);
    supplementary.figures.passratio_phasecurve_heading = string(fig_heading_pass_path);
end
close(fig_joint_pass);
close(fig_heading_pass);

family_phasecurve_table = build_family_phasecurve_table(struct( ...
    'nominal', pool.full_theta_table_nominal, ...
    'heading', pool.full_theta_table_heading, ...
    'critical', pool.full_theta_table_critical));
family_phasecurve_csv = fullfile(paths.tables, 'MB_family_phasecurve_table.csv');
milestone_common_save_table(family_phasecurve_table, family_phasecurve_csv);
supplementary.tables.family_phasecurve = string(family_phasecurve_csv);
if write_figures
    fig_margin = plot_mb_phasecurve_by_family(family_phasecurve_table, 'best_joint_margin_feasible', style);
    fig_margin_path = fullfile(paths.figures, 'MB_phasecurve_best_jointmargin_by_family.png');
    milestone_common_save_figure(fig_margin, fig_margin_path);
    close(fig_margin);
    supplementary.figures.phasecurve_best_jointmargin_by_family = string(fig_margin_path);

    fig_ratio = plot_mb_phasecurve_by_family(family_phasecurve_table, 'feasible_ratio', style);
    fig_ratio_path = fullfile(paths.figures, 'MB_phasecurve_feasibleratio_by_family.png');
    milestone_common_save_figure(fig_ratio, fig_ratio_path);
    close(fig_ratio);
    supplementary.figures.phasecurve_feasibleratio_by_family = string(fig_ratio_path);
end

frontier_table = build_frontier_table_vs_i(pool.full_theta_table_joint, 'joint');
frontier_csv = fullfile(paths.tables, 'MB_frontier_vs_i.csv');
milestone_common_save_table(frontier_table, frontier_csv);
supplementary.tables.frontier_vs_i = string(frontier_csv);
if write_figures
    fig_frontier = plot_mb_frontier_vs_i(frontier_table, style);
    fig_frontier_path = fullfile(paths.figures, 'MB_frontier_vs_i.png');
    milestone_common_save_figure(fig_frontier, fig_frontier_path);
    close(fig_frontier);
    supplementary.figures.frontier_vs_i = string(fig_frontier_path);
end

[fig_gap, gap_table] = plot_mb_family_gap_heatmap(surface_ip_heading, surface_ip_nominal, 'heading', 'nominal', style);
gap_csv = fullfile(paths.tables, 'MB_family_gap_heatmap_heading_minus_nominal.csv');
milestone_common_save_table(gap_table, gap_csv);
supplementary.tables.family_gap_heatmap_heading_minus_nominal = string(gap_csv);
if write_figures
    fig_gap_path = fullfile(paths.figures, 'MB_family_gap_heatmap_heading_minus_nominal.png');
    milestone_common_save_figure(fig_gap, fig_gap_path);
    supplementary.figures.family_gap_heatmap_heading_minus_nominal = string(fig_gap_path);
end
close(fig_gap);
end

function out = local_merge_struct_fields(out, add)
if isempty(add) || ~isstruct(add)
    return;
end
fields = fieldnames(add);
for k = 1:numel(fields)
    out.(fields{k}) = add.(fields{k});
end
end

function txt = local_make_conclusion(pool, minimum_pack, task_summary_table)
domain_text = sprintf('当前 MB 统一 design pool 含 %d 个 unique design，其中 %d 个属于 joint truth feasible domain。', ...
    height(pool.design_pool_table), height(minimum_pack.feasible_theta_table));
if isempty(minimum_pack.minimum_design_table)
    minimum_text = sprintf('当前统一 feasible domain 中未提取到 minimum design；near-optimal region 大小为 %d。', ...
        height(minimum_pack.near_optimal_table));
else
    minimum_text = sprintf('minimum design 对应 N_s=%g，unique minimum design 数为 %d，near-optimal region 大小为 %d，最常见 active constraint 为 %s。', ...
        minimum_pack.minimum_design_table.Ns(1), height(minimum_pack.minimum_design_table), ...
        height(minimum_pack.near_optimal_table), local_mode_text(minimum_pack.minimum_design_table, 'dominant_constraint'));
end
task_text = local_task_conclusion(task_summary_table);
txt = join([string(domain_text); string(minimum_text); string(task_text)], sprintf('\n\n'));
txt = txt(1);
end

function out = local_checkpoint_summary(joint_eval_timing)
out = struct();
if isempty(joint_eval_timing) || ~isstruct(joint_eval_timing)
    return;
end
fields = {'enable_checkpoint', 'resume_used', 'checkpoint_file', 'checkpoint_save_count', 'checkpoint_save_total_s'};
for k = 1:numel(fields)
    if isfield(joint_eval_timing, fields{k})
        out.(fields{k}) = joint_eval_timing.(fields{k});
    end
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
if local_task_differences_are_weak(task_summary_table)
    prefix = '共享 design pool 上三类任务族的差异较弱，但仍可从 minimum resource scale 与最佳裕度中读取细微差别。';
else
    prefix = '共享 design pool 上三类任务族的差异已在 feasible ratio 与 minimum resource scale 上显性出现。';
end
txt = prefix + " " + strjoin(parts, '; ');
end

function value = local_first_value(T, field_name)
value = NaN;
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    return;
end
value = T.(field_name)(1);
end

function txt = local_mode_text(T, field_name)
txt = "unknown";
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    return;
end
values = string(T.(field_name));
values = values(values ~= "");
if isempty(values)
    return;
end
[uvals, ~, ic] = unique(values);
counts = accumarray(ic, 1);
[~, idx] = max(counts);
txt = uvals(idx);
end

function tf = local_task_differences_are_weak(task_summary_table)
tf = true;
if isempty(task_summary_table)
    return;
end
ratio_span = max(task_summary_table.feasible_ratio) - min(task_summary_table.feasible_ratio);
min_ns_values = task_summary_table.Ns_min_feasible;
min_ns_values = min_ns_values(isfinite(min_ns_values));
if isempty(min_ns_values)
    min_ns_span = 0;
else
    min_ns_span = max(min_ns_values) - min(min_ns_values);
end
tf = ratio_span < 0.05 && min_ns_span <= 2;
end
