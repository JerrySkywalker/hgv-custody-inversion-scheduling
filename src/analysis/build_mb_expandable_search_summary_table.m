function summary_table = build_mb_expandable_search_summary_table(run_outputs, meta)
%BUILD_MB_EXPANDABLE_SEARCH_SUMMARY_TABLE Summarize MB expandable-search outcomes.

if nargin < 1
    run_outputs = repmat(struct(), 0, 1);
end
if nargin < 2 || isempty(meta)
    meta = struct();
end

rows = cell(0, 1);
initial_grid = string(mat2str(reshape(local_getfield_or(meta, 'Ns_initial_range', [NaN NaN NaN]), 1, [])));
hard_max = double(local_getfield_or(meta, 'Ns_hard_max', NaN));

for idx = 1:numel(run_outputs)
    run_output = run_outputs(idx).run_output;
    sensor_group = string(local_getfield_or(run_output.sensor_group, 'name', ""));
    semantic_mode = string(local_getfield_or(run_outputs(idx), 'mode', ""));
    runs = local_getfield_or(run_output, 'runs', repmat(struct(), 0, 1));
    for idx_run = 1:numel(runs)
        run = runs(idx_run);
        history = local_getfield_or(run, 'incremental_search_history', table());
        expansion_state = local_getfield_or(run, 'expansion_state', struct());
        effective_domain = local_getfield_or(expansion_state, 'effective_search_domain', struct());
        stop_reason = string(local_getfield_or(expansion_state, 'stop_reason', ""));
        if stop_reason == "" && istable(history) && ~isempty(history) && ismember('stop_reason', history.Properties.VariableNames)
            stop_reason = string(history.stop_reason(end));
        end
        rows{end + 1, 1} = { ... %#ok<AGROW>
            semantic_mode, sensor_group, string(local_getfield_or(run, 'family_name', "")), ...
            double(local_getfield_or(run, 'h_km', NaN)), ...
            initial_grid, ...
            double(local_getfield_or(effective_domain, 'ns_search_max', NaN)), ...
            hard_max, ...
            double(height(history)), ...
            string(local_getfield_or(expansion_state, 'state', "")), ...
            stop_reason, ...
            logical(local_getfield_or(local_getfield_or(expansion_state, 'diagnostics', struct()), 'right_unity_reached', false)), ...
            logical(local_getfield_or(local_getfield_or(expansion_state, 'diagnostics', struct()), 'frontier_truncated', false) == false && ...
                local_getfield_or(local_getfield_or(expansion_state, 'diagnostics', struct()), 'frontier_points', 0) > 0), ...
            logical(double(local_getfield_or(effective_domain, 'ns_search_max', NaN)) >= hard_max - 1e-9)};
    end
end

if isempty(rows)
    summary_table = table();
    return;
end

summary_table = cell2table(vertcat(rows{:}), 'VariableNames', { ...
    'semantic_mode', 'sensor_group', 'family_name', 'height_km', ...
    'Ns_initial_grid', 'final_ns_search_max', 'Ns_hard_max', 'expansion_iterations', ...
    'expansion_state', 'stop_reason', 'unity_plateau_reached', ...
    'frontier_internally_defined', 'hard_max_touched'});
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
