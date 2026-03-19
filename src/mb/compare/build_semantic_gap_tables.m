function comparison = build_semantic_gap_tables(legacy_output, closed_output)
%BUILD_SEMANTIC_GAP_TABLES Build aligned comparison tables between legacyDG and closedD.

comparison = struct();
comparison.sensor_group = string(legacy_output.sensor_group.name);
comparison.sensor_label = string(legacy_output.sensor_group.sensor_label);
comparison.run_pairs = repmat(struct( ...
    'h_km', NaN, ...
    'family_name', "", ...
    'requirement_gap_table', table(), ...
    'passratio_gap_table', table(), ...
    'frontier_gap_table', table(), ...
    'summary', struct()), 0, 1);

closed_lookup = containers.Map('KeyType', 'char', 'ValueType', 'int32');
for idx = 1:numel(closed_output.runs)
    key = local_run_key(closed_output.runs(idx).h_km, closed_output.runs(idx).family_name);
    closed_lookup(key) = int32(idx);
end

pair_cursor = 0;
comparison.run_pairs = repmat(comparison.run_pairs, numel(legacy_output.runs), 1);
for idx = 1:numel(legacy_output.runs)
    legacy_run = legacy_output.runs(idx);
    key = local_run_key(legacy_run.h_km, legacy_run.family_name);
    if ~isKey(closed_lookup, key)
        continue;
    end
    closed_run = closed_output.runs(closed_lookup(key));
    pair_cursor = pair_cursor + 1;
    comparison.run_pairs(pair_cursor, 1) = struct( ...
        'h_km', legacy_run.h_km, ...
        'family_name', string(legacy_run.family_name), ...
        'requirement_gap_table', local_build_requirement_gap_table(legacy_run, closed_run), ...
        'passratio_gap_table', local_build_passratio_gap_table(legacy_run, closed_run), ...
        'frontier_gap_table', local_build_frontier_gap_table(legacy_run, closed_run), ...
        'summary', local_build_pair_summary(legacy_run, closed_run));
end
comparison.run_pairs = comparison.run_pairs(1:pair_cursor, 1);
comparison.summary_table = local_build_summary_table(comparison.run_pairs);
end

function gap_table = local_build_requirement_gap_table(legacy_run, closed_run)
legacy = legacy_run.aggregate.requirement_surface_iP.surface_table;
closed = closed_run.aggregate.requirement_surface_iP.surface_table;
legacy = renamevars(legacy(:, {'h_km', 'family_name', 'P', 'i_deg', 'minimum_feasible_Ns'}), ...
    'minimum_feasible_Ns', 'minimum_feasible_Ns_legacyDG');
closed = renamevars(closed(:, {'h_km', 'family_name', 'P', 'i_deg', 'minimum_feasible_Ns'}), ...
    'minimum_feasible_Ns', 'minimum_feasible_Ns_closedD');
gap_table = outerjoin(legacy, closed, 'Keys', {'h_km', 'family_name', 'P', 'i_deg'}, 'MergeKeys', true, 'Type', 'full');
gap_table.delta_Ns = local_delta_with_inf(gap_table.minimum_feasible_Ns_legacyDG, gap_table.minimum_feasible_Ns_closedD);
gap_table.gap_state = local_gap_state(gap_table.minimum_feasible_Ns_legacyDG, gap_table.minimum_feasible_Ns_closedD);
gap_table = sortrows(gap_table, {'i_deg', 'P'}, {'ascend', 'ascend'});
end

function gap_table = local_build_passratio_gap_table(legacy_run, closed_run)
legacy = legacy_run.aggregate.passratio_phasecurve(:, {'h_km', 'family_name', 'i_deg', 'Ns', 'max_pass_ratio'});
closed = closed_run.aggregate.passratio_phasecurve(:, {'h_km', 'family_name', 'i_deg', 'Ns', 'max_pass_ratio'});
legacy = renamevars(legacy, 'max_pass_ratio', 'max_pass_ratio_legacyDG');
closed = renamevars(closed, 'max_pass_ratio', 'max_pass_ratio_closedD');
gap_table = outerjoin(legacy, closed, 'Keys', {'h_km', 'family_name', 'i_deg', 'Ns'}, 'MergeKeys', true, 'Type', 'full');
gap_table.legacy_present = isfinite(gap_table.max_pass_ratio_legacyDG);
gap_table.closed_present = isfinite(gap_table.max_pass_ratio_closedD);
gap_table.max_pass_ratio_legacyDG = local_fill_missing_numeric(gap_table.max_pass_ratio_legacyDG, 0);
gap_table.max_pass_ratio_closedD = local_fill_missing_numeric(gap_table.max_pass_ratio_closedD, 0);
gap_table.passratio_gap = gap_table.max_pass_ratio_closedD - gap_table.max_pass_ratio_legacyDG;
gap_table = sortrows(gap_table, {'i_deg', 'Ns'}, {'ascend', 'ascend'});
end

