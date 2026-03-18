function phasecurve_table = build_dense_passratio_phasecurve(full_theta_table, i_list)
%BUILD_DENSE_PASSRATIO_PHASECURVE Aggregate dense local pass-ratio envelopes by inclination and shell.

phasecurve_table = table();
if nargin < 2 || isempty(i_list)
    if isempty(full_theta_table)
        i_list = [];
    else
        i_list = unique(full_theta_table.i_deg, 'sorted');
    end
end
if isempty(full_theta_table) || ~ismember('pass_ratio', full_theta_table.Properties.VariableNames)
    return;
end

rows = cell(height(full_theta_table), 1);
row_count = 0;
for idx = 1:numel(i_list)
    sub_i = full_theta_table(full_theta_table.i_deg == i_list(idx), :);
    if isempty(sub_i)
        continue;
    end
    Ns_values = unique(sub_i.Ns, 'sorted');
    for j = 1:numel(Ns_values)
        sub_ns = sub_i(sub_i.Ns == Ns_values(j), :);
        row_count = row_count + 1;
        rows{row_count, 1} = table(i_list(idx), Ns_values(j), max(sub_ns.pass_ratio), ...
            sum(local_pick_feasible(sub_ns)), height(sub_ns), ...
            'VariableNames', {'i_deg', 'Ns', 'max_pass_ratio', 'num_feasible', 'num_total'});
    end
end

rows = rows(1:row_count);
if ~isempty(rows)
    phasecurve_table = vertcat(rows{:});
    phasecurve_table = sortrows(phasecurve_table, {'i_deg', 'Ns'}, {'ascend', 'ascend'});
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
