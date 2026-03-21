function out = package_mb_closure_delivery(options)
%PACKAGE_MB_CLOSURE_DELIVERY Package fresh MB closure outputs into a clean delivery bundle.

mb_safe_startup();

if nargin < 1 || isempty(options)
    options = struct();
end

tag = char(string(local_getfield_or(options, 'tag', '20260321_round3')));
round_slug = tag;
cfg = milestone_common_defaults();
milestone_root = fullfile(cfg.paths.outputs, 'milestones');

fresh_id = char(string(local_getfield_or(options, 'fresh_id', "MB_" + tag + "_fresh")));
strict_id = char(string(local_getfield_or(options, 'strict_id', "MB_" + tag + "_strict")));
cache_id = char(string(local_getfield_or(options, 'cache_id', "MB_" + tag + "_cacheAB")));
delivery_id = char(string(local_getfield_or(options, 'delivery_id', "MB_" + tag + "-delivery")));

fresh_root = fullfile(milestone_root, fresh_id);
strict_root = fullfile(milestone_root, strict_id);
cache_root = fullfile(milestone_root, cache_id);
delivery_root = fullfile(milestone_root, delivery_id);

if isfolder(delivery_root)
    rmdir(delivery_root, 's');
end

fig_root = fullfile(delivery_root, 'figures');
tab_root = fullfile(delivery_root, 'tables');
ensure_dir(delivery_root);
ensure_dir(fig_root);
ensure_dir(tab_root);
ensure_dir(fullfile(fig_root, 'strict_replica'));
ensure_dir(fullfile(fig_root, 'baseline_h1000'));
ensure_dir(fullfile(fig_root, 'cross_profile'));
ensure_dir(fullfile(fig_root, 'diagnostics'));
ensure_dir(fullfile(tab_root, 'strict_replica'));
ensure_dir(fullfile(tab_root, 'baseline_h1000'));
ensure_dir(fullfile(tab_root, 'cross_profile'));
ensure_dir(fullfile(tab_root, 'cache_ab'));
ensure_dir(fullfile(tab_root, 'diagnostics'));

fresh_manifest = readtable(fullfile(fresh_root, 'tables', 'MB_output_metadata_manifest.csv'));
strict_manifest = readtable(fullfile(strict_root, 'tables', 'MB_output_metadata_manifest.csv'));
expanded_sources = [fresh_manifest; strict_manifest];
expanded_sources = expanded_sources(expanded_sources.snapshot_stage == "expanded_final", :);
expanded_sources_csv = fullfile(delivery_root, 'EXPANDED_FINAL_SOURCE_LIST.csv');
writetable(expanded_sources, expanded_sources_csv);

comparison_grade = local_concat_tables({ ...
    fullfile(fresh_root, 'tables', 'MB_comparison_export_grade_h1000_baseline.csv'), ...
    fullfile(fresh_root, 'tables', 'MB_comparison_export_grade_h1000_optimistic.csv'), ...
    fullfile(fresh_root, 'tables', 'MB_comparison_export_grade_h1000_robust.csv')});
profile_grade = readtable(fullfile(fresh_root, 'tables', 'MB_profileCompare_export_grade.csv'));
strict_profile_grade = readtable(fullfile(strict_root, 'tables', 'MB_profileCompare_export_grade.csv'));
diagnostic_only = vertcat( ...
    local_normalize_grade_table(comparison_grade(comparison_grade.export_grade ~= "paper_candidate", :), "comparison_export"), ...
    local_normalize_grade_table(profile_grade(profile_grade.export_grade ~= "paper_candidate", :), "cross_profile_export"), ...
    local_normalize_grade_table(strict_profile_grade(strict_profile_grade.export_grade ~= "paper_candidate", :), "strict_cross_profile_export"));
diagnostic_csv = fullfile(delivery_root, 'DIAGNOSTIC_ONLY_LIST.csv');
writetable(diagnostic_only, diagnostic_csv);

copied_manifest = table('Size', [0, 3], ...
    'VariableTypes', {'string', 'string', 'string'}, ...
    'VariableNames', {'source_path', 'relative_path', 'kind'});

