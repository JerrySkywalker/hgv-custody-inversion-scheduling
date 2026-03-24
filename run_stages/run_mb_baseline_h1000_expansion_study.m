function out = run_mb_baseline_h1000_expansion_study(cfg)
%RUN_MB_BASELINE_H1000_EXPANSION_STUDY Dedicated baseline-h1000 expansion study for MB.
% LEGACY MB ENTRYPOINT (FROZEN).
% Keep for historical reproduction only; do not add new MB features here.

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root), addpath(proj_root); end
startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end

paths = mb_output_paths(cfg, 'MB', 'semantic_compare');
semantic_modes = ["legacyDG"; "closedD"];
case_results = repmat(struct( ...
    'semantic_mode', "", ...
    'initial', struct(), ...
    'expanded', struct(), ...
    'autotune', struct(), ...
    'study_row', table(), ...
    'history_table', table()), numel(semantic_modes), 1);

history_rows = cell(numel(semantic_modes), 1);
summary_rows = cell(numel(semantic_modes), 1);
for idx = 1:numel(semantic_modes)
    case_results(idx) = local_run_semantic_study(cfg, semantic_modes(idx));
    summary_rows{idx, 1} = case_results(idx).study_row;
    history_rows{idx, 1} = case_results(idx).history_table;
end

study_table = vertcat(summary_rows{:});
history_table = vertcat(history_rows{:});

study_csv = fullfile(paths.tables, 'MB_baseline_h1000_expansion_study.csv');
history_csv = fullfile(paths.tables, 'MB_baseline_h1000_expansion_history.csv');
milestone_common_save_table(study_table, study_csv);
milestone_common_save_table(history_table, history_csv);

study_fig = plot_mb_baseline_h1000_expansion_study(case_results);
study_png = fullfile(paths.figures, 'MB_baseline_h1000_expansion_study.png');
milestone_common_save_figure(study_fig, study_png);
close(study_fig);

out = struct();
out.study_table = study_table;
out.history_table = history_table;
out.study_csv = string(study_csv);
out.history_csv = string(history_csv);
out.study_png = string(study_png);
out.case_results = case_results;
out.paths = paths;
end

function case_result = local_run_semantic_study(cfg, semantic_mode)
initial_cfg = local_build_study_cfg(cfg, semantic_mode, false);
initial_result = milestone_B_semantic_compare(initial_cfg);
initial_run_output = initial_result.artifacts.run_outputs(1).run_output;
initial_run = initial_run_output.runs(1);
initial_diag = local_build_run_snapshot(initial_run_output, initial_run, semantic_mode, "initial_domain", struct());

expanded_cfg = local_build_study_cfg(cfg, semantic_mode, true);
expanded_result = run_milestone_B_semantic_compare(expanded_cfg, false);
expanded_run_output = expanded_result.artifacts.run_outputs(1).run_output;
expanded_run = expanded_run_output.runs(1);
autotune_result = local_getfield_or(expanded_result.config.milestones.MB_semantic_compare, 'auto_tune_result', struct());
expanded_diag = local_build_run_snapshot(expanded_run_output, expanded_run, semantic_mode, "expanded_domain", autotune_result);

case_result = struct();
case_result.semantic_mode = string(semantic_mode);
case_result.initial = struct( ...
    'result', initial_result, ...
    'run_output', initial_run_output, ...
    'run', initial_run, ...
    'snapshot', initial_diag);
case_result.expanded = struct( ...
    'result', expanded_result, ...
    'run_output', expanded_run_output, ...
    'run', expanded_run, ...
    'snapshot', expanded_diag);
case_result.autotune = autotune_result;
case_result.study_row = local_build_study_row(case_result);
case_result.history_table = local_build_history_table(case_result);
end

