function out = stage14_scan_openD_raan_grid_legacy_prepivot_20260329(cfg, overrides)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
%STAGE14_SCAN_OPEND_RAAN_GRID_LEGACY_PREPIVOT_20260329
% Stage14 旧版探索归档（原 Stage14.1A）:
%   Minimal DG-only RAAN-expanded scan on (i, P, T, RAAN).
%
% Current scope:
%   - serial execution only
%   - no plots
%   - cache + csv export
%   - strict Stage05-compatible DG-only pass criterion
%
% Inputs:
%   cfg        : base config (optional)
%   overrides  : stage14 overrides (optional)
%
% Output:
%   out struct with fields:
%     cfg
%     grid
%     summary
%     files

startup();

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end
if nargin < 2 || isempty(overrides)
    overrides = struct();
end

cfg = stage14_default_config(cfg, overrides);
cfg.project_stage = 'stage14_scan_openD_raan_grid';
cfg = configure_stage_output_paths(cfg);

seed_rng(cfg.random.seed);
ensure_dir(cfg.paths.logs);
ensure_dir(cfg.paths.cache);
ensure_dir(cfg.paths.tables);

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
log_file = fullfile(cfg.paths.logs, sprintf('stage14_scan_openD_raan_grid_%s.log', timestamp));
log_fid = fopen(log_file, 'w');
if log_fid < 0
    error('Failed to open log file: %s', log_file);
end
cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

log_msg(log_fid, 'INFO', 'Stage14.1A started.');

% ------------------------------------------------------------
% Load Stage04 gamma_req
% ------------------------------------------------------------
[S4, stage04_file, gamma_req] = local_load_stage04_gamma(cfg, log_fid);
cfg.stage04.gamma_req = gamma_req;

% ------------------------------------------------------------
% Load Stage02 nominal family
% ------------------------------------------------------------
[S2, stage02_file, trajs_nominal] = local_load_stage02_nominal(cfg, log_fid); %#ok<NASGU>
if isfinite(cfg.stage14.case_limit) && cfg.stage14.case_limit < numel(trajs_nominal)
    trajs_nominal = trajs_nominal(1:cfg.stage14.case_limit);
    log_msg(log_fid, 'INFO', 'Applied case_limit: %d', numel(trajs_nominal));
end

% ------------------------------------------------------------
% Hard-case-first ordering from Stage04 nominal results
% ------------------------------------------------------------
hard_order = local_build_hard_order(S4, trajs_nominal, cfg);
eval_context = local_prepare_eval_context(trajs_nominal, cfg);

% ------------------------------------------------------------
% Build Stage14 grid
% ------------------------------------------------------------
grid = build_stage14_search_grid(cfg);
grid.gamma_req(:) = gamma_req;
nGrid = height(grid);

log_msg(log_fid, 'INFO', 'Stage14 grid size: %d', nGrid);
log_msg(log_fid, 'INFO', 'Nominal family size: %d', numel(trajs_nominal));

t_all = tic;
for ig = 1:nGrid
    row = grid(ig, :);
    result = evaluate_single_layer_walker_stage14(row, trajs_nominal, gamma_req, cfg, hard_order, eval_context);
    grid = local_apply_result_to_grid(grid, ig, result);

    if mod(ig, cfg.stage14.progress_every) == 0 || ig == nGrid
        log_msg(log_fid, 'INFO', ...
            '[%d/%d] i=%.1f, P=%d, T=%d, RAAN=%.1f, Ns=%d, D_G_min=%.6f, pass_ratio=%.6f, feasible=%d, n_eval=%d, early=%d', ...
            ig, nGrid, row.i_deg, row.P, row.T, row.RAAN_deg, row.Ns, ...
            result.D_G_min, result.pass_ratio, logical(result.feasible_flag), ...
            result.n_case_evaluated, logical(result.failed_early));
    end
end
dt_all = toc(t_all);

summary = local_build_summary(grid, cfg, stage02_file, stage04_file, gamma_req, dt_all);

files = struct();
files.log_file = log_file;
files.cache_file = '';
files.table_file = '';

out = struct();
out.cfg = cfg;
out.grid = grid;
out.summary = summary;
out.files = files;

if cfg.stage14.save_table
    files.table_file = fullfile(cfg.paths.tables, sprintf('stage14_grid_%s.csv', timestamp));
    writetable(grid, files.table_file);
    log_msg(log_fid, 'INFO', 'Saved grid csv: %s', files.table_file);
end

if cfg.stage14.save_cache
    files.cache_file = fullfile(cfg.paths.cache, sprintf('stage14_scan_openD_raan_grid_%s.mat', timestamp));
    out.files = files;
    save(files.cache_file, 'out', '-v7.3');
    log_msg(log_fid, 'INFO', 'Saved cache: %s', files.cache_file);
else
    out.files = files;
end

log_msg(log_fid, 'INFO', 'Stage14.1A finished in %.3f s.', dt_all);
end

function [S4, stage04_file, gamma_req] = local_load_stage04_gamma(cfg, log_fid)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
listing = find_stage_cache_files(cfg.paths.cache, 'stage04_window_worstcase_*.mat');
assert(~isempty(listing), 'No Stage04 cache found. Please run stage04_window_worstcase first.');

[~, idx] = max([listing.datenum]);
stage04_file = fullfile(listing(idx).folder, listing(idx).name);
S4 = load(stage04_file);

assert(isfield(S4, 'out'), 'Invalid Stage04 cache: missing out');
assert(isfield(S4.out, 'summary') && isfield(S4.out.summary, 'gamma_meta'), ...
    'Stage04 cache missing summary.gamma_meta');

