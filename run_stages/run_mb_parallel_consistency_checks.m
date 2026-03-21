function out = run_mb_parallel_consistency_checks(options)
%RUN_MB_PARALLEL_CONSISTENCY_CHECKS Compare serial and parallel MB search outputs on a small regression slice.

mb_safe_startup();

if nargin < 1 || isempty(options)
    options = struct();
end

cfg = milestone_common_defaults();
[cfg, ~] = apply_mb_search_profile_to_cfg(cfg, local_getfield_or(options, 'profile_name', 'mb_default'));
run_id = char(string(local_getfield_or(options, 'milestone_id', "MB_parallel_check")));
tag = char(string(local_getfield_or(options, 'tag', 'parallel_check')));

base_cfg = cfg;
base_cfg.milestones.MB_semantic_compare.milestone_id = run_id;
base_cfg.milestones.MB_semantic_compare.title = 'semantic_compare';
base_cfg.milestones.MB_semantic_compare.mode = 'comparison';
base_cfg.milestones.MB_semantic_compare.sensor_groups = local_getfield_or(options, 'sensor_groups', {'baseline'});
base_cfg.milestones.MB_semantic_compare.heights_to_run = local_getfield_or(options, 'heights_to_run', 1000);
base_cfg.milestones.MB_semantic_compare.family_set = local_getfield_or(options, 'family_set', {'nominal'});
if isfield(options, 'i_grid_deg')
    base_cfg.milestones.MB_semantic_compare.i_grid_deg = reshape(options.i_grid_deg, 1, []);
end
if isfield(options, 'P_grid')
    base_cfg.milestones.MB_semantic_compare.P_grid = reshape(options.P_grid, 1, []);
end
if isfield(options, 'T_grid')
    base_cfg.milestones.MB_semantic_compare.T_grid = reshape(options.T_grid, 1, []);
end
base_cfg.milestones.MB_semantic_compare.run_dense_local = false;
base_cfg.runtime.plotting.mode = 'headless';

serial_cfg = base_cfg;
serial_cfg.runtime.parallel.enable = false;
serial_cfg.runtime.parallel.scope = 'none';
serial_cfg.runtime.parallel.mode = 'serial';
serial_cfg.parallel = serial_cfg.runtime.parallel;

parallel_cfg = base_cfg;
parallel_cfg.runtime.parallel.enable = true;
parallel_cfg.runtime.parallel.scope = char(string(local_getfield_or(options, 'parallel_scope', 'outer_loop_only')));
parallel_cfg.runtime.parallel.mode = char(string(local_getfield_or(options, 'parallel_mode', 'grid')));
parallel_cfg.runtime.parallel.max_workers = local_getfield_or(options, 'max_workers', 4);
parallel_cfg.parallel = parallel_cfg.runtime.parallel;

paths = mb_output_paths(base_cfg, run_id, 'semantic_compare');

tic;
serial_result = milestone_B_semantic_compare(serial_cfg);
serial_elapsed_s = toc;

tic;
parallel_result = milestone_B_semantic_compare(parallel_cfg);
parallel_elapsed_s = toc;

serial_summary = local_build_result_summary(serial_result, "serial");
parallel_summary = local_build_result_summary(parallel_result, "parallel");
consistency_summary = local_compare_result_summaries(serial_summary, parallel_summary);
timing_summary = table( ...
    string(tag), serial_elapsed_s, parallel_elapsed_s, ...
    serial_elapsed_s - parallel_elapsed_s, ...
    serial_elapsed_s / max(parallel_elapsed_s, eps), ...
    'VariableNames', {'tag', 'serial_elapsed_s', 'parallel_elapsed_s', 'time_saved_s', 'speedup_ratio'});

consistency_csv = fullfile(paths.tables, 'MB_parallel_consistency_summary.csv');
timing_csv = fullfile(paths.tables, 'MB_parallel_timing_summary.csv');
milestone_common_save_table(consistency_summary, consistency_csv);
milestone_common_save_table(timing_summary, timing_csv);

out = struct();
out.serial_result = serial_result;
out.parallel_result = parallel_result;
out.consistency_csv = string(consistency_csv);
out.timing_csv = string(timing_csv);
out.consistency_summary = consistency_summary;
out.timing_summary = timing_summary;
end

