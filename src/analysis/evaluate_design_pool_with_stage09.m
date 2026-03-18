function out = evaluate_design_pool_with_stage09(cfg, design_pool_table, family_mode, overrides)
%EVALUATE_DESIGN_POOL_WITH_STAGE09 Evaluate an explicit design pool with the Stage09 truth kernel.

startup();

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end
if nargin < 2 || ~istable(design_pool_table)
    error('evaluate_design_pool_with_stage09 requires cfg and design_pool_table.');
end
if nargin < 3 || isempty(family_mode)
    family_mode = 'joint';
end
if nargin < 4 || isempty(overrides)
    overrides = struct();
end

cfg_stage = stage09_prepare_cfg(cfg);
cfg_stage.stage09.scheme_type = 'custom';
cfg_stage.stage09.write_csv = false;
cfg_stage.stage09.save_cache_file = false;
cfg_stage.stage09.save_eval_bank = false;
cfg_stage.stage09.make_plot = false;
cfg_stage.stage09.disable_progress = true;
cfg_stage.stage09.use_early_stop = false;
cfg_stage.stage09.use_parallel = true;
cfg_stage.stage09.save_case_window_bank = false;
cfg_stage.stage09.casebank_mode = 'custom';
cfg_stage.stage09.casebank_include_nominal = false;
cfg_stage.stage09.casebank_include_heading = false;
cfg_stage.stage09.casebank_include_critical = false;

heading_subset_max = cfg_stage.stage09.casebank_heading_subset_max;
if isfield(overrides, 'heading_subset_max') && ~isempty(overrides.heading_subset_max)
    heading_subset_max = overrides.heading_subset_max;
end
cfg_stage.stage09.casebank_heading_subset_max = heading_subset_max;
cfg_stage.stage09.run_tag = sprintf('stage09_pool_%s', char(string(family_mode)));
if isfield(overrides, 'use_parallel') && ~isempty(overrides.use_parallel)
    cfg_stage.stage09.use_parallel = logical(overrides.use_parallel);
end
if isfield(overrides, 'save_case_window_bank') && ~isempty(overrides.save_case_window_bank)
    cfg_stage.stage09.save_case_window_bank = logical(overrides.save_case_window_bank);
end

switch lower(char(string(family_mode)))
    case 'joint'
        cfg_stage.stage09.casebank_include_nominal = true;
        cfg_stage.stage09.casebank_include_heading = true;
        cfg_stage.stage09.casebank_include_critical = true;
    case 'nominal'
        cfg_stage.stage09.casebank_include_nominal = true;
    case 'heading'
        cfg_stage.stage09.casebank_include_heading = true;
    case 'critical'
        cfg_stage.stage09.casebank_include_critical = true;
    otherwise
        error('Unsupported family_mode: %s', string(family_mode));
end

if isempty(design_pool_table)
    empty_table = design_pool_table;
    out = struct();
    out.cfg = cfg_stage;
    out.family_name = string(family_mode);
    out.design_pool_table = empty_table;
    out.full_theta_table = empty_table;
    out.feasible_theta_table = empty_table;
    out.infeasible_theta_table = empty_table;
    out.fail_partition_table = table();
    out.summary_table = table();
    out.summary = struct('family_name', string(family_mode), 'num_total', 0, 'num_feasible', 0, ...
        'feasible_ratio', 0, 'Ns_min_feasible', NaN, 'best_joint_margin', NaN, ...
        'casebank_size', 0, 'config_signature', "");
    out.casebank = repmat(struct(), 0, 1);
    out.result_bank = repmat(struct(), 0, 1);
    return;
end

