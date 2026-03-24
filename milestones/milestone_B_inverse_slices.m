function result = milestone_B_inverse_slices(cfg)
%MILESTONE_B_INVERSE_SLICES Dissertation-grade Chapter 4 Milestone B pipeline.
% LEGACY MB ENTRYPOINT (FROZEN).
% New MB feature work must move to milestones/active/MB_v2 and src/mb/v2.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end

meta = cfg.milestones.MB;
paths = mb_output_paths(cfg, meta.milestone_id, meta.title);
paths.summary_report = fullfile(paths.tables, 'MB_summary.md');
paths.summary_mat = fullfile(paths.tables, 'MB_inverse_slices_summary.mat');
style = milestone_common_plot_style();
write_figures = cfg.milestones.save_figures && ~(isfield(meta, 'preflight_mode') && logical(meta.preflight_mode));
write_layer_exports = local_write_layer_exports(meta);
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
    close(fig1);

    fig2 = plot_mb_minimum_design_map(minimum_pack.feasible_theta_table, minimum_design_table, near_optimal_table, style, pool.baseline_theta);
    fig2_path = fullfile(paths.figures, 'MB_inverse_slices_minimum_design_map.png');
    fig2_legacy_path = fullfile(paths.figures, 'MB_inverse_slices_minimum_boundary_map.png');
    milestone_common_save_figure(fig2, fig2_path);
    milestone_common_save_figure(fig2, fig2_legacy_path);
    close(fig2);

    fig3 = plot_mb_task_family_comparison(task_summary_table, style);
    fig3_path = fullfile(paths.figures, 'MB_inverse_slices_task_family_slice_comparison.png');
    milestone_common_save_figure(fig3, fig3_path);
    close(fig3);
end

layer_outputs = local_build_layer_exports(cfg, meta, paths, style, pool, minimum_pack, task_summary_table, write_figures, write_layer_exports);

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
result.tables = local_merge_struct_fields(result.tables, layer_outputs.tables);
result.figures = local_merge_struct_fields(result.figures, layer_outputs.figures);
result.artifacts.temporal_metric_note = "时序图表展示采用有界时序连续性裕度 DT_bar，闭合判定与主导失效识别继续采用标准化时序连续性裕度 DT >= 1。";
result.artifacts.execution_mode = string(local_execution_mode(meta));
if isfield(meta, 'preflight_mode') && logical(meta.preflight_mode)
    result.artifacts.preflight_note = "Preflight mode enabled: figures were intentionally skipped while truth tables and summary artifacts were preserved.";
end
result.artifacts.timing_note = local_timing_note(pool.summary.timing, pool.summary.joint_eval_timing);
result.artifacts.layer_exports_enabled = write_layer_exports;
result.artifacts.cache_dir = string(paths.cache);
result.artifacts.near_optimal_shell_conclusion = local_getfield_or(local_getfield_or(layer_outputs.summary.formal, 'near_optimal_shell_check', struct()), 'conclusion', "");
result.artifacts.fixed_h_exploration_note = local_getfield_or(layer_outputs.summary.fixed_h_exploration, 'interpretation_note', "");
result.artifacts.stage05_semantic_control_note = local_getfield_or(layer_outputs.summary.stage05_semantic_control, 'interpretation_note', "");
result.artifacts.local_dense_zoom_note = local_getfield_or(layer_outputs.summary.local_dense_zoom, 'note', "");

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
    'layer_exports_enabled', write_layer_exports, ...
    'near_optimal_shell_check', layer_outputs.summary.formal.near_optimal_shell_check, ...
    'formal_layer', local_build_formal_layer_summary(minimum_pack, task_summary_table, layer_outputs.summary.formal), ...
    'fixed_h_exploration', layer_outputs.summary.fixed_h_exploration, ...
    'stage05_semantic_control', layer_outputs.summary.stage05_semantic_control, ...
    'local_dense_zoom', layer_outputs.summary.local_dense_zoom, ...
    'slice_anchor_hi', local_struct_to_string(slice_hi.view_anchor), ...
    'slice_anchor_pt', local_struct_to_string(slice_pt.view_anchor), ...
    'slice_anchor_used_for_hi_view', local_struct_to_string(slice_hi.view_anchor), ...
    'slice_anchor_used_for_pt_view', local_struct_to_string(slice_pt.view_anchor), ...
    'dominant_constraint_distribution', minimum_pack.dominant_constraint_distribution, ...
    'key_counts', struct('num_tables', numel(fieldnames(result.tables)), 'num_figures', numel(fieldnames(result.figures))), ...
    'success_flags', struct('constellation_slice_packager', true, 'task_slice_packager', true, 'minimum_design_extractor', true), ...
    'main_conclusion', local_make_conclusion(pool, minimum_pack, task_summary_table));

files = milestone_common_export_summary(result, paths);
local_write_mb_layered_summary(paths.summary_report, result, layer_outputs);
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

function tf = local_write_layer_exports(meta)
tf = local_getfield_or(meta, 'export_extended_outputs', local_getfield_or(meta, 'export_supplementary_figures', true)) && ...
    ~(isfield(meta, 'preflight_mode') && logical(meta.preflight_mode));
end