function summary_table = local_build_result_summary(result, run_mode)
rows = {};
run_outputs = local_getfield_or(local_getfield_or(result, 'artifacts', struct()), 'run_outputs', struct([]));
for idx = 1:numel(run_outputs)
    run_output = run_outputs(idx).run_output;
    for idx_run = 1:numel(run_output.runs)
        run = run_output.runs(idx_run);
        passratio = local_getfield_or(local_getfield_or(run, 'aggregate', struct()), 'passratio_phasecurve', table());
        frontier = local_getfield_or(local_getfield_or(run, 'aggregate', struct()), 'frontier_vs_i', table());
        requirement = local_getfield_or(local_getfield_or(run, 'aggregate', struct()), 'requirement_surface_iP', struct());
        requirement_table = local_getfield_or(requirement, 'surface_table', table());
        max_pass = local_get_column_extreme(passratio, 'max_pass_ratio', @max, 0);
        frontier_count = local_count_defined_frontier(frontier);
        defined_cells = local_count_defined_requirement(requirement_table);
        max_ns = local_get_column_extreme(local_getfield_or(run, 'design_table', table()), 'Ns', @max, NaN);
        rows(end + 1, :) = { ... %#ok<AGROW>
            string(run_mode), string(run_outputs(idx).mode), string(run_output.sensor_group.name), ...
            string(local_getfield_or(run, 'family_name', "")), double(local_getfield_or(run, 'h_km', NaN)), ...
            double(max_ns), double(max_pass), double(frontier_count), double(defined_cells)};
    end
end
summary_table = cell2table(rows, 'VariableNames', ...
    {'run_mode', 'semantic_mode', 'sensor_group', 'family_name', 'height_km', 'max_design_ns', 'max_pass_ratio', 'frontier_defined_count', 'defined_heatmap_cells'});
summary_table.run_mode = string(summary_table.run_mode);
summary_table.semantic_mode = string(summary_table.semantic_mode);
summary_table.sensor_group = string(summary_table.sensor_group);
summary_table.family_name = string(summary_table.family_name);
end

function consistency = local_compare_result_summaries(serial_summary, parallel_summary)
keys = {'semantic_mode', 'sensor_group', 'family_name', 'height_km'};
serial_key = local_compose_key(serial_summary, keys);
parallel_key = local_compose_key(parallel_summary, keys);
all_keys = unique([serial_key; parallel_key], 'stable');
rows = {};
for idx = 1:numel(all_keys)
    key = all_keys(idx);
    s_hit = serial_summary(serial_key == key, :);
    p_hit = parallel_summary(parallel_key == key, :);
    metrics_equal = false;
    note = "";
    if ~isempty(s_hit) && ~isempty(p_hit)
        metrics_equal = isequaln(s_hit{1, {'max_design_ns', 'max_pass_ratio', 'frontier_defined_count', 'defined_heatmap_cells'}}, ...
            p_hit{1, {'max_design_ns', 'max_pass_ratio', 'frontier_defined_count', 'defined_heatmap_cells'}});
        if ~metrics_equal
            note = "Serial/parallel metrics differ.";
        end
    else
        note = "Missing summary row in one execution mode.";
    end
    rows(end + 1, :) = { ... %#ok<AGROW>
        key, ...
        string(local_pick_value(s_hit, 'semantic_mode', "")), ...
        string(local_pick_value(s_hit, 'sensor_group', local_pick_value(p_hit, 'sensor_group', ""))), ...
        string(local_pick_value(s_hit, 'family_name', local_pick_value(p_hit, 'family_name', ""))), ...
        double(local_pick_value(s_hit, 'height_km', local_pick_value(p_hit, 'height_km', NaN))), ...
        logical(metrics_equal), string(note)};
end
consistency = cell2table(rows, 'VariableNames', {'row_key', 'semantic_mode', 'sensor_group', 'family_name', 'height_km', 'metrics_equal', 'note'});
consistency.row_key = string(consistency.row_key);
consistency.semantic_mode = string(consistency.semantic_mode);
consistency.sensor_group = string(consistency.sensor_group);
consistency.family_name = string(consistency.family_name);
consistency.metrics_equal = logical(consistency.metrics_equal);
end

function keys = local_compose_key(T, key_fields)
if isempty(T)
    keys = strings(0, 1);
    return;
end
parts = strings(height(T), numel(key_fields));
for idx = 1:numel(key_fields)
    parts(:, idx) = string(T.(key_fields{idx}));
end
keys = join(parts, "|", 2);
end

function value = local_pick_value(T, field_name, fallback)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = fallback;
    return;
end
value = T.(field_name)(1);
end

function value = local_get_column_extreme(T, field_name, reducer, fallback)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = fallback;
    return;
end
vals = T.(field_name);
vals = vals(isfinite(vals));
if isempty(vals)
    value = fallback;
else
    value = reducer(vals);
end
end

function count = local_count_defined_frontier(frontier)
if isempty(frontier) || ~ismember('minimum_feasible_Ns', frontier.Properties.VariableNames)
    count = 0;
    return;
end
vals = frontier.minimum_feasible_Ns;
count = nnz(isfinite(vals));
end

function count = local_count_defined_requirement(surface_table)
if isempty(surface_table) || ~ismember('minimum_feasible_Ns', surface_table.Properties.VariableNames)
    count = 0;
    return;
end
vals = surface_table.minimum_feasible_Ns;
count = nnz(isfinite(vals));
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
