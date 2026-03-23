function ns_list = mb_vgeom_get_ns_list(cfg_vgeom, source_run, inclination_deg)
%MB_VGEOM_GET_NS_LIST Resolve the frontier-adjacent Ns list for one vgeom case.

if nargin < 1 || isempty(cfg_vgeom)
    cfg_vgeom = struct();
end
if nargin < 2 || ~isstruct(source_run)
    error('mb_vgeom_get_ns_list requires source_run.');
end
if nargin < 3 || ~isfinite(inclination_deg)
    error('mb_vgeom_get_ns_list requires inclination_deg.');
end

ns_mode = lower(strtrim(char(string(local_getfield_or(cfg_vgeom, 'ns_mode', 'frontier_only')))));
override = local_getfield_or(cfg_vgeom, 'ns_list_override', []);
neighbor_count = max(0, round(local_getfield_or(cfg_vgeom, 'frontier_neighbor_count', 1)));

if strcmp(ns_mode, 'manual')
    ns_list = local_normalize_numeric_vector(override);
    return;
end

if ~isfield(source_run, 'design_table') || isempty(source_run.design_table)
    ns_list = [];
    return;
end

design_table = source_run.design_table;
mask_i = ismember_tol(design_table.i_deg, inclination_deg);
available_ns = unique(design_table.Ns(mask_i));
available_ns = sort(available_ns(:).');
if isempty(available_ns)
    ns_list = [];
    return;
end

frontier_ns = NaN;
if isfield(source_run, 'aggregate') && isfield(source_run.aggregate, 'frontier_vs_i') && ...
        istable(source_run.aggregate.frontier_vs_i) && ~isempty(source_run.aggregate.frontier_vs_i)
    frontier_table = source_run.aggregate.frontier_vs_i;
    if ismember('i_deg', frontier_table.Properties.VariableNames) && ismember('minimum_feasible_Ns', frontier_table.Properties.VariableNames)
        row_mask = ismember_tol(frontier_table.i_deg, inclination_deg) & isfinite(frontier_table.minimum_feasible_Ns);
        if any(row_mask)
            frontier_ns = frontier_table.minimum_feasible_Ns(find(row_mask, 1, 'first'));
        end
    end
end

if ~isfinite(frontier_ns)
    if ~isempty(override)
        ns_list = local_normalize_numeric_vector(override);
        return;
    end
    ns_list = available_ns(max(1, numel(available_ns) - 2):end);
    return;
end

[~, idx0] = min(abs(available_ns - frontier_ns));
idx_min = max(1, idx0 - neighbor_count);
idx_max = min(numel(available_ns), idx0 + neighbor_count);
ns_list = available_ns(idx_min:idx_max);
ns_list = unique(ns_list(:).');
end

function tf = ismember_tol(values, target)
tf = abs(double(values) - double(target)) < 1e-9;
end

function values = local_normalize_numeric_vector(values)
values = reshape(double(values), 1, []);
values = values(isfinite(values));
values = unique(round(values), 'stable');
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