copy_items = {
    fullfile(strict_root, 'tables', 'MB_stage05_strictReplica_validation_summary.csv'), 'tables/strict_replica/MB_stage05_strictReplica_validation_summary.csv', 'table';
    fullfile(strict_root, 'tables', 'MB_stage05_strict_replica_manifest.csv'), 'tables/strict_replica/MB_stage05_strict_replica_manifest.csv', 'table';
    fullfile(strict_root, 'figures', 'MB_legacyDG_passratio_h1000_stage05_strict_reference.png'), 'figures/strict_replica/MB_legacyDG_passratio_h1000_stage05_strict_reference.png', 'figure';
    fullfile(strict_root, 'figures', 'MB_control_stage05_passratio_envelope_h1000_stage05_strict_reference.png'), 'figures/strict_replica/MB_control_stage05_passratio_envelope_h1000_stage05_strict_reference.png', 'figure';
    fullfile(strict_root, 'figures', 'MB_control_stage05_DG_envelope_h1000_stage05_strict_reference.png'), 'figures/strict_replica/MB_control_stage05_DG_envelope_h1000_stage05_strict_reference.png', 'figure';
    fullfile(fresh_root, 'tables', 'MB_run_manifest.csv'), 'tables/baseline_h1000/MB_run_manifest.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_output_metadata_manifest.csv'), 'tables/baseline_h1000/MB_output_metadata_manifest.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_headless_smoke_summary.csv'), 'tables/diagnostics/MB_headless_smoke_summary.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_frontier_coverage_report.csv'), 'tables/diagnostics/MB_frontier_coverage_report.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_gap_reliability_report.csv'), 'tables/diagnostics/MB_gap_reliability_report.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_parallel_consistency_summary.csv'), 'tables/diagnostics/MB_parallel_consistency_summary.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_parallel_timing_summary.csv'), 'tables/diagnostics/MB_parallel_timing_summary.csv', 'table';
    fullfile(cache_root, 'tables', 'MB_cache_ab_validation.csv'), 'tables/cache_ab/MB_cache_ab_validation.csv', 'table';
    fullfile(cache_root, 'tables', 'MB_cache_reuse_summary.csv'), 'tables/cache_ab/MB_cache_reuse_summary.csv', 'table';
    fullfile(cache_root, 'tables', 'MB_cache_signature_manifest.csv'), 'tables/cache_ab/MB_cache_signature_manifest.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_legacyDG_passratio_h1000_baseline.csv'), 'tables/baseline_h1000/MB_legacyDG_passratio_h1000_baseline.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_closedD_passratio_h1000_baseline.csv'), 'tables/baseline_h1000/MB_closedD_passratio_h1000_baseline.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_legacyDG_minimumNs_heatmap_iP_h1000_baseline.csv'), 'tables/baseline_h1000/MB_legacyDG_minimumNs_heatmap_iP_h1000_baseline.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_closedD_minimumNs_heatmap_iP_h1000_baseline.csv'), 'tables/baseline_h1000/MB_closedD_minimumNs_heatmap_iP_h1000_baseline.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_comparison_summary_h1000_baseline.csv'), 'tables/diagnostics/MB_comparison_summary_h1000_baseline.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_comparison_export_grade_h1000_baseline.csv'), 'tables/diagnostics/MB_comparison_export_grade_h1000_baseline.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_profileCompare_export_grade.csv'), 'tables/cross_profile/MB_profileCompare_export_grade.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_profileCompare_summary.csv'), 'tables/cross_profile/MB_profileCompare_summary.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_sensor_group_sensitivity_check.csv'), 'tables/diagnostics/MB_sensor_group_sensitivity_check.csv', 'table';
    fullfile(fresh_root, 'tables', 'MB_run_all_stages_headless_smoke.csv'), 'tables/diagnostics/MB_run_all_stages_headless_smoke.csv', 'table';
    fullfile(fresh_root, 'figures', 'MB_legacyDG_passratio_h1000_baseline.png'), 'figures/baseline_h1000/MB_legacyDG_passratio_h1000_baseline.png', 'figure';
    fullfile(fresh_root, 'figures', 'MB_closedD_passratio_h1000_baseline.png'), 'figures/baseline_h1000/MB_closedD_passratio_h1000_baseline.png', 'figure';
    fullfile(fresh_root, 'figures', 'MB_legacyDG_minimumNs_heatmap_iP_h1000_baseline.png'), 'figures/baseline_h1000/MB_legacyDG_minimumNs_heatmap_iP_h1000_baseline.png', 'figure';
    fullfile(fresh_root, 'figures', 'MB_closedD_minimumNs_heatmap_iP_h1000_baseline.png'), 'figures/baseline_h1000/MB_closedD_minimumNs_heatmap_iP_h1000_baseline.png', 'figure';
    fullfile(fresh_root, 'figures', 'MB_comparison_passratio_overlay_h1000_baseline.png'), 'figures/diagnostics/MB_comparison_passratio_overlay_h1000_baseline.png', 'figure';
    fullfile(fresh_root, 'figures', 'MB_comparison_gap_heatmap_iP_h1000_baseline.png'), 'figures/diagnostics/MB_comparison_gap_heatmap_iP_h1000_baseline.png', 'figure';
    fullfile(fresh_root, 'figures', 'MB_comparison_frontier_shift_h1000_baseline.png'), 'figures/diagnostics/MB_comparison_frontier_shift_h1000_baseline.png', 'figure';
    fullfile(fresh_root, 'figures', 'MB_profileCompare_legacyDG_passratio_h1000.png'), 'figures/cross_profile/MB_profileCompare_legacyDG_passratio_h1000.png', 'figure';
    fullfile(fresh_root, 'figures', 'MB_profileCompare_closedD_passratio_h1000.png'), 'figures/cross_profile/MB_profileCompare_closedD_passratio_h1000.png', 'figure';
    fullfile(fresh_root, 'figures', 'MB_profileCompare_legacyDG_frontier_h1000.png'), 'figures/cross_profile/MB_profileCompare_legacyDG_frontier_h1000.png', 'figure';
    fullfile(fresh_root, 'figures', 'MB_profileCompare_closedD_frontier_h1000.png'), 'figures/cross_profile/MB_profileCompare_closedD_frontier_h1000.png', 'figure';
    fullfile(fresh_root, 'figures', 'MB_profileCompare_legacyDG_DG_envelope_h1000.png'), 'figures/cross_profile/MB_profileCompare_legacyDG_DG_envelope_h1000.png', 'figure'};

