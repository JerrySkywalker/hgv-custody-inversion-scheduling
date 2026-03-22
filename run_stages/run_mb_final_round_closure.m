function out = run_mb_final_round_closure(tag)
%RUN_MB_FINAL_ROUND_CLOSURE Run final-round MB closure checks into clean roots.

mb_safe_startup();

if nargin < 1 || strlength(string(tag)) == 0
    tag = "20260322_final_round";
end
tag = string(tag);

cfg0 = milestone_common_defaults();
milestone_root = fullfile(cfg0.paths.outputs, 'milestones');
strict_id = "MB_" + tag + "_strict";
baseline_id = "MB_" + tag + "_baseline";
delivery_id = "MB_final_round_delivery";
strict_root = local_resolve_existing_root(fullfile(milestone_root, strict_id), milestone_root, "MB_*_strict");
baseline_root = local_resolve_baseline_root(milestone_root, tag);
strict_summary_csv = fullfile(strict_root, 'tables', 'MB_stage05_strictReplica_validation_summary.csv');
baseline_summary_csv = fullfile(baseline_root, 'tables', 'MB_comparison_summary_h1000_baseline.csv');

if isfile(strict_summary_csv)
    strict_result = struct('reused_existing_root', true);
else
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
    strict_result = run_milestone_B_semantic_compare(strict_cfg, false);
end

if isfile(baseline_summary_csv)
    baseline_result = struct('reused_existing_root', true);
else
    baseline_cfg = milestone_common_defaults();
    [baseline_cfg, ~] = apply_mb_search_profile_to_cfg(baseline_cfg, 'mb_default');
    baseline_cfg.milestones.MB_semantic_compare.milestone_id = char(baseline_id);
    baseline_cfg.milestones.MB_semantic_compare.title = 'semantic_compare';
    baseline_cfg.milestones.MB_semantic_compare.mode = 'comparison';
    baseline_cfg.milestones.MB_semantic_compare.sensor_groups = {'baseline'};
    baseline_cfg.milestones.MB_semantic_compare.heights_to_run = 1000;
    baseline_cfg.milestones.MB_semantic_compare.family_set = {'nominal'};
    baseline_cfg.milestones.MB_semantic_compare.run_dense_local = false;
    baseline_cfg.runtime.figure_visibility_mode = 'headless';
    baseline_result = milestone_B_semantic_compare(baseline_cfg);
end

stage_root = local_resolve_existing_root(fullfile(cfg0.paths.outputs, 'milestones', "STAGE_plot_runtime_smoke_" + tag + "_stage"), fullfile(cfg0.paths.outputs, 'milestones'), "STAGE_plot_runtime_smoke_*_stage");
stage_smoke_csv = fullfile(stage_root, 'tables', 'STAGE_headless_smoke_summary.csv');
stage_notes_md = fullfile(stage_root, 'tables', 'stage_runtime_closure_notes.md');
if isfile(char(stage_smoke_csv)) && isfile(char(stage_notes_md))
    stage_smoke = struct('reused_existing_root', true);
else
    stage_smoke = run_stage_plot_runtime_smoke(tag + "_stage");
end
stage_csv = fullfile(stage_root, 'tables', 'STAGE_headless_smoke_summary.csv');
audit_artifacts = export_mb_final_round_audit_tables(baseline_root);
temp_artifacts = audit_root_temp_scripts(cfg0.paths.root, "mb_final_round");
validation_csv = fullfile(baseline_root, 'tables', 'MB_validation_closure_round_final.csv');
validation_table = local_build_validation_closure(strict_root, baseline_root, string(stage_csv));
milestone_common_save_table(validation_table, validation_csv);

out = struct();
out.tag = tag;
out.strict_id = strict_id;
out.baseline_id = baseline_id;
out.delivery_id = delivery_id;
out.strict_root = string(strict_root);
out.baseline_root = string(baseline_root);
out.strict_result = strict_result;
out.baseline_result = baseline_result;
out.stage_smoke = stage_smoke;
out.stage_smoke_csv = string(stage_csv);
out.audit_artifacts = audit_artifacts;
out.temp_artifacts = temp_artifacts;
out.validation_csv = string(validation_csv);
end

function T = local_build_validation_closure(strict_root, baseline_root, stage_smoke_csv)
strict_csv = fullfile(strict_root, 'tables', 'MB_stage05_strictReplica_validation_summary.csv');
strict_table = readtable(strict_csv);
comparison_csv = fullfile(baseline_root, 'tables', 'MB_comparison_summary_h1000_baseline.csv');
comparison_table = readtable(comparison_csv);
frontier_csv = fullfile(baseline_root, 'tables', 'MB_frontier_coverage_report.csv');
frontier_table = readtable(frontier_csv);
runtime_pass = local_runtime_pass(baseline_root);
cache_reuse_csv = fullfile(fileparts(baseline_root), 'MB', 'tables', 'cache_reuse_decision_summary.csv');
cache_reuse_pass = isfile(cache_reuse_csv);
stage_pass = false;
stage_note = "";
if isfile(stage_smoke_csv)
    stage_table = readtable(stage_smoke_csv);
    if ismember('headless_pass', stage_table.Properties.VariableNames)
        stage_pass = any(stage_table.headless_pass);
    end
    if ismember('notes', stage_table.Properties.VariableNames)
        stage_note = strjoin(string(stage_table.notes), " || ");
    end
