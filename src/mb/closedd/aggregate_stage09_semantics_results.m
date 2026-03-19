function out = aggregate_stage09_semantics_results(eval_table, h_km, family_name, sensor_group_name, i_grid_deg)
%AGGREGATE_STAGE09_SEMANTICS_RESULTS Build MB comparison-ready aggregates for closedD semantics.

if nargin < 5
    i_grid_deg = [];
end

requirement_surface = build_mb_fixed_h_requirement_surface_iP(eval_table, h_km, family_name);
passratio_phasecurve = build_mb_fixed_h_passratio_phasecurve(eval_table, h_km, i_grid_deg, family_name);
frontier_vs_i = build_mb_fixed_h_frontier_vs_i(eval_table, h_km, family_name);
dg_control_envelope = local_build_dg_control_envelope(eval_table, h_km, i_grid_deg);
pareto_frontier = local_build_joint_pareto_frontier(eval_table, h_km, family_name, sensor_group_name);

out = struct();
out.requirement_surface_iP = requirement_surface;
out.passratio_phasecurve = passratio_phasecurve;
out.frontier_vs_i = frontier_vs_i;
out.dg_control_envelope = dg_control_envelope;
out.pareto_frontier = pareto_frontier;
out.summary = struct( ...
    'h_km', h_km, ...
    'family_name', string(family_name), ...
    'sensor_group', string(sensor_group_name), ...
    'minimum_feasible_Ns', local_min_or_missing(frontier_vs_i, 'minimum_feasible_Ns'), ...
    'num_feasible_points', sum(local_pick_feasible(eval_table)));
end

function envelope = local_build_dg_control_envelope(eval_table, h_km, i_grid_deg)
if ~ismember('D_G_min', eval_table.Properties.VariableNames)
    envelope = table();
    return;
end
envelope = build_mb_stage05_semantic_envelope(eval_table, h_km, i_grid_deg);
end

function frontier = local_build_joint_pareto_frontier(eval_table, h_km, family_name, sensor_group_name)
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
        dominates = feasible_rows.Ns(j) <= feasible_rows.Ns(i) && feasible_rows.joint_margin(j) >= feasible_rows.joint_margin(i);
        strict_better = feasible_rows.Ns(j) < feasible_rows.Ns(i) || feasible_rows.joint_margin(j) > feasible_rows.joint_margin(i);
        if dominates && strict_better
            mask(i) = false;
            break;
        end
    end
end

frontier = feasible_rows(mask, {'h_km', 'i_deg', 'P', 'T', 'F', 'Ns', 'joint_margin', 'pass_ratio'});
frontier.family_name = repmat(string(family_name), height(frontier), 1);
frontier.sensor_group = repmat(string(sensor_group_name), height(frontier), 1);
frontier = sortrows(frontier, {'Ns', 'joint_margin', 'i_deg'}, {'ascend', 'descend', 'ascend'});
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
