function out = package_mb_final_round_delivery(tag)
%PACKAGE_MB_FINAL_ROUND_DELIVERY Build the final MB delivery bundle.

mb_safe_startup();

if nargin < 1 || strlength(string(tag)) == 0
    tag = "20260322_final_round";
end
tag = string(tag);

cfg = milestone_common_defaults();
milestone_root = fullfile(cfg.paths.outputs, 'milestones');
strict_root = fullfile(milestone_root, "MB_" + tag + "_strict");
baseline_root = fullfile(milestone_root, "MB_" + tag + "_baseline");
delivery_root = fullfile(milestone_root, 'MB_final_round_delivery');

ensure_dir(delivery_root);
ensure_dir(fullfile(delivery_root, 'figures'));
ensure_dir(fullfile(delivery_root, 'tables'));
ensure_dir(fullfile(delivery_root, 'docs'));

copy_manifest = table('Size', [0, 3], ...
    'VariableTypes', {'string', 'string', 'string'}, ...
    'VariableNames', {'source_path', 'relative_path', 'kind'});

items = { ...
    fullfile(strict_root, 'tables', 'MB_stage05_strictReplica_validation_summary.csv'), 'tables/MB_stage05_strictReplica_validation_summary.csv', 'table'; ...
    fullfile(strict_root, 'tables', 'MB_stage05_strict_replica_manifest.csv'), 'tables/MB_stage05_strict_replica_manifest.csv', 'table'; ...
    fullfile(baseline_root, 'tables', 'MB_validation_closure_round_final.csv'), 'tables/MB_validation_closure_round_final.csv', 'table'; ...
    fullfile(baseline_root, 'tables', 'MB_expandable_search_summary.csv'), 'tables/MB_expandable_search_summary.csv', 'table'; ...
    fullfile(baseline_root, 'tables', 'MB_search_domain_audit_table.csv'), 'tables/MB_search_domain_audit_table.csv', 'table'; ...
    fullfile(baseline_root, 'tables', 'MB_search_stop_reason_summary.csv'), 'tables/MB_search_stop_reason_summary.csv', 'table'; ...
    fullfile(baseline_root, 'tables', 'MB_frontier_coverage_report.csv'), 'tables/MB_frontier_coverage_report.csv', 'table'; ...
    fullfile(baseline_root, 'tables', 'MB_gap_reliability_report.csv'), 'tables/MB_gap_reliability_report.csv', 'table'; ...
    fullfile(baseline_root, 'tables', 'MB_comparison_summary_h1000_baseline.csv'), 'tables/MB_comparison_summary_h1000_baseline.csv', 'table'; ...
    fullfile(baseline_root, 'tables', 'MB_heatmap_overcompute_summary_closedD_h1000_baseline.csv'), 'tables/MB_heatmap_overcompute_summary_closedD_h1000_baseline.csv', 'table'; ...
    fullfile(baseline_root, 'tables', 'MB_heatmap_provenance_map_closedD_h1000_baseline.csv'), 'tables/MB_heatmap_provenance_map_closedD_h1000_baseline.csv', 'table'; ...
    fullfile(baseline_root, 'tables', 'MB_frontier_refinement_summary_closedD_h1000_baseline.csv'), 'tables/MB_frontier_refinement_summary_closedD_h1000_baseline.csv', 'table'; ...
    fullfile(baseline_root, 'tables', 'MB_output_metadata_manifest.csv'), 'tables/MB_output_metadata_manifest.csv', 'table'; ...
    fullfile(fileparts(baseline_root), 'STAGE_plot_runtime_smoke_' + tag + "_stage", 'tables', 'STAGE_headless_smoke_summary.csv'), 'tables/STAGE_headless_smoke_summary.csv', 'table'; ...
    fullfile(baseline_root, 'figures', 'MB_legacyDG_passratio_historyFull_h1000_baseline.png'), 'figures/baseline_final/MB_legacyDG_passratio_historyFull_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_legacyDG_passratio_effectiveFullRange_h1000_baseline.png'), 'figures/baseline_final/MB_legacyDG_passratio_effectiveFullRange_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_legacyDG_passratio_frontierZoom_h1000_baseline.png'), 'figures/baseline_final/MB_legacyDG_passratio_frontierZoom_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_closedD_passratio_historyFull_h1000_baseline.png'), 'figures/baseline_final/MB_closedD_passratio_historyFull_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_closedD_passratio_effectiveFullRange_h1000_baseline.png'), 'figures/baseline_final/MB_closedD_passratio_effectiveFullRange_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_closedD_passratio_frontierZoom_h1000_baseline.png'), 'figures/baseline_final/MB_closedD_passratio_frontierZoom_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_comparison_passratio_overlay_historyFull_h1000_baseline.png'), 'figures/comparison/MB_comparison_passratio_overlay_historyFull_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_comparison_passratio_overlay_effectiveFullRange_h1000_baseline.png'), 'figures/comparison/MB_comparison_passratio_overlay_effectiveFullRange_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_comparison_passratio_overlay_frontierZoom_h1000_baseline.png'), 'figures/comparison/MB_comparison_passratio_overlay_frontierZoom_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_legacyDG_minimumNs_heatmap_local_h1000_baseline.png'), 'figures/heatmap/MB_legacyDG_minimumNs_heatmap_local_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_legacyDG_minimumNs_heatmap_globalSkeleton_h1000_baseline.png'), 'figures/heatmap/MB_legacyDG_minimumNs_heatmap_globalSkeleton_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_closedD_minimumNs_heatmap_local_h1000_baseline.png'), 'figures/heatmap/MB_closedD_minimumNs_heatmap_local_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_closedD_minimumNs_heatmap_globalSkeleton_h1000_baseline.png'), 'figures/heatmap/MB_closedD_minimumNs_heatmap_globalSkeleton_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_legacyDG_heatmap_stateMap_local_h1000_baseline.png'), 'figures/heatmap/MB_legacyDG_heatmap_stateMap_local_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_legacyDG_heatmap_stateMap_globalSkeleton_h1000_baseline.png'), 'figures/heatmap/MB_legacyDG_heatmap_stateMap_globalSkeleton_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_closedD_heatmap_stateMap_local_h1000_baseline.png'), 'figures/heatmap/MB_closedD_heatmap_stateMap_local_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_closedD_heatmap_stateMap_globalSkeleton_h1000_baseline.png'), 'figures/heatmap/MB_closedD_heatmap_stateMap_globalSkeleton_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_comparison_frontier_shift_h1000_baseline.png'), 'figures/comparison/MB_comparison_frontier_shift_h1000_baseline.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_profileCompare_legacyDG_passratio_fullRange_h1000.png'), 'figures/cross_profile/MB_profileCompare_legacyDG_passratio_fullRange_h1000.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_profileCompare_closedD_passratio_fullRange_h1000.png'), 'figures/cross_profile/MB_profileCompare_closedD_passratio_fullRange_h1000.png', 'figure'; ...
    fullfile(baseline_root, 'figures', 'MB_profileCompare_legacyDG_DG_envelope_h1000.png'), 'figures/cross_profile/MB_profileCompare_legacyDG_DG_envelope_h1000.png', 'figure'};