function cfg_out = local_build_study_cfg(cfg_in, semantic_mode, enable_autotune)
cfg_out = milestone_common_defaults(cfg_in);
cfg_out.milestones.MB_semantic_compare.milestone_id = sprintf('MB_h1000_%s_%s', lower(char(semantic_mode)), ternary(enable_autotune, 'expanded', 'initial'));
cfg_out.milestones.MB_semantic_compare.title = sprintf('baseline_h1000_%s_%s', lower(char(semantic_mode)), ternary(enable_autotune, 'expanded', 'initial'));
cfg_out.milestones.MB_semantic_compare.search_profile = 'mb_default';
cfg_out.milestones.MB_semantic_compare.search_profile_mode = 'paper';
cfg_out.milestones.MB_semantic_compare.sensor_groups = {'baseline'};
cfg_out.milestones.MB_semantic_compare.heights_to_run = 1000;
cfg_out.milestones.MB_semantic_compare.family_set = {'nominal'};
cfg_out.milestones.MB_semantic_compare.mode = char(semantic_mode);
cfg_out.milestones.MB_semantic_compare.run_dense_local = false;
cfg_out.milestones.MB_semantic_compare.fast_mode = false;
cfg_out.milestones.MB_semantic_compare.parallel_policy = 'off';
cfg_out.milestones.MB_semantic_compare.use_parallel = false;
cfg_out.milestones.MB_semantic_compare.boundary_diagnostics_enabled = true;
cfg_out.milestones.MB_semantic_compare.incremental_expansion_enabled = true;
cfg_out.milestones.MB_semantic_compare.auto_tuned_flag = false;
cfg_out.milestones.MB_semantic_compare.auto_tune.enabled = logical(enable_autotune);
if enable_autotune
    cfg_out.milestones.MB_semantic_compare.auto_tune.mode = "iterative_recommend_and_apply";
    cfg_out.milestones.MB_semantic_compare.auto_tune_apply = true;
else
    cfg_out.milestones.MB_semantic_compare.auto_tune.mode = "off";
    cfg_out.milestones.MB_semantic_compare.auto_tune_apply = false;
end
end

function snapshot = local_build_run_snapshot(run_output, run, semantic_mode, stage_name, autotune_result)
search_domain = local_build_search_domain(run_output, run);
boundary_table = build_mb_boundary_hit_table(run.aggregate.requirement_surface_iP.surface_table, search_domain, struct( ...
    'value_fields', {{'minimum_feasible_Ns'}}, ...
    'semantic_labels', {{char(semantic_mode)}}, ...
    'h_km', run.h_km, ...
    'family_name', string(run.family_name)));
passratio_table = build_mb_passratio_saturation_diagnostics(run.aggregate.passratio_phasecurve, search_domain, struct( ...
    'value_fields', {{'max_pass_ratio'}}, ...
    'semantic_labels', {{char(semantic_mode)}}, ...
    'h_km', run.h_km, ...
    'family_name', string(run.family_name)));
frontier_table = build_mb_frontier_truncation_diagnostics(run.aggregate.frontier_vs_i, search_domain, struct( ...
    'value_fields', {{'minimum_feasible_Ns'}}, ...
    'semantic_labels', {{char(semantic_mode)}}, ...
    'h_km', run.h_km, ...
    'family_name', string(run.family_name)));

boundary_row = local_first_row(boundary_table);
passratio_row = local_first_row(passratio_table);
frontier_row = local_first_row(frontier_table);

