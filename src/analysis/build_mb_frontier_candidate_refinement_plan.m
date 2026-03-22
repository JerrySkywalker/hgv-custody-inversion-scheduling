function plan = build_mb_frontier_candidate_refinement_plan(run, search_domain, options)
%BUILD_MB_FRONTIER_CANDIDATE_REFINEMENT_PLAN Build a bounded local refinement plan near a weak frontier.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

defaults = struct( ...
    'mode', "light", ...
    'max_refined_cells', 6, ...
    'max_extra_P_neighbors', 1, ...
    'max_extra_i_neighbors', 1, ...
    'max_extra_T_trials', 4, ...
    'max_refined_designs', 96);
cfg = local_merge_structs(defaults, options);

plan = struct( ...
    'weak_frontier_detected', false, ...
    'candidate_cells', table(), ...
    'candidate_designs', table(), ...
    'budget_hit', false, ...
    'refinement_scope', "", ...
    'note', "frontier refinement not triggered");

design_table = local_getfield_or(run, 'design_table', table());
eval_table = local_getfield_or(run, 'eval_table', table());
frontier = local_getfield_or(local_getfield_or(run, 'aggregate', struct()), 'frontier_vs_i', table());
surface_table = local_getfield_or(local_getfield_or(local_getfield_or(run, 'aggregate', struct()), 'requirement_surface_iP', struct()), 'surface_table', table());
if isempty(design_table) || isempty(eval_table)
    return;
end

i_values = unique(design_table.i_deg, 'sorted');
defined_i = [];
if istable(frontier) && ~isempty(frontier) && all(ismember({'i_deg', 'minimum_feasible_Ns'}, frontier.Properties.VariableNames))
    frontier = frontier(isfinite(frontier.minimum_feasible_Ns), :);
    defined_i = unique(frontier.i_deg, 'sorted');
end
defined_ratio = local_safe_ratio(numel(defined_i), numel(i_values));
weak_frontier = numel(defined_i) <= 3 || defined_ratio <= 0.35;
if ~weak_frontier
    return;
end
plan.weak_frontier_detected = true;

P_values = unique(design_table.P, 'sorted');
T_values = unique(design_table.T, 'sorted');
max_P = max(P_values);
hard_max = local_getfield_or(search_domain, 'Ns_hard_max', max(design_table.Ns));

cell_rows = cell(0, 4);
cell_cursor = 0;
for idx_i = 1:numel(i_values)
    i_deg = i_values(idx_i);
    if any(abs(defined_i - i_deg) < 1.0e-9)
        continue;
    end
    neighbor_hint = local_pick_neighbor_hint(frontier, surface_table, i_deg);
    if isempty(neighbor_hint)
        continue;
    end
    P_center = local_getfield_or(neighbor_hint, 'P', max_P);
    P_candidates = unique(max(1, round(P_center + (-cfg.max_extra_P_neighbors:cfg.max_extra_P_neighbors))), 'sorted');
    P_candidates = P_candidates(P_candidates <= max_P + cfg.max_extra_P_neighbors);
    i_candidates = unique(local_neighbor_i_values(i_values, i_deg, cfg.max_extra_i_neighbors), 'stable');
    for ii = 1:numel(i_candidates)
        for ip = 1:numel(P_candidates)
            cell_cursor = cell_cursor + 1;
            cell_rows{cell_cursor, 1} = {local_getfield_or(run, 'h_km', NaN), i_candidates(ii), P_candidates(ip), "frontier_refinement"}; %#ok<AGROW>
            if cell_cursor >= cfg.max_refined_cells
                plan.budget_hit = true;
                break;
            end
        end
        if cell_cursor >= cfg.max_refined_cells
            break;
        end
    end
    if cell_cursor >= cfg.max_refined_cells
        break;
    end
end

if isempty(cell_rows)
    plan.note = "no weak-frontier neighborhood candidate survived planning";
    return;
end

candidate_cells = cell2table(vertcat(cell_rows{:}), 'VariableNames', {'h_km', 'i_deg', 'P', 'cell_source'});
candidate_cells = unique(candidate_cells, 'rows', 'stable');

design_rows = cell(0, 7);
design_cursor = 0;
F_fixed = local_pick_F(design_table);
for idx = 1:height(candidate_cells)
    i_deg = candidate_cells.i_deg(idx);
    P_value = candidate_cells.P(idx);
    t_center = local_estimate_t_center(frontier, surface_table, eval_table, i_deg, P_value);
    T_candidates = local_build_t_candidates(T_values, t_center, cfg.max_extra_T_trials);
    for idx_t = 1:numel(T_candidates)
        Ns = P_value * T_candidates(idx_t);
        if isfinite(hard_max) && Ns > hard_max + 1.0e-9
            continue;
        end
        design_cursor = design_cursor + 1;
        design_rows{design_cursor, 1} = {candidate_cells.h_km(idx), i_deg, P_value, T_candidates(idx_t), F_fixed, Ns, "frontier_refinement"}; %#ok<AGROW>
        if design_cursor >= cfg.max_refined_designs
            plan.budget_hit = true;
            break;
        end
    end
    if design_cursor >= cfg.max_refined_designs
        break;
    end
