function out = package_mb_full_rebuild_delivery(tag)
%PACKAGE_MB_FULL_REBUILD_DELIVERY Build a non-destructive delivery bundle for the MB full-rebuild round.

mb_safe_startup();

if nargin < 1 || strlength(string(tag)) == 0
    tag = "20260323_fullrebuild";
end
tag = string(tag);

cfg = milestone_common_defaults();
milestone_root = fullfile(cfg.paths.outputs, 'milestones');
baseline_root = fullfile(milestone_root, "MB_" + tag + "_baseline");
strict_root = fullfile(milestone_root, "MB_" + tag + "_strict");
delivery_root = fullfile(milestone_root, "MB_" + tag + "_delivery");

ensure_dir(delivery_root);
ensure_dir(fullfile(delivery_root, 'figures'));
ensure_dir(fullfile(delivery_root, 'tables'));
ensure_dir(fullfile(delivery_root, 'docs'));
ensure_dir(fullfile(delivery_root, 'canonical_figures'));
ensure_dir(fullfile(delivery_root, 'canonical_tables'));

copy_manifest = table('Size', [0, 3], ...
    'VariableTypes', {'string', 'string', 'string'}, ...
    'VariableNames', {'source_path', 'relative_path', 'kind'});

items = local_build_copy_items(baseline_root, strict_root);
for idx = 1:size(items, 1)
    src = items{idx, 1};
    rel = items{idx, 2};
    kind = items{idx, 3};
    if exist(src, 'file') ~= 2
        continue;
    end
    dst = fullfile(delivery_root, rel);
    ensure_dir(fileparts(dst));
    copyfile(src, dst);
    copy_manifest(end + 1, :) = {string(src), string(rel), string(kind)}; %#ok<AGROW>

    meta_src = string(src) + ".meta.json";
    if exist(char(meta_src), 'file') == 2
        meta_rel = rel + ".meta.json";
        meta_dst = fullfile(delivery_root, char(meta_rel));
        ensure_dir(fileparts(meta_dst));
        copyfile(char(meta_src), meta_dst);
        copy_manifest(end + 1, :) = {meta_src, string(meta_rel), "meta"}; %#ok<AGROW>
    end
end

writetable(copy_manifest, fullfile(delivery_root, 'copied_file_manifest.csv'));
writetable(copy_manifest, fullfile(delivery_root, 'MB_output_inventory.csv'));

local_copy_doc_if_exists(fullfile(cfg.paths.root, 'README_full_rebuild_round.md'), fullfile(delivery_root, 'docs', 'README_full_rebuild_round.md'));
local_copy_doc_if_exists(fullfile(cfg.paths.root, 'README_final_repair_round.md'), fullfile(delivery_root, 'docs', 'README_final_repair_round.md'));

recommended = local_build_recommended_figure_index(copy_manifest);
writetable(recommended, fullfile(delivery_root, 'MB_recommended_figure_index.csv'));

local_copy_canonical_figures(copy_manifest, delivery_root);
local_copy_canonical_tables(copy_manifest, delivery_root);

recommended_roots = local_build_recommended_roots(baseline_root, strict_root, delivery_root, fullfile(milestone_root, 'MB_20260323_final_repair_fullnight'), fullfile(milestone_root, 'MB_final_repair_round_delivery'), fullfile(milestone_root, 'MB'));
writetable(recommended_roots, fullfile(delivery_root, 'MB_output_recommended_roots.csv'));

history_map = local_build_historical_output_map(milestone_root, delivery_root, baseline_root, strict_root);
writetable(history_map, fullfile(delivery_root, 'MB_historical_output_map.csv'));

out = struct();
out.delivery_root = string(delivery_root);
out.copy_manifest_csv = string(fullfile(delivery_root, 'copied_file_manifest.csv'));
out.inventory_csv = string(fullfile(delivery_root, 'MB_output_inventory.csv'));
out.recommended_roots_csv = string(fullfile(delivery_root, 'MB_output_recommended_roots.csv'));
out.history_map_csv = string(fullfile(delivery_root, 'MB_historical_output_map.csv'));
out.figure_index_csv = string(fullfile(delivery_root, 'MB_recommended_figure_index.csv'));
end

