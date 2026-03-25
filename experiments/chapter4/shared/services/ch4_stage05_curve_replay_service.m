function replay_result = ch4_stage05_curve_replay_service(tbl)
assert(istable(tbl), 'ch4_stage05_curve_replay_service:InvalidInput', ...
    'Input must be a table.');

required = {'Ns','pass_ratio','is_feasible','joint_margin'};
for k = 1:numel(required)
    assert(ismember(required{k}, tbl.Properties.VariableNames), ...
        'ch4_stage05_curve_replay_service:MissingField', ...
        'Missing required field: %s', required{k});
end

Ns_vals = unique(tbl.Ns);
Ns_vals = sort(Ns_vals(:));

rows = repmat(struct(), numel(Ns_vals), 1);

for i = 1:numel(Ns_vals)
    ns = Ns_vals(i);
    sub = tbl(tbl.Ns == ns, :);

    rows(i).Ns = ns;
    rows(i).design_count = height(sub);
    rows(i).pass_ratio_mean = mean(sub.pass_ratio);
    rows(i).pass_ratio_min = min(sub.pass_ratio);
    rows(i).pass_ratio_max = max(sub.pass_ratio);
    rows(i).feasible_ratio = mean(double(sub.is_feasible));
    rows(i).joint_margin_min = min(sub.joint_margin);
    rows(i).joint_margin_mean = mean(sub.joint_margin);
    rows(i).joint_margin_max = max(sub.joint_margin);
end

curve_table = struct2table(rows);

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
