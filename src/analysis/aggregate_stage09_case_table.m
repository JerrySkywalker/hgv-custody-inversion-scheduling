function metrics = aggregate_stage09_case_table(case_table, row, cfg_or_stage09, failed_early, n_case_total, n_case_evaluated)
%AGGREGATE_STAGE09_CASE_TABLE Aggregate case-level Stage09 metrics into one design-level summary.

if nargin < 3
    error('aggregate_stage09_case_table requires case_table, row, and cfg_or_stage09.');
end
if nargin < 4 || isempty(failed_early)
    failed_early = false;
end
if nargin < 5 || isempty(n_case_total)
    n_case_total = height(case_table);
end
if nargin < 6 || isempty(n_case_evaluated)
    n_case_evaluated = height(case_table);
end

s9 = local_pick_stage09(cfg_or_stage09);
if isempty(case_table)
    metrics = local_empty_metrics(row, s9, n_case_total, n_case_evaluated, failed_early);
    return;
end

DG_valid = case_table.DG(isfinite(case_table.DG));
DA_valid = case_table.DA(isfinite(case_table.DA));
DT_bar_valid = case_table.DT_bar(isfinite(case_table.DT_bar));
DT_valid = case_table.DT(isfinite(case_table.DT));
pass_valid = case_table.pass_flag_case;

if isempty(DG_valid), DG_rob = NaN; else, DG_rob = min(DG_valid); end
if isempty(DA_valid), DA_rob = NaN; else, DA_rob = min(DA_valid); end
if isempty(DT_bar_valid), DT_bar_rob = NaN; else, DT_bar_rob = min(DT_bar_valid); end
if isempty(DT_valid), DT_rob = NaN; else, DT_rob = min(DT_valid); end

joint_margin = min([DG_rob, DA_rob, DT_rob]);

if isempty(pass_valid)
    pass_ratio = NaN;
else
    if failed_early
        pass_ratio = sum(pass_valid) / n_case_total;
    else
        pass_ratio = mean(pass_valid, 'omitnan');
    end
end

feasible_flag = ...
    (pass_ratio >= s9.require_pass_ratio) && ...
    (DG_rob >= s9.require_DG_min) && ...
    (DA_rob >= s9.require_DA_min) && ...
    (DT_rob >= s9.require_DT_min);

metrics = struct();
metrics.DG_rob = DG_rob;
metrics.DA_rob = DA_rob;
metrics.DT_bar_rob = DT_bar_rob;
metrics.DT_rob = DT_rob;
metrics.joint_margin = joint_margin;
metrics.pass_ratio = pass_ratio;
metrics.feasible_flag = feasible_flag;
metrics.dominant_fail_tag = local_theta_fail_tag(DG_rob, DA_rob, DT_rob, s9);
metrics.worst_case_id_DG = local_pick_case_id(case_table, 'DG', 'min');
metrics.worst_case_id_DA = local_pick_case_id(case_table, 'DA', 'min');
metrics.worst_case_id_DT = local_pick_case_id(case_table, 'DT', 'min');
metrics.n_case_total = n_case_total;
metrics.n_case_evaluated = n_case_evaluated;
metrics.failed_early = failed_early;
metrics.rank_score = local_rank_score(row, joint_margin, s9);
end

function s9 = local_pick_stage09(cfg_or_stage09)
if isstruct(cfg_or_stage09) && isfield(cfg_or_stage09, 'stage09')
    s9 = cfg_or_stage09.stage09;
else
    s9 = cfg_or_stage09;
end
end

function metrics = local_empty_metrics(row, s9, n_case_total, n_case_evaluated, failed_early)
metrics = struct();
metrics.DG_rob = NaN;
metrics.DA_rob = NaN;
metrics.DT_bar_rob = NaN;
metrics.DT_rob = NaN;
metrics.joint_margin = NaN;
metrics.pass_ratio = NaN;
metrics.feasible_flag = false;
metrics.dominant_fail_tag = "unknown";
metrics.worst_case_id_DG = "";
metrics.worst_case_id_DA = "";
metrics.worst_case_id_DT = "";
metrics.n_case_total = n_case_total;
metrics.n_case_evaluated = n_case_evaluated;
metrics.failed_early = failed_early;
metrics.rank_score = local_rank_score(row, NaN, s9);
end

function score = local_rank_score(row, joint_margin, s9)
switch string(s9.rank_rule)
    case "min_Ns_then_max_joint_margin"
        score = row.Ns - 1e-3 * joint_margin;
    otherwise
        score = row.Ns - 1e-3 * joint_margin;
end
end

function tag = local_theta_fail_tag(DG, DA, DT, s9)
g = DG < s9.require_DG_min;
a = DA < s9.require_DA_min;
t = DT < s9.require_DT_min;
tag = local_join_fail_tag(g, a, t);
end

function tag = local_join_fail_tag(g, a, t)
if ~(g || a || t)
    tag = "OK";
    return;
end

pieces = strings(0, 1);
if g, pieces(end + 1, 1) = "G"; end
if a, pieces(end + 1, 1) = "A"; end
if t, pieces(end + 1, 1) = "T"; end
tag = join(pieces, "");
tag = string(tag);
end

function cid = local_pick_case_id(case_table, metric_name, mode)
cid = "";
if ~istable(case_table) || height(case_table) < 1
    return;
end

x = case_table.(metric_name);
valid = isfinite(x);
if ~any(valid)
    return;
end

switch lower(string(mode))
    case "min"
        values = x;
        values(~valid) = inf;
        [~, idx] = min(values);
    case "max"
        values = x;
        values(~valid) = -inf;
        [~, idx] = max(values);
    otherwise
        error('Unsupported mode: %s', string(mode));
end

cid = case_table.case_id(idx);
end