snapshot = struct();
snapshot.stage_name = string(stage_name);
snapshot.semantic_mode = string(semantic_mode);
snapshot.h_km = run.h_km;
snapshot.family_name = string(run.family_name);
snapshot.sensor_group = string(run_output.sensor_group.name);
snapshot.search_domain = search_domain;
snapshot.boundary_hit_table = boundary_table;
snapshot.passratio_saturation_table = passratio_table;
snapshot.frontier_truncation_table = frontier_table;
snapshot.boundary_row = boundary_row;
snapshot.passratio_row = passratio_row;
snapshot.frontier_row = frontier_row;
snapshot.passratio_phasecurve = run.aggregate.passratio_phasecurve;
snapshot.frontier_vs_i = run.aggregate.frontier_vs_i;
snapshot.incremental_history = run.incremental_search_history;
snapshot.cache_hits = local_getfield_or(run_output.summary, 'cache_hits', 0);
snapshot.fresh_evaluations = local_getfield_or(run_output.summary, 'fresh_evaluations', 0);
snapshot.max_passratio = local_getfield_or(passratio_row, 'max_passratio', NaN);
snapshot.right_unity_reached = logical(local_getfield_or(passratio_row, 'right_unity_reached', false));
snapshot.first_unity_ns = local_getfield_or(passratio_row, 'first_unity_ns', NaN);
snapshot.frontier_points = local_getfield_or(frontier_row, 'num_frontier_points', 0);
snapshot.internal_frontier_points = local_getfield_or(frontier_row, 'num_internal_frontier_points', 0);
snapshot.upper_bound_hit_ratio = local_getfield_or(boundary_row, 'ratio_upper_bound_hit', NaN);
snapshot.boundary_dominated = logical(local_getfield_or(boundary_row, 'is_boundary_dominated', false));
snapshot.frontier_truncated = logical(local_getfield_or(frontier_row, 'frontier_truncated_by_upper_bound', false));
snapshot.stop_reason = local_resolve_stop_reason(run.incremental_search_history, autotune_result);
snapshot.diagnostic_note = local_resolve_case_note(boundary_row, passratio_row, frontier_row);
snapshot.autotune_result = autotune_result;
end

function T = local_build_study_row(case_result)
initial = case_result.initial.snapshot;
expanded = case_result.expanded.snapshot;
autotune_result = case_result.autotune;

T = table( ...
    string(case_result.semantic_mode), ...
    string(initial.sensor_group), ...
    initial.h_km, ...
    local_getfield_or(initial.search_domain, 'ns_search_min', NaN), ...
    local_getfield_or(initial.search_domain, 'ns_search_max', NaN), ...
    local_getfield_or(expanded.search_domain, 'ns_search_min', NaN), ...
    local_getfield_or(expanded.search_domain, 'ns_search_max', NaN), ...
    initial.max_passratio, ...
    expanded.max_passratio, ...
    logical(initial.right_unity_reached), ...
    logical(expanded.right_unity_reached), ...
    initial.first_unity_ns, ...
    expanded.first_unity_ns, ...
    initial.frontier_points, ...
    expanded.frontier_points, ...
    initial.internal_frontier_points, ...
    expanded.internal_frontier_points, ...
    initial.upper_bound_hit_ratio, ...
    expanded.upper_bound_hit_ratio, ...
    logical(initial.boundary_dominated), ...
    logical(expanded.boundary_dominated), ...
    string(local_getfield_or(autotune_result, 'state', "")), ...
    string(local_getfield_or(autotune_result, 'final_stop_reason', "")), ...
    logical(local_getfield_or(autotune_result, 'unresolved_due_to_search_limit', false)), ...
    local_getfield_or(local_getfield_or(autotune_result, 'stats', struct()), 'total_iterations', 0), ...
    local_getfield_or(local_getfield_or(autotune_result, 'stats', struct()), 'cache_hits', 0), ...
    local_getfield_or(local_getfield_or(autotune_result, 'stats', struct()), 'fresh_evaluations', 0), ...
    string(local_build_study_conclusion(initial, expanded)), ...
    'VariableNames', {'semantic_mode', 'sensor_group', 'height_km', ...
    'initial_search_ns_min', 'initial_search_ns_max', 'expanded_search_ns_min', 'expanded_search_ns_max', ...
    'initial_max_passratio', 'expanded_max_passratio', ...
    'initial_right_unity_reached', 'expanded_right_unity_reached', ...
    'initial_first_unity_ns', 'expanded_first_unity_ns', ...
    'initial_frontier_points', 'expanded_frontier_points', ...
    'initial_internal_frontier_points', 'expanded_internal_frontier_points', ...
    'initial_ratio_upper_bound_hit', 'expanded_ratio_upper_bound_hit', ...
    'initial_boundary_dominated', 'expanded_boundary_dominated', ...
    'autotune_state', 'autotune_stop_reason', 'unresolved_due_to_search_limit', ...
    'total_iterations', 'cache_hits', 'fresh_evaluations', 'study_conclusion'});