function items = local_build_copy_items(baseline_root, strict_root)
heights_km = [500, 750, 1000];
items = cell(0, 3);

root_tables = { ...
    'fresh_recompute_manifest.csv', 'tables/full_rebuild/fresh_recompute_manifest.csv'; ...
    'passratio_source_semantics_audit_summary.csv', 'tables/full_rebuild/passratio_source_semantics_audit_summary.csv'; ...
    'heatmap_source_semantics_audit_summary.csv', 'tables/full_rebuild/heatmap_source_semantics_audit_summary.csv'; ...
    'plot_domain_root_cause_audit_summary.csv', 'tables/full_rebuild/plot_domain_root_cause_audit_summary.csv'; ...
    'passratio_history_padding_summary.csv', 'tables/full_rebuild/passratio_history_padding_summary.csv'; ...
    'plot_cache_domain_semantics_audit.csv', 'tables/full_rebuild/plot_cache_domain_semantics_audit.csv'; ...
    'heatmap_render_mode_audit_summary.csv', 'tables/full_rebuild/heatmap_render_mode_audit_summary.csv'; ...
    'semantic_domain_consistency_summary.csv', 'tables/full_rebuild/semantic_domain_consistency_summary.csv'; ...
    'MB_expandable_search_summary.csv', 'tables/full_rebuild/MB_expandable_search_summary.csv'; ...
    'MB_frontier_coverage_report.csv', 'tables/full_rebuild/MB_frontier_coverage_report.csv'; ...
    'MB_gap_reliability_report.csv', 'tables/full_rebuild/MB_gap_reliability_report.csv'; ...
    'MB_fullnight_run_summary.csv', 'tables/full_rebuild/MB_fullnight_run_summary.csv'; ...
    'MB_full_rebuild_closure_summary.csv', 'tables/full_rebuild/MB_full_rebuild_closure_summary.csv'; ...
    'MB_output_metadata_manifest.csv', 'tables/full_rebuild/MB_output_metadata_manifest.csv'};

for idx = 1:size(root_tables, 1)
    items = local_append_item(items, fullfile(baseline_root, 'tables', root_tables{idx, 1}), root_tables{idx, 2}, 'table');
end

items = local_append_item(items, fullfile(strict_root, 'tables', 'MB_stage05_strictReplica_validation_summary.csv'), 'tables/strict_replica/MB_stage05_strictReplica_validation_summary.csv', 'table');
items = local_append_item(items, fullfile(strict_root, 'tables', 'MB_stage05_strict_replica_manifest.csv'), 'tables/strict_replica/MB_stage05_strict_replica_manifest.csv', 'table');