for idx = 1:size(items, 1)
    src = items{idx, 1};
    rel = items{idx, 2};
    kind = items{idx, 3};
    if ~isfile(src)
        continue;
    end
    dst = fullfile(delivery_root, rel);
    ensure_dir(fileparts(dst));
    copyfile(src, dst);
    copy_manifest(end + 1, :) = {string(src), string(rel), string(kind)}; %#ok<AGROW>
    meta_src = string(src) + ".meta.json";
    if isfile(char(meta_src))
        meta_rel = rel + ".meta.json";
        meta_dst = fullfile(delivery_root, char(meta_rel));
        copyfile(char(meta_src), meta_dst);
        copy_manifest(end + 1, :) = {meta_src, string(meta_rel), "meta"}; %#ok<AGROW>
    end
end

writetable(copy_manifest, fullfile(delivery_root, 'copied_file_manifest.csv'));
writetable(copy_manifest, fullfile(delivery_root, 'MB_output_inventory.csv'));

local_copy_doc_if_exists(fullfile(cfg.paths.root, 'README_final_round.md'), fullfile(delivery_root, 'docs', 'README_final_round.md'));
local_copy_doc_if_exists(fullfile(cfg.paths.root, 'VALIDATION_CLOSURE_final_round.md'), fullfile(delivery_root, 'docs', 'VALIDATION_CLOSURE_final_round.md'));
local_copy_doc_if_exists(fullfile(cfg.paths.root, 'CACHE_POLICY_final_round.md'), fullfile(delivery_root, 'docs', 'CACHE_POLICY_final_round.md'));
local_copy_doc_if_exists(fullfile(cfg.paths.root, 'PAPER_FIGURE_SHORTLIST_final_round.md'), fullfile(delivery_root, 'docs', 'PAPER_FIGURE_SHORTLIST_final_round.md'));
local_copy_doc_if_exists(fullfile(cfg.paths.root, 'MB_FINAL_FREEZE_NOTES.md'), fullfile(delivery_root, 'docs', 'MB_FINAL_FREEZE_NOTES.md'));

recommended = local_build_recommended_figure_index(copy_manifest);
writetable(recommended, fullfile(delivery_root, 'MB_recommended_figure_index.csv'));

history_map = local_build_historical_output_map(milestone_root);
writetable(history_map, fullfile(delivery_root, 'MB_historical_output_map.csv'));

out = struct();
out.delivery_root = string(delivery_root);
out.copy_manifest = string(fullfile(delivery_root, 'copied_file_manifest.csv'));
end

function local_copy_doc_if_exists(src, dst)
if isfile(src)
    ensure_dir(fileparts(dst));
    copyfile(src, dst);
end
end

function T = local_build_recommended_figure_index(copy_manifest)
paths = string(copy_manifest.relative_path(copy_manifest.kind == "figure"));
status = repmat("diagnostic_only", numel(paths), 1);
notes = repmat("supplemental", numel(paths), 1);
for idx = 1:numel(paths)
    rel = paths(idx);
    if contains(rel, "historyFull")
        status(idx) = "paper_candidate";
        notes(idx) = "primary global trend view";
    elseif contains(rel, "effectiveFullRange")
        status(idx) = "paper_candidate";
        notes(idx) = "final effective-domain trend view";
    elseif contains(rel, "frontierZoom")
        status(idx) = "supplemental";
        notes(idx) = "local frontier zoom";
    elseif contains(rel, "globalSkeleton")
        status(idx) = "paper_candidate";
        notes(idx) = "global heatmap skeleton/state map";
    elseif contains(rel, "frontier_shift")
        status(idx) = "diagnostic_only";
        notes(idx) = "comparison shift remains sparse";
    end
end
T = table(paths, status, notes, 'VariableNames', {'relative_path', 'status', 'notes'});
end

function T = local_build_historical_output_map(milestone_root)
dirs = dir(fullfile(milestone_root, 'MB*'));
dirs = dirs([dirs.isdir]);
names = string({dirs.name})';
full_paths = string(fullfile({dirs.folder}, {dirs.name}))';
kind = repmat("historical_or_active_root", numel(names), 1);
kind(startsWith(names, "MB_final_round_delivery")) = "delivery_bundle";
T = table(names, full_paths, kind, 'VariableNames', {'name', 'full_path', 'kind'});
end