function layer_outputs = local_build_layer_exports(cfg, meta, paths, style, pool, minimum_pack, task_summary_table, write_figures, write_layer_exports)
layer_outputs = struct( ...
    'tables', struct(), ...
    'figures', struct(), ...
    'summary', struct( ...
        'formal', struct('near_optimal_shell_check', struct()), ...
        'fixed_h_exploration', struct(), ...
        'stage05_semantic_control', struct(), ...
        'local_dense_zoom', struct()));
if ~write_layer_exports
    return;
end

layer_outputs = local_export_formal_layer(cfg, meta, paths, style, pool, minimum_pack, write_figures, layer_outputs);
layer_outputs = local_export_fixed_h_layer(cfg, meta, paths, style, pool, minimum_pack, write_figures, layer_outputs);
layer_outputs = local_export_stage05_semantic_control(cfg, meta, paths, write_figures, layer_outputs);
layer_outputs = local_export_local_zoom_layer(cfg, meta, paths, style, pool, minimum_pack, task_summary_table, write_figures, layer_outputs);
end

function layer_outputs = local_export_formal_layer(cfg, meta, paths, style, pool, minimum_pack, write_figures, layer_outputs)
meta_with_paths = meta;
meta_with_paths.output_paths = paths;
shell_check = stage12H_mb_near_optimal_shell_check(cfg, pool, minimum_pack.minimum_design_table, minimum_pack.near_optimal_table, meta_with_paths);
shell_summary_csv = fullfile(paths.tables, 'MB_near_optimal_shell_check_summary.csv');
shell_candidates_csv = fullfile(paths.tables, 'MB_near_optimal_shell_candidates.csv');
milestone_common_save_table(shell_check.summary_table, shell_summary_csv);
milestone_common_save_table(shell_check.candidate_table, shell_candidates_csv);
layer_outputs.tables.near_optimal_shell_check_summary = string(shell_summary_csv);
layer_outputs.tables.near_optimal_shell_candidates = string(shell_candidates_csv);
layer_outputs.figures.near_optimal_shell_phasecurve = string(shell_check.figure_path);
layer_outputs.summary.formal.near_optimal_shell_check = shell_check.summary;

surface_hi = build_mb_requirement_surface(pool.full_theta_table_joint, 'i_deg', 'h_km');
surface_ip_joint = build_mb_requirement_surface(pool.full_theta_table_joint, 'P', 'i_deg');
surface_ip_nominal = build_mb_requirement_surface(pool.full_theta_table_nominal, 'P', 'i_deg');
surface_ip_heading = build_mb_requirement_surface(pool.full_theta_table_heading, 'P', 'i_deg');
surface_hi_csv = fullfile(paths.tables, 'MB_requirement_heatmap_hi.csv');
surface_ip_csv = fullfile(paths.tables, 'MB_requirement_heatmap_iP.csv');
milestone_common_save_table(surface_hi.surface_table, surface_hi_csv);
milestone_common_save_table(surface_ip_joint.surface_table, surface_ip_csv);
layer_outputs.tables.requirement_heatmap_hi = string(surface_hi_csv);
layer_outputs.tables.requirement_heatmap_iP = string(surface_ip_csv);

if write_figures
    fig_hi = plot_mb_requirement_heatmap_hi(surface_hi, minimum_pack.minimum_design_table, style);
    fig_hi_path = fullfile(paths.figures, 'MB_requirement_heatmap_hi.png');
    milestone_common_save_figure(fig_hi, fig_hi_path);
    close(fig_hi);
    layer_outputs.figures.requirement_heatmap_hi = string(fig_hi_path);

    fig_ip = plot_mb_requirement_heatmap_iP(surface_ip_joint, minimum_pack.minimum_design_table, style);
    fig_ip_path = fullfile(paths.figures, 'MB_requirement_heatmap_iP.png');
    milestone_common_save_figure(fig_ip, fig_ip_path);
    close(fig_ip);
    layer_outputs.figures.requirement_heatmap_iP = string(fig_ip_path);
end

if write_figures
    fig_cloud_joint = plot_mb_resource_performance_cloud(pool.feasible_theta_table_joint, minimum_pack.minimum_design_table, shell_check.candidate_table, 'joint_margin', style);
    fig_cloud_joint_path = fullfile(paths.figures, 'MB_resource_performance_cloud_jointmargin.png');
    milestone_common_save_figure(fig_cloud_joint, fig_cloud_joint_path);
    close(fig_cloud_joint);
    layer_outputs.figures.resource_performance_cloud_jointmargin = string(fig_cloud_joint_path);

    fig_cloud_dt = plot_mb_resource_performance_cloud(pool.feasible_theta_table_joint, minimum_pack.minimum_design_table, shell_check.candidate_table, 'DT_worst', style);
    fig_cloud_dt_path = fullfile(paths.figures, 'MB_resource_performance_cloud_DT.png');
    milestone_common_save_figure(fig_cloud_dt, fig_cloud_dt_path);
    close(fig_cloud_dt);
    layer_outputs.figures.resource_performance_cloud_DT = string(fig_cloud_dt_path);
end

