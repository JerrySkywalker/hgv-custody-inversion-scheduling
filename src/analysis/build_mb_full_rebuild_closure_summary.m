function closure_table = build_mb_full_rebuild_closure_summary(strict_root, baseline_root)
%BUILD_MB_FULL_REBUILD_CLOSURE_SUMMARY Build one-row closure summary for the MB full rebuild round.

strict_root = char(string(strict_root));
baseline_root = char(string(baseline_root));

strict_csv = fullfile(strict_root, 'tables', 'MB_stage05_strictReplica_validation_summary.csv');
fresh_csv = fullfile(baseline_root, 'tables', 'fresh_recompute_manifest.csv');
passratio_csv = fullfile(baseline_root, 'tables', 'passratio_source_semantics_audit_summary.csv');
heatmap_csv = fullfile(baseline_root, 'tables', 'heatmap_source_semantics_audit_summary.csv');
fullnight_csv = fullfile(baseline_root, 'tables', 'MB_fullnight_run_summary.csv');

strict_table = local_read_if_present(strict_csv);
fresh_table = local_read_if_present(fresh_csv);
passratio_table = local_read_if_present(passratio_csv);
heatmap_table = local_read_if_present(heatmap_csv);
fullnight_table = local_read_if_present(fullnight_csv);

strict_replica_pass = local_strict_replica_pass(strict_table);
full_cache_rebuild_pass = local_full_cache_rebuild_pass(fresh_table);
passratio_semantics_pass = ~isempty(passratio_table) && all(logical(passratio_table.expected_semantics_match));
heatmap_semantics_pass = ~isempty(heatmap_table) && all(logical(heatmap_table.semantics_match));
history_no_zero_padding_pass = ~isempty(passratio_table) && all(~logical(passratio_table.zero_padding_used(passratio_table.mode_name == "historyFull")));
effective_dense_rebuild_pass = ~isempty(passratio_table) && ...
    all(logical(passratio_table.dense_rebuild_used(passratio_table.mode_name == "effectiveFullRange"))) && ...
    all(logical(passratio_table.dense_rebuild_used(passratio_table.mode_name == "frontierZoom") | passratio_table.inherited_from_effective_dense(passratio_table.mode_name == "frontierZoom")));
full_heights_run_pass = ~isempty(fullnight_table) && all(ismember([500, 750, 1000], unique(double(fullnight_table.height_km))));
[status, diff_text] = system('git diff -- stages/stage05_* stages/stage06_*');
stage05_06_core_untouched = (status == 0) && strlength(strtrim(string(diff_text))) == 0;

final_status = "fail";
if all([full_cache_rebuild_pass, passratio_semantics_pass, heatmap_semantics_pass, history_no_zero_padding_pass, effective_dense_rebuild_pass, full_heights_run_pass, strict_replica_pass, stage05_06_core_untouched])
    final_status = "pass";
end

closure_table = table( ...
    logical(full_cache_rebuild_pass), ...
    logical(passratio_semantics_pass), ...
    logical(heatmap_semantics_pass), ...
    logical(history_no_zero_padding_pass), ...
    logical(effective_dense_rebuild_pass), ...
    logical(full_heights_run_pass), ...
    logical(strict_replica_pass), ...
    logical(stage05_06_core_untouched), ...
    string(final_status), ...
    'VariableNames', {'full_cache_rebuild_pass', 'passratio_semantics_pass', 'heatmap_semantics_pass', 'history_no_zero_padding_pass', 'effective_dense_rebuild_pass', 'full_heights_run_pass', 'strict_replica_pass', 'stage05_06_core_untouched', 'final_status'});
end

function T = local_read_if_present(file_path)
if exist(file_path, 'file') == 2
    T = readtable(file_path, 'TextType', 'string');
else
    T = table();
end
end

function tf = local_strict_replica_pass(T)
tf = false;
if isempty(T)
    return;
end
max_curve = 0;
max_abs = 0;
if ismember('max_abs_diff_over_curve', T.Properties.VariableNames)
    max_curve = max(double(T.max_abs_diff_over_curve));
end
if ismember('max_abs_diff', T.Properties.VariableNames)
    max_abs = max(double(T.max_abs_diff));
elseif ismember('abs_diff', T.Properties.VariableNames)
    max_abs = max(double(T.abs_diff));
end
tf = max_curve == 0 && max_abs == 0;
end

function tf = local_full_cache_rebuild_pass(T)
tf = false;
if isempty(T) || ~ismember('artifact_name', T.Properties.VariableNames) || ~ismember('cache_reused', T.Properties.VariableNames)
    return;
end
artifact_name = string(T.artifact_name);
essential_mask = ~contains(artifact_name, "static_stage", 'IgnoreCase', true);
if ~any(essential_mask)
    tf = true;
    return;
end
tf = all(~logical(T.cache_reused(essential_mask)));
end