end

if isempty(design_rows)
    plan.note = "refinement plan generated no additional design candidate";
    return;
end

candidate_designs = cell2table(vertcat(design_rows{:}), 'VariableNames', {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'slice_source'});
candidate_designs = unique(candidate_designs, 'rows', 'stable');

[tf_existing, ~] = ismember(candidate_designs(:, {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'}), design_table(:, {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns'}), 'rows');
candidate_designs = candidate_designs(~tf_existing, :);
if isempty(candidate_designs)
    plan.note = "all frontier-refinement design points were already evaluated";
    return;
end

plan.candidate_cells = unique(candidate_designs(:, {'h_km', 'i_deg', 'P'}), 'rows', 'stable');
plan.candidate_cells.cell_source = repmat("frontier_refinement", height(plan.candidate_cells), 1);
plan.candidate_designs = candidate_designs;
plan.refinement_scope = sprintf('weak frontier: %.0f/%d defined inclinations', numel(defined_i), numel(i_values));
plan.note = "frontier neighborhood refinement plan prepared";
end

function hint = local_pick_neighbor_hint(frontier, surface_table, i_deg)
hint = struct();
if istable(frontier) && ~isempty(frontier)
    frontier_sorted = sortrows(frontier, {'i_deg', 'minimum_feasible_Ns'}, {'ascend', 'ascend'});
    [~, idx] = min(abs(frontier_sorted.i_deg - i_deg));
    if ~isempty(idx) && isfinite(idx)
        hit = frontier_sorted(idx, :);
        hint = struct('P', local_getfield_or(hit, 'P', NaN), 'Ns', local_getfield_or(hit, 'minimum_feasible_Ns', NaN));
        return;
    end
end
if istable(surface_table) && ~isempty(surface_table)
    finite_rows = surface_table(isfinite(surface_table.minimum_feasible_Ns), :);
    if ~isempty(finite_rows)
        [~, idx] = min(abs(finite_rows.i_deg - i_deg));
        hit = finite_rows(idx, :);
        hint = struct('P', local_getfield_or(hit, 'P', NaN), 'Ns', local_getfield_or(hit, 'minimum_feasible_Ns', NaN));
    end
end
end

function i_candidates = local_neighbor_i_values(i_values, i_deg, max_neighbors)
i_candidates = i_deg;
if isempty(i_values)
    return;
end
[~, idx] = min(abs(i_values - i_deg));
left = max(1, idx - max_neighbors);
right = min(numel(i_values), idx + max_neighbors);
i_candidates = unique(i_values(left:right), 'stable');
end

function t_center = local_estimate_t_center(frontier, surface_table, eval_table, i_deg, P_value)
t_center = NaN;
if istable(frontier) && ~isempty(frontier) && all(ismember({'i_deg', 'minimum_feasible_Ns'}, frontier.Properties.VariableNames))
    [~, idx] = min(abs(frontier.i_deg - i_deg));
    if ~isempty(idx)
        t_center = ceil(frontier.minimum_feasible_Ns(idx) / max(P_value, 1));
    end
end
if ~isfinite(t_center) && istable(surface_table) && ~isempty(surface_table)
    finite_rows = surface_table(isfinite(surface_table.minimum_feasible_Ns), :);
    if ~isempty(finite_rows)
        [~, idx] = min(abs(finite_rows.i_deg - i_deg));
        t_center = ceil(finite_rows.minimum_feasible_Ns(idx) / max(P_value, 1));
    end
end
if ~isfinite(t_center) && istable(eval_table) && ~isempty(eval_table)
    mask = eval_table.i_deg == i_deg & eval_table.P == P_value;
    if any(mask) && ismember('joint_margin', eval_table.Properties.VariableNames)
        sub = sortrows(eval_table(mask, :), {'joint_margin', 'Ns'}, {'descend', 'ascend'});
        t_center = sub.T(1);
    end
end
if ~isfinite(t_center)
    t_center = max(4, round(max(P_value, 4) / 2));
end
end

function T_candidates = local_build_t_candidates(T_values, t_center, max_extra_trials)
base = unique(round(T_values(:).'), 'sorted');
extra = unique(round(t_center + (-max_extra_trials:max_extra_trials)), 'sorted');
T_candidates = unique([base, extra], 'sorted');
T_candidates = T_candidates(T_candidates >= 1);
end

function value = local_pick_F(design_table)
if isempty(design_table) || ~ismember('F', design_table.Properties.VariableNames)
    value = 0;
elseif isnumeric(design_table.F)
    value = median(design_table.F, 'omitnan');
else
    value = design_table.F(1);
end
end

function out = local_merge_structs(a, b)
out = a;
fields = fieldnames(b);
for idx = 1:numel(fields)
    out.(fields{idx}) = b.(fields{idx});
end
end

function ratio = local_safe_ratio(num_value, den_value)
if den_value <= 0
    ratio = 0;
else
    ratio = num_value / den_value;
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
elseif istable(S) && ismember(field_name, S.Properties.VariableNames) && ~isempty(S)
    value = S.(field_name)(1);
else
    value = fallback;
end
end