phasecurve_options = local_phasecurve_options(cfg, minimum_pack);
[fig_joint_pass, joint_pass_table] = plot_mb_passratio_phasecurve_by_i(pool.full_theta_table_joint, 'joint', [], style, phasecurve_options);
[fig_heading_pass, heading_pass_table] = plot_mb_passratio_phasecurve_by_i(pool.full_theta_table_heading, 'heading', [], style, phasecurve_options);
joint_pass_csv = fullfile(paths.tables, 'MB_passratio_phasecurve_joint.csv');
heading_pass_csv = fullfile(paths.tables, 'MB_passratio_phasecurve_heading.csv');
milestone_common_save_table(joint_pass_table, joint_pass_csv);
milestone_common_save_table(heading_pass_table, heading_pass_csv);
layer_outputs.tables.passratio_phasecurve_joint = string(joint_pass_csv);
layer_outputs.tables.passratio_phasecurve_heading = string(heading_pass_csv);
if write_figures
    fig_joint_pass_path = fullfile(paths.figures, 'MB_passratio_phasecurve_joint.png');
    fig_heading_pass_path = fullfile(paths.figures, 'MB_passratio_phasecurve_heading.png');
    milestone_common_save_figure(fig_joint_pass, fig_joint_pass_path);
    milestone_common_save_figure(fig_heading_pass, fig_heading_pass_path);
    layer_outputs.figures.passratio_phasecurve_joint = string(fig_joint_pass_path);
    layer_outputs.figures.passratio_phasecurve_heading = string(fig_heading_pass_path);
end
close(fig_joint_pass);
close(fig_heading_pass);

family_phasecurve_table = build_family_phasecurve_table(struct( ...
    'nominal', pool.full_theta_table_nominal, ...
    'heading', pool.full_theta_table_heading, ...
    'critical', pool.full_theta_table_critical));
family_phasecurve_csv = fullfile(paths.tables, 'MB_family_phasecurve_table.csv');
milestone_common_save_table(family_phasecurve_table, family_phasecurve_csv);
layer_outputs.tables.family_phasecurve = string(family_phasecurve_csv);
if write_figures
    fig_margin = plot_mb_phasecurve_by_family(family_phasecurve_table, 'best_joint_margin_feasible', style);
    fig_margin_path = fullfile(paths.figures, 'MB_phasecurve_best_jointmargin_by_family.png');
    milestone_common_save_figure(fig_margin, fig_margin_path);
    close(fig_margin);
    layer_outputs.figures.phasecurve_best_jointmargin_by_family = string(fig_margin_path);

    fig_ratio = plot_mb_phasecurve_by_family(family_phasecurve_table, 'feasible_ratio', style);
    fig_ratio_path = fullfile(paths.figures, 'MB_phasecurve_feasibleratio_by_family.png');
    milestone_common_save_figure(fig_ratio, fig_ratio_path);
    close(fig_ratio);
    layer_outputs.figures.phasecurve_feasibleratio_by_family = string(fig_ratio_path);
end

frontier_table = build_frontier_table_vs_i(pool.full_theta_table_joint, 'joint');
frontier_csv = fullfile(paths.tables, 'MB_frontier_vs_i.csv');
milestone_common_save_table(frontier_table, frontier_csv);
layer_outputs.tables.frontier_vs_i = string(frontier_csv);
if write_figures
    fig_frontier = plot_mb_frontier_vs_i(frontier_table, style);
    fig_frontier_path = fullfile(paths.figures, 'MB_frontier_vs_i.png');
    milestone_common_save_figure(fig_frontier, fig_frontier_path);
    close(fig_frontier);
    layer_outputs.figures.frontier_vs_i = string(fig_frontier_path);
end

[fig_gap, gap_table] = plot_mb_family_gap_heatmap(surface_ip_heading, surface_ip_nominal, 'heading', 'nominal', style);
gap_csv = fullfile(paths.tables, 'MB_family_gap_heatmap_heading_minus_nominal.csv');
milestone_common_save_table(gap_table, gap_csv);
layer_outputs.tables.family_gap_heatmap_heading_minus_nominal = string(gap_csv);
if write_figures
    fig_gap_path = fullfile(paths.figures, 'MB_family_gap_heatmap_heading_minus_nominal.png');
    milestone_common_save_figure(fig_gap, fig_gap_path);
    layer_outputs.figures.family_gap_heatmap_heading_minus_nominal = string(fig_gap_path);
end
close(fig_gap);
end

function layer_outputs = local_export_fixed_h_layer(cfg, meta, paths, style, pool, minimum_pack, write_figures, layer_outputs)
fixed_h = stage12J_mb_fixed_h_exploration(cfg, pool, meta);
layer_outputs.summary.fixed_h_exploration = fixed_h.summary;
if ~local_getfield_or(fixed_h.summary, 'enabled', false)
    return;
end

