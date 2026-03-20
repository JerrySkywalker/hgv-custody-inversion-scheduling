function merged = merge_mb_phasecurve_tables(existing_table, added_table)
%MERGE_MB_PHASECURVE_TABLES Merge MB phasecurve tables while preserving the latest values.

if nargin < 1 || isempty(existing_table)
    merged = added_table;
    return;
end
if nargin < 2 || isempty(added_table)
    merged = existing_table;
    return;
end

merged = [existing_table; added_table];
key_vars = intersect({'h_km', 'family_name', 'i_deg', 'Ns'}, merged.Properties.VariableNames, 'stable');
if isempty(key_vars)
    merged = sortrows(merged);
    return;
end
merged = sortrows(merged, key_vars);
[~, keep_idx] = unique(merged(:, key_vars), 'rows', 'last');
merged = merged(sort(keep_idx), :);
end