for idx = 1:size(copy_items, 1)
    src = copy_items{idx, 1};
    rel = copy_items{idx, 2};
    kind = copy_items{idx, 3};
    if ~isfile(src)
        continue;
    end
    dst = fullfile(delivery_root, rel);
    ensure_dir(fileparts(dst));
    copyfile(src, dst);
    copied_manifest(end + 1, :) = {string(src), string(rel), string(kind)}; %#ok<AGROW>
    meta_src = char(string(src) + ".meta.json");
    if isfile(meta_src)
        meta_rel = rel + ".meta.json";
        meta_dst = fullfile(delivery_root, meta_rel);
        copyfile(meta_src, meta_dst);
        copied_manifest(end + 1, :) = {string(meta_src), string(meta_rel), "meta"}; %#ok<AGROW>
    end
end

copied_manifest_csv = fullfile(delivery_root, 'copied_file_manifest.csv');
writetable(copied_manifest, copied_manifest_csv);

local_write_readme(fullfile(delivery_root, sprintf('README_delivery_%s.md', round_slug)), delivery_id, fresh_id, strict_id, cache_id);
local_write_validation(fullfile(delivery_root, sprintf('VALIDATION_CLOSURE_%s.md', round_slug)), strict_root, fresh_root, cache_root, round_slug);
local_write_cache_policy(fullfile(delivery_root, sprintf('CACHE_POLICY_%s.md', round_slug)), cache_root, round_slug);
local_write_paper_shortlist(fullfile(delivery_root, sprintf('PAPER_FIGURE_SHORTLIST_%s.md', round_slug)), delivery_root, round_slug);
cleanup_out = build_mb_history_cleanup_inventory(struct('tag', tag, 'delivery_id', delivery_id));

out = struct();
out.delivery_root = string(delivery_root);
out.expanded_source_csv = string(expanded_sources_csv);
out.diagnostic_only_csv = string(diagnostic_csv);
out.copied_manifest_csv = string(copied_manifest_csv);
out.history_inventory_csv = string(cleanup_out.csv_path);
out.history_cleanup_md = string(cleanup_out.md_path);
end

function T = local_concat_tables(paths)
parts = {};
cursor = 0;
for idx = 1:numel(paths)
    if isfile(paths{idx})
        cursor = cursor + 1;
        parts{cursor, 1} = readtable(paths{idx}); %#ok<AGROW>
    end
end
if cursor == 0
    T = table();
else
    T = vertcat(parts{1:cursor});
end
end