for idx = 1:numel(fixed_h.height_runs)
    run = fixed_h.height_runs(idx);
    h_label = sprintf('%d', round(run.h_km));

    req_csv = fullfile(paths.tables, sprintf('MB_fixedH_%s_requirement_heatmap_iP.csv', h_label));
    phase_csv = fullfile(paths.tables, sprintf('MB_fixedH_%s_passratio_phasecurve.csv', h_label));
    phase_replica_csv = fullfile(paths.tables, sprintf('MB_fixedH_%s_passratio_profile_stage05replica.csv', h_label));
    frontier_csv = fullfile(paths.tables, sprintf('MB_fixedH_%s_frontier_vs_i.csv', h_label));
    milestone_common_save_table(run.requirement_surface_iP.surface_table, req_csv);
    milestone_common_save_table(run.passratio_phasecurve, phase_csv);
    milestone_common_save_table(run.frontier_vs_i, frontier_csv);

    layer_outputs.tables.(matlab.lang.makeValidName(sprintf('fixedH_%s_requirement_heatmap_iP', h_label))) = string(req_csv);
    layer_outputs.tables.(matlab.lang.makeValidName(sprintf('fixedH_%s_passratio_phasecurve', h_label))) = string(phase_csv);
    layer_outputs.tables.(matlab.lang.makeValidName(sprintf('fixedH_%s_frontier_vs_i', h_label))) = string(frontier_csv);
    if local_getfield_or(meta, 'enable_stage05_passratio_replica', true)
        milestone_common_save_table(run.stage05_passratio_replica, phase_replica_csv);
        layer_outputs.tables.(matlab.lang.makeValidName(sprintf('fixedH_%s_passratio_profile_stage05replica', h_label))) = string(phase_replica_csv);
    end

    if write_figures
        fig_req = plot_mb_fixed_h_requirement_heatmap_iP(run.requirement_surface_iP, style);
        req_png = fullfile(paths.figures, sprintf('MB_fixedH_%s_requirement_heatmap_iP.png', h_label));
        milestone_common_save_figure(fig_req, req_png);
        close(fig_req);

        fig_phase = plot_mb_fixed_h_passratio_phasecurve(run.passratio_phasecurve, run.h_km, style, struct( ...
            'required_pass_ratio', local_get_required_pass_ratio(cfg)));
        phase_png = fullfile(paths.figures, sprintf('MB_fixedH_%s_passratio_phasecurve.png', h_label));
        milestone_common_save_figure(fig_phase, phase_png);
        close(fig_phase);

        if local_getfield_or(meta, 'enable_stage05_passratio_replica', true)
            fig_phase_replica = plot_mb_fixed_h_passratio_profile_stage05replica(run.eval.nominal.full_theta_table, run.h_km, unique(run.eval.nominal.full_theta_table.i_deg, 'sorted'));
            phase_replica_png = fullfile(paths.figures, sprintf('MB_fixedH_%s_passratio_profile_stage05replica.png', h_label));
            milestone_common_save_figure(fig_phase_replica, phase_replica_png);
            close(fig_phase_replica);
            layer_outputs.figures.(matlab.lang.makeValidName(sprintf('fixedH_%s_passratio_profile_stage05replica', h_label))) = string(phase_replica_png);
        end

        fig_frontier = plot_mb_fixed_h_frontier_vs_i(run.frontier_vs_i, run.h_km, style);
        frontier_png = fullfile(paths.figures, sprintf('MB_fixedH_%s_frontier_vs_i.png', h_label));
        milestone_common_save_figure(fig_frontier, frontier_png);
        close(fig_frontier);

        layer_outputs.figures.(matlab.lang.makeValidName(sprintf('fixedH_%s_requirement_heatmap_iP', h_label))) = string(req_png);
        layer_outputs.figures.(matlab.lang.makeValidName(sprintf('fixedH_%s_passratio_phasecurve', h_label))) = string(phase_png);
        layer_outputs.figures.(matlab.lang.makeValidName(sprintf('fixedH_%s_frontier_vs_i', h_label))) = string(frontier_png);
    end
end

fixed_summary_md = fullfile(paths.tables, 'MB_fixed_h_exploration_summary.md');
local_write_fixed_h_exploration_summary(fixed_summary_md, fixed_h);
layer_outputs.tables.fixed_h_exploration_summary = string(fixed_summary_md);

if ~isempty(minimum_pack.minimum_design_table)
    layer_outputs.summary.fixed_h_exploration.formal_reference_minimum_shell_Ns = minimum_pack.minimum_design_table.Ns(1);
end
end

function layer_outputs = local_export_local_zoom_layer(cfg, meta, paths, style, pool, minimum_pack, task_summary_table, write_figures, layer_outputs)
zoom = stage12I_mb_dense_refinement(cfg, pool, minimum_pack.minimum_design_table, task_summary_table, meta);
layer_outputs.summary.local_dense_zoom = zoom.summary;
if ~local_getfield_or(zoom.summary, 'enabled', false)
    return;
end

zoom_req_ip_csv = fullfile(paths.tables, 'MB_zoom_requirement_heatmap_iP.csv');
zoom_gap_csv = fullfile(paths.tables, 'MB_zoom_gap_heatmap_heading_minus_nominal.csv');
zoom_pass_joint_csv = fullfile(paths.tables, 'MB_zoom_passratio_phasecurve_joint.csv');
zoom_pass_heading_csv = fullfile(paths.tables, 'MB_zoom_passratio_phasecurve_heading.csv');
milestone_common_save_table(zoom.requirement_surface_iP.surface_table, zoom_req_ip_csv);
milestone_common_save_table(zoom.gap_surface_heading_minus_nominal.gap_table, zoom_gap_csv);
milestone_common_save_table(zoom.phasecurve_joint, zoom_pass_joint_csv);
milestone_common_save_table(zoom.phasecurve_heading, zoom_pass_heading_csv);
layer_outputs.tables.zoom_requirement_heatmap_iP = string(zoom_req_ip_csv);
layer_outputs.tables.zoom_gap_heatmap_heading_minus_nominal = string(zoom_gap_csv);
layer_outputs.tables.zoom_passratio_phasecurve_joint = string(zoom_pass_joint_csv);
layer_outputs.tables.zoom_passratio_phasecurve_heading = string(zoom_pass_heading_csv);