end

function history_table = local_build_history_table(case_result)
initial = case_result.initial.snapshot;
expanded = case_result.expanded.snapshot;
autotune_result = case_result.autotune;

iter_history = local_getfield_or(autotune_result, 'iteration_history', table());
row_count = 2 + height(iter_history);
rows = cell(row_count, 1);
cursor = 1;
rows{cursor, 1} = local_snapshot_row(case_result.semantic_mode, "initial_domain", 0, initial);
if istable(iter_history) && ~isempty(iter_history)
    for idx = 1:height(iter_history)
        row = iter_history(idx, :);
        cursor = cursor + 1;
        rows{cursor, 1} = table( ...
            string(case_result.semantic_mode), ...
            "autotune_iteration", ...
            row.iteration, ...
            row.recommended_search_ns_min, ...
            row.recommended_search_ns_max, ...
            local_parse_plot_min(row.plot_xlim_ns), ...
            local_parse_plot_max(row.plot_xlim_ns), ...
            row.final_passratio_median, ...
            logical(row.right_plateau_reached), ...
            NaN, ...
            NaN, ...
            NaN, ...
            NaN, ...
            string(row.stop_reason), ...
            string(row.stop_reason_detail), ...
            'VariableNames', {'semantic_mode', 'stage_name', 'iteration', ...
            'search_ns_min', 'search_ns_max', 'plot_ns_min', 'plot_ns_max', ...
            'max_passratio', 'right_unity_reached', 'ratio_upper_bound_hit', ...
            'frontier_points', 'internal_frontier_points', 'boundary_dominated', ...
            'stop_reason', 'note'});
    end
end

cursor = cursor + 1;
rows{cursor, 1} = local_snapshot_row(case_result.semantic_mode, "expanded_domain", local_getfield_or(local_getfield_or(autotune_result, 'stats', struct()), 'total_iterations', 0), expanded);
history_table = vertcat(rows{1:cursor});
end

function row = local_snapshot_row(semantic_mode, stage_name, iteration, snapshot)
row = table( ...
    string(semantic_mode), ...
    string(stage_name), ...
    iteration, ...
    local_getfield_or(snapshot.search_domain, 'ns_search_min', NaN), ...
    local_getfield_or(snapshot.search_domain, 'ns_search_max', NaN), ...
    NaN, ...
    NaN, ...
    snapshot.max_passratio, ...
    logical(snapshot.right_unity_reached), ...
    snapshot.upper_bound_hit_ratio, ...
    snapshot.frontier_points, ...
    snapshot.internal_frontier_points, ...
    logical(snapshot.boundary_dominated), ...
    string(snapshot.stop_reason), ...
    string(snapshot.diagnostic_note), ...
    'VariableNames', {'semantic_mode', 'stage_name', 'iteration', ...
    'search_ns_min', 'search_ns_max', 'plot_ns_min', 'plot_ns_max', ...
    'max_passratio', 'right_unity_reached', 'ratio_upper_bound_hit', ...
    'frontier_points', 'internal_frontier_points', 'boundary_dominated', ...
    'stop_reason', 'note'});
end

function search_domain = local_build_search_domain(run_output, run)
search_domain = struct( ...
    'ns_search_min', local_getfield_or(run_output.options, 'ns_search_min', local_min_or_nan(run.design_table, 'Ns')), ...
    'ns_search_max', local_getfield_or(run_output.options, 'ns_search_max', local_max_or_nan(run.design_table, 'Ns')), ...
    'ns_search_step', local_min_spacing(run.design_table, 'Ns'), ...
    'P_grid', unique(run.design_table.P, 'sorted'), ...
    'T_grid', unique(run.design_table.T, 'sorted'));
