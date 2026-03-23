function out = run_mb_plot_mode_switch_smoke(tag)
%RUN_MB_PLOT_MODE_SWITCH_SMOKE Validate unified MB plot-mode switching on baseline h=1000.

mb_safe_startup();

if nargin < 1 || strlength(string(tag)) == 0
    tag = "20260323";
end
tag = string(tag);

cfg0 = milestone_common_defaults();
summary_paths = mb_output_paths(cfg0, "MB_plotmode_smoke_validation_" + tag, 'plot_mode_switch_smoke');
modes = ["effectiveFullRange", "historyFull", "frontierZoom"];
rows = cell(numel(modes), 15);

for idx = 1:numel(modes)
    primary_mode = modes(idx);
    smoke_id = "MB_plotmode_smoke_" + lower(primary_mode) + "_" + tag;
    cfg = local_build_smoke_cfg(smoke_id, primary_mode);
    milestone_B_semantic_compare(cfg);

    legacy_meta = local_read_sidecar(fullfile(cfg.paths.outputs, 'milestones', char(smoke_id), 'figures', 'MB_legacyDG_passratio_primary_h1000_baseline.png'));
    closed_meta = local_read_sidecar(fullfile(cfg.paths.outputs, 'milestones', char(smoke_id), 'figures', 'MB_closedD_passratio_primary_h1000_baseline.png'));
    comparison_meta = local_read_sidecar(fullfile(cfg.paths.outputs, 'milestones', char(smoke_id), 'figures', 'MB_comparison_passratio_overlay_primary_h1000_baseline.png'));
    cross_meta = local_read_sidecar(fullfile(cfg.paths.outputs, 'milestones', char(smoke_id), 'figures', 'MB_profileCompare_legacyDG_passratio_primary_h1000.png'));
    heatmap_meta = local_read_sidecar(fullfile(cfg.paths.outputs, 'milestones', char(smoke_id), 'figures', 'MB_legacyDG_minimumNs_heatmap_iP_h1000_baseline.png'));

    rows(idx, :) = { ...
        string(smoke_id), ...
        primary_mode, ...
        string(local_getfield_or(legacy_meta, 'current_plot_mode', "")), ...
        string(local_getfield_or(closed_meta, 'current_plot_mode', "")), ...
        string(local_getfield_or(comparison_meta, 'current_plot_mode', "")), ...
        string(local_getfield_or(cross_meta, 'current_plot_mode', "")), ...
        string(local_getfield_or(heatmap_meta, 'heatmap_primary_value_mode', "")), ...
        string(local_getfield_or(heatmap_meta, 'heatmap_primary_domain_mode', "")), ...
        logical(strcmp(char(string(local_getfield_or(legacy_meta, 'current_plot_mode', ""))), char(primary_mode))), ...
        logical(strcmp(char(string(local_getfield_or(closed_meta, 'current_plot_mode', ""))), char(primary_mode))), ...
        logical(strcmp(char(string(local_getfield_or(comparison_meta, 'current_plot_mode', ""))), char(primary_mode))), ...
        logical(strcmp(char(string(local_getfield_or(cross_meta, 'current_plot_mode', ""))), char(primary_mode))), ...
        logical(strcmp(char(string(local_getfield_or(heatmap_meta, 'heatmap_primary_value_mode', ""))), 'numeric_requirement')), ...
        logical(strcmp(char(string(local_getfield_or(heatmap_meta, 'heatmap_primary_domain_mode', ""))), 'globalSkeleton')), ...
        string(fullfile(cfg.paths.outputs, 'milestones', char(smoke_id)))};
end

summary_table = cell2table(rows, 'VariableNames', { ...
    'smoke_id', 'requested_primary_mode', ...
    'legacy_primary_mode_meta', 'closed_primary_mode_meta', 'comparison_primary_mode_meta', 'cross_profile_primary_mode_meta', ...
    'heatmap_primary_value_mode_meta', 'heatmap_primary_domain_mode_meta', ...
    'legacy_match', 'closed_match', 'comparison_match', 'cross_profile_match', ...
    'heatmap_value_match', 'heatmap_domain_match', 'smoke_root'});
summary_csv = fullfile(summary_paths.tables, 'MB_plot_mode_switch_smoke_summary.csv');
milestone_common_save_table(summary_table, summary_csv);

strict_root = "";
strict_csv = "";
strict_pass = false;
strict_max_curve = NaN;
strict_max_abs = NaN;
try
    strict_id = "MB_plotmode_smoke_strict_" + tag;
    strict_cfg = milestone_common_defaults();
    [strict_cfg, ~, ~] = mb_cli_configure_search_profile(strict_cfg, false, struct( ...
        'run_mode', 'strict_stage05_validation_only', ...
        'profile_name', 'strict_stage05_replica', ...
        'profile_mode', 'strict_replica'));
    strict_cfg.milestones.MB_semantic_compare.milestone_id = char(strict_id);
    strict_cfg.milestones.MB_semantic_compare.title = 'semantic_compare';
    strict_cfg.milestones.MB_semantic_compare.heights_to_run = 1000;
    strict_cfg.milestones.MB_semantic_compare.family_set = {'nominal'};
    strict_cfg.runtime.figure_visibility_mode = 'headless';
    strict_cfg.runtime.force_fresh = false;
    strict_cfg.runtime.regenerate_all_cache = false;
    strict_cfg.runtime.regenerate_all_export = true;
    strict_cfg.cache.force_fresh = false;
    strict_cfg.cache.reuse_semantic = true;
    strict_cfg.cache.reuse_plot = false;
    strict_cfg.cache.rebuild_all = false;
    strict_cfg.milestones.MB_semantic_compare.force_fresh = false;
    strict_cfg.milestones.MB_semantic_compare.regenerate_all_cache = false;
    strict_cfg.milestones.MB_semantic_compare.regenerate_all_export = true;
    strict_cfg.milestones.MB_semantic_compare.cache_profile.force_fresh = false;
    strict_cfg.milestones.MB_semantic_compare.cache_profile.reuse_semantic = true;
    strict_cfg.milestones.MB_semantic_compare.cache_profile.reuse_plot = false;
    strict_cfg.milestones.MB_semantic_compare.cache_profile.reuse_plotting = false;
    strict_cfg.milestones.MB_semantic_compare.cache_profile.rebuild_all = false;
    run_milestone_B_semantic_compare(strict_cfg, false);
    strict_root = fullfile(strict_cfg.paths.outputs, 'milestones', char(strict_id));
    strict_csv = fullfile(strict_root, 'tables', 'MB_stage05_strictReplica_validation_summary.csv');
    strict_table = readtable(strict_csv, 'TextType', 'string');
    strict_max_curve = max(strict_table.max_abs_diff_over_curve);
    strict_max_abs = max(strict_table.max_abs_diff);
    strict_pass = strict_max_curve == 0 && strict_max_abs == 0;