if isfield(zoom, 'requirement_surface_hi') && isstruct(zoom.requirement_surface_hi) && ...
        isfield(zoom.requirement_surface_hi, 'surface_table') && ~isempty(zoom.requirement_surface_hi.surface_table)
    zoom_req_hi_csv = fullfile(paths.tables, 'MB_zoom_requirement_heatmap_hi.csv');
    milestone_common_save_table(zoom.requirement_surface_hi.surface_table, zoom_req_hi_csv);
    layer_outputs.tables.zoom_requirement_heatmap_hi = string(zoom_req_hi_csv);
end

zoom_summary_md = fullfile(paths.tables, 'MB_local_dense_zoom_summary.md');
local_write_dense_refinement_summary(zoom_summary_md, zoom.summary);
layer_outputs.tables.local_dense_zoom_summary = string(zoom_summary_md);

if write_figures
    fig_zoom_ip = plot_mb_dense_requirement_heatmap_iP(zoom.requirement_surface_iP, minimum_pack.minimum_design_table, style);
    fig_zoom_ip_path = fullfile(paths.figures, 'MB_zoom_requirement_heatmap_iP.png');
    milestone_common_save_figure(fig_zoom_ip, fig_zoom_ip_path);
    close(fig_zoom_ip);
    layer_outputs.figures.zoom_requirement_heatmap_iP = string(fig_zoom_ip_path);

    [fig_zoom_gap, ~] = plot_mb_dense_gap_heatmap_heading_minus_nominal(zoom.gap_surface_heading_minus_nominal, style);
    fig_zoom_gap_path = fullfile(paths.figures, 'MB_zoom_gap_heatmap_heading_minus_nominal.png');
    milestone_common_save_figure(fig_zoom_gap, fig_zoom_gap_path);
    close(fig_zoom_gap);
    layer_outputs.figures.zoom_gap_heatmap_heading_minus_nominal = string(fig_zoom_gap_path);

    dense_phasecurve_options = local_phasecurve_options(cfg, minimum_pack);
    fig_zoom_joint = plot_mb_dense_passratio_phasecurve(zoom.phasecurve_joint, 'joint', style, dense_phasecurve_options);
    fig_zoom_joint_path = fullfile(paths.figures, 'MB_zoom_passratio_phasecurve_joint.png');
    milestone_common_save_figure(fig_zoom_joint, fig_zoom_joint_path);
    close(fig_zoom_joint);
    layer_outputs.figures.zoom_passratio_phasecurve_joint = string(fig_zoom_joint_path);

    fig_zoom_heading = plot_mb_dense_passratio_phasecurve(zoom.phasecurve_heading, 'heading', style, dense_phasecurve_options);
    fig_zoom_heading_path = fullfile(paths.figures, 'MB_zoom_passratio_phasecurve_heading.png');
    milestone_common_save_figure(fig_zoom_heading, fig_zoom_heading_path);
    close(fig_zoom_heading);
    layer_outputs.figures.zoom_passratio_phasecurve_heading = string(fig_zoom_heading_path);

    if isfield(zoom, 'requirement_surface_hi') && isstruct(zoom.requirement_surface_hi) && ...
            isfield(zoom.requirement_surface_hi, 'surface_table') && ~isempty(zoom.requirement_surface_hi.surface_table)
        fig_zoom_hi = plot_mb_dense_requirement_heatmap_hi(zoom.requirement_surface_hi, minimum_pack.minimum_design_table, style);
        fig_zoom_hi_path = fullfile(paths.figures, 'MB_zoom_requirement_heatmap_hi.png');
        milestone_common_save_figure(fig_zoom_hi, fig_zoom_hi_path);
        close(fig_zoom_hi);
        layer_outputs.figures.zoom_requirement_heatmap_hi = string(fig_zoom_hi_path);
    end
end
end

function layer_outputs = local_export_stage05_semantic_control(cfg, meta, paths, write_figures, layer_outputs)
control = stage12K_mb_stage05_semantic_reproduction(cfg, meta);
layer_outputs.summary.stage05_semantic_control = control.summary;
if ~local_getfield_or(control.summary, 'enabled', false)
    return;
end