end

function row = local_first_row(T)
if istable(T) && ~isempty(T)
    row = table2struct(T(1, :), 'ToScalar', true);
else
    row = struct();
end
end

function stop_reason = local_resolve_stop_reason(incremental_history, autotune_result)
stop_reason = string(local_getfield_or(autotune_result, 'final_stop_reason', ""));
if strlength(stop_reason) > 0
    return;
end
if istable(incremental_history) && ~isempty(incremental_history) && ismember('stop_reason', incremental_history.Properties.VariableNames)
    stop_reason = string(incremental_history.stop_reason(end));
else
    stop_reason = "";
end
end

function note = local_resolve_case_note(boundary_row, passratio_row, frontier_row)
notes = strings(0, 1);
if isfield(boundary_row, 'diagnostic_note') && strlength(string(boundary_row.diagnostic_note)) > 0
    notes(end + 1, 1) = string(boundary_row.diagnostic_note); %#ok<AGROW>
end
if isfield(passratio_row, 'diagnostic_note') && strlength(string(passratio_row.diagnostic_note)) > 0
    notes(end + 1, 1) = string(passratio_row.diagnostic_note); %#ok<AGROW>
end
if isfield(frontier_row, 'diagnostic_note') && strlength(string(frontier_row.diagnostic_note)) > 0
    notes(end + 1, 1) = string(frontier_row.diagnostic_note); %#ok<AGROW>
end
notes = unique(notes(strlength(notes) > 0), 'stable');
note = strjoin(notes, " | ");
end

function conclusion = local_build_study_conclusion(initial, expanded)
if expanded.right_unity_reached && expanded.frontier_points > initial.frontier_points
    conclusion = "Expansion resolved a fuller 0->1 transition and strengthened the internal frontier definition.";
elseif expanded.right_unity_reached
    conclusion = "Expansion reached the unity plateau, but the frontier remains only weakly improved.";
elseif expanded.frontier_points > initial.frontier_points
    conclusion = "Expansion added frontier structure, but the pass-ratio curve still does not reach a full unity plateau.";
elseif expanded.boundary_dominated
    conclusion = "Even after expansion, the result remains boundary dominated; the baseline sensor or semantic criterion is still restrictive under h=1000 km.";
else
    conclusion = "Expansion changed diagnostics only marginally; the current semantic bottleneck is likely not just the initial search upper bound.";
end
end

function value = local_parse_plot_min(plot_xlim_value)
vals = local_parse_numeric_pair(plot_xlim_value);
if isempty(vals)
    value = NaN;
else
    value = vals(1);
end
end

function value = local_parse_plot_max(plot_xlim_value)
vals = local_parse_numeric_pair(plot_xlim_value);
if isempty(vals)
    value = NaN;
else
    value = vals(end);
end
end

function vals = local_parse_numeric_pair(value)
if isnumeric(value)
    vals = reshape(value, 1, []);
    return;
end
txt = char(string(value));
txt = erase(txt, '[');
txt = erase(txt, ']');
parts = textscan(txt, '%f', 'Delimiter', ', ');
vals = reshape(parts{1}, 1, []);
end

function value = local_min_or_nan(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = NaN;
    return;
end
values = T.(field_name);
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = min(values);
end
end

function value = local_max_or_nan(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = NaN;
    return;
end
values = T.(field_name);
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = max(values);
end
end

function value = local_min_spacing(T, field_name)
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    value = NaN;
    return;
end
values = unique(sort(T.(field_name)));
values = values(isfinite(values));
if numel(values) < 2
    value = NaN;
else
    value = min(diff(values));
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function value = ternary(cond, a, b)
if cond
    value = a;
else
    value = b;
end
end
