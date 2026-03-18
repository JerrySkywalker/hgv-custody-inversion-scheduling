function phasecurve_table = build_family_phasecurve_table(family_tables)
%BUILD_FAMILY_PHASECURVE_TABLE Build family-level phase-transition summaries over constellation size.

if nargin < 1 || isempty(family_tables)
    phasecurve_table = table();
    return;
end

entries = local_normalize_family_tables(family_tables);
rows = cell(sum(cellfun(@(e) numel(unique(e.table.Ns)), entries(~cellfun(@isempty, entries)))), 1);
row_count = 0;

for idx = 1:numel(entries)
    entry = entries{idx};
    if isempty(entry) || isempty(entry.table)
        continue;
    end
    T = entry.table;
    feasible_mask = local_pick_feasible(T);
    Ns_values = unique(T.Ns, 'sorted');
    for j = 1:numel(Ns_values)
        sub = T(T.Ns == Ns_values(j), :);
        sub_feasible = sub(feasible_mask(T.Ns == Ns_values(j)), :);
        row_count = row_count + 1;
        rows{row_count} = table(string(entry.family_name), Ns_values(j), ...
            local_safe_max(sub, 'joint_margin'), ...
            local_safe_max(sub_feasible, 'joint_margin'), ...
            local_safe_divide(height(sub_feasible), height(sub)), ...
            height(sub_feasible), height(sub), ...
            'VariableNames', {'family_name', 'Ns', 'best_joint_margin_all', 'best_joint_margin_feasible', 'feasible_ratio', 'num_feasible', 'num_total'});
    end
end

rows = rows(1:row_count);
if isempty(rows)
    phasecurve_table = table();
else
    phasecurve_table = vertcat(rows{:});
    phasecurve_table = sortrows(phasecurve_table, {'family_name', 'Ns'}, {'ascend', 'ascend'});
end
end

function entries = local_normalize_family_tables(family_tables)
if isstruct(family_tables)
    names = fieldnames(family_tables);
    entries = cell(numel(names), 1);
    for idx = 1:numel(names)
        entries{idx} = struct('family_name', names{idx}, 'table', family_tables.(names{idx}));
    end
elseif iscell(family_tables)
    entries = family_tables;
else
    error('Unsupported family_tables input.');
end
end

function feasible_mask = local_pick_feasible(T)
if ismember('feasible_flag', T.Properties.VariableNames)
    feasible_mask = logical(T.feasible_flag);
elseif ismember('joint_feasible', T.Properties.VariableNames)
    feasible_mask = logical(T.joint_feasible);
else
    feasible_mask = false(height(T), 1);
end
end

function value = local_safe_max(T, field_name)
value = NaN;
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    return;
end
values = T.(field_name);
values = values(isfinite(values));
if ~isempty(values)
    value = max(values);
end
end

function value = local_safe_divide(a, b)
if b == 0
    value = 0;
else
    value = a / b;
end
end