for idx_height = 1:numel(heights_km)
    h_km = heights_km(idx_height);
    items = local_append_item(items, fullfile(baseline_root, 'tables', sprintf('MB_comparison_summary_h%d_baseline.csv', h_km)), sprintf('tables/comparison/MB_comparison_summary_h%d_baseline.csv', h_km), 'table');
    items = local_append_item(items, fullfile(baseline_root, 'tables', sprintf('MB_comparison_export_grade_h%d_baseline.csv', h_km)), sprintf('tables/comparison/MB_comparison_export_grade_h%d_baseline.csv', h_km), 'table');

    semantics = {'legacyDG', 'closedD'};
    for idx_semantic = 1:numel(semantics)
        semantic_name = semantics{idx_semantic};
        items = local_append_item(items, fullfile(baseline_root, 'tables', sprintf('MB_heatmap_edge_truncation_summary_%s_h%d_baseline.csv', semantic_name, h_km)), sprintf('tables/heatmap/MB_heatmap_edge_truncation_summary_%s_h%d_baseline.csv', semantic_name, h_km), 'table');
        items = local_append_item(items, fullfile(baseline_root, 'tables', sprintf('MB_heatmap_overcompute_summary_%s_h%d_baseline.csv', semantic_name, h_km)), sprintf('tables/heatmap/MB_heatmap_overcompute_summary_%s_h%d_baseline.csv', semantic_name, h_km), 'table');
        items = local_append_item(items, fullfile(baseline_root, 'tables', sprintf('MB_heatmap_provenance_map_%s_h%d_baseline.csv', semantic_name, h_km)), sprintf('tables/heatmap/MB_heatmap_provenance_map_%s_h%d_baseline.csv', semantic_name, h_km), 'table');
    end

    items = local_append_passratio_items(items, baseline_root, h_km, 'legacyDG_passratio', 'figures/passratio', true);
    items = local_append_passratio_items(items, baseline_root, h_km, 'closedD_passratio', 'figures/passratio', true);
    items = local_append_passratio_items(items, baseline_root, h_km, 'comparison_passratio_overlay', 'figures/comparison', true);
    items = local_append_passratio_items(items, baseline_root, h_km, 'profileCompare_legacyDG_passratio', 'figures/cross_profile', false);
    items = local_append_passratio_items(items, baseline_root, h_km, 'profileCompare_closedD_passratio', 'figures/cross_profile', false);

    items = local_append_heatmap_items(items, baseline_root, h_km, 'legacyDG');
    items = local_append_heatmap_items(items, baseline_root, h_km, 'closedD');
end
end

function items = local_append_passratio_items(items, root_dir, height_km, prefix_key, rel_dir, baseline_suffix)
domain_tags = {'historyFull', 'effectiveFullRange', 'frontierZoom'};
for idx = 1:numel(domain_tags)
    tag = domain_tags{idx};
    if baseline_suffix
        file_name = sprintf('MB_%s_%s_h%d_baseline.png', prefix_key, tag, height_km);
    else
        file_name = sprintf('MB_%s_%s_h%d.png', prefix_key, tag, height_km);
    end
    items = local_append_item(items, fullfile(root_dir, 'figures', file_name), fullfile(rel_dir, file_name), 'figure');
end
end

function items = local_append_heatmap_items(items, root_dir, height_km, semantic_name)
figure_names = { ...
    sprintf('MB_%s_minimumNs_heatmap_local_h%d_baseline.png', semantic_name, height_km), ...
    sprintf('MB_%s_minimumNs_heatmap_globalSkeleton_h%d_baseline.png', semantic_name, height_km), ...
    sprintf('MB_%s_heatmap_stateMap_globalSkeleton_h%d_baseline.png', semantic_name, height_km)};

for idx = 1:numel(figure_names)
    file_name = figure_names{idx};
    items = local_append_item(items, fullfile(root_dir, 'figures', file_name), fullfile('figures/heatmap', file_name), 'figure');
end
end

function items = local_append_item(items, src, rel, kind)
items(end + 1, :) = {char(src), char(rel), char(kind)}; %#ok<AGROW>
end

function local_copy_doc_if_exists(src, dst)
if exist(src, 'file') == 2
    ensure_dir(fileparts(dst));
    copyfile(src, dst);
end
end

function T = local_build_recommended_figure_index(copy_manifest)
figure_rows = copy_manifest(copy_manifest.kind == "figure", :);
paths = string(figure_rows.relative_path);
status = repmat("supplemental", numel(paths), 1);
notes = repmat("full rebuild figure bundle", numel(paths), 1);

for idx = 1:numel(paths)
    rel = paths(idx);
    if contains(rel, "effectiveFullRange")
        status(idx) = "paper_primary";
        notes(idx) = "default primary pass-ratio mode from dense effective-domain rebuild";
    elseif contains(rel, "historyFull")
        status(idx) = "paper_supporting";
        notes(idx) = "true computed history points without zero padding";
    elseif contains(rel, "frontierZoom")
        status(idx) = "diagnostic_support";
        notes(idx) = "frontier-local zoom derived from dense effective-domain rebuild";
    elseif contains(rel, "minimumNs_heatmap_globalSkeleton")
        status(idx) = "paper_primary";
        notes(idx) = "global numeric requirement surface rebuilt on full i-P grid";
    elseif contains(rel, "heatmap_stateMap_globalSkeleton")
        status(idx) = "paper_supporting";
        notes(idx) = "global skeleton state coverage map with discrete semantics";
    elseif contains(rel, "minimumNs_heatmap_local")
        status(idx) = "supplemental";
        notes(idx) = "local numeric heatmap retained for focused diagnostics";
    end