for idx = 1:numel(control.height_runs)
    run = control.height_runs(idx);
    h_label = sprintf('%d', round(run.h_km));

    eval_csv = fullfile(paths.tables, sprintf('MB_stage05sem_%s_design_eval.csv', h_label));
    envelope_csv = fullfile(paths.tables, sprintf('MB_stage05sem_%s_envelope.csv', h_label));
    frontier_csv = fullfile(paths.tables, sprintf('MB_stage05sem_%s_frontier_summary.csv', h_label));
    milestone_common_save_table(run.eval_table, eval_csv);
    milestone_common_save_table(run.envelope_table, envelope_csv);
    milestone_common_save_table(run.frontier_summary, frontier_csv);

    layer_outputs.tables.(matlab.lang.makeValidName(sprintf('stage05sem_%s_design_eval', h_label))) = string(eval_csv);
    layer_outputs.tables.(matlab.lang.makeValidName(sprintf('stage05sem_%s_envelope', h_label))) = string(envelope_csv);
    layer_outputs.tables.(matlab.lang.makeValidName(sprintf('stage05sem_%s_frontier_summary', h_label))) = string(frontier_csv);

    if write_figures
        fig_pass = plot_mb_stage05_semantic_passratio_envelope(run.envelope_table, run.h_km);
        pass_png = fullfile(paths.figures, sprintf('MB_stage05sem_%s_passratio_envelope.png', h_label));
        milestone_common_save_figure(fig_pass, pass_png);
        close(fig_pass);

        fig_dg = plot_mb_stage05_semantic_DG_envelope(run.envelope_table, run.h_km);
        dg_png = fullfile(paths.figures, sprintf('MB_stage05sem_%s_DG_envelope.png', h_label));
        milestone_common_save_figure(fig_dg, dg_png);
        close(fig_dg);

        fig_frontier = plot_mb_stage05_semantic_frontier_summary(run.frontier_summary, run.h_km);
        frontier_png = fullfile(paths.figures, sprintf('MB_stage05sem_%s_frontier_summary.png', h_label));
        milestone_common_save_figure(fig_frontier, frontier_png);
        close(fig_frontier);

        layer_outputs.figures.(matlab.lang.makeValidName(sprintf('stage05sem_%s_passratio_envelope', h_label))) = string(pass_png);
        layer_outputs.figures.(matlab.lang.makeValidName(sprintf('stage05sem_%s_DG_envelope', h_label))) = string(dg_png);
        layer_outputs.figures.(matlab.lang.makeValidName(sprintf('stage05sem_%s_frontier_summary', h_label))) = string(frontier_png);
    end
end

summary_md = fullfile(paths.tables, 'MB_stage05_semantic_reproduction_summary.md');
local_write_stage05_semantic_summary(summary_md, control);
layer_outputs.tables.stage05_semantic_reproduction_summary = string(summary_md);
end

function options = local_phasecurve_options(cfg, minimum_pack)
options = struct();
options.minimum_shell_Ns = NaN;
options.required_pass_ratio = NaN;
if ~isempty(minimum_pack.minimum_design_table) && ismember('Ns', minimum_pack.minimum_design_table.Properties.VariableNames)
    options.minimum_shell_Ns = minimum_pack.minimum_design_table.Ns(1);
end
if isfield(cfg, 'stage09') && isfield(cfg.stage09, 'require_pass_ratio')
    options.required_pass_ratio = cfg.stage09.require_pass_ratio;
end
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

function out = local_family_gap_map(task_summary_table, formal_minimum_Ns)
out = struct();
if isempty(task_summary_table) || ~isfinite(formal_minimum_Ns) || ~ismember('Ns_min_feasible', task_summary_table.Properties.VariableNames)
    return;
end
for k = 1:height(task_summary_table)
    key = matlab.lang.makeValidName(char(string(task_summary_table.family_name(k))));
    out.(key) = task_summary_table.Ns_min_feasible(k) - formal_minimum_Ns;
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

function value = local_get_required_pass_ratio(cfg)
value = NaN;
if isfield(cfg, 'stage09') && isfield(cfg.stage09, 'require_pass_ratio')
    value = cfg.stage09.require_pass_ratio;
end
end

function formal = local_build_formal_layer_summary(minimum_pack, task_summary_table, formal_layer)
formal = struct();
formal.minimum_shell_Ns = local_first_value(minimum_pack.minimum_design_table, 'Ns');
formal.minimum_shell_count = height(minimum_pack.minimum_design_table);
formal.near_optimal_region_size = height(minimum_pack.near_optimal_table);
formal.family_feasible_ratio = local_task_metric_map(task_summary_table, 'feasible_ratio');
formal.family_minimum = local_task_metric_map(task_summary_table, 'Ns_min_feasible');
formal.family_gap = local_family_gap_map(task_summary_table, formal.minimum_shell_Ns);
formal.near_optimal_shell_check = local_getfield_or(formal_layer, 'near_optimal_shell_check', struct());
end

function local_write_fixed_h_exploration_summary(file_path, fixed_h)
fid = fopen(file_path, 'w');
if fid < 0
    error('Failed to open fixed-h exploration summary for writing: %s', file_path);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# MB Fixed-h Exploratory Summary\n\n');
fprintf(fid, '%s\n\n', local_stringify_summary_value(local_getfield_or(fixed_h.summary, 'interpretation_note', "")));
fprintf(fid, '- `enabled`: %s\n', local_stringify_summary_value(local_getfield_or(fixed_h.summary, 'enabled', false)));
fprintf(fid, '- `family_name`: %s\n', local_stringify_summary_value(local_getfield_or(fixed_h.summary, 'family_name', "")));
fprintf(fid, '- `h_fixed_list`: %s\n', local_stringify_summary_value(local_getfield_or(fixed_h.summary, 'h_fixed_list', [])));
fprintf(fid, '- `i_grid_deg`: %s\n', local_stringify_summary_value(local_getfield_or(fixed_h.summary, 'i_grid_deg', [])));
fprintf(fid, '- `P_grid`: %s\n', local_stringify_summary_value(local_getfield_or(fixed_h.summary, 'P_grid', [])));
fprintf(fid, '- `T_grid`: %s\n', local_stringify_summary_value(local_getfield_or(fixed_h.summary, 'T_grid', [])));
fprintf(fid, '- `F_fixed`: %s\n', local_stringify_summary_value(local_getfield_or(fixed_h.summary, 'F_fixed', NaN)));
fprintf(fid, '- `stage05_passratio_replica_enabled`: %s\n', local_stringify_summary_value(local_getfield_or(fixed_h.cfg, 'enable_stage05_passratio_replica', true)));
fprintf(fid, '\n## Height Runs\n\n');
for idx = 1:numel(fixed_h.height_runs)
    run = fixed_h.height_runs(idx);
    fprintf(fid, '### h = %.0f km\n\n', run.h_km);
    fprintf(fid, '- `design_count`: %s\n', local_stringify_summary_value(local_getfield_or(run.summary, 'design_count', 0)));
    fprintf(fid, '- `feasible_count`: %s\n', local_stringify_summary_value(local_getfield_or(run.summary, 'feasible_count', 0)));
    fprintf(fid, '- `minimum_feasible_Ns`: %s\n', local_stringify_summary_value(local_getfield_or(run.summary, 'minimum_feasible_Ns', NaN)));
    fprintf(fid, '- `eval_s`: %s\n\n', local_stringify_summary_value(local_getfield_or(run.summary, 'eval_s', NaN)));
