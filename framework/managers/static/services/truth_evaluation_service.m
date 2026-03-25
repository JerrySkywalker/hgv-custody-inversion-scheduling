function truth_result = truth_evaluation_service(cfg, design_pool, task_family)
if nargin < 3
    error('truth_evaluation_service:InvalidInput', ...
        'cfg, design_pool, and task_family are required.');
end

rows = design_pool.design_table;

search_result = run_design_grid_search( ...
    rows, task_family, cfg.evaluator_mode, cfg.engine_cfg, struct( ...
        'gamma_eff_scalar', cfg.threshold.gamma_eff_scalar, ...
        'run_tag', local_run_tag(cfg), ...
        'source_profile', cfg.profile));

truth_table = local_normalize_truth_table(search_result.grid_table, cfg);
eval_rows = table2struct(truth_table);

truth_result = struct();
truth_result.rows = eval_rows;
truth_result.table = truth_table;
truth_result.row_count = numel(eval_rows);
truth_result.meta = search_result.meta;
truth_result.search_result = search_result;
end

function truth_table = local_normalize_truth_table(grid_table, cfg)
n = height(grid_table);

truth_table = table();
truth_table.design_id = string(grid_table.design_id);
truth_table.P = grid_table.P;
truth_table.T = grid_table.T;
truth_table.h_km = grid_table.h_km;
truth_table.i_deg = grid_table.i_deg;
truth_table.F = grid_table.F;
truth_table.Ns = grid_table.Ns;

truth_table.gamma_eff_scalar = repmat(cfg.threshold.gamma_eff_scalar, n, 1);
truth_table.gamma_source = repmat(string(cfg.threshold.gamma_source), n, 1);
truth_table.Tw_s = repmat(local_tw_value(cfg), n, 1);

truth_table.pass_ratio = grid_table.pass_ratio;
truth_table.rank_score = grid_table.rank_score;
truth_table.is_feasible = logical(grid_table.feasible_flag);
truth_table.joint_margin = grid_table.joint_margin;
truth_table.n_case_total = grid_table.n_case_total;
truth_table.n_case_evaluated = grid_table.n_case_evaluated;
truth_table.failed_early = grid_table.failed_early;

truth_table.geometry_margin = local_get_var(grid_table, 'DG_rob', NaN(n, 1));
truth_table.accuracy_margin = local_get_var(grid_table, 'DA_rob', NaN(n, 1));
truth_table.temporal_margin_bar = local_get_var(grid_table, 'DT_bar_rob', NaN(n, 1));
truth_table.temporal_margin = local_get_var(grid_table, 'DT_rob', NaN(n, 1));

truth_table.raw_DG_rob = truth_table.geometry_margin;
truth_table.raw_DA_rob = truth_table.accuracy_margin;
truth_table.raw_DT_bar_rob = truth_table.temporal_margin_bar;
truth_table.raw_DT_rob = truth_table.temporal_margin;
truth_table.raw_joint_margin = truth_table.joint_margin;
truth_table.raw_feasible_flag = grid_table.feasible_flag;

truth_table.worst_case_id_DG = local_get_string_var(grid_table, 'worst_case_id_DG', n);
truth_table.worst_case_id_DA = local_get_string_var(grid_table, 'worst_case_id_DA', n);
truth_table.worst_case_id_DT = local_get_string_var(grid_table, 'worst_case_id_DT', n);

if ismember('dominant_fail_tag', grid_table.Properties.VariableNames)
    truth_table.fail_reason = string(grid_table.dominant_fail_tag);
else
    truth_table.fail_reason = repmat("OK", n, 1);
    truth_table.fail_reason(~truth_table.is_feasible) = "G";
end
end

function run_tag = local_run_tag(cfg)
run_tag = 'static_manager';
if isfield(cfg, 'profile') && isfield(cfg.profile, 'name') && ~isempty(cfg.profile.name)
    run_tag = char(string(cfg.profile.name));
end
end

function v = local_tw_value(cfg)
if isfield(cfg.threshold, 'Tw_s') && ~isempty(cfg.threshold.Tw_s)
    v = cfg.threshold.Tw_s;
else
    v = cfg.engine_cfg.stage04.Tw_s;
end
end

function value = local_get_var(tbl, name, default_value)
if ismember(name, tbl.Properties.VariableNames)
    value = tbl.(name);
else
    value = default_value;
end
end

function value = local_get_string_var(tbl, name, n)
if ismember(name, tbl.Properties.VariableNames)
    value = string(tbl.(name));
else
    value = repmat("", n, 1);
end
end
