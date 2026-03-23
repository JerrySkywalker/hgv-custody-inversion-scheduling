function [target_ns_grid, grid_meta] = build_mb_global_full_dense_ns_grid(search_domain, source_table, ns_field, options)
%BUILD_MB_GLOBAL_FULL_DENSE_NS_GRID Build the dense Ns grid for a globalFullDense pass-ratio view.

if nargin < 1 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 2 || isempty(source_table)
    source_table = table();
end
if nargin < 3 || strlength(string(ns_field)) == 0
    ns_field = 'Ns';
end
if nargin < 4 || isempty(options)
    options = struct();
end

ns_field = char(string(ns_field));
initial_range = reshape(local_getfield_or(search_domain, 'Ns_initial_range', [NaN, NaN, NaN]), 1, []);
source_ns = [];
if istable(source_table) && ismember(ns_field, source_table.Properties.VariableNames)
    source_ns = unique(source_table.(ns_field), 'sorted');
    source_ns = source_ns(isfinite(source_ns));
end

origin_mode = string(local_getfield_or(options, 'origin_mode', "initial_ns_min"));
initial_ns_min = local_first_finite( ...
    local_getfield_or(options, 'initial_ns_min', NaN), ...
    local_getfield_or(search_domain, 'history_ns_min', NaN), ...
    local_pick_initial(initial_range, 1), ...
    local_min_or_nan(source_ns));
if origin_mode == "zero"
    initial_ns_min = 0;
end

final_ns_max = local_first_finite( ...
    local_getfield_or(options, 'final_ns_max', NaN), ...
    local_getfield_or(search_domain, 'history_ns_max', NaN), ...
    local_getfield_or(search_domain, 'ns_search_max', NaN), ...
    local_pick_initial(initial_range, 3), ...
    local_max_or_nan(source_ns));
ns_step = local_first_finite_positive( ...
    local_getfield_or(options, 'ns_step', NaN), ...
    local_getfield_or(search_domain, 'ns_search_step', NaN), ...
    local_pick_initial(initial_range, 2), ...
    local_min_spacing(source_ns), ...
    4);

target_ns_grid = local_make_ns_grid(initial_ns_min, final_ns_max, ns_step);
grid_meta = struct( ...
    'initial_ns_min', initial_ns_min, ...
    'final_ns_max', final_ns_max, ...
    'ns_step', ns_step, ...
    'origin_mode', origin_mode, ...
    'num_grid_points', numel(target_ns_grid));
end

function value = local_pick_initial(initial_range, idx_pick)
if numel(initial_range) >= idx_pick && isfinite(initial_range(idx_pick))
    value = initial_range(idx_pick);
else
    value = NaN;
end
end

function value = local_min_or_nan(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = min(values);
end
end

function value = local_max_or_nan(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = max(values);
end
end

function step = local_min_spacing(values)
values = unique(values(isfinite(values)), 'sorted');
if numel(values) < 2
    step = NaN;
else
    step = min(diff(values));
end
end

function ns_grid = local_make_ns_grid(min_ns, max_ns, step)
if ~all(isfinite([min_ns, max_ns, step])) || step <= 0 || min_ns > max_ns
    ns_grid = [];
    return;
end
count = floor((max_ns - min_ns) / step + 0.5);
ns_grid = min_ns + (0:count) * step;
if isempty(ns_grid) || abs(ns_grid(end) - max_ns) > 1.0e-9
    ns_grid = [ns_grid, max_ns]; %#ok<AGROW>
end
ns_grid = unique(round(ns_grid / step) * step, 'sorted');
end

function value = local_first_finite(varargin)
value = NaN;
for idx = 1:nargin
    candidate = varargin{idx};
    if isnumeric(candidate) && isscalar(candidate) && isfinite(candidate)
        value = candidate;
        return;
    end
end
end

function value = local_first_finite_positive(varargin)
value = NaN;
for idx = 1:nargin
    candidate = varargin{idx};
    if isnumeric(candidate) && isscalar(candidate) && isfinite(candidate) && candidate > 0
        value = candidate;
        return;
    end
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