end

T = table(paths, status, notes, 'VariableNames', {'relative_path', 'status', 'notes'});
end

function local_copy_canonical_figures(copy_manifest, delivery_root)
recommended = local_build_recommended_figure_index(copy_manifest);
keep_mask = recommended.status == "paper_primary" | recommended.status == "paper_supporting";
rel_paths = recommended.relative_path(keep_mask);
for idx = 1:numel(rel_paths)
    src = fullfile(delivery_root, char(rel_paths(idx)));
    if exist(src, 'file') ~= 2
        continue;
    end
    dst = fullfile(delivery_root, 'canonical_figures', char(rel_paths(idx)));
    ensure_dir(fileparts(dst));
    copyfile(src, dst);
end
end

function local_copy_canonical_tables(copy_manifest, delivery_root)
table_rows = copy_manifest(copy_manifest.kind == "table", :);
for idx = 1:height(table_rows)
    rel = table_rows.relative_path(idx);
    src = fullfile(delivery_root, char(rel));
    if exist(src, 'file') ~= 2
        continue;
    end
    dst = fullfile(delivery_root, 'canonical_tables', char(rel));
    ensure_dir(fileparts(dst));
    copyfile(src, dst);
end
end

function T = local_build_recommended_roots(baseline_root, strict_root, delivery_root, prior_fullnight_root, prior_delivery_root, legacy_root)
labels = [ ...
    "full_rebuild_baseline_root"; ...
    "full_rebuild_delivery_root"; ...
    "strict_replica_root"; ...
    "prior_final_repair_root"; ...
    "prior_final_repair_delivery_root"; ...
    "legacy_mixed_root"];
paths = [ ...
    string(baseline_root); ...
    string(delivery_root); ...
    string(strict_root); ...
    string(prior_fullnight_root); ...
    string(prior_delivery_root); ...
    string(legacy_root)];
usage = [ ...
    "recommended canonical baseline root for current full-rebuild round"; ...
    "curated bundle for canonical figures, tables, and docs in the current full-rebuild round"; ...
    "strict Stage05 replica validation anchor"; ...
    "older final-repair fresh root retained for history only; no longer recommended for citation"; ...
    "older final-repair delivery bundle retained for history only; no longer recommended for citation"; ...
    "historical mixed MB root; do not cite as canonical"];
T = table(labels, paths, usage, 'VariableNames', {'label', 'root_path', 'usage'});
end

function T = local_build_historical_output_map(milestone_root, delivery_root, baseline_root, strict_root)
dirs = dir(fullfile(milestone_root, 'MB*'));
dirs = dirs([dirs.isdir]);
names = string({dirs.name})';
full_paths = string(fullfile({dirs.folder}, {dirs.name}))';
kind = repmat("historical_or_active_root", numel(names), 1);

delivery_name = string(local_basename_dir(delivery_root));
baseline_name = string(local_basename_dir(baseline_root));
strict_name = string(local_basename_dir(strict_root));
kind(names == delivery_name) = "delivery_bundle";
kind(names == baseline_name) = "full_rebuild_baseline_root";
kind(names == strict_name) = "strict_replica_root";
kind(names == "MB") = "legacy_mixed_root";
kind(contains(names, "final_repair", 'IgnoreCase', true)) = "prior_final_repair_root";
kind(contains(names, "plotmode_smoke", 'IgnoreCase', true) | contains(names, "task", 'IgnoreCase', true)) = "task_or_smoke_root";

T = table(names, full_paths, kind, 'VariableNames', {'name', 'full_path', 'kind'});
T = sortrows(T, {'kind', 'name'});
end

function name = local_basename_dir(path_value)
[~, name, ~] = fileparts(char(path_value));
end
