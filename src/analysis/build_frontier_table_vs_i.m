function frontier_table = build_frontier_table_vs_i(full_theta_table, family_name)
%BUILD_FRONTIER_TABLE_VS_I Build the minimum-feasible constellation frontier as a function of inclination.

if nargin < 2 || isempty(family_name)
    family_name = "joint";
end
if isempty(full_theta_table)
    frontier_table = table();
    return;
end

feasible_mask = local_pick_feasible(full_theta_table);
Tfeas = full_theta_table(feasible_mask, :);
if isempty(Tfeas)
    frontier_table = table();
    return;
end

i_values = unique(Tfeas.i_deg, 'sorted');
rows = cell(numel(i_values), 1);
for idx = 1:numel(i_values)
    sub = Tfeas(Tfeas.i_deg == i_values(idx), :);
    sub = sortrows(sub, {'Ns', 'joint_margin', 'h_km', 'P', 'T'}, {'ascend', 'descend', 'ascend', 'ascend', 'ascend'});
    best = sub(1, :);
    row = table(string(family_name), i_values(idx), best.Ns, best.h_km, best.P, best.T, best.F, best.joint_margin, ...
        'VariableNames', {'family_name', 'i_deg', 'minimum_feasible_Ns', 'h_km', 'P', 'T', 'F', 'joint_margin'});
    if ismember('support_sources', best.Properties.VariableNames)
        row.support_sources = string(best.support_sources);
    end
    rows{idx} = row;
end

frontier_table = vertcat(rows{:});
frontier_table = sortrows(frontier_table, 'i_deg', 'ascend');
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