gamma_req = S4.out.summary.gamma_meta.gamma_req;
log_msg(log_fid, 'INFO', 'Loaded Stage04 cache: %s', stage04_file);
log_msg(log_fid, 'INFO', 'Inherited gamma_req = %.6e', gamma_req);
end

function [S2, stage02_file, trajs_nominal] = local_load_stage02_nominal(cfg, log_fid)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
listing = find_stage_cache_files(cfg.paths.cache, 'stage02_hgv_nominal_*.mat');
assert(~isempty(listing), 'No Stage02 cache found. Please run stage02_hgv_nominal first.');

[~, idx] = max([listing.datenum]);
stage02_file = fullfile(listing(idx).folder, listing(idx).name);
S2 = load(stage02_file);

assert(isfield(S2, 'out') && isfield(S2.out, 'trajbank') && isfield(S2.out.trajbank, 'nominal'), ...
    'Invalid Stage02 cache: missing out.trajbank.nominal');

trajs_nominal = S2.out.trajbank.nominal;
log_msg(log_fid, 'INFO', 'Loaded Stage02 cache: %s', stage02_file);
log_msg(log_fid, 'INFO', 'Nominal family size: %d', numel(trajs_nominal));
end

function hard_order = local_build_hard_order(S4, trajs_nominal, cfg)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
hard_order = (1:numel(trajs_nominal)).';

if ~cfg.stage14.hard_case_first
    return;
end

try
    if isfield(S4.out.summary, 'margin') && isfield(S4.out.summary.margin, 'case_table')
        tab4 = S4.out.summary.margin.case_table;
    elseif isfield(S4.out.summary, 'spectrum') && isfield(S4.out.summary.spectrum, 'case_table')
        tab4 = S4.out.summary.spectrum.case_table;
    else
        tab4 = table();
    end

    if isempty(tab4)
        return;
    end

    traj_case_ids = strings(numel(trajs_nominal),1);
    for k = 1:numel(trajs_nominal)
        traj_case_ids(k) = string(trajs_nominal(k).case.case_id);
    end

    if ismember('case_ids', tab4.Properties.VariableNames) && ...
       ismember('D_G', tab4.Properties.VariableNames) && ...
       ismember('families', tab4.Properties.VariableNames)

        nominal_rows = strcmp(string(tab4.families), "nominal");
        tab_nom = tab4(nominal_rows, :);
        [~, ord] = sort(tab_nom.D_G, 'ascend');

        hard_ids = string(tab_nom.case_ids(ord));
        hard_order_tmp = nan(numel(hard_ids),1);

        for k = 1:numel(hard_ids)
            idxk = find(traj_case_ids == hard_ids(k), 1);
            if ~isempty(idxk)
                hard_order_tmp(k) = idxk;
            end
        end

        hard_order_tmp = hard_order_tmp(isfinite(hard_order_tmp));
        if numel(hard_order_tmp) == numel(trajs_nominal)
            hard_order = hard_order_tmp;
        end
    end
catch
    hard_order = (1:numel(trajs_nominal)).';
end
end

function eval_context = local_prepare_eval_context(trajs_nominal, cfg)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
t_end_all = arrayfun(@(s) s.traj.t_s(end), trajs_nominal);
t_max = max(t_end_all);
dt = cfg.stage02.Ts_s;

eval_context = struct();
eval_context.t_s_common = (0:dt:t_max).';
end

function grid = local_apply_result_to_grid(grid, idx, result)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
grid.is_evaluated(idx) = true;
grid.lambda_worst_min(idx) = result.lambda_worst_min;
grid.lambda_worst_mean(idx) = result.lambda_worst_mean;
grid.D_G_min(idx) = result.D_G_min;
grid.D_G_mean(idx) = result.D_G_mean;
grid.pass_ratio(idx) = result.pass_ratio;
grid.feasible_flag(idx) = logical(result.feasible_flag);
grid.rank_score(idx) = result.rank_score;
grid.n_case_evaluated(idx) = result.n_case_evaluated;
grid.failed_early(idx) = logical(result.failed_early);
end

function summary = local_build_summary(grid, cfg, stage02_file, stage04_file, gamma_req, elapsed_s)
% Stage14 legacy archive note:
% This file was renamed in-place on 20260329 after the Stage14 line of work pivoted back to the Stage05-upgraded mainline.
% Keep logic frozen for comparison, reproduction, and later Stage14.4/14.5 reuse.
feasible_rows = grid.feasible_flag;
n_feasible = sum(feasible_rows);
n_total = height(grid);

summary = struct();
summary.stage_name = cfg.stage14.stage_name;
summary.mode = cfg.stage14.mode;
summary.family_scope = cfg.stage14.family_scope;
summary.gamma_source = cfg.stage14.gamma_source;
summary.gamma_req = gamma_req;
summary.stage02_file = stage02_file;
summary.stage04_file = stage04_file;
summary.n_grid = n_total;
summary.n_feasible = n_feasible;
summary.feasible_ratio = n_feasible / max(n_total, 1);
summary.elapsed_s = elapsed_s;
summary.i_grid_deg = cfg.stage14.i_grid_deg;
summary.P_grid = cfg.stage14.P_grid;
summary.T_grid = cfg.stage14.T_grid;
summary.RAAN_scan_deg = cfg.stage14.RAAN_scan_deg;

if any(feasible_rows)
    feasible_grid = grid(feasible_rows, :);
    [~, idx_best] = min(feasible_grid.rank_score);
    summary.best_feasible_row = feasible_grid(idx_best, :);
else
    summary.best_feasible_row = table();
end
end

