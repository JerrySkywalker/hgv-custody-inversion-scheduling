function [summary_table, meta] = build_mb_sensor_group_sensitivity_check(run_outputs, profile_name)
%BUILD_MB_SENSOR_GROUP_SENSITIVITY_CHECK Compare closedD outputs across sensor groups.

if nargin < 1 || isempty(run_outputs)
    run_outputs = repmat(struct(), 0, 1);
end
if nargin < 2 || isempty(profile_name)
    profile_name = "";
end

closed_hits = run_outputs(arrayfun(@(r) isfield(r, 'mode') && string(r.mode) == "closedD", run_outputs));
summary_table = table();
meta = struct( ...
    'profile_name', string(profile_name), ...
    'row_count', 0, ...
    'all_equal_everywhere', false, ...
    'warning_emitted', false);

if numel(closed_hits) < 2
    return;
end

pair_idx = nchoosek(1:numel(closed_hits), 2);
rows = cell(size(pair_idx, 1), 1);
cursor = 0;
for idx_pair = 1:size(pair_idx, 1)
    run_a = closed_hits(pair_idx(idx_pair, 1)).run_output;
    run_b = closed_hits(pair_idx(idx_pair, 2)).run_output;
    for idx_run = 1:numel(run_a.runs)
        match_idx = local_find_matching_run(run_b.runs, run_a.runs(idx_run));
        if isempty(match_idx)
            continue;
        end
        comparison = local_compare_eval_tables(run_a.runs(idx_run).eval_table, run_b.runs(match_idx).eval_table);
        cursor = cursor + 1;
        rows{cursor, 1} = table( ...
            run_a.runs(idx_run).h_km, ...
            string(profile_name), ...
            "closedD", ...
            string(run_a.runs(idx_run).family_name), ...
            string(run_a.sensor_group.name), ...
            string(run_b.sensor_group.name), ...
            comparison.design_count, ...
            comparison.num_designs_changed, ...
            comparison.max_joint_margin_diff, ...
            comparison.max_passratio_diff, ...
            comparison.max_DG_diff, ...
            comparison.max_DA_diff, ...
            comparison.max_DT_diff, ...
            comparison.feasible_flag_changes, ...
            comparison.all_equal_flag, ...
            string(comparison.warning_message), ...
            'VariableNames', { ...
                'height_km', ...
                'profile_name', ...
                'semantic_mode', ...
                'family_name', ...
                'sensor_group_a', ...
                'sensor_group_b', ...
                'design_count', ...
                'num_designs_changed', ...
                'max_joint_margin_diff', ...
                'max_passratio_diff', ...
                'max_DG_diff', ...
                'max_DA_diff', ...
                'max_DT_diff', ...
                'feasible_flag_changes', ...
                'all_equal_flag', ...
                'warning_message'});
    end
end

if cursor < 1
    return;
end

summary_table = vertcat(rows{1:cursor});
meta.row_count = height(summary_table);
meta.all_equal_everywhere = all(summary_table.all_equal_flag);
if meta.all_equal_everywhere
    warning('MB:ClosedDSensorSensitivity:NoDifference', ...
        'ClosedD sensor-group sensitivity check found no differences across all compared groups for profile %s.', ...
        char(string(profile_name)));
    meta.warning_emitted = true;
end
end

function match_idx = local_find_matching_run(run_bank, target_run)
match_idx = find(arrayfun(@(r) isequaln(r.h_km, target_run.h_km) && string(r.family_name) == string(target_run.family_name), run_bank), 1);
end

function comparison = local_compare_eval_tables(eval_a, eval_b)
keys = {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'};
common_keys = intersect(keys, eval_a.Properties.VariableNames, 'stable');
common_keys = intersect(common_keys, eval_b.Properties.VariableNames, 'stable');
eval_a = local_suffix_nonkey_variables(eval_a, common_keys, '_a');
eval_b = local_suffix_nonkey_variables(eval_b, common_keys, '_b');
joined = innerjoin(eval_a, eval_b, 'Keys', common_keys);

joint_margin_diff = local_absdiff(joined, 'joint_margin_a', 'joint_margin_b');
passratio_diff = local_absdiff(joined, 'pass_ratio_a', 'pass_ratio_b');
DG_diff = local_absdiff(joined, 'DG_worst_a', 'DG_worst_b');
DA_diff = local_absdiff(joined, 'DA_worst_a', 'DA_worst_b');
DT_diff = local_absdiff(joined, 'DT_worst_a', 'DT_worst_b');
feasible_change = local_logical_diff(joined, 'feasible_flag_a', 'feasible_flag_b');

tol_margin = 1e-12;
tol_ratio = 1e-12;
changed_mask = ...
    (joint_margin_diff > tol_margin) | ...
    (passratio_diff > tol_ratio) | ...
    (DG_diff > tol_margin) | ...
    (DA_diff > tol_margin) | ...
    (DT_diff > tol_margin) | ...
    feasible_change;

comparison = struct();
comparison.design_count = height(joined);
comparison.num_designs_changed = sum(changed_mask);
comparison.max_joint_margin_diff = local_max_or_zero(joint_margin_diff);
comparison.max_passratio_diff = local_max_or_zero(passratio_diff);
comparison.max_DG_diff = local_max_or_zero(DG_diff);
comparison.max_DA_diff = local_max_or_zero(DA_diff);
comparison.max_DT_diff = local_max_or_zero(DT_diff);
comparison.feasible_flag_changes = sum(feasible_change);
comparison.all_equal_flag = comparison.num_designs_changed == 0;
comparison.warning_message = "";
if comparison.all_equal_flag
    comparison.warning_message = "All compared closedD design-level metrics are identical for this sensor-group pair.";
end
end

function diff_values = local_absdiff(T, left_name, right_name)
left_values = T.(left_name);
right_values = T.(right_name);
both_nan = isnan(left_values) & isnan(right_values);
diff_values = abs(left_values - right_values);
diff_values(both_nan) = 0;
diff_values(~isfinite(diff_values) & ~both_nan) = inf;
end

function diff_values = local_logical_diff(T, left_name, right_name)
if ~ismember(left_name, T.Properties.VariableNames) || ~ismember(right_name, T.Properties.VariableNames)
    diff_values = false(height(T), 1);
    return;
end
diff_values = logical(T.(left_name)) ~= logical(T.(right_name));
end

function value = local_max_or_zero(x)
if isempty(x)
    value = 0;
    return;
end
x = x(isfinite(x));
if isempty(x)
    value = 0;
else
    value = max(x);
end
end

function T = local_suffix_nonkey_variables(T, key_names, suffix)
rename_vars = setdiff(T.Properties.VariableNames, key_names, 'stable');
for idx = 1:numel(rename_vars)
    T.Properties.VariableNames{rename_vars{idx}} = [rename_vars{idx} suffix];
end
end