function local_write_readme(path_str, delivery_id, fresh_id, strict_id, cache_id)
fid = fopen(path_str, 'w');
fprintf(fid, '# %s\n\n', delivery_id);
fprintf(fid, '- fresh root: `%s`\n', fresh_id);
fprintf(fid, '- strict root: `%s`\n', strict_id);
fprintf(fid, '- cache A/B root: `%s`\n', cache_id);
fprintf(fid, '- package contents: expanded-final source list, diagnostic-only list, strict replica validation, baseline h=1000 fresh results, cross-profile overlays, cache A/B summary, MB/stage headless smoke summaries, frontier/gap reliability, and parallel consistency tables\n');
fprintf(fid, '- intent: provide a clean handoff bundle without mixing historical `outputs/milestones/MB` artifacts\n');
fclose(fid);
end

function local_write_validation(path_str, strict_root, fresh_root, cache_root, round_slug)
strict_summary = readtable(fullfile(strict_root, 'tables', 'MB_stage05_strictReplica_validation_summary.csv'));
comparison_summary = readtable(fullfile(fresh_root, 'tables', 'MB_comparison_summary_h1000_baseline.csv'));
cache_ab = readtable(fullfile(cache_root, 'tables', 'MB_cache_ab_validation.csv'));
frontier_cov = readtable(fullfile(fresh_root, 'tables', 'MB_frontier_coverage_report.csv'));
gap_rel = readtable(fullfile(fresh_root, 'tables', 'MB_gap_reliability_report.csv'));
fid = fopen(path_str, 'w');
fprintf(fid, '# Validation Closure %s\n\n', round_slug);
fprintf(fid, '- strict replica max_abs_diff_over_curve: `%g`\n', strict_summary.max_abs_diff_over_curve(1));
fprintf(fid, '- baseline comparison snapshot stage: `%s`\n', string(comparison_summary.snapshot_stage(1)));
fprintf(fid, '- baseline comparison legacy minimum Ns: `%g`\n', comparison_summary.legacy_minimum_feasible_Ns(1));
fprintf(fid, '- baseline comparison closedD minimum Ns: `%g`\n', comparison_summary.closed_minimum_feasible_Ns(1));
fprintf(fid, '- baseline comparison right_plateau_reached_legacy: `%d`\n', comparison_summary.right_plateau_reached_legacy(1));
fprintf(fid, '- baseline comparison right_plateau_reached_closed: `%d`\n', comparison_summary.right_plateau_reached_closed(1));
fprintf(fid, '- cache A/B rows: `%d`\n', height(cache_ab));
fprintf(fid, '- frontier coverage rows: `%d`\n', height(frontier_cov));
fprintf(fid, '- gap reliability rows: `%d`\n', height(gap_rel));
fprintf(fid, '- headless smoke: see `tables/diagnostics/MB_run_all_stages_headless_smoke.csv`\n');
fclose(fid);
end

function local_write_cache_policy(path_str, cache_root, round_slug)
cache_ab = readtable(fullfile(cache_root, 'tables', 'MB_cache_ab_validation.csv'));
cache_reuse = readtable(fullfile(cache_root, 'tables', 'MB_cache_reuse_summary.csv'));
cache_manifest = readtable(fullfile(cache_root, 'tables', 'MB_cache_signature_manifest.csv'));
fid = fopen(path_str, 'w');
fprintf(fid, '# Cache Policy %s\n\n', round_slug);
fprintf(fid, '- semantic cache key includes semantic mode, sensor group, search profile, profile mode, Ns/P/T grids, expand blocks, hard max, evaluator version, sensor propagation version\n');
fprintf(fid, '- plotting-only rerun should reuse semantic cache\n');
fprintf(fid, '- semantic search-domain change should invalidate semantic cache\n\n');
for idx = 1:height(cache_ab)
    fprintf(fid, '- %s / %s: cache_hits=%g, fresh=%g\n', ...
        char(string(cache_ab.scenario(idx))), char(string(cache_ab.semantic_mode(idx))), ...
        cache_ab.cache_hits(idx), cache_ab.fresh_evaluations(idx));
end
fprintf(fid, '\n## Reuse Classification\n');
for idx = 1:height(cache_reuse)
    fprintf(fid, '- %s / %s: expected_reuse=%d, actual_reuse=%d, status=%s\n', ...
        char(string(cache_reuse.scenario(idx))), ...
        char(string(cache_reuse.semantic_mode(idx))), ...
        cache_reuse.expected_reuse(idx), cache_reuse.actual_reuse(idx), ...
        char(string(cache_reuse.status(idx))));
end
fprintf(fid, '\n## Signature Manifest Rows\n');
fprintf(fid, '- manifest rows: `%d`\n', height(cache_manifest));
fclose(fid);
end