function gap_table = local_build_frontier_gap_table(legacy_run, closed_run)
legacy = local_standardize_frontier_table(legacy_run.aggregate.frontier_vs_i, legacy_run.h_km, legacy_run.family_name);
closed = local_standardize_frontier_table(closed_run.aggregate.frontier_vs_i, closed_run.h_km, closed_run.family_name);
legacy = legacy(:, {'h_km', 'family_name', 'i_deg', 'minimum_feasible_Ns'});
closed = closed(:, {'h_km', 'family_name', 'i_deg', 'minimum_feasible_Ns'});
legacy = renamevars(legacy, 'minimum_feasible_Ns', 'minimum_feasible_Ns_legacyDG');
closed = renamevars(closed, 'minimum_feasible_Ns', 'minimum_feasible_Ns_closedD');
gap_table = outerjoin(legacy, closed, 'Keys', {'h_km', 'family_name', 'i_deg'}, 'MergeKeys', true, 'Type', 'full');
gap_table.delta_Ns = local_delta_with_inf(gap_table.minimum_feasible_Ns_legacyDG, gap_table.minimum_feasible_Ns_closedD);
gap_table.gap_state = local_gap_state(gap_table.minimum_feasible_Ns_legacyDG, gap_table.minimum_feasible_Ns_closedD);
gap_table = sortrows(gap_table, 'i_deg');
end

function frontier = local_standardize_frontier_table(frontier, h_km, family_name)
if isempty(frontier)
    frontier = table('Size', [0, 4], ...
        'VariableTypes', {'double', 'string', 'double', 'double'}, ...
        'VariableNames', {'h_km', 'family_name', 'i_deg', 'minimum_feasible_Ns'});
    return;
end
if ~ismember('h_km', frontier.Properties.VariableNames)
    frontier.h_km = repmat(h_km, height(frontier), 1);
end
if ~ismember('family_name', frontier.Properties.VariableNames)
    frontier.family_name = repmat(string(family_name), height(frontier), 1);
end
if ~ismember('minimum_feasible_Ns', frontier.Properties.VariableNames)
    frontier.minimum_feasible_Ns = NaN(height(frontier), 1);
end
end

function summary_table = local_build_summary_table(run_pairs)
summary_table = table('Size', [numel(run_pairs), 15], ...
    'VariableTypes', {'double', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'logical', 'logical', 'double', 'double', 'double'}, ...
    'VariableNames', {'h_km', 'family_name', 'legacy_feasible_count', 'closed_feasible_count', 'legacy_minimum_feasible_Ns', 'closed_minimum_feasible_Ns', 'num_finite_delta_cells', 'num_closed_infeasible_cells', 'legacyDG_final_passratio', 'closedD_final_passratio', 'right_plateau_reached_legacy', 'right_plateau_reached_closed', 'semantic_gap_max', 'semantic_gap_at_end', 'gap_sign_changes_count'});
for idx = 1:numel(run_pairs)
    pair = run_pairs(idx);
    finite_delta = isfinite(pair.requirement_gap_table.delta_Ns);
    closed_infeasible = isinf(pair.requirement_gap_table.delta_Ns) & pair.requirement_gap_table.delta_Ns > 0;
    summary_table(idx, :) = { ...
        pair.h_km, ...
        string(pair.family_name), ...
        local_getfield_or(pair.summary, 'legacy_feasible_count', 0), ...
        local_getfield_or(pair.summary, 'closed_feasible_count', 0), ...
        local_getfield_or(pair.summary, 'legacy_minimum_feasible_Ns', missing), ...
        local_getfield_or(pair.summary, 'closed_minimum_feasible_Ns', missing), ...
        sum(finite_delta), ...
        sum(closed_infeasible), ...
        local_getfield_or(pair.summary, 'legacyDG_final_passratio', NaN), ...
        local_getfield_or(pair.summary, 'closedD_final_passratio', NaN), ...
        logical(local_getfield_or(pair.summary, 'right_plateau_reached_legacy', false)), ...
        logical(local_getfield_or(pair.summary, 'right_plateau_reached_closed', false)), ...
        local_getfield_or(pair.summary, 'semantic_gap_max', NaN), ...
        local_getfield_or(pair.summary, 'semantic_gap_at_end', NaN), ...
        local_getfield_or(pair.summary, 'gap_sign_changes_count', 0)};
