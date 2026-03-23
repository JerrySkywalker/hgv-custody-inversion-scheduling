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

summary_table = local_build_summary_table(run_output, plot_options);
summary_csv = fullfile(paths.tables, sprintf('MB_legacyDG_summary_%s.csv', sensor_group));
milestone_common_save_table(summary_table, summary_csv);
artifacts.tables.summary = string(summary_csv);

for idx = 1:numel(run_output.runs)
    run = run_output.runs(idx);
    h_label = sprintf('h%d', round(run.h_km));
    search_domain = local_build_search_domain(run_output, run);
    diagnostics = local_build_diagnostics(run, search_domain);
    plot_mode_profile = local_resolve_plot_mode_profile(plot_options);

    pass_csv = fullfile(paths.tables, sprintf('MB_legacyDG_passratio_%s_%s.csv', h_label, sensor_group));
    pass_primary_csv = fullfile(paths.tables, sprintf('MB_legacyDG_passratio_primary_%s_%s.csv', h_label, sensor_group));
    pass_history_csv = fullfile(paths.tables, sprintf('MB_legacyDG_passratio_historyFull_%s_%s.csv', h_label, sensor_group));
    pass_effective_csv = fullfile(paths.tables, sprintf('MB_legacyDG_passratio_effectiveFullRange_%s_%s.csv', h_label, sensor_group));
    pass_zoom_csv = fullfile(paths.tables, sprintf('MB_legacyDG_passratio_frontierZoom_%s_%s.csv', h_label, sensor_group));
    pass_padding_csv = fullfile(paths.tables, sprintf('MB_legacyDG_passratio_historyPadding_%s_%s.csv', h_label, sensor_group));
    heat_csv = fullfile(paths.tables, sprintf('MB_legacyDG_minimumNs_heatmap_iP_%s_%s.csv', h_label, sensor_group));
    heat_primary_csv = fullfile(paths.tables, sprintf('MB_legacyDG_minimumNs_heatmap_primary_%s_%s.csv', h_label, sensor_group));
    heat_local_csv = fullfile(paths.tables, sprintf('MB_legacyDG_minimumNs_heatmap_local_%s_%s.csv', h_label, sensor_group));
    heat_global_csv = fullfile(paths.tables, sprintf('MB_legacyDG_minimumNs_heatmap_globalSkeleton_%s_%s.csv', h_label, sensor_group));
    heat_state_csv = fullfile(paths.tables, sprintf('MB_legacyDG_heatmap_stateMap_%s_%s.csv', h_label, sensor_group));
    heat_state_primary_csv = fullfile(paths.tables, sprintf('MB_legacyDG_heatmap_stateMap_primary_%s_%s.csv', h_label, sensor_group));
    heat_state_local_csv = fullfile(paths.tables, sprintf('MB_legacyDG_heatmap_stateMap_local_%s_%s.csv', h_label, sensor_group));
    heat_state_global_csv = fullfile(paths.tables, sprintf('MB_legacyDG_heatmap_stateMap_globalSkeleton_%s_%s.csv', h_label, sensor_group));
    overcompute_csv = fullfile(paths.tables, sprintf('MB_heatmap_overcompute_summary_legacyDG_%s_%s.csv', h_label, sensor_group));
    provenance_csv = fullfile(paths.tables, sprintf('MB_heatmap_provenance_map_legacyDG_%s_%s.csv', h_label, sensor_group));
    refinement_csv = fullfile(paths.tables, sprintf('MB_frontier_refinement_summary_legacyDG_%s_%s.csv', h_label, sensor_group));
    incr_history_csv = fullfile(paths.tables, sprintf('MB_incremental_search_history_legacyDG_%s_%s.csv', h_label, sensor_group));
    incr_stop_csv = fullfile(paths.tables, sprintf('MB_incremental_search_stop_reason_legacyDG_%s_%s.csv', h_label, sensor_group));
    milestone_common_save_table(run.aggregate.passratio_phasecurve, pass_csv);
    milestone_common_save_table(local_getfield_or(run.aggregate, 'heatmap_overcompute_summary', table()), overcompute_csv);
    milestone_common_save_table(local_build_heatmap_provenance_table(run), provenance_csv);
    milestone_common_save_table(local_getfield_or(run.aggregate, 'frontier_refinement_summary', table()), refinement_csv);
    milestone_common_save_table(run.incremental_search_history, incr_history_csv);
    milestone_common_save_table(local_build_incremental_stop_reason(run), incr_stop_csv);
    diag_artifacts = export_mb_boundary_hit_outputs(diagnostics, paths, sprintf('legacyDG_%s_%s', h_label, sensor_group));
    heatmap_edge_csv = fullfile(paths.tables, sprintf('MB_heatmap_edge_truncation_summary_legacyDG_%s_%s.csv', h_label, sensor_group));
    milestone_common_save_table(diagnostics.heatmap_edge_table, heatmap_edge_csv);

    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_%s', h_label))) = string(pass_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_historyFull_%s', h_label))) = string(pass_history_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_effectiveFullRange_%s', h_label))) = string(pass_effective_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_frontierZoom_%s', h_label))) = string(pass_zoom_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_historyPadding_%s', h_label))) = string(pass_padding_csv);
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
    pass_view_spec = struct( ...
        'group_fields', {{'h_km', 'family_name', 'i_deg'}}, ...
        'value_fields', {{'max_pass_ratio', 'num_feasible', 'num_total'}}, ...
        'fill_values', struct('max_pass_ratio', 0, 'num_feasible', 0, 'num_total', 0), ...
        'history_fill_mode', "zero", ...
        'history_origin', "initial_ns_min", ...
        'resolver_options', struct('y_fields', "max_pass_ratio"));
    history_view_spec = pass_view_spec;
    history_view_spec.domain_view = "history_full";
    history_view_spec.figure_name = sprintf('MB_legacyDG_passratio_historyFull_%s_%s.png', h_label, sensor_group);
    effective_view_spec = pass_view_spec;
    effective_view_spec.domain_view = "effective_full_range";
    effective_view_spec.figure_name = sprintf('MB_legacyDG_passratio_effectiveFullRange_%s_%s.png', h_label, sensor_group);
    zoom_view_spec = pass_view_spec;
    zoom_view_spec.domain_view = "frontier_zoom";
    zoom_view_spec.plot_window = pass_windows.frontier_zoom;
    zoom_view_spec.figure_name = sprintf('MB_legacyDG_passratio_frontierZoom_%s_%s.png', h_label, sensor_group);
    [pass_history_table, pass_padding_summary, pass_history_meta] = build_mb_passratio_domain_view(run.aggregate.passratio_phasecurve, search_domain, history_view_spec);
    [pass_effective_table, ~, pass_effective_meta] = build_mb_passratio_domain_view(run.aggregate.passratio_phasecurve, search_domain, effective_view_spec);
    [pass_zoom_table, ~, pass_zoom_meta] = build_mb_passratio_domain_view(run.aggregate.passratio_phasecurve, search_domain, zoom_view_spec);
    milestone_common_save_table(pass_history_table, pass_history_csv);
    milestone_common_save_table(pass_effective_table, pass_effective_csv);
    milestone_common_save_table(pass_zoom_table, pass_zoom_csv);
    milestone_common_save_table(pass_padding_summary, pass_padding_csv);

    history_options = pass_plot_options;
    history_options.plot_xlim_ns = pass_windows.history_full;
    history_options.plot_domain_label = "history_full";
    history_options.plot_domain_source = "history_full";
    fig_pass_history = plot_mb_fixed_h_passratio_phasecurve(pass_history_table, run.h_km, style, history_options);
    local_retitle(fig_pass_history, sprintf('legacyDG History-Full Pass-Ratio versus N_s at h = %.0f km [%s]', run.h_km, sensor_label));
    pass_history_png = fullfile(paths.figures, sprintf('MB_legacyDG_passratio_historyFull_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass_history, pass_history_png);
    write_mb_plot_domain_sidecar(pass_history_png, "history_full", "initial_search_domain_lower_bound", local_capture_axis_xlim(fig_pass_history), ...
        build_mb_passratio_view_sidecar_fields(fig_pass_history, pass_history_table, pass_history_csv, "history_full", pass_windows.history_full, pass_history_meta, struct( ...
        'figure_family', "legacyDG_passratio", ...
        'figure_style_mode', string(local_getfield_or(plot_options, 'figure_style_mode', "")), ...
        'primary_plot_mode', plot_mode_profile.passratio_primary_mode, ...
        'canonical_primary_mode', plot_mode_profile.canonical_primary_mode, ...
        'current_mode', "historyFull", ...
        'is_primary_selection', plot_mode_profile.passratio_primary_mode == "historyFull", ...
        'is_canonical_selection', plot_mode_profile.canonical_primary_mode == "historyFull", ...
        'expected_domain_behavior', "history_full_from_initial_ns_min_with_zero_padding", ...
        'actual_domain_behavior', "history_full_padded_table")));
    close(fig_pass_history);

    effective_options = pass_plot_options;
    effective_options.plot_xlim_ns = pass_windows.effective_full_range;
    effective_options.plot_domain_label = "effective_full_range";
    effective_options.plot_domain_source = "effective_full_range";
    fig_pass_effective = plot_mb_fixed_h_passratio_phasecurve(pass_effective_table, run.h_km, style, effective_options);
    local_retitle(fig_pass_effective, sprintf('legacyDG Effective Full-Range Pass-Ratio versus N_s at h = %.0f km [%s]', run.h_km, sensor_label));
    pass_effective_png = fullfile(paths.figures, sprintf('MB_legacyDG_passratio_effectiveFullRange_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass_effective, pass_effective_png);
    write_mb_plot_domain_sidecar(pass_effective_png, "effective_full_range", "effective_search_domain", local_capture_axis_xlim(fig_pass_effective), ...
        build_mb_passratio_view_sidecar_fields(fig_pass_effective, pass_effective_table, pass_effective_csv, "effective_full_range", pass_windows.effective_full_range, pass_effective_meta, struct( ...
        'figure_family', "legacyDG_passratio", ...
        'figure_style_mode', string(local_getfield_or(plot_options, 'figure_style_mode', "")), ...
        'primary_plot_mode', plot_mode_profile.passratio_primary_mode, ...
        'canonical_primary_mode', plot_mode_profile.canonical_primary_mode, ...
        'current_mode', "effectiveFullRange", ...
        'is_primary_selection', plot_mode_profile.passratio_primary_mode == "effectiveFullRange", ...
        'is_canonical_selection', plot_mode_profile.canonical_primary_mode == "effectiveFullRange", ...
        'expected_domain_behavior', "effective_domain_only_without_history_padding", ...
        'actual_domain_behavior', "effective_domain_view")));
    pass_alias_png = fullfile(paths.figures, sprintf('MB_legacyDG_passratio_fullRange_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass_effective, pass_alias_png);
    write_mb_plot_domain_sidecar(pass_alias_png, "effective_full_range", "effective_search_domain", local_capture_axis_xlim(fig_pass_effective), ...
        build_mb_passratio_view_sidecar_fields(fig_pass_effective, pass_effective_table, pass_effective_csv, "effective_full_range", pass_windows.effective_full_range, pass_effective_meta, struct('figure_family', "legacyDG_passratio")));
    legacy_alias_png = fullfile(paths.figures, sprintf('MB_legacyDG_passratio_globalTrend_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass_effective, legacy_alias_png);
    write_mb_plot_domain_sidecar(legacy_alias_png, "effective_full_range", "effective_search_domain", local_capture_axis_xlim(fig_pass_effective), ...
        build_mb_passratio_view_sidecar_fields(fig_pass_effective, pass_effective_table, pass_effective_csv, "effective_full_range", pass_windows.effective_full_range, pass_effective_meta, struct('figure_family', "legacyDG_passratio")));
    close(fig_pass_effective);

    legacy_zoom_options = pass_plot_options;
    legacy_zoom_options.plot_xlim_ns = pass_windows.frontier_zoom;
    legacy_zoom_options.plot_domain_label = "frontier_zoom";
    legacy_zoom_options.plot_domain_source = "frontier_zoom";
    fig_pass_zoom = plot_mb_fixed_h_passratio_phasecurve(pass_zoom_table, run.h_km, style, legacy_zoom_options);
    local_retitle(fig_pass_zoom, sprintf('legacyDG Frontier Zoom Pass-Ratio versus N_s at h = %.0f km [%s]', run.h_km, sensor_label));
    pass_zoom_png = fullfile(paths.figures, sprintf('MB_legacyDG_passratio_frontierZoom_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass_zoom, pass_zoom_png);
    write_mb_plot_domain_sidecar(pass_zoom_png, "frontier_zoom", "frontier_zoom_window", local_capture_axis_xlim(fig_pass_zoom), ...
        build_mb_passratio_view_sidecar_fields(fig_pass_zoom, pass_zoom_table, pass_zoom_csv, "frontier_zoom", pass_windows.frontier_zoom, pass_zoom_meta, struct( ...
        'figure_family', "legacyDG_passratio", ...
        'primary_plot_mode', plot_mode_profile.passratio_primary_mode, ...
        'canonical_primary_mode', plot_mode_profile.canonical_primary_mode, ...
        'current_mode', "frontierZoom", ...
        'is_primary_selection', plot_mode_profile.passratio_primary_mode == "frontierZoom", ...
        'is_canonical_selection', plot_mode_profile.canonical_primary_mode == "frontierZoom", ...
        'expected_domain_behavior', "frontier_zoom_local_window", ...
        'actual_domain_behavior', "frontier_zoom_view")));
    close(fig_pass_zoom);
    local_maybe_export_paper_ready(@() plot_mb_fixed_h_passratio_phasecurve(run.aggregate.passratio_phasecurve, run.h_km, style, local_build_paper_options(pass_plot_options)), ...
        fullfile(paths.figures, sprintf('MB_legacyDG_passratio_effectiveFullRange_%s_%s_paperReady.png', h_label, sensor_group)), ...
        "legacyDG_passratio", diagnostics, plot_options);

    local_surface = annotate_mb_heatmap_surface_semantics(run.aggregate.requirement_surface_iP, search_domain, struct('domain_mode', "local"));
    global_surface = build_mb_global_skeleton_heatmap_surface(run.aggregate.requirement_surface_iP, search_domain, struct('h_km', run.h_km, 'family_name', string(run.family_name)));
    global_surface = annotate_mb_heatmap_surface_semantics(global_surface, search_domain, struct('domain_mode', "globalSkeleton"));
    milestone_common_save_table(local_getfield_or(local_surface, 'surface_table', table()), heat_local_csv);
    milestone_common_save_table(local_getfield_or(global_surface, 'surface_table', table()), heat_global_csv);
    milestone_common_save_table(local_getfield_or(local_surface, 'surface_table', table()), heat_state_local_csv);
    milestone_common_save_table(local_getfield_or(global_surface, 'surface_table', table()), heat_state_global_csv);

    fig_heat = plot_mb_fixed_h_requirement_heatmap_iP(local_surface, style, struct( ...
        'boundary_hit_table', diagnostics.boundary_hit_table, ...
        'heatmap_edge_table', diagnostics.heatmap_edge_table, ...
        'search_domain_bounds', [search_domain.ns_search_min, search_domain.ns_search_max], ...
        'domain_summary', char(string(local_getfield_or(plot_options, 'search_domain_label', ""))), ...
        'heatmap_render_mode', "numeric_requirement", ...
        'plot_domain_label', "local_defined_surface", ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    local_retitle(fig_heat, sprintf('legacyDG Local Minimum Feasible Constellation Heatmap at h = %.0f km [%s]', run.h_km, sensor_label));
    heat_local_png = fullfile(paths.figures, sprintf('MB_legacyDG_minimumNs_heatmap_local_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_heat, heat_local_png);
    write_mb_plot_domain_sidecar(heat_local_png, "local_defined_surface", "current_defined_surface", [], ...
        build_mb_heatmap_sidecar_fields(local_surface, "numeric_requirement", "local", struct( ...
        'figure_style_mode', string(local_getfield_or(plot_options, 'figure_style_mode', "")), ...
        'heatmap_primary_value_mode', plot_mode_profile.heatmap_primary_value_mode, ...
        'heatmap_primary_domain_mode', plot_mode_profile.heatmap_primary_domain_mode, ...
        'heatmap_is_primary_selection', plot_mode_profile.heatmap_primary_value_mode == "numeric_requirement" && plot_mode_profile.heatmap_primary_domain_mode == "local", ...
        'canonical_heatmap_selection_key', plot_mode_profile.heatmap_primary_selection.selection_key)));
    close(fig_heat);

    fig_heat_global = plot_mb_fixed_h_requirement_heatmap_iP(global_surface, style, struct( ...
        'boundary_hit_table', diagnostics.boundary_hit_table, ...
        'heatmap_edge_table', diagnostics.heatmap_edge_table, ...
        'search_domain_bounds', [search_domain.history_ns_min, search_domain.history_ns_max], ...
        'domain_summary', char(string(local_getfield_or(plot_options, 'search_domain_label', ""))), ...
        'heatmap_render_mode', "numeric_requirement", ...
        'plot_domain_label', "global_skeleton_surface", ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    local_retitle(fig_heat_global, sprintf('legacyDG Global-Skeleton Minimum Feasible Constellation Heatmap at h = %.0f km [%s]', run.h_km, sensor_label));
    heat_global_png = fullfile(paths.figures, sprintf('MB_legacyDG_minimumNs_heatmap_globalSkeleton_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_heat_global, heat_global_png);
    write_mb_plot_domain_sidecar(heat_global_png, "global_skeleton_surface", "global_i_p_skeleton", [], ...
        build_mb_heatmap_sidecar_fields(global_surface, "numeric_requirement", "globalSkeleton", struct( ...
        'figure_style_mode', string(local_getfield_or(plot_options, 'figure_style_mode', "")), ...
        'heatmap_primary_value_mode', plot_mode_profile.heatmap_primary_value_mode, ...
        'heatmap_primary_domain_mode', plot_mode_profile.heatmap_primary_domain_mode, ...
        'heatmap_is_primary_selection', plot_mode_profile.heatmap_primary_value_mode == "numeric_requirement" && plot_mode_profile.heatmap_primary_domain_mode == "globalSkeleton", ...
        'canonical_heatmap_selection_key', plot_mode_profile.heatmap_primary_selection.selection_key)));
    close(fig_heat_global);

    fig_heat_state = plot_mb_fixed_h_requirement_heatmap_iP(local_surface, style, struct( ...
        'boundary_hit_table', diagnostics.boundary_hit_table, ...
        'heatmap_edge_table', diagnostics.heatmap_edge_table, ...
        'search_domain_bounds', [search_domain.ns_search_min, search_domain.ns_search_max], ...
        'domain_summary', char(string(local_getfield_or(plot_options, 'search_domain_label', ""))), ...
        'heatmap_render_mode', "state_map", ...
        'plot_domain_label', "state_map_local", ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    local_retitle(fig_heat_state, sprintf('legacyDG Local Heatmap State Map at h = %.0f km [%s]', run.h_km, sensor_label));
    heat_state_local_png = fullfile(paths.figures, sprintf('MB_legacyDG_heatmap_stateMap_local_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_heat_state, heat_state_local_png);
    write_mb_plot_domain_sidecar(heat_state_local_png, "local_defined_surface", "current_defined_surface", [], ...
        build_mb_heatmap_sidecar_fields(local_surface, "state_map", "local", struct( ...
        'figure_style_mode', string(local_getfield_or(plot_options, 'figure_style_mode', "")), ...
        'heatmap_primary_value_mode', plot_mode_profile.heatmap_primary_value_mode, ...
        'heatmap_primary_domain_mode', plot_mode_profile.heatmap_primary_domain_mode, ...
        'heatmap_is_primary_selection', plot_mode_profile.heatmap_primary_value_mode == "state_map" && plot_mode_profile.heatmap_primary_domain_mode == "local", ...
        'canonical_heatmap_selection_key', plot_mode_profile.heatmap_primary_selection.selection_key)));
    close(fig_heat_state);

    fig_heat_state_global = plot_mb_fixed_h_requirement_heatmap_iP(global_surface, style, struct( ...
        'boundary_hit_table', diagnostics.boundary_hit_table, ...
        'heatmap_edge_table', diagnostics.heatmap_edge_table, ...
        'search_domain_bounds', [search_domain.history_ns_min, search_domain.history_ns_max], ...
        'domain_summary', char(string(local_getfield_or(plot_options, 'search_domain_label', ""))), ...
        'heatmap_render_mode', "state_map", ...
        'plot_domain_label', "state_map_global_skeleton", ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    local_retitle(fig_heat_state_global, sprintf('legacyDG Global-Skeleton Heatmap State Map at h = %.0f km [%s]', run.h_km, sensor_label));
    heat_state_global_png = fullfile(paths.figures, sprintf('MB_legacyDG_heatmap_stateMap_globalSkeleton_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_heat_state_global, heat_state_global_png);
    write_mb_plot_domain_sidecar(heat_state_global_png, "global_skeleton_surface", "global_i_p_skeleton", [], ...
        build_mb_heatmap_sidecar_fields(global_surface, "state_map", "globalSkeleton", struct( ...
        'figure_style_mode', string(local_getfield_or(plot_options, 'figure_style_mode', "")), ...
        'heatmap_primary_value_mode', plot_mode_profile.heatmap_primary_value_mode, ...
        'heatmap_primary_domain_mode', plot_mode_profile.heatmap_primary_domain_mode, ...
        'heatmap_is_primary_selection', plot_mode_profile.heatmap_primary_value_mode == "state_map" && plot_mode_profile.heatmap_primary_domain_mode == "globalSkeleton", ...
        'canonical_heatmap_selection_key', plot_mode_profile.heatmap_primary_selection.selection_key)));
    close(fig_heat_state_global);
    local_maybe_export_paper_ready(@() plot_mb_fixed_h_requirement_heatmap_iP(run.aggregate.requirement_surface_iP, style, struct( ...
        'boundary_hit_table', diagnostics.boundary_hit_table, ...
        'heatmap_edge_table', diagnostics.heatmap_edge_table, ...
        'search_domain_bounds', [search_domain.ns_search_min, search_domain.ns_search_max], ...
        'domain_summary', char(string(local_getfield_or(plot_options, 'search_domain_label', ""))), ...
        'figure_style', resolve_mb_figure_style_mode('paper_ready'))), ...
        fullfile(paths.figures, sprintf('MB_legacyDG_minimumNs_heatmap_iP_%s_%s_paperReady.png', h_label, sensor_group)), ...
        "legacyDG_heatmap", diagnostics, plot_options);

    pass_mode_files = struct( ...
        'historyFull', struct('csv', string(pass_history_csv), 'png', string(pass_history_png), 'table', pass_history_table), ...
        'effectiveFullRange', struct('csv', string(pass_effective_csv), 'png', string(pass_effective_png), 'table', pass_effective_table), ...
        'frontierZoom', struct('csv', string(pass_zoom_csv), 'png', string(pass_zoom_png), 'table', pass_zoom_table));
    primary_pass = pass_mode_files.(char(plot_mode_profile.passratio_primary_mode));
    milestone_common_save_table(primary_pass.table, pass_primary_csv);
    pass_primary_png = fullfile(paths.figures, sprintf('MB_legacyDG_passratio_primary_%s_%s.png', h_label, sensor_group));
    local_copy_figure_with_sidecar(primary_pass.png, string(pass_primary_png));
    pass_alias_png = fullfile(paths.figures, sprintf('MB_legacyDG_passratio_fullRange_%s_%s.png', h_label, sensor_group));
    local_copy_figure_with_sidecar(primary_pass.png, string(pass_alias_png));
    legacy_alias_png = fullfile(paths.figures, sprintf('MB_legacyDG_passratio_globalTrend_%s_%s.png', h_label, sensor_group));
    local_copy_figure_with_sidecar(primary_pass.png, string(legacy_alias_png));

    numeric_primary_surface = local_surface;
    numeric_primary_png = string(heat_local_png);
    numeric_primary_csv = string(heat_local_csv);
    if plot_mode_profile.heatmap_primary_domain_mode == "globalSkeleton"
        numeric_primary_surface = global_surface;
        numeric_primary_png = string(heat_global_png);
        numeric_primary_csv = string(heat_global_csv);
    end
    milestone_common_save_table(local_getfield_or(numeric_primary_surface, 'surface_table', table()), heat_csv);
    milestone_common_save_table(local_getfield_or(numeric_primary_surface, 'surface_table', table()), heat_primary_csv);
    heat_png = fullfile(paths.figures, sprintf('MB_legacyDG_minimumNs_heatmap_iP_%s_%s.png', h_label, sensor_group));
    local_copy_figure_with_sidecar(numeric_primary_png, string(heat_png));
    heat_primary_png = fullfile(paths.figures, sprintf('MB_legacyDG_minimumNs_heatmap_primary_%s_%s.png', h_label, sensor_group));
    local_copy_figure_with_sidecar(numeric_primary_png, string(heat_primary_png));

    state_primary_surface = local_surface;
    state_primary_png = string(heat_state_local_png);
    state_primary_csv = string(heat_state_local_csv);
    if plot_mode_profile.heatmap_primary_domain_mode == "globalSkeleton"
        state_primary_surface = global_surface;
        state_primary_png = string(heat_state_global_png);
        state_primary_csv = string(heat_state_global_csv);
    end
    milestone_common_save_table(local_getfield_or(state_primary_surface, 'surface_table', table()), heat_state_csv);
    milestone_common_save_table(local_getfield_or(state_primary_surface, 'surface_table', table()), heat_state_primary_csv);
    heat_state_png = fullfile(paths.figures, sprintf('MB_legacyDG_heatmap_stateMap_%s_%s.png', h_label, sensor_group));
    local_copy_figure_with_sidecar(state_primary_png, string(heat_state_png));
    heat_state_primary_png = fullfile(paths.figures, sprintf('MB_legacyDG_heatmap_stateMap_primary_%s_%s.png', h_label, sensor_group));
    local_copy_figure_with_sidecar(state_primary_png, string(heat_state_primary_png));

    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratioHistory_%s', h_label))) = string(pass_history_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratioEffective_%s', h_label))) = string(pass_effective_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratioZoom_%s', h_label))) = string(pass_zoom_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratioPrimary_%s', h_label))) = string(pass_primary_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('minimumNs_heatmap_local_%s', h_label))) = string(heat_local_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('minimumNs_heatmap_globalSkeleton_%s', h_label))) = string(heat_global_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('minimumNs_heatmap_iP_%s', h_label))) = string(heat_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('minimumNs_heatmap_primary_%s', h_label))) = string(heat_primary_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('heatmapStateMapLocal_%s', h_label))) = string(heat_state_local_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('heatmapStateMapGlobalSkeleton_%s', h_label))) = string(heat_state_global_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('heatmapStateMap_%s', h_label))) = string(heat_state_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('heatmapStateMapPrimary_%s', h_label))) = string(heat_state_primary_png);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_primary_%s', h_label))) = string(pass_primary_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('minimumNs_heatmap_iP_%s', h_label))) = string(heat_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('minimumNs_heatmap_primary_%s', h_label))) = string(heat_primary_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('minimumNs_heatmap_local_%s', h_label))) = string(heat_local_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('minimumNs_heatmap_globalSkeleton_%s', h_label))) = string(heat_global_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('heatmapStateMap_%s', h_label))) = string(heat_state_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('heatmapStateMap_primary_%s', h_label))) = string(heat_state_primary_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('heatmapStateMapLocal_%s', h_label))) = string(heat_state_local_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('heatmapStateMapGlobalSkeleton_%s', h_label))) = string(heat_state_global_csv);
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
effective_p_grid = reshape(local_getfield_or(effective_domain, 'P_grid', unique(run.design_table.P, 'sorted')), 1, []);
effective_i_grid = reshape(local_getfield_or(effective_domain, 'inclination_grid_deg', unique(run.design_table.i_deg, 'sorted')), 1, []);
global_p_grid = reshape(local_getfield_or(history_domain, 'P_grid', local_getfield_or(run_output.options, 'P_grid', effective_p_grid)), 1, []);
global_i_grid = reshape(local_getfield_or(history_domain, 'inclination_grid_deg', local_getfield_or(run_output.options, 'i_grid_deg', effective_i_grid)), 1, []);
search_domain = struct( ...
    'ns_search_min', local_getfield_or(effective_domain, 'ns_search_min', local_min_or_nan(run.design_table, 'Ns')), ...
    'ns_search_max', local_getfield_or(effective_domain, 'ns_search_max', local_max_or_nan(run.design_table, 'Ns')), ...
    'ns_search_step', local_getfield_or(effective_domain, 'ns_search_step', local_min_spacing(run.design_table, 'Ns')), ...
    'P_grid', effective_p_grid, ...
    'effective_P_grid', effective_p_grid, ...
    'global_P_grid', global_p_grid, ...
    'T_grid', reshape(local_getfield_or(effective_domain, 'T_grid', unique(run.design_table.T, 'sorted')), 1, []), ...
    'inclination_grid_deg', effective_i_grid, ...
    'effective_inclination_grid_deg', effective_i_grid, ...
    'global_inclination_grid_deg', global_i_grid, ...
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

function summary_table = local_build_summary_table(run_output, plot_options)
plot_mode_profile = local_resolve_plot_mode_profile(plot_options);
summary_table = table('Size', [numel(run_output.runs), 12], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'string', 'string', 'string', 'string', 'string', 'string'}, ...
    'VariableNames', {'semantic_mode', 'sensor_group', 'h_km', 'design_count', 'feasible_count', 'minimum_feasible_Ns', 'family_name', ...
    'passratio_primary_mode', 'heatmap_primary_value_mode', 'heatmap_primary_domain_mode', 'canonical_primary_mode', 'canonical_passratio_figure'});
for idx = 1:numel(run_output.runs)
    run = run_output.runs(idx);
    h_label = sprintf('h%d', round(run.h_km));
    summary_table(idx, :) = { ...
        "legacyDG", ...
        string(run_output.sensor_group.name), ...
        run.h_km, ...
        height(run.design_table), ...
        height(run.feasible_table), ...
        local_getfield_or(run.summary, 'minimum_feasible_Ns', missing), ...
        string(run.family_name), ...
        plot_mode_profile.passratio_primary_mode, ...
        plot_mode_profile.heatmap_primary_value_mode, ...
        plot_mode_profile.heatmap_primary_domain_mode, ...
        plot_mode_profile.canonical_primary_mode, ...
        string(sprintf('MB_legacyDG_passratio_primary_%s_%s.png', h_label, char(string(run_output.sensor_group.name))))};
end
end

function local_retitle(fig, title_text)
ax = get(fig, 'CurrentAxes');
if isempty(ax)
    ax = axes(fig);
end
title(ax, title_text);
end

function xlim_values = local_capture_axis_xlim(fig)
xlim_values = capture_mb_primary_axes_xlim(fig);
end

function profile = local_resolve_plot_mode_profile(plot_options)
profile = resolve_mb_plot_mode_profile(local_getfield_or(plot_options, 'runtime', struct()));
if isfield(plot_options, 'plot_mode_profile') && isstruct(plot_options.plot_mode_profile)
    profile = plot_options.plot_mode_profile;
end
end

function local_copy_figure_with_sidecar(source_png, target_png)
source_png = char(string(source_png));
target_png = char(string(target_png));
if strcmpi(source_png, target_png)
    return;
end
copyfile(source_png, target_png);
[source_folder, source_stem, ~] = fileparts(source_png);
[target_folder, target_stem, ~] = fileparts(target_png);
source_meta = fullfile(source_folder, [source_stem, '.meta.json']);
target_meta = fullfile(target_folder, [target_stem, '.meta.json']);
if isfile(source_meta)
    copyfile(source_meta, target_meta);
end
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