catch err
    warning('MB:PlotModeSmokeStrictReplica', '%s', err.message);
end

[status, diff_text] = system('git diff -- stages/stage05_* stages/stage06_*');
core_diff_empty = (status == 0) && strlength(strtrim(string(diff_text))) == 0;
closure_table = table( ...
    logical(all(summary_table.legacy_match) && all(summary_table.closed_match) && all(summary_table.comparison_match) && all(summary_table.cross_profile_match)), ...
    logical(all(summary_table.heatmap_value_match)), ...
    logical(all(summary_table.heatmap_domain_match)), ...
    logical(strict_pass), ...
    double(strict_max_curve), ...
    double(strict_max_abs), ...
    logical(core_diff_empty), ...
    string(strict_root), ...
    string(strict_csv), ...
    'VariableNames', {'passratio_switch_pass', 'heatmap_value_pass', 'heatmap_domain_pass', 'strict_replica_pass', 'strict_max_abs_diff_over_curve', 'strict_max_abs_diff', 'stage05_06_core_untouched', 'strict_root', 'strict_summary_csv'});
closure_csv = fullfile(summary_paths.tables, 'MB_plot_mode_switch_closure_summary.csv');
milestone_common_save_table(closure_table, closure_csv);

out = struct();
out.summary_csv = string(summary_csv);
out.closure_csv = string(closure_csv);
out.summary_root = string(summary_paths.milestone_root);
out.strict_root = string(strict_root);
out.strict_summary_csv = string(strict_csv);
end

function cfg = local_build_smoke_cfg(smoke_id, primary_mode)
cfg = milestone_common_defaults();
[cfg, ~] = apply_mb_search_profile_to_cfg(cfg, 'mb_default');
cfg.milestones.MB_semantic_compare.milestone_id = char(smoke_id);
cfg.milestones.MB_semantic_compare.title = 'semantic_compare';
cfg.milestones.MB_semantic_compare.mode = 'comparison';
cfg.milestones.MB_semantic_compare.sensor_groups = {'baseline'};
cfg.milestones.MB_semantic_compare.heights_to_run = 1000;
cfg.milestones.MB_semantic_compare.family_set = {'nominal'};
cfg.milestones.MB_semantic_compare.run_dense_local = false;
cfg.runtime.figure_visibility_mode = 'headless';
cfg.runtime.force_fresh = false;
cfg.runtime.regenerate_all_cache = false;
cfg.runtime.regenerate_all_export = true;
cfg.cache.force_fresh = false;
cfg.cache.reuse_semantic = true;
cfg.cache.reuse_plot = false;
cfg.cache.rebuild_all = false;
cfg.milestones.MB_semantic_compare.force_fresh = false;
cfg.milestones.MB_semantic_compare.regenerate_all_cache = false;
cfg.milestones.MB_semantic_compare.regenerate_all_export = true;
cfg.milestones.MB_semantic_compare.cache_policy = 'reuse_semantic_rebuild_plot';
cfg.milestones.MB_semantic_compare.cache_profile.force_fresh = false;
cfg.milestones.MB_semantic_compare.cache_profile.reuse_semantic = true;
cfg.milestones.MB_semantic_compare.cache_profile.reuse_plot = false;
cfg.milestones.MB_semantic_compare.cache_profile.reuse_plotting = false;
cfg.milestones.MB_semantic_compare.cache_profile.rebuild_all = false;
cfg.milestones.MB_plotting.passratio_primary_mode = char(primary_mode);
cfg.milestones.MB_plotting.comparison_primary_mode = char(primary_mode);
cfg.milestones.MB_plotting.cross_profile_primary_mode = char(primary_mode);
cfg.milestones.MB_plotting.heatmap_primary_value_mode = 'numeric_requirement';
cfg.milestones.MB_plotting.heatmap_primary_domain_mode = 'globalSkeleton';
cfg.milestones.MB_plotting.export_all_passratio_modes = true;
cfg.milestones.MB_plotting.export_all_heatmap_modes = true;
cfg.milestones.MB_plotting.canonical_primary_mode = char(primary_mode);
cfg.milestones.MB_plotting.diagnostic_export_full_bundle = true;
end

function meta = local_read_sidecar(file_path)
sidecar = string(file_path) + ".meta.json";
if ~isfile(sidecar)
    error('Missing sidecar: %s', char(sidecar));
end
meta = jsondecode(fileread(sidecar));
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
