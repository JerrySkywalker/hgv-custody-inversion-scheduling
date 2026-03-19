function inputs = load_mb_stage05_semantic_inputs(opts)
%LOAD_MB_STAGE05_SEMANTIC_INPUTS Load or prepare the nominal-family inputs used by Stage05 semantics.

startup();

if nargin < 1 || isempty(opts)
    opts = struct();
end

cfg = default_params();
cfg.stage01.make_plot = false;
cfg.stage02.make_plot = false;
cfg.stage02.make_plot_3d = false;
cfg.stage03.make_plot = false;
cfg.stage04.make_plot = false;

use_parallel = local_getfield_or(opts, 'use_parallel', true);
force_rebuild = local_getfield_or(opts, 'force_rebuild', false);
run_mode = local_run_mode(use_parallel);

stage02_out = [];
stage04_out = [];
stage02_file = "";
stage04_file = "";

if ~force_rebuild
    [stage02_out, stage02_file] = local_try_load_stage_output(cfg, 'stage02_hgv_nominal_*.mat');
    [stage04_out, stage04_file] = local_try_load_stage_output(cfg, 'stage04_window_worstcase_*.mat');
end

if isempty(stage02_out) || isempty(stage04_out)
    stage02_out = stage02_hgv_nominal(cfg, struct('mode', run_mode));
    stage03_visibility_pipeline(cfg, struct('mode', run_mode));
    stage04_out = stage04_window_worstcase(cfg, struct('mode', run_mode));
    stage02_file = string(local_getfield_or(stage02_out, 'cache_file', ""));
    [~, stage04_file] = local_try_load_stage_output(cfg, 'stage04_window_worstcase_*.mat');
end

trajs_nominal = stage02_out.trajbank.nominal;
gamma_req = stage04_out.summary.gamma_meta.gamma_req;
hard_order = local_build_hard_order(trajs_nominal, stage04_out);

t_end_all = arrayfun(@(s) s.traj.t_s(end), trajs_nominal);
eval_context = struct();
eval_context.t_s_common = (0:cfg.stage02.Ts_s:max(t_end_all)).';

inputs = struct();
inputs.cfg = cfg;
inputs.trajs_nominal = trajs_nominal;
inputs.gamma_req = gamma_req;
inputs.hard_order = hard_order;
inputs.eval_context = eval_context;
inputs.stage02_file = string(stage02_file);
inputs.stage04_file = string(stage04_file);
inputs.use_parallel = use_parallel;
end

function [out_struct, cache_file] = local_try_load_stage_output(cfg, pattern)
out_struct = [];
cache_file = "";
listing = find_stage_cache_files(cfg, pattern);
if isempty(listing)
    return;
end

[~, idx_latest] = max([listing.datenum]);
cache_file = fullfile(listing(idx_latest).folder, listing(idx_latest).name);
tmp = load(cache_file);
if isfield(tmp, 'out')
    out_struct = tmp.out;
end
end

function hard_order = local_build_hard_order(trajs_nominal, stage04_out)
hard_order = (1:numel(trajs_nominal)).';
if ~isfield(stage04_out, 'summary') || ~isfield(stage04_out.summary, 'margin')
    return;
end

margin = stage04_out.summary.margin;
if ~isfield(margin, 'case_table')
    return;
end

tab4 = margin.case_table;
if isempty(tab4)
    return;
end

required_vars = {'case_ids', 'D_G', 'families'};
if ~all(ismember(required_vars, tab4.Properties.VariableNames))
    return;
end

traj_case_ids = strings(numel(trajs_nominal), 1);
for idx = 1:numel(trajs_nominal)
    traj_case_ids(idx) = string(trajs_nominal(idx).case.case_id);
end

nominal_rows = strcmp(string(tab4.families), "nominal");
tab_nom = tab4(nominal_rows, :);
if isempty(tab_nom)
    return;
end

[~, ord] = sort(tab_nom.D_G, 'ascend');
hard_ids = string(tab_nom.case_ids(ord));
hard_order_tmp = nan(numel(hard_ids), 1);
for idx = 1:numel(hard_ids)
    hit = find(traj_case_ids == hard_ids(idx), 1);
    if ~isempty(hit)
        hard_order_tmp(idx) = hit;
    end
end

hard_order_tmp = hard_order_tmp(isfinite(hard_order_tmp));
if numel(hard_order_tmp) == numel(trajs_nominal)
    hard_order = hard_order_tmp;
end
end

function run_mode = local_run_mode(use_parallel)
if use_parallel
    run_mode = 'parallel';
else
    run_mode = 'serial';
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
