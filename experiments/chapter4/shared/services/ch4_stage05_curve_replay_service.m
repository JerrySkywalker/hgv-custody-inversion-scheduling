function replay_result = ch4_stage05_curve_replay_service(tbl)
assert(istable(tbl), 'ch4_stage05_curve_replay_service:InvalidInput', ...
    'Input must be a table.');

required = {'Ns','pass_ratio'};
for k = 1:numel(required)
    assert(ismember(required{k}, tbl.Properties.VariableNames), ...
        'ch4_stage05_curve_replay_service:MissingField', ...
        'Missing required field: %s', required{k});
end

curve_table = build_best_envelope(tbl, 'Ns', 'pass_ratio', struct(), 'max');
curve_table = renamevars(curve_table, 'pass_ratio', 'best_pass');

stats_pass = build_statistical_curve(tbl, 'Ns', 'pass_ratio', struct(), ...
    struct('stats', {{'mean', 'min', 'max'}}));

feasible_curve = build_statistical_curve(tbl, 'Ns', 'is_feasible', struct(), ...
    struct('stats', {{'mean'}}));
if ismember('mean', feasible_curve.Properties.VariableNames)
    feasible_curve = renamevars(feasible_curve, 'mean', 'feasible_ratio');
end

curve_table = outerjoin(curve_table, stats_pass, 'Keys', 'Ns', 'MergeKeys', true);
curve_table = outerjoin(curve_table, feasible_curve, 'Keys', 'Ns', 'MergeKeys', true);

summary = struct();
summary.point_count = height(curve_table);
summary.Ns_min = min(curve_table.Ns);
summary.Ns_max = max(curve_table.Ns);
summary.first_feasible_Ns = NaN;

idx_first = find(curve_table.feasible_ratio > 0, 1, 'first');
if ~isempty(idx_first)
    summary.first_feasible_Ns = curve_table.Ns(idx_first);
end

summary_table = struct2table(summary);

replay_result = struct();
replay_result.curve_table = curve_table;
replay_result.summary_table = summary_table;
end
