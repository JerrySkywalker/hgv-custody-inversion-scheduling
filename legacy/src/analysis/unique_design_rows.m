function [tbl_unique, group_info] = unique_design_rows(tbl)
%UNIQUE_DESIGN_ROWS Deduplicate design rows across slice sources.

if nargin < 1 || ~istable(tbl)
    error('unique_design_rows requires a table input.');
end

key_vars = {'h_km', 'i_deg', 'P', 'T', 'F'};
missing = setdiff(key_vars, tbl.Properties.VariableNames);
if ~isempty(missing)
    error('unique_design_rows missing key variables: %s', strjoin(missing, ', '));
end

if isempty(tbl)
    tbl_unique = tbl;
    if ~ismember('support_sources', tbl_unique.Properties.VariableNames)
        tbl_unique.support_sources = strings(0, 1);
    end
    if ~ismember('num_support_sources', tbl_unique.Properties.VariableNames)
        tbl_unique.num_support_sources = zeros(0, 1);
    end
    group_info = table();
    return;
end

key_table = tbl(:, key_vars);
[~, ia, ic] = unique(key_table, 'rows', 'stable');
tbl_unique = tbl(sort(ia), :);

support_sources = strings(height(tbl_unique), 1);
num_support_sources = zeros(height(tbl_unique), 1);
group_rows = cell(height(tbl_unique), 1);

for g = 1:height(tbl_unique)
    row_idx = find(ic == g);
    group_rows{g} = row_idx;
    if ismember('slice_source', tbl.Properties.VariableNames)
        [support_sources(g), num_support_sources(g)] = merge_slice_source_support(tbl.slice_source(row_idx));
    else
        support_sources(g) = "";
        num_support_sources(g) = 0;
    end
end

tbl_unique.support_sources = support_sources;
tbl_unique.num_support_sources = num_support_sources;
if ismember('slice_source', tbl_unique.Properties.VariableNames)
    tbl_unique.slice_source = support_sources;
end

group_info = tbl_unique(:, key_vars);
group_info.group_rows = group_rows;
group_info.support_sources = support_sources;
group_info.num_support_sources = num_support_sources;
end
