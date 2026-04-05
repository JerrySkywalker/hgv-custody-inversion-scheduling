function selection_trace = build_selection_trace_from_scan_table(scan_table, policy_name)
%BUILD_SELECTION_TRACE_FROM_SCAN_TABLE
% Build a simple stepwise selection trace from R8.5c.5 scan_table.

assert(istable(scan_table), 'scan_table must be a table.');
assert(ischar(policy_name) || isstring(policy_name), 'policy_name must be char or string.');
policy_name = char(string(policy_name));

n_steps = height(scan_table);
selection_trace = cell(n_steps,1);

for k = 1:n_steps
    row = scan_table(k,:);
    rec = struct();
    rec.step_index = row.step_index;
    rec.source = string(policy_name);

    switch policy_name
        case 'pta'
            if row.has_candidate
                rec.best_pair = [row.pta_sat1, row.pta_sat2];
            else
                rec.best_pair = [];
            end
        case 'observability_family'
            if row.has_candidate
                rec.best_pair = [row.cn_sat1, row.cn_sat2];
            else
                rec.best_pair = [];
            end
        otherwise
            error('Unsupported policy_name: %s', policy_name);
    end

    selection_trace{k} = rec;
end
end