end
end

function key = local_run_key(h_km, family_name)
key = sprintf('h%.6g|%s', h_km, char(string(family_name)));
end

function delta = local_delta_with_inf(legacy_min, closed_min)
delta = NaN(size(legacy_min));
finite_both = isfinite(legacy_min) & isfinite(closed_min);
delta(finite_both) = closed_min(finite_both) - legacy_min(finite_both);
delta(isfinite(legacy_min) & ~isfinite(closed_min)) = Inf;
delta(~isfinite(legacy_min) & isfinite(closed_min)) = -Inf;
end

function state = local_gap_state(legacy_min, closed_min)
state = repmat("both_infeasible", size(legacy_min));
finite_both = isfinite(legacy_min) & isfinite(closed_min);
state(finite_both) = "finite_gap";
state(isfinite(legacy_min) & ~isfinite(closed_min)) = "closedD_infeasible";
state(~isfinite(legacy_min) & isfinite(closed_min)) = "legacyDG_infeasible";
end

function data = local_fill_missing_numeric(data, fill_value)
mask = isnan(data);
data(mask) = fill_value;
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function summary = local_build_pair_summary(legacy_run, closed_run)
passratio_gap_table = local_build_passratio_gap_table(legacy_run, closed_run);
[legacy_final, closed_final, legacy_plateau, closed_plateau, end_gap] = local_summarize_passratio_end_state(passratio_gap_table);

summary = struct( ...
    'legacy_minimum_feasible_Ns', local_getfield_or(legacy_run.summary, 'minimum_feasible_Ns', missing), ...
    'closed_minimum_feasible_Ns', local_getfield_or(closed_run.summary, 'minimum_feasible_Ns', missing), ...
    'legacy_feasible_count', height(legacy_run.feasible_table), ...
    'closed_feasible_count', height(closed_run.feasible_table), ...
    'legacyDG_final_passratio', legacy_final, ...
    'closedD_final_passratio', closed_final, ...
    'right_plateau_reached_legacy', legacy_plateau, ...
    'right_plateau_reached_closed', closed_plateau, ...
    'semantic_gap_max', local_max_abs_or_zero(passratio_gap_table.passratio_gap), ...
    'semantic_gap_at_end', end_gap, ...
    'gap_sign_changes_count', local_count_gap_sign_changes(passratio_gap_table));
end

function [legacy_final, closed_final, legacy_plateau, closed_plateau, end_gap] = local_summarize_passratio_end_state(gap_table)
legacy_final = NaN;
closed_final = NaN;
legacy_plateau = false;
closed_plateau = false;
end_gap = NaN;
if isempty(gap_table)
    return;
end

i_values = unique(gap_table.i_deg, 'sorted');
legacy_last = nan(numel(i_values), 1);
closed_last = nan(numel(i_values), 1);
for idx = 1:numel(i_values)
    Ti = sortrows(gap_table(gap_table.i_deg == i_values(idx), :), 'Ns');
    if isempty(Ti)
        continue;
    end
    legacy_last(idx) = Ti.max_pass_ratio_legacyDG(end);
    closed_last(idx) = Ti.max_pass_ratio_closedD(end);
end

legacy_final = median(legacy_last, 'omitnan');
closed_final = median(closed_last, 'omitnan');
tol = 0.02;
legacy_plateau = all(legacy_last(~isnan(legacy_last)) >= 1 - tol);
closed_plateau = all(closed_last(~isnan(closed_last)) >= 1 - tol);
end_gap = median(closed_last - legacy_last, 'omitnan');
end

function value = local_max_abs_or_zero(x)
if isempty(x)
    value = 0;
    return;
end
x = x(isfinite(x));
if isempty(x)
    value = 0;
else
    value = max(abs(x));
end
end

function count = local_count_gap_sign_changes(gap_table)
count = 0;
if isempty(gap_table)
    return;
end
i_values = unique(gap_table.i_deg, 'sorted');
for idx = 1:numel(i_values)
    Ti = sortrows(gap_table(gap_table.i_deg == i_values(idx), :), 'Ns');
    if isempty(Ti)
        continue;
    end
    signs = sign(Ti.passratio_gap);
    signs = signs(signs ~= 0);
    if numel(signs) < 2
        continue;
    end
    count = count + sum(signs(1:end-1) ~= signs(2:end));
end
end