design_pool_table = local_prepare_design_pool_table(design_pool_table);
trajs_in = build_stage09_casebank(cfg_stage);
gamma_eff_scalar = 1.0;
eval_ctx = build_stage09_eval_context(trajs_in, cfg_stage, gamma_eff_scalar);
row_bank = table2struct(design_pool_table(:, {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'}));

n_theta = numel(row_bank);
result_cell = cell(n_theta, 1);
use_parallel = local_enable_parallel(cfg_stage);
if use_parallel
    parfor idx = 1:n_theta
        result_cell{idx} = evaluate_single_layer_walker_stage09(row_bank(idx), trajs_in, gamma_eff_scalar, cfg_stage, eval_ctx);
    end
else
    for idx = 1:n_theta
        result_cell{idx} = evaluate_single_layer_walker_stage09(row_bank(idx), trajs_in, gamma_eff_scalar, cfg_stage, eval_ctx);
    end
end
result_bank = vertcat(result_cell{:});

S = summarize_stage09_grid(result_bank, cfg_stage);
full_theta_table = local_normalize_theta_table(S.full_theta_table);
feasible_theta_table = local_normalize_theta_table(S.feasible_theta_table);
infeasible_theta_table = local_normalize_theta_table(S.infeasible_theta_table);

out = struct();
out.cfg = cfg_stage;
out.family_name = string(family_mode);
out.design_pool_table = design_pool_table;
out.full_theta_table = full_theta_table;
out.feasible_theta_table = feasible_theta_table;
out.infeasible_theta_table = infeasible_theta_table;
out.fail_partition_table = S.fail_partition_table;
out.summary_table = S.summary_table;
out.summary = local_build_summary(string(family_mode), full_theta_table, feasible_theta_table, trajs_in, cfg_stage);
out.casebank = trajs_in;
out.result_bank = result_bank;
end

function T = local_prepare_design_pool_table(T)
required = {'h_km', 'i_deg', 'P', 'T', 'F'};
missing = setdiff(required, T.Properties.VariableNames);
if ~isempty(missing)
    error('design_pool_table missing variables: %s', strjoin(missing, ', '));
end
if ~ismember('Ns', T.Properties.VariableNames)
    T.Ns = T.P .* T.T;
end
T = sortrows(T, {'Ns', 'h_km', 'i_deg', 'P', 'T'}, {'ascend', 'ascend', 'ascend', 'ascend', 'ascend'});
end

function T = local_normalize_theta_table(T)
if isempty(T)
    return;
end
if ~ismember('DG_worst', T.Properties.VariableNames) && ismember('DG_rob', T.Properties.VariableNames)
    T.DG_worst = T.DG_rob;
end
if ~ismember('DA_worst', T.Properties.VariableNames) && ismember('DA_rob', T.Properties.VariableNames)
    T.DA_worst = T.DA_rob;
end
if ~ismember('DT_bar_worst', T.Properties.VariableNames) && ismember('DT_bar_rob', T.Properties.VariableNames)
    T.DT_bar_worst = T.DT_bar_rob;
end
if ~ismember('DT_worst', T.Properties.VariableNames) && ismember('DT_rob', T.Properties.VariableNames)
    T.DT_worst = T.DT_rob;
end
if ~ismember('feasible_flag', T.Properties.VariableNames) && ismember('joint_feasible', T.Properties.VariableNames)
    T.feasible_flag = T.joint_feasible;
end
end

function summary = local_build_summary(family_name, full_theta_table, feasible_theta_table, trajs_in, cfg_stage)
num_total = height(full_theta_table);
num_feasible = height(feasible_theta_table);
feasible_ratio = 0;
if num_total > 0
    feasible_ratio = num_feasible / num_total;
end

Ns_min_feasible = NaN;
best_joint_margin = NaN;
if num_feasible > 0
    Ns_min_feasible = min(feasible_theta_table.Ns);
    best_joint_margin = max(feasible_theta_table.joint_margin);
end

summary = struct();
summary.family_name = family_name;
summary.num_total = num_total;
summary.num_feasible = num_feasible;
summary.feasible_ratio = feasible_ratio;
summary.Ns_min_feasible = Ns_min_feasible;
summary.best_joint_margin = best_joint_margin;
summary.casebank_size = numel(trajs_in);
summary.config_signature = local_casebank_signature(cfg_stage, family_name);
end

function signature = local_casebank_signature(cfg_stage, family_name)
signature = sprintf('family=%s|heading_subset_max=%g|pool_size=%s', ...
    char(family_name), ...
    cfg_stage.stage09.casebank_heading_subset_max, ...
    char(string(cfg_stage.stage09.casebank_mode)));
end

function use_parallel = local_enable_parallel(cfg_stage)
use_parallel = false;
if ~isfield(cfg_stage.stage09, 'use_parallel') || ~cfg_stage.stage09.use_parallel
    return;
end

requested_profile = string(cfg_stage.stage09.parallel_pool_profile);
if requested_profile == ""
    requested_profile = "threads";
end

try
    pool = gcp('nocreate');
    if isempty(pool)
        pool = ensure_parallel_pool(char(requested_profile), cfg_stage.stage09.parallel_num_workers);
    end
    use_parallel = ~isempty(pool);
catch
    use_parallel = false;
end
end
