function out = aggregate_stage05_semantics_results(eval_table, h_km, family_name, sensor_group_name, i_grid_deg)
%AGGREGATE_STAGE05_SEMANTICS_RESULTS Build MB comparison-ready aggregates for Stage05 semantics.

if nargin < 5
    i_grid_deg = [];
end

requirement_surface = build_mb_fixed_h_requirement_surface_iP(eval_table, h_km, family_name);
passratio_phasecurve = build_mb_fixed_h_passratio_phasecurve(eval_table, h_km, i_grid_deg, family_name);
frontier_vs_i = build_mb_fixed_h_frontier_vs_i(eval_table, h_km, family_name);
dg_envelope = build_mb_stage05_semantic_envelope(eval_table, h_km, i_grid_deg);
frontier_summary = build_mb_stage05_semantic_transition_summary(eval_table, dg_envelope, h_km, i_grid_deg);
pareto_frontier = local_build_pareto_frontier(eval_table, h_km, family_name, sensor_group_name);

out = struct();
out.requirement_surface_iP = requirement_surface;
out.passratio_phasecurve = passratio_phasecurve;
out.frontier_vs_i = frontier_vs_i;
out.dg_envelope = dg_envelope;
out.frontier_summary = frontier_summary;
out.pareto_frontier = pareto_frontier;
out.summary = struct( ...
    'h_km', h_km, ...
    'family_name', string(family_name), ...
    'sensor_group', string(sensor_group_name), ...
    'minimum_feasible_Ns', local_min_or_missing(frontier_vs_i, 'minimum_feasible_Ns'), ...
    'num_feasible_points', sum(local_pick_feasible(eval_table)));
end

function frontier = local_build_pareto_frontier(eval_table, h_km, family_name, sensor_group_name)
feasible_rows = eval_table(local_pick_feasible(eval_table), :);
if isempty(feasible_rows)
    frontier = table();
    return;
end

mask = true(height(feasible_rows), 1);
for i = 1:height(feasible_rows)
    for j = 1:height(feasible_rows)
        if i == j
            continue;
        end
        dominates = feasible_rows.Ns(j) <= feasible_rows.Ns(i) && feasible_rows.D_G_min(j) >= feasible_rows.D_G_min(i);
        strict_better = feasible_rows.Ns(j) < feasible_rows.Ns(i) || feasible_rows.D_G_min(j) > feasible_rows.D_G_min(i);
        if dominates && strict_better
            mask(i) = false;
            break;
        end
    end
end

frontier = feasible_rows(mask, {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'D_G_min', 'pass_ratio'});
frontier.family_name = repmat(string(family_name), height(frontier), 1);
frontier.sensor_group = repmat(string(sensor_group_name), height(frontier), 1);
frontier = sortrows(frontier, {'Ns', 'D_G_min', 'i_deg'}, {'ascend', 'descend', 'ascend'});
if isempty(frontier.h_km)
    frontier.h_km = repmat(h_km, height(frontier), 1);
end
end

function value = local_min_or_missing(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = missing;
    return;
end
value = min(T.(field_name), [], 'omitnan');
if ~isfinite(value)
    value = missing;
end
end

function feasible_mask = local_pick_feasible(T)
if ismember('feasible_flag', T.Properties.VariableNames)
    feasible_mask = logical(T.feasible_flag);
elseif ismember('joint_feasible', T.Properties.VariableNames)
    feasible_mask = logical(T.joint_feasible);
else
    feasible_mask = false(height(T), 1);
end
end
