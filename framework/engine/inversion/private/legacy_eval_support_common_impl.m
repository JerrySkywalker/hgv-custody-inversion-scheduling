function out = legacy_eval_support_common_impl(mode, varargin)
%LEGACY_EVAL_SUPPORT_COMMON_IMPL Shared helpers for engine inversion bootstrap.

switch lower(string(mode))
    case "normalize_design_row"
        out = local_normalize_design_row(varargin{1});
    case "normalize_design_grid"
        out = local_normalize_design_grid(varargin{1});
    case "build_eval_context"
        out = local_build_eval_context(varargin{1}, varargin{2}, varargin{3});
    case "build_stage09_context"
        out = local_build_stage09_context(varargin{1}, varargin{2}, varargin{3}, varargin{4});
    case "get_design_id"
        out = local_get_design_id(varargin{1}, varargin{2});
    otherwise
        error('legacy_eval_support_common_impl:UnsupportedMode', ...
            'Unsupported mode: %s', string(mode));
end
end

function row = local_normalize_design_row(design_row)
if istable(design_row)
    if height(design_row) ~= 1
        error('legacy_eval_support_common_impl:InvalidRowTable', ...
            'Expected a single-row design table.');
    end
    row = table2struct(design_row);
else
    row = design_row;
end

required = {'h_km', 'i_deg', 'P', 'T', 'F'};
for k = 1:numel(required)
    name = required{k};
    if ~isfield(row, name)
        error('legacy_eval_support_common_impl:MissingField', ...
            'Design row is missing field "%s".', name);
    end
end

if ~isfield(row, 'Ns') || isempty(row.Ns) || ~isfinite(row.Ns)
    row.Ns = row.P * row.T;
end
end

function rows = local_normalize_design_grid(design_grid)
if istable(design_grid)
    rows = table2struct(design_grid);
elseif isstruct(design_grid)
    rows = design_grid;
else
    error('legacy_eval_support_common_impl:InvalidGridType', ...
        'design_grid must be a table or struct array.');
end

for k = 1:numel(rows)
    rows(k) = local_normalize_design_row(rows(k));
end
end

function eval_ctx = local_build_eval_context(trajs_in, cfg, eval_ctx_in)
if nargin < 3 || isempty(eval_ctx_in)
    eval_ctx_in = struct();
end

eval_ctx = eval_ctx_in;

if ~isfield(eval_ctx, 't_s_common') || isempty(eval_ctx.t_s_common)
    t_end_all = arrayfun(@(s) s.traj.t_s(end), trajs_in);
    t_max = max(t_end_all);
    dt = cfg.stage02.Ts_s;
    eval_ctx.t_s_common = (0:dt:t_max).';
else
    eval_ctx.t_s_common = eval_ctx.t_s_common(:);
end

if ~isfield(eval_ctx, 'hard_order') || isempty(eval_ctx.hard_order)
    eval_ctx.hard_order = (1:numel(trajs_in)).';
else
    eval_ctx.hard_order = eval_ctx.hard_order(:);
end
end

function design_id = local_get_design_id(row, idx)
if isfield(row, 'design_id') && ~isempty(row.design_id)
    design_id = char(string(row.design_id));
else
    design_id = sprintf('design_%03d', idx);
end
end

function eval_ctx = local_build_stage09_context(trajs_in, cfg, gamma_eff_scalar, eval_ctx_in)
if nargin < 4 || isempty(eval_ctx_in)
    eval_ctx_in = struct();
end

cfg = stage09_prepare_cfg(cfg);

eval_ctx = eval_ctx_in;
eval_ctx.cfg = cfg;
eval_ctx.gamma_eff_scalar = gamma_eff_scalar;

if ~isfield(eval_ctx, 't_s_common') || isempty(eval_ctx.t_s_common)
    t_end_all = arrayfun(@(s) s.traj.t_s(end), trajs_in);
    t_max = max(t_end_all);
    dt = cfg.stage02.Ts_s;
    eval_ctx.t_s_common = (0:dt:t_max).';
else
    eval_ctx.t_s_common = eval_ctx.t_s_common(:);
end

nCase = numel(trajs_in);
eval_ctx.nCase = nCase;

case_id = strings(nCase, 1);
family = strings(nCase, 1);
subfamily = strings(nCase, 1);
entry_id = nan(nCase, 1);
heading_offset_deg = nan(nCase, 1);

for k = 1:nCase
    case_id(k) = string(trajs_in(k).case.case_id);
    if isfield(trajs_in(k).case, 'family')
        family(k) = string(trajs_in(k).case.family);
    end
    if isfield(trajs_in(k).case, 'subfamily')
        subfamily(k) = string(trajs_in(k).case.subfamily);
    end
    if isfield(trajs_in(k).case, 'entry_id')
        entry_id(k) = trajs_in(k).case.entry_id;
    elseif isfield(trajs_in(k).case, 'entry_point_id')
        entry_id(k) = trajs_in(k).case.entry_point_id;
    end
    if isfield(trajs_in(k).case, 'heading_offset_deg')
        heading_offset_deg(k) = trajs_in(k).case.heading_offset_deg;
    end
end

eval_ctx.case_id = case_id;
eval_ctx.family = family;
eval_ctx.subfamily = subfamily;
eval_ctx.entry_id = entry_id;
eval_ctx.heading_offset_deg = heading_offset_deg;

if ~isfield(eval_ctx, 'hard_order') || isempty(eval_ctx.hard_order)
    eval_ctx.hard_order = (1:nCase).';
else
    eval_ctx.hard_order = eval_ctx.hard_order(:);
end
end
