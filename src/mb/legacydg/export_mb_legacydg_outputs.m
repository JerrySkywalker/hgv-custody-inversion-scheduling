function artifacts = export_mb_legacydg_outputs(run_output, paths, plot_options)
%EXPORT_MB_LEGACYDG_OUTPUTS Export legacyDG semantic outputs under MB layout.

if nargin < 2 || isempty(paths)
    error('export_mb_legacydg_outputs requires run_output and paths.');
end
if nargin < 3 || isempty(plot_options)
    plot_options = struct();
end

style = milestone_common_plot_style();
sensor_group = char(string(run_output.sensor_group.name));
sensor_label = char(string(run_output.sensor_group.sensor_label));

artifacts = struct();
artifacts.tables = struct();
artifacts.figures = struct();

summary_table = local_build_summary_table(run_output);
summary_csv = fullfile(paths.tables, sprintf('MB_legacyDG_summary_%s.csv', sensor_group));
milestone_common_save_table(summary_table, summary_csv);
artifacts.tables.summary = string(summary_csv);

for idx = 1:numel(run_output.runs)
    run = run_output.runs(idx);
    h_label = sprintf('h%d', round(run.h_km));
    search_domain = local_build_search_domain(run_output, run);
    diagnostics = local_build_diagnostics(run, search_domain);

    pass_csv = fullfile(paths.tables, sprintf('MB_legacyDG_passratio_%s_%s.csv', h_label, sensor_group));
    heat_csv = fullfile(paths.tables, sprintf('MB_legacyDG_minimumNs_heatmap_iP_%s_%s.csv', h_label, sensor_group));
    overcompute_csv = fullfile(paths.tables, sprintf('MB_heatmap_overcompute_summary_legacyDG_%s_%s.csv', h_label, sensor_group));
    provenance_csv = fullfile(paths.tables, sprintf('MB_heatmap_provenance_map_legacyDG_%s_%s.csv', h_label, sensor_group));
    refinement_csv = fullfile(paths.tables, sprintf('MB_frontier_refinement_summary_legacyDG_%s_%s.csv', h_label, sensor_group));
    incr_history_csv = fullfile(paths.tables, sprintf('MB_incremental_search_history_legacyDG_%s_%s.csv', h_label, sensor_group));
    incr_stop_csv = fullfile(paths.tables, sprintf('MB_incremental_search_stop_reason_legacyDG_%s_%s.csv', h_label, sensor_group));
    milestone_common_save_table(run.aggregate.passratio_phasecurve, pass_csv);
    milestone_common_save_table(run.aggregate.requirement_surface_iP.surface_table, heat_csv);
    milestone_common_save_table(local_getfield_or(run.aggregate, 'heatmap_overcompute_summary', table()), overcompute_csv);
    milestone_common_save_table(local_build_heatmap_provenance_table(run), provenance_csv);
    milestone_common_save_table(local_getfield_or(run.aggregate, 'frontier_refinement_summary', table()), refinement_csv);
    milestone_common_save_table(run.incremental_search_history, incr_history_csv);
    milestone_common_save_table(local_build_incremental_stop_reason(run), incr_stop_csv);
    diag_artifacts = export_mb_boundary_hit_outputs(diagnostics, paths, sprintf('legacyDG_%s_%s', h_label, sensor_group));
    heatmap_edge_csv = fullfile(paths.tables, sprintf('MB_heatmap_edge_truncation_summary_legacyDG_%s_%s.csv', h_label, sensor_group));
    milestone_common_save_table(diagnostics.heatmap_edge_table, heatmap_edge_csv);

    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_%s', h_label))) = string(pass_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('minimumNs_heatmap_iP_%s', h_label))) = string(heat_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('heatmap_overcompute_%s', h_label))) = string(overcompute_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('heatmap_provenance_%s', h_label))) = string(provenance_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('frontier_refinement_%s', h_label))) = string(refinement_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('incremental_history_%s', h_label))) = string(incr_history_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('incremental_stop_%s', h_label))) = string(incr_stop_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('boundary_hit_%s', h_label))) = diag_artifacts.boundary_hit_csv;
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_saturation_%s', h_label))) = diag_artifacts.passratio_csv;
    artifacts.tables.(matlab.lang.makeValidName(sprintf('frontier_truncation_%s', h_label))) = diag_artifacts.frontier_csv;
    artifacts.tables.(matlab.lang.makeValidName(sprintf('heatmap_edge_%s', h_label))) = string(heatmap_edge_csv);

    pass_plot_options = plot_options;
    pass_plot_options.passratio_saturation_table = diagnostics.passratio_saturation_table;
    pass_plot_options.boundary_hit_table = diagnostics.boundary_hit_table;
    pass_plot_options.search_domain_bounds = [search_domain.ns_search_min, search_domain.ns_search_max];
    pass_plot_options.plot_domain_label = "expanded_final";
    pass_windows = resolve_mb_passratio_plot_windows(run.aggregate.passratio_phasecurve, search_domain, struct('y_fields', "max_pass_ratio"));

    history_options = pass_plot_options;
    history_options.plot_xlim_ns = pass_windows.history_full;
    history_options.plot_domain_label = "history_full";
    fig_pass_history = plot_mb_fixed_h_passratio_phasecurve(run.aggregate.passratio_phasecurve, run.h_km, style, history_options);
    local_retitle(fig_pass_history, sprintf('legacyDG History-Full Pass-Ratio versus N_s at h = %.0f km [%s]', run.h_km, sensor_label));
    pass_history_png = fullfile(paths.figures, sprintf('MB_legacyDG_passratio_historyFull_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass_history, pass_history_png);
    close(fig_pass_history);

    effective_options = pass_plot_options;
    effective_options.plot_xlim_ns = pass_windows.effective_full_range;
    effective_options.plot_domain_label = "effective_full_range";
    fig_pass_effective = plot_mb_fixed_h_passratio_phasecurve(run.aggregate.passratio_phasecurve, run.h_km, style, effective_options);
    local_retitle(fig_pass_effective, sprintf('legacyDG Effective Full-Range Pass-Ratio versus N_s at h = %.0f km [%s]', run.h_km, sensor_label));
    pass_effective_png = fullfile(paths.figures, sprintf('MB_legacyDG_passratio_effectiveFullRange_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass_effective, pass_effective_png);
    pass_alias_png = fullfile(paths.figures, sprintf('MB_legacyDG_passratio_fullRange_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass_effective, pass_alias_png);
    legacy_alias_png = fullfile(paths.figures, sprintf('MB_legacyDG_passratio_globalTrend_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass_effective, legacy_alias_png);
    close(fig_pass_effective);

    legacy_zoom_options = pass_plot_options;
    legacy_zoom_options.plot_xlim_ns = pass_windows.frontier_zoom;
    legacy_zoom_options.plot_domain_label = "frontier_zoom";
    fig_pass_zoom = plot_mb_fixed_h_passratio_phasecurve(run.aggregate.passratio_phasecurve, run.h_km, style, legacy_zoom_options);
    local_retitle(fig_pass_zoom, sprintf('legacyDG Frontier Zoom Pass-Ratio versus N_s at h = %.0f km [%s]', run.h_km, sensor_label));
    pass_zoom_png = fullfile(paths.figures, sprintf('MB_legacyDG_passratio_frontierZoom_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass_zoom, pass_zoom_png);
    close(fig_pass_zoom);
    local_maybe_export_paper_ready(@() plot_mb_fixed_h_passratio_phasecurve(run.aggregate.passratio_phasecurve, run.h_km, style, local_build_paper_options(pass_plot_options)), ...
        fullfile(paths.figures, sprintf('MB_legacyDG_passratio_effectiveFullRange_%s_%s_paperReady.png', h_label, sensor_group)), ...
        "legacyDG_passratio", diagnostics, plot_options);

    fig_heat = plot_mb_fixed_h_requirement_heatmap_iP(run.aggregate.requirement_surface_iP, style, struct( ...
        'boundary_hit_table', diagnostics.boundary_hit_table, ...
        'heatmap_edge_table', diagnostics.heatmap_edge_table, ...
        'search_domain_bounds', [search_domain.ns_search_min, search_domain.ns_search_max], ...
        'domain_summary', char(string(local_getfield_or(plot_options, 'search_domain_label', ""))), ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    local_retitle(fig_heat, sprintf('legacyDG Minimum Feasible Constellation Requirement over (i, P) at h = %.0f km [%s]', run.h_km, sensor_label));
    heat_png = fullfile(paths.figures, sprintf('MB_legacyDG_minimumNs_heatmap_iP_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_heat, heat_png);
    close(fig_heat);
    fig_heat_state = plot_mb_fixed_h_requirement_heatmap_iP(run.aggregate.requirement_surface_iP, style, struct( ...
        'boundary_hit_table', diagnostics.boundary_hit_table, ...
        'heatmap_edge_table', diagnostics.heatmap_edge_table, ...
        'search_domain_bounds', [search_domain.ns_search_min, search_domain.ns_search_max], ...
        'domain_summary', char(string(local_getfield_or(plot_options, 'search_domain_label', ""))), ...
        'heatmap_render_mode', "discrete_state", ...
        'plot_domain_label', "state_map", ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    local_retitle(fig_heat_state, sprintf('legacyDG Heatmap State Map over (i, P) at h = %.0f km [%s]', run.h_km, sensor_label));
    heat_state_png = fullfile(paths.figures, sprintf('MB_legacyDG_heatmap_stateMap_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_heat_state, heat_state_png);
    close(fig_heat_state);
    local_maybe_export_paper_ready(@() plot_mb_fixed_h_requirement_heatmap_iP(run.aggregate.requirement_surface_iP, style, struct( ...
        'boundary_hit_table', diagnostics.boundary_hit_table, ...
        'heatmap_edge_table', diagnostics.heatmap_edge_table, ...
        'search_domain_bounds', [search_domain.ns_search_min, search_domain.ns_search_max], ...
        'domain_summary', char(string(local_getfield_or(plot_options, 'search_domain_label', ""))), ...
        'figure_style', resolve_mb_figure_style_mode('paper_ready'))), ...
        fullfile(paths.figures, sprintf('MB_legacyDG_minimumNs_heatmap_iP_%s_%s_paperReady.png', h_label, sensor_group)), ...
        "legacyDG_heatmap", diagnostics, plot_options);

    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratioHistory_%s', h_label))) = string(pass_history_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratioEffective_%s', h_label))) = string(pass_effective_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratioZoom_%s', h_label))) = string(pass_zoom_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('minimumNs_heatmap_iP_%s', h_label))) = string(heat_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('heatmapStateMap_%s', h_label))) = string(heat_state_png);
end

function local_maybe_export_paper_ready(builder_fn, file_path, figure_family, diagnostics, plot_options)
if ~logical(local_getfield_or(plot_options, 'export_paper_ready', false))
    return;
end
guard = guard_mb_paper_ready_export(figure_family, diagnostics, local_getfield_or(plot_options, 'paper_ready_guardrail', struct()));
if ~guard.allowed
    warning('MB:PaperReadyGuard', '%s', char(guard.note));
    return;
end
fig = builder_fn();
milestone_common_save_figure(fig, file_path);
close(fig);
end

function options_out = local_build_paper_options(options_in)
options_out = options_in;
options_out.figure_style = resolve_mb_figure_style_mode('paper_ready');
end

function T = local_build_incremental_stop_reason(run)
history = run.incremental_search_history;
expansion_state = local_getfield_or(run, 'expansion_state', struct());
if isempty(history)
    T = table(string(run.family_name), run.h_km, "no_history", "", "", false, false, 0, 0, 0, ...
        'VariableNames', {'family_name', 'h_km', 'stop_reason', 'stop_reason_detail', 'expansion_state', 'unity_plateau_reached', 'frontier_internalized', 'previous_design_count', 'added_design_count', 'merged_design_count'});
    return;
end
last_row = history(end, :);
T = table( ...
    string(run.family_name), ...
    run.h_km, ...
    string(last_row.stop_reason), ...
    string(local_getfield_or(last_row, 'stop_reason_detail', "")), ...
    string(local_getfield_or(expansion_state, 'state', "")), ...
    logical(local_getfield_or(last_row, 'unity_plateau_reached', false)), ...
    logical(local_getfield_or(last_row, 'internal_frontier_points', 0) >= 2 && ~logical(local_getfield_or(last_row, 'frontier_truncated', false))), ...
    last_row.previous_design_count, ...
    last_row.added_design_count, ...
    last_row.merged_design_count, ...
    'VariableNames', {'family_name', 'h_km', 'stop_reason', 'stop_reason_detail', 'expansion_state', 'unity_plateau_reached', 'frontier_internalized', 'previous_design_count', 'added_design_count', 'merged_design_count'});
end
end

function search_domain = local_build_search_domain(run_output, run)
effective_domain = local_getfield_or(local_getfield_or(run, 'expansion_state', struct()), 'effective_search_domain', struct());
history_domain = local_getfield_or(local_getfield_or(run_output, 'options', struct()), 'search_domain', struct());
initial_range = reshape(local_getfield_or(history_domain, 'Ns_initial_range', local_getfield_or(run_output.options, 'Ns_initial_range', [])), 1, []);
search_domain = struct( ...
    'ns_search_min', local_getfield_or(effective_domain, 'ns_search_min', local_min_or_nan(run.design_table, 'Ns')), ...
    'ns_search_max', local_getfield_or(effective_domain, 'ns_search_max', local_max_or_nan(run.design_table, 'Ns')), ...
    'ns_search_step', local_getfield_or(effective_domain, 'ns_search_step', local_min_spacing(run.design_table, 'Ns')), ...
    'P_grid', reshape(local_getfield_or(effective_domain, 'P_grid', unique(run.design_table.P, 'sorted')), 1, []), ...
    'T_grid', reshape(local_getfield_or(effective_domain, 'T_grid', unique(run.design_table.T, 'sorted')), 1, []), ...
    'Ns_initial_range', initial_range, ...
    'history_ns_min', local_getfield_or(history_domain, 'ns_search_min', local_pick_initial(initial_range, 1)), ...
    'history_ns_max', max([local_getfield_or(effective_domain, 'ns_search_max', NaN), local_pick_initial(initial_range, 3)], [], 'omitnan'), ...
    'effective_ns_min', local_getfield_or(effective_domain, 'ns_search_min', local_min_or_nan(run.design_table, 'Ns')), ...
    'effective_ns_max', local_getfield_or(effective_domain, 'ns_search_max', local_max_or_nan(run.design_table, 'Ns')));
end

function diagnostics = local_build_diagnostics(run, search_domain)
diagnostics = struct();
diagnostics.boundary_hit_table = build_mb_boundary_hit_table(run.aggregate.requirement_surface_iP.surface_table, search_domain, struct( ...
    'value_fields', {{'minimum_feasible_Ns'}}, ...
    'semantic_labels', {{'legacyDG'}}, ...
    'h_km', run.h_km, ...
    'family_name', string(run.family_name)));
diagnostics.passratio_saturation_table = build_mb_passratio_saturation_diagnostics(run.aggregate.passratio_phasecurve, search_domain, struct( ...
    'value_fields', {{'max_pass_ratio'}}, ...
    'semantic_labels', {{'legacyDG'}}, ...
    'h_km', run.h_km, ...
    'family_name', string(run.family_name)));
diagnostics.frontier_truncation_table = build_mb_frontier_truncation_diagnostics(run.aggregate.frontier_vs_i, search_domain, struct( ...
    'value_fields', {{'minimum_feasible_Ns'}}, ...
    'semantic_labels', {{'legacyDG'}}, ...
    'h_km', run.h_km, ...
    'family_name', string(run.family_name)));
diagnostics.heatmap_edge_table = build_mb_heatmap_edge_truncation_diagnostics(run.aggregate.requirement_surface_iP.surface_table, search_domain, struct( ...
    'semantic_mode', 'legacyDG', ...
    'h_km', run.h_km, ...
    'family_name', string(run.family_name)));
diagnostics.heatmap_overcompute_summary = local_getfield_or(run.aggregate, 'heatmap_overcompute_summary', table());
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

function value = local_pick_initial(initial_range, idx_pick)
if numel(initial_range) >= idx_pick && isfinite(initial_range(idx_pick))
    value = initial_range(idx_pick);
else
    value = NaN;
end
end

function summary_table = local_build_summary_table(run_output)
summary_table = table('Size', [numel(run_output.runs), 7], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'string'}, ...
    'VariableNames', {'semantic_mode', 'sensor_group', 'h_km', 'design_count', 'feasible_count', 'minimum_feasible_Ns', 'family_name'});
for idx = 1:numel(run_output.runs)
    run = run_output.runs(idx);
    summary_table(idx, :) = { ...
        "legacyDG", ...
        string(run_output.sensor_group.name), ...
        run.h_km, ...
        height(run.design_table), ...
        height(run.feasible_table), ...
        local_getfield_or(run.summary, 'minimum_feasible_Ns', missing), ...
        string(run.family_name)};
end
end

function local_retitle(fig, title_text)
ax = get(fig, 'CurrentAxes');
if isempty(ax)
    ax = axes(fig);
end
title(ax, title_text);
end

function T = local_build_heatmap_provenance_table(run)
surface_table = local_getfield_or(local_getfield_or(local_getfield_or(run, 'aggregate', struct()), 'requirement_surface_iP', struct()), 'surface_table', table());
keep = intersect({'h_km', 'family_name', 'i_deg', 'P', 'minimum_feasible_Ns', 'aesthetic_overcompute_touched', 'aesthetic_overcompute_status', 'frontier_refinement_touched', 'frontier_refinement_status'}, surface_table.Properties.VariableNames, 'stable');
if isempty(surface_table) || isempty(keep)
    T = table();
else
    T = surface_table(:, keep);
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