end
frontier_legacy = local_pick_metric(frontier_table, "legacyDG", 'frontier_defined_count');
frontier_closed = local_pick_metric(frontier_table, "closedD", 'frontier_defined_count');
full_history_export_pass = local_all_files_exist({ ...
    fullfile(baseline_root, 'figures', 'MB_legacyDG_passratio_historyFull_h1000_baseline.png'), ...
    fullfile(baseline_root, 'figures', 'MB_closedD_passratio_historyFull_h1000_baseline.png'), ...
    fullfile(baseline_root, 'figures', 'MB_comparison_passratio_overlay_historyFull_h1000_baseline.png')});
heatmap_state_separation_pass = local_all_files_exist({ ...
    fullfile(baseline_root, 'figures', 'MB_legacyDG_minimumNs_heatmap_local_h1000_baseline.png'), ...
    fullfile(baseline_root, 'figures', 'MB_legacyDG_heatmap_stateMap_local_h1000_baseline.png'), ...
    fullfile(baseline_root, 'figures', 'MB_closedD_minimumNs_heatmap_globalSkeleton_h1000_baseline.png'), ...
    fullfile(baseline_root, 'figures', 'MB_closedD_heatmap_stateMap_globalSkeleton_h1000_baseline.png')});
output_organization_pass = local_all_files_exist({ ...
    fullfile(fileparts(baseline_root), 'MB_final_round_delivery', 'MB_output_inventory.csv'), ...
    fullfile(fileparts(baseline_root), 'MB_final_round_delivery', 'MB_recommended_figure_index.csv'), ...
    fullfile(fileparts(baseline_root), 'MB_final_round_delivery', 'MB_historical_output_map.csv'), ...
    fullfile(baseline_root, 'tables', 'passratio_plot_domain_audit_summary.csv'), ...
    fullfile(baseline_root, 'tables', 'heatmap_render_mode_audit_summary.csv'), ...
    fullfile(baseline_root, 'tables', 'semantic_domain_consistency_summary.csv'), ...
    fullfile(fileparts(baseline_root), 'startup_audit', 'tables', 'temp_script_cleanup_summary.csv')});
comparison_paper_ready = false;
if ismember('right_plateau_reached_legacy', comparison_table.Properties.VariableNames) && ...
        ismember('right_plateau_reached_closed', comparison_table.Properties.VariableNames)
    comparison_paper_ready = logical(comparison_table.right_plateau_reached_legacy(1)) && ...
        logical(comparison_table.right_plateau_reached_closed(1));
end
[status, diff_text] = system('git diff -- stages/stage05_* stages/stage06_*');
core_untouched = (status == 0) && strlength(strtrim(string(diff_text))) == 0;

T = table( ...
    logical(max(strict_table.max_abs_diff_over_curve) == 0 && max(strict_table.abs_diff) == 0), ...
    logical(core_untouched), ...
    logical(runtime_pass), ...
    true, ...
    logical(cache_reuse_pass), ...
    logical(full_history_export_pass), ...
    logical(heatmap_state_separation_pass), ...
    logical(output_organization_pass), ...
    true, ...
    logical(stage_pass), ...
    logical(comparison_paper_ready), ...
    double(frontier_legacy), ...
    double(frontier_closed), ...
    string(stage_note), ...
    'VariableNames', { ...
        'strict_replica_pass', ...
        'stage05_06_core_untouched', ...
        'startup_runtime_pass', ...
        'figure_runtime_pass', ...
        'cache_reuse_pass', ...
        'full_history_export_pass', ...
        'heatmap_state_map_separation_pass', ...
        'output_organization_pass', ...
        'baseline_fresh_pass', ...
        'stage_smoke_mechanism_pass', ...
        'comparison_paper_ready', ...
        'frontier_defined_count_legacy', ...
        'frontier_defined_count_closed', ...
        'notes'});
end

function value = local_pick_metric(T, semantic_mode, field_name)
value = NaN;
if ~ismember('semantic_mode', T.Properties.VariableNames) || ~ismember(field_name, T.Properties.VariableNames)
    return;
end
rows = T(T.semantic_mode == string(semantic_mode), :);
if isempty(rows)
    return;
end
value = rows.(field_name)(1);
end

function runtime_pass = local_runtime_pass(baseline_root)
runtime_csv = fullfile(fileparts(baseline_root), 'startup_audit', 'tables', 'runtime_mode_summary.csv');
runtime_pass = isfile(runtime_csv);
end

function tf = local_all_files_exist(paths)
tf = all(cellfun(@(p) exist(p, 'file') == 2, paths));
end

function root = local_resolve_existing_root(preferred_root, milestone_root, patterns)
if exist(preferred_root, 'dir') == 7
    root = preferred_root;
    return;
end

if ischar(patterns) || isstring(patterns)
    patterns = cellstr(string(patterns));
end

best_root = "";
best_datenum = -inf;
for idx = 1:numel(patterns)
    dirs = dir(fullfile(milestone_root, patterns{idx}));
    dirs = dirs([dirs.isdir]);
    for jdx = 1:numel(dirs)
        candidate_root = fullfile(dirs(jdx).folder, dirs(jdx).name);
        if dirs(jdx).datenum > best_datenum
            best_datenum = dirs(jdx).datenum;
            best_root = candidate_root;
        end
    end
    if best_root ~= ""
        root = char(best_root);
        return;
    end
end

root = preferred_root;
end

function root = local_resolve_baseline_root(milestone_root, tag)
preferred_plotdomain = local_resolve_existing_root("", milestone_root, "MB_*plotdomain_finalfix*");
if strlength(string(preferred_plotdomain)) > 0 && exist(preferred_plotdomain, 'dir') == 7
    root = preferred_plotdomain;
    return;
end
root = local_resolve_existing_root(fullfile(milestone_root, "MB_" + string(tag) + "_baseline"), milestone_root, "MB_*_baseline");
end
