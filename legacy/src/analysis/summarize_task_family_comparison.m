function summary_table = summarize_task_family_comparison(task_results)
%SUMMARIZE_TASK_FAMILY_COMPARISON Build dissertation-facing task-family summary metrics.

if nargin < 1 || isempty(task_results)
    summary_table = table();
    return;
end

rows = cell(numel(task_results), 1);
for k = 1:numel(task_results)
    r = task_results{k};
    full_unique = unique_design_rows(r.full_theta_table);
    feasible_unique = unique_design_rows(r.feasible_theta_table);

    num_total = height(full_unique);
    num_feasible = height(feasible_unique);
    feasible_ratio = local_safe_ratio(num_feasible, num_total);

    Ns_min_feasible = NaN;
    num_minimum_designs = 0;
    best_joint_margin = NaN;
    if ~isempty(feasible_unique)
        Ns_min_feasible = min(feasible_unique.Ns);
        num_minimum_designs = sum(feasible_unique.Ns == Ns_min_feasible);
        if ismember('joint_margin', feasible_unique.Properties.VariableNames)
            best_joint_margin = max(feasible_unique.joint_margin);
        end
    end

    [dg_ratio, da_ratio, dt_ratio] = local_fail_ratios(full_unique);

    rows{k} = table( ...
        string(r.task_slice_id), num_total, num_feasible, feasible_ratio, ...
        Ns_min_feasible, num_minimum_designs, best_joint_margin, ...
        dg_ratio, da_ratio, dt_ratio, ...
        r.summary.casebank_size, string(r.summary.config_signature), ...
        'VariableNames', { ...
            'family_name', 'num_total', 'num_feasible', 'feasible_ratio', ...
            'Ns_min_feasible', 'num_minimum_designs', 'best_joint_margin', ...
            'dominant_fail_DG_ratio', 'dominant_fail_DA_ratio', 'dominant_fail_DT_ratio', ...
            'casebank_size', 'config_signature'});
    if isfield(r.summary, 'casebank_breakdown')
        rows{k}.casebank_nominal = r.summary.casebank_breakdown.nominal;
        rows{k}.casebank_heading = r.summary.casebank_breakdown.heading;
        rows{k}.casebank_critical = r.summary.casebank_breakdown.critical;
    end
end

summary_table = vertcat(rows{:});
end

function ratio = local_safe_ratio(a, b)
if b <= 0
    ratio = 0;
else
    ratio = a / b;
end
end

function [dg_ratio, da_ratio, dt_ratio] = local_fail_ratios(full_unique)
dg_ratio = 0;
da_ratio = 0;
dt_ratio = 0;
if isempty(full_unique) || ~ismember('dominant_fail_tag', full_unique.Properties.VariableNames)
    return;
end

tags = upper(string(full_unique.dominant_fail_tag));
n = numel(tags);
if n == 0
    return;
end

dg_ratio = sum(contains(tags, "DG")) / n;
da_ratio = sum(contains(tags, "DA")) / n;
dt_ratio = sum(contains(tags, "DT")) / n;
end
