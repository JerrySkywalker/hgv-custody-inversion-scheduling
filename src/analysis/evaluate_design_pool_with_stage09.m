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
if isfield(overrides, 'enable_checkpoint') && ~isempty(overrides.enable_checkpoint)
    cfg_stage.stage09.enable_checkpoint = logical(overrides.enable_checkpoint);
end
if isfield(overrides, 'checkpoint_every_n') && ~isempty(overrides.checkpoint_every_n)
    cfg_stage.stage09.checkpoint_every_n = overrides.checkpoint_every_n;
end
if isfield(overrides, 'checkpoint_dir') && ~isempty(overrides.checkpoint_dir)
    cfg_stage.stage09.checkpoint_dir = overrides.checkpoint_dir;
end
if isfield(overrides, 'resume_from_checkpoint') && ~isempty(overrides.resume_from_checkpoint)
    cfg_stage.stage09.resume_from_checkpoint = logical(overrides.resume_from_checkpoint);
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
t_casebank = tic;
trajs_in = build_stage09_casebank(cfg_stage);
t_casebank_s = toc(t_casebank);
gamma_eff_scalar = 1.0;
t_eval_ctx = tic;
eval_ctx = build_stage09_eval_context(trajs_in, cfg_stage, gamma_eff_scalar);
t_eval_ctx_s = toc(t_eval_ctx);
row_bank = table2struct(design_pool_table(:, {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'}));

n_theta = numel(row_bank);
result_cell = cell(n_theta, 1);
use_parallel = local_enable_parallel(cfg_stage);
checkpoint_state = local_prepare_checkpoint_state(cfg_stage, family_mode, design_pool_table, n_theta);
if checkpoint_state.enabled && checkpoint_state.resume_used
    result_cell = checkpoint_state.result_cell;
end
completed_mask = checkpoint_state.completed_mask;
pending_idx = find(~completed_mask);
if checkpoint_state.enabled
    fprintf('[MB][%s] checkpoint %s | completed %d/%d designs.\n', ...
        char(string(family_mode)), char(checkpoint_state.checkpoint_file), sum(completed_mask), n_theta);
end
t_design_eval = tic;
[result_cell, completed_mask, checkpoint_state] = local_evaluate_design_chunks( ...
    row_bank, result_cell, completed_mask, pending_idx, trajs_in, gamma_eff_scalar, cfg_stage, eval_ctx, use_parallel, checkpoint_state, family_mode);
if ~all(completed_mask)
    error('evaluate_design_pool_with_stage09 did not complete all designs.');
end
t_design_eval_s = toc(t_design_eval);
result_bank = vertcat(result_cell{:});
if checkpoint_state.enabled
    checkpoint_state.timing.total_design_eval_completed_s = checkpoint_state.timing.total_design_eval_completed_s + t_design_eval_s;
    checkpoint_state.completed_mask = completed_mask;
    checkpoint_state.result_cell = result_cell;
    checkpoint_state.completed = true;
    checkpoint_state = local_save_checkpoint(checkpoint_state);
end

S = summarize_stage09_grid(result_bank, cfg_stage);
full_theta_table = local_attach_design_pool_metadata(local_normalize_theta_table(S.full_theta_table), design_pool_table);
feasible_theta_table = local_attach_design_pool_metadata(local_normalize_theta_table(S.feasible_theta_table), design_pool_table);
infeasible_theta_table = local_attach_design_pool_metadata(local_normalize_theta_table(S.infeasible_theta_table), design_pool_table);

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
out.timing = struct( ...
    'casebank_build_s', t_casebank_s, ...
    'eval_context_build_s', t_eval_ctx_s, ...
    'design_eval_total_s', t_design_eval_s, ...
    'design_eval_mean_s', local_safe_divide(t_design_eval_s, n_theta), ...
    'use_parallel', use_parallel, ...
    'enable_checkpoint', checkpoint_state.enabled, ...
    'resume_used', checkpoint_state.resume_used, ...
    'checkpoint_file', string(checkpoint_state.checkpoint_file), ...
    'checkpoint_save_count', checkpoint_state.save_count, ...
    'checkpoint_save_total_s', checkpoint_state.timing.checkpoint_save_total_s, ...
    'checkpoint_save_mean_s', local_safe_divide(checkpoint_state.timing.checkpoint_save_total_s, checkpoint_state.save_count), ...
    'checkpoint_overhead_fraction', local_safe_divide(checkpoint_state.timing.checkpoint_save_total_s, t_design_eval_s + checkpoint_state.timing.checkpoint_save_total_s), ...
    'completed_ratio', local_safe_divide(sum(completed_mask), n_theta), ...
    'completed_design_count', sum(completed_mask));
out.summary.timing = out.timing;
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

function value = local_safe_divide(a, b)
if b == 0
    value = 0;
else
    value = a / b;
end
end

function T = local_attach_design_pool_metadata(T, design_pool_table)
if isempty(T) || isempty(design_pool_table)
    return;
end

meta_vars = intersect({'slice_source', 'support_sources', 'num_support_sources'}, design_pool_table.Properties.VariableNames, 'stable');
if isempty(meta_vars)
    return;
end

keys = {'h_km', 'i_deg', 'P', 'T', 'F'};
[tf, loc] = ismember(T(:, keys), design_pool_table(:, keys), 'rows');
for idx = 1:numel(meta_vars)
    if isstring(design_pool_table.(meta_vars{idx}))
        values = strings(height(T), 1);
    elseif isnumeric(design_pool_table.(meta_vars{idx}))
        values = nan(height(T), 1);
    else
        values = repmat(missing, height(T), 1);
    end
    values(tf) = design_pool_table.(meta_vars{idx})(loc(tf));
    T.(meta_vars{idx}) = values;
end
end

function checkpoint_state = local_prepare_checkpoint_state(cfg_stage, family_mode, design_pool_table, n_theta)
checkpoint_state = struct();
checkpoint_state.enabled = strcmpi(char(string(family_mode)), 'joint') && ...
    isfield(cfg_stage.stage09, 'enable_checkpoint') && logical(cfg_stage.stage09.enable_checkpoint);
checkpoint_state.resume_used = false;
checkpoint_state.result_cell = cell(n_theta, 1);
checkpoint_state.completed_mask = false(n_theta, 1);
checkpoint_state.checkpoint_file = "";
checkpoint_state.save_count = 0;
checkpoint_state.completed = false;
checkpoint_state.timing = struct('checkpoint_save_total_s', 0, 'total_design_eval_completed_s', 0);
checkpoint_state.design_keys = design_pool_table(:, {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'});
checkpoint_state.family_name = string(family_mode);
checkpoint_state.run_tag = string(cfg_stage.stage09.run_tag);

if ~checkpoint_state.enabled
    return;
end

checkpoint_dir = char(string(cfg_stage.stage09.checkpoint_dir));
if ~exist(checkpoint_dir, 'dir')
    mkdir(checkpoint_dir);
end
checkpoint_state.checkpoint_file = fullfile(checkpoint_dir, ...
    sprintf('%s_%s_checkpoint.mat', local_make_safe_token(cfg_stage.stage09.run_tag), local_make_safe_token(family_mode)));

if isfield(cfg_stage.stage09, 'resume_from_checkpoint') && cfg_stage.stage09.resume_from_checkpoint && ...
        exist(checkpoint_state.checkpoint_file, 'file') == 2
    data = load(checkpoint_state.checkpoint_file, 'checkpoint_payload');
    if isfield(data, 'checkpoint_payload') && local_checkpoint_matches(data.checkpoint_payload, checkpoint_state)
        checkpoint_state.result_cell = data.checkpoint_payload.result_cell;
        checkpoint_state.completed_mask = logical(data.checkpoint_payload.completed_mask);
        checkpoint_state.save_count = data.checkpoint_payload.save_count;
        checkpoint_state.timing = data.checkpoint_payload.timing;
        checkpoint_state.resume_used = true;
        checkpoint_state.completed = isfield(data.checkpoint_payload, 'completed') && logical(data.checkpoint_payload.completed);
    end
end
end

function [result_cell, completed_mask, checkpoint_state] = local_evaluate_design_chunks(row_bank, result_cell, completed_mask, pending_idx, trajs_in, gamma_eff_scalar, cfg_stage, eval_ctx, use_parallel, checkpoint_state, family_mode)
if isempty(pending_idx)
    return;
end

chunk_size = max(1, round(cfg_stage.stage09.checkpoint_every_n));
t_progress = tic;
for start_idx = 1:chunk_size:numel(pending_idx)
    chunk = pending_idx(start_idx:min(start_idx + chunk_size - 1, numel(pending_idx)));
    chunk_rows = row_bank(chunk);
    chunk_result = cell(numel(chunk), 1);
    if use_parallel && numel(chunk) > 1
        parfor local_idx = 1:numel(chunk)
            chunk_result{local_idx} = evaluate_single_layer_walker_stage09(chunk_rows(local_idx), trajs_in, gamma_eff_scalar, cfg_stage, eval_ctx);
        end
    else
        for local_idx = 1:numel(chunk)
            chunk_result{local_idx} = evaluate_single_layer_walker_stage09(chunk_rows(local_idx), trajs_in, gamma_eff_scalar, cfg_stage, eval_ctx);
        end
    end

    for local_idx = 1:numel(chunk)
        design_idx = chunk(local_idx);
        result_cell{design_idx} = chunk_result{local_idx};
        completed_mask(design_idx) = true;
    end

    elapsed_s = toc(t_progress);
    completed_count = sum(completed_mask);
    remaining_count = numel(row_bank) - completed_count;
    mean_s = local_safe_divide(elapsed_s, max(1, completed_count - (sum(checkpoint_state.completed_mask))));
    eta_s = remaining_count * mean_s;
    fprintf('[MB][%s] completed %d/%d designs (%.1f%%), elapsed %.1fs, ETA %.1fs.\n', ...
        char(string(family_mode)), completed_count, numel(row_bank), 100 * completed_count / numel(row_bank), elapsed_s, eta_s);

    if checkpoint_state.enabled
        checkpoint_state.result_cell = result_cell;
        checkpoint_state.completed_mask = completed_mask;
        checkpoint_state.completed = all(completed_mask);
        checkpoint_state = local_save_checkpoint(checkpoint_state);
    end
end
end

function checkpoint_state = local_save_checkpoint(checkpoint_state)
if ~checkpoint_state.enabled
    return;
end
t_save = tic;
checkpoint_payload = struct();
checkpoint_payload.version = 1;
checkpoint_payload.family_name = checkpoint_state.family_name;
checkpoint_payload.run_tag = checkpoint_state.run_tag;
checkpoint_payload.design_keys = checkpoint_state.design_keys;
checkpoint_payload.result_cell = checkpoint_state.result_cell;
checkpoint_payload.completed_mask = checkpoint_state.completed_mask;
checkpoint_payload.save_count = checkpoint_state.save_count + 1;
checkpoint_payload.completed = checkpoint_state.completed;
checkpoint_payload.timing = checkpoint_state.timing;
checkpoint_payload.saved_at = string(datetime('now'));
save(checkpoint_state.checkpoint_file, 'checkpoint_payload', '-v7.3');
save_time_s = toc(t_save);
checkpoint_state.save_count = checkpoint_payload.save_count;
checkpoint_state.timing.checkpoint_save_total_s = checkpoint_state.timing.checkpoint_save_total_s + save_time_s;
fprintf('[MB][joint] checkpoint saved (%d) in %.2fs -> %s\n', checkpoint_state.save_count, save_time_s, checkpoint_state.checkpoint_file);
end

function tf = local_checkpoint_matches(payload, checkpoint_state)
tf = false;
required = {'family_name', 'run_tag', 'design_keys', 'result_cell', 'completed_mask'};
if ~all(isfield(payload, required))
    return;
end
tf = string(payload.family_name) == checkpoint_state.family_name && ...
    string(payload.run_tag) == checkpoint_state.run_tag && ...
    isequal(payload.design_keys, checkpoint_state.design_keys) && ...
    numel(payload.result_cell) == numel(checkpoint_state.result_cell) && ...
    numel(payload.completed_mask) == numel(checkpoint_state.completed_mask);
end

function token = local_make_safe_token(value)
token = regexprep(char(string(value)), '[^A-Za-z0-9_-]', '_');
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