end
end

function local_write_stage05_semantic_summary(file_path, control)
fid = fopen(file_path, 'w');
if fid < 0
    error('Failed to open Stage05 semantic control summary for writing: %s', file_path);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# MB Stage05 Semantic Reproduction Summary\n\n');
fprintf(fid, '%s\n\n', local_stringify_summary_value(local_getfield_or(control.summary, 'interpretation_note', "")));
fprintf(fid, '- `enabled`: %s\n', local_stringify_summary_value(local_getfield_or(control.summary, 'enabled', false)));
fprintf(fid, '- `family_name`: %s\n', local_stringify_summary_value(local_getfield_or(control.summary, 'family_name', "")));
fprintf(fid, '- `h_fixed_list`: %s\n', local_stringify_summary_value(local_getfield_or(control.summary, 'h_fixed_list', [])));
fprintf(fid, '- `i_grid_deg`: %s\n', local_stringify_summary_value(local_getfield_or(control.summary, 'i_grid_deg', [])));
fprintf(fid, '- `P_grid`: %s\n', local_stringify_summary_value(local_getfield_or(control.summary, 'P_grid', [])));
fprintf(fid, '- `T_grid`: %s\n', local_stringify_summary_value(local_getfield_or(control.summary, 'T_grid', [])));
fprintf(fid, '- `F_fixed`: %s\n', local_stringify_summary_value(local_getfield_or(control.summary, 'F_fixed', NaN)));
fprintf(fid, '- `gamma_req`: %s\n', local_stringify_summary_value(local_getfield_or(control.summary, 'gamma_req', NaN)));
fprintf(fid, '- `source_stage02_file`: %s\n', local_stringify_summary_value(local_getfield_or(control.summary, 'source_stage02_file', "")));
fprintf(fid, '- `source_stage04_file`: %s\n', local_stringify_summary_value(local_getfield_or(control.summary, 'source_stage04_file', "")));
fprintf(fid, '\n## Height Runs\n\n');
for idx = 1:numel(control.height_runs)
    run = control.height_runs(idx);
    fprintf(fid, '### h = %.0f km\n\n', run.h_km);
    fprintf(fid, '- `design_count`: %s\n', local_stringify_summary_value(local_getfield_or(run.summary, 'design_count', 0)));
    fprintf(fid, '- `feasible_count`: %s\n', local_stringify_summary_value(local_getfield_or(run.summary, 'feasible_count', 0)));
    fprintf(fid, '- `minimum_feasible_Ns`: %s\n', local_stringify_summary_value(local_getfield_or(run.summary, 'minimum_feasible_Ns', missing)));
    fprintf(fid, '- `eval_s`: %s\n\n', local_stringify_summary_value(local_getfield_or(run.summary, 'eval_s', NaN)));
end
end

function local_write_mb_layered_summary(file_path, result, layer_outputs)
fid = fopen(file_path, 'w');
if fid < 0
    error('Failed to open MB summary for writing: %s', file_path);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# MB Summary\n\n');
fprintf(fid, '## Formal MB\n\n');
fprintf(fid, '- Formal MB remains the only layer that defines the thesis-facing full MB minimum shell, family ratios, family gaps, and near-optimal shell conclusions.\n');
fprintf(fid, '- `formal_minimum_shell_Ns`: %s\n', local_stringify_summary_value(local_getfield_or(result.summary.formal_layer, 'minimum_shell_Ns', NaN)));
fprintf(fid, '- `formal_family_feasible_ratio`: %s\n', local_stringify_summary_value(local_getfield_or(result.summary.formal_layer, 'family_feasible_ratio', struct())));
fprintf(fid, '- `formal_family_minimum`: %s\n', local_stringify_summary_value(local_getfield_or(result.summary.formal_layer, 'family_minimum', struct())));
fprintf(fid, '- `formal_family_gap`: %s\n', local_stringify_summary_value(local_getfield_or(result.summary.formal_layer, 'family_gap', struct())));
fprintf(fid, '- `near_optimal_shell_check`: %s\n\n', local_stringify_summary_value(local_getfield_or(layer_outputs.summary.formal, 'near_optimal_shell_check', struct())));