function local_write_paper_shortlist(path_str, delivery_root, round_slug)
fid = fopen(path_str, 'w');
fprintf(fid, '# Paper Figure Shortlist %s\n\n', round_slug);
fprintf(fid, '## Tier A\n');
fprintf(fid, '- `figures/strict_replica/MB_control_stage05_passratio_envelope_h1000_stage05_strict_reference.png`\n');
fprintf(fid, '- `figures/strict_replica/MB_control_stage05_DG_envelope_h1000_stage05_strict_reference.png`\n');
fprintf(fid, '- `figures/baseline_h1000/MB_legacyDG_passratio_h1000_baseline.png`\n');
fprintf(fid, '- `figures/baseline_h1000/MB_legacyDG_minimumNs_heatmap_iP_h1000_baseline.png`\n');
fprintf(fid, '- `figures/baseline_h1000/MB_closedD_minimumNs_heatmap_iP_h1000_baseline.png`\n\n');
fprintf(fid, '## Tier B\n');
fprintf(fid, '- `figures/cross_profile/MB_profileCompare_legacyDG_passratio_h1000.png` (paper candidate for legacyDG pass-ratio cross-profile)\n');
fprintf(fid, '- `figures/cross_profile/MB_profileCompare_legacyDG_DG_envelope_h1000.png` (paper candidate for raw DG envelope comparison)\n\n');
fprintf(fid, '## Diagnostic Only\n');
fprintf(fid, '- `figures/diagnostics/MB_comparison_passratio_overlay_h1000_baseline.png`\n');
fprintf(fid, '- `figures/diagnostics/MB_comparison_gap_heatmap_iP_h1000_baseline.png`\n');
fprintf(fid, '- `figures/diagnostics/MB_comparison_frontier_shift_h1000_baseline.png`\n');
fprintf(fid, '- `figures/cross_profile/MB_profileCompare_closedD_passratio_h1000.png`\n');
fprintf(fid, '- `figures/cross_profile/MB_profileCompare_closedD_frontier_h1000.png`\n\n');
fprintf(fid, 'See `EXPANDED_FINAL_SOURCE_LIST.csv` and `DIAGNOSTIC_ONLY_LIST.csv` for provenance and export grading.\n');
fprintf(fid, '\nPackage root: `%s`\n', delivery_root);
fclose(fid);
end

function T = local_normalize_grade_table(T_in, source_kind)
row_count = height(T_in);
T = table('Size', [row_count, 8], ...
    'VariableTypes', {'string', 'string', 'string', 'double', 'string', 'string', 'logical', 'string'}, ...
    'VariableNames', {'source_kind', 'semantic_mode', 'sensor_group', 'h_km', 'family_name', 'artifact_kind', 'paper_candidate', 'note'});
T.source_kind = repmat(string(source_kind), row_count, 1);
if ismember('semantic_mode', T_in.Properties.VariableNames)
    T.semantic_mode = string(T_in.semantic_mode);
elseif ismember('artifact_semantic_mode', T_in.Properties.VariableNames)
    T.semantic_mode = string(T_in.artifact_semantic_mode);
else
    T.semantic_mode = repmat("", row_count, 1);
end
if ismember('sensor_group', T_in.Properties.VariableNames)
    T.sensor_group = string(T_in.sensor_group);
elseif ismember('artifact_sensor_group', T_in.Properties.VariableNames)
    T.sensor_group = string(T_in.artifact_sensor_group);
else
    T.sensor_group = repmat("", row_count, 1);
end
T.h_km = double(local_pick_or_repeat(T_in, 'h_km', NaN, row_count));
T.family_name = string(local_pick_or_repeat(T_in, 'family_name', "", row_count));
if ismember('figure_family', T_in.Properties.VariableNames)
    T.artifact_kind = string(T_in.figure_family);
elseif ismember('summary_kind', T_in.Properties.VariableNames)
    T.artifact_kind = string(T_in.summary_kind);
else
    T.artifact_kind = repmat("", row_count, 1);
end
if ismember('paper_candidate', T_in.Properties.VariableNames)
    T.paper_candidate = logical(T_in.paper_candidate);
elseif ismember('paper_ready_allowed', T_in.Properties.VariableNames)
    T.paper_candidate = logical(T_in.paper_ready_allowed);
else
    T.paper_candidate = false(row_count, 1);
end
T.note = string(local_pick_or_repeat(T_in, 'note', "", row_count));
end

function values = local_pick_or_repeat(T, var_name, fallback, row_count)
if ismember(var_name, T.Properties.VariableNames)
    values = T.(var_name);
else
    values = repmat(fallback, row_count, 1);
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
