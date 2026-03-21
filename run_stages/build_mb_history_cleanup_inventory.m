function out = build_mb_history_cleanup_inventory(options)
%BUILD_MB_HISTORY_CLEANUP_INVENTORY Build a non-destructive inventory/cleanup plan for MB output roots.

mb_safe_startup();

if nargin < 1 || isempty(options)
    options = struct();
end

cfg = milestone_common_defaults();
milestone_root = fullfile(cfg.paths.outputs, 'milestones');
tag = char(string(local_getfield_or(options, 'tag', '20260321_round3')));
delivery_id = char(string(local_getfield_or(options, 'delivery_id', "MB_" + tag + "-delivery")));
delivery_root = fullfile(milestone_root, delivery_id);

entries = dir(fullfile(milestone_root, 'MB*'));
entries = entries([entries.isdir]);

inventory = table('Size', [0, 5], ...
    'VariableTypes', {'string', 'string', 'string', 'string', 'string'}, ...
    'VariableNames', {'folder_name', 'category', 'recommended_action', 'reason', 'full_path'});

for idx = 1:numel(entries)
    folder_name = string(entries(idx).name);
    full_path = string(fullfile(entries(idx).folder, entries(idx).name));
    [category, action, reason] = local_classify_folder(folder_name, delivery_id);
    inventory(end + 1, :) = {folder_name, category, action, reason, full_path}; %#ok<AGROW>
end

inventory = sortrows(inventory, {'category', 'folder_name'});

csv_path = fullfile(delivery_root, 'HISTORICAL_OUTPUT_INVENTORY.csv');
md_path = fullfile(delivery_root, 'HISTORY_CLEANUP_PLAN.md');
writetable(inventory, csv_path);
local_write_cleanup_plan(md_path, inventory);

out = struct();
out.csv_path = string(csv_path);
out.md_path = string(md_path);
out.inventory = inventory;
end

function [category, action, reason] = local_classify_folder(folder_name, delivery_id)
folder_name = string(folder_name);
delivery_id = string(delivery_id);

if folder_name == "MB"
    category = "legacy_root_mixed";
    action = "do_not_use_as_canonical_source";
    reason = "Contains historical and current artifacts mixed together; prefer fresh-root and delivery bundles.";
elseif folder_name == delivery_id || endsWith(folder_name, "-delivery")
    category = "delivery_bundle";
    action = "keep";
    reason = "Curated handoff package with selected figures/tables and provenance docs.";
elseif contains(folder_name, "_round3_fresh") || contains(folder_name, "_round3_strict") || contains(folder_name, "_round3_cacheAB")
    category = "current_clean_root";
    action = "keep";
    reason = "Fresh regression root used for current closure validation.";
elseif contains(folder_name, "devcheck")
    category = "historical_devcheck";
    action = "archive_or_delete_after_backup";
    reason = "Intermediate development verification root retained mainly for historical debugging.";
elseif contains(folder_name, "step") || contains(folder_name, "_freshroot") || contains(folder_name, "_fresh_strict")
    category = "historical_validation_root";
    action = "archive_or_delete_after_backup";
    reason = "Prior closure/step validation root superseded by the current fresh round.";
elseif contains(folder_name, "parallel")
    category = "parallel_check_root";
    action = "archive";
    reason = "Parallel/serial consistency check output retained for reproducibility.";
else
    category = "other_mb_root";
    action = "review_manually";
    reason = "MB-related root not auto-classified; inspect before cleanup.";
end
end

function local_write_cleanup_plan(path_str, inventory)
fid = fopen(path_str, 'w');
fprintf(fid, '# MB Historical Output Cleanup Plan\n\n');
fprintf(fid, '- policy: non-destructive inventory only; no directories were removed automatically\n');
fprintf(fid, '- canonical source recommendation: use the latest fresh roots and curated delivery bundle, not the mixed `outputs/milestones/MB` root\n\n');

categories = unique(inventory.category, 'stable');
for idx = 1:numel(categories)
    category = categories(idx);
    rows = inventory(inventory.category == category, :);
    fprintf(fid, '## %s\n', category);
    for row_idx = 1:height(rows)
        fprintf(fid, '- `%s`: %s (%s)\n', ...
            char(rows.folder_name(row_idx)), ...
            char(rows.recommended_action(row_idx)), ...
            char(rows.reason(row_idx)));
    end
    fprintf(fid, '\n');
end
fclose(fid);
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