fprintf(fid, '## Fixed-h Exploratory MB\n\n');
fprintf(fid, '%s\n\n', local_stringify_summary_value(local_getfield_or(layer_outputs.summary.fixed_h_exploration, 'interpretation_note', "")));
fprintf(fid, '- This layer reuses Stage05-style coarse scans at fixed height to explain threshold and phase-transition behavior from an engineering-design perspective.\n');
fprintf(fid, '- `h_fixed_list`: %s\n', local_stringify_summary_value(local_getfield_or(layer_outputs.summary.fixed_h_exploration, 'h_fixed_list', [])));
fprintf(fid, '- `family_name`: %s\n\n', local_stringify_summary_value(local_getfield_or(layer_outputs.summary.fixed_h_exploration, 'family_name', "")));

fprintf(fid, '### Stage05-Semantic Control\n\n');
fprintf(fid, '%s\n\n', local_stringify_summary_value(local_getfield_or(layer_outputs.summary.stage05_semantic_control, 'interpretation_note', "")));
fprintf(fid, '- `stage05_semantic_h_fixed_list`: %s\n', local_stringify_summary_value(local_getfield_or(layer_outputs.summary.stage05_semantic_control, 'h_fixed_list', [])));
fprintf(fid, '- `stage05_semantic_gamma_req`: %s\n', local_stringify_summary_value(local_getfield_or(layer_outputs.summary.stage05_semantic_control, 'gamma_req', NaN)));
fprintf(fid, '- `stage05_semantic_source_stage04`: %s\n\n', local_stringify_summary_value(local_getfield_or(layer_outputs.summary.stage05_semantic_control, 'source_stage04_file', "")));

fprintf(fid, '## Local Dense Zoom\n\n');
fprintf(fid, '- Local Dense Zoom is a shell-neighborhood observation layer. It can reveal finer-grained feasible candidates inside the zoomed local domain, but it does not replace the formal full-MB minimum-shell definition.\n');
fprintf(fid, '- `formal_minimum_shell_Ns`: %s\n', local_stringify_summary_value(local_getfield_or(layer_outputs.summary.local_dense_zoom, 'formal_minimum_shell_Ns', NaN)));
fprintf(fid, '- `zoom_candidate_minimum_Ns_joint`: %s\n', local_stringify_summary_value(local_getfield_or(layer_outputs.summary.local_dense_zoom, 'zoom_candidate_minimum_Ns_joint', NaN)));
fprintf(fid, '- `zoom_requirement_h_km`: %s\n', local_stringify_summary_value(local_getfield_or(layer_outputs.summary.local_dense_zoom, 'zoom_requirement_h_km', [])));
fprintf(fid, '- `zoom_requirement_i_deg`: %s\n', local_stringify_summary_value(local_getfield_or(layer_outputs.summary.local_dense_zoom, 'zoom_requirement_i_deg', [])));
fprintf(fid, '\n%s\n', local_stringify_summary_value(local_getfield_or(layer_outputs.summary.local_dense_zoom, 'note', "")));
end

function local_write_dense_refinement_summary(file_path, summary)
fid = fopen(file_path, 'w');
if fid < 0
    error('Failed to open dense refinement summary for writing: %s', file_path);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# MB Local Dense Zoom Summary\n\n');
fprintf(fid, 'These figures come from a local shell-neighborhood zoom rather than a new formal global MB scan.\n\n');
fprintf(fid, '- `enabled`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'enabled', false)));
fprintf(fid, '- `formal_minimum_shell_Ns`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'formal_minimum_shell_Ns', NaN)));
fprintf(fid, '- `zoom_candidate_minimum_Ns_joint`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'zoom_candidate_minimum_Ns_joint', NaN)));
fprintf(fid, '- `baseline_F`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'baseline_F', NaN)));
fprintf(fid, '- `requirement_design_count`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'requirement_design_count', 0)));
fprintf(fid, '- `phasecurve_design_count`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'phasecurve_design_count', 0)));
fprintf(fid, '- `requirement_eval_s`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'requirement_eval_s', NaN)));
fprintf(fid, '- `phasecurve_eval_s`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'phasecurve_eval_s', NaN)));
fprintf(fid, '- `zoom_requirement_i_deg`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'zoom_requirement_i_deg', [])));
fprintf(fid, '- `zoom_requirement_P`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'zoom_requirement_P', [])));
fprintf(fid, '- `zoom_requirement_h_km`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'zoom_requirement_h_km', [])));
fprintf(fid, '- `zoom_requirement_T`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'zoom_requirement_T', [])));
fprintf(fid, '- `zoom_phasecurve_i_deg`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'zoom_phasecurve_i_deg', [])));
fprintf(fid, '- `zoom_phasecurve_P`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'zoom_phasecurve_P', [])));
fprintf(fid, '- `zoom_phasecurve_T`: %s\n', local_stringify_summary_value(local_getfield_or(summary, 'zoom_phasecurve_T', [])));
fprintf(fid, '\n%s\n', local_stringify_summary_value(local_getfield_or(summary, 'note', "")));
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function txt = local_stringify_summary_value(value)
if ismissing(value)
    if isscalar(value)
        txt = "<missing>";
    else
        txt = mat2str(string(value));
    end
    return;
end

if isstring(value) || ischar(value)
    txt = char(string(value));
elseif isnumeric(value) || islogical(value)
    if isscalar(value)
        txt = char(string(value));
    else
        txt = mat2str(value);
    end
elseif isstruct(value)
    txt = sprintf('struct(%d fields)', numel(fieldnames(value)));
elseif istable(value)
    txt = sprintf('table[%d x %d]', height(value), width(value));
else
    txt = char(string(value));
end
end
