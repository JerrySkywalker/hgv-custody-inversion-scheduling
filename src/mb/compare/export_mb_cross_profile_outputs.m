function artifacts = export_mb_cross_profile_outputs(run_outputs, paths, plot_options)
%EXPORT_MB_CROSS_PROFILE_OUTPUTS Export cross-profile overlays across sensor groups.

artifacts = struct('tables', struct(), 'figures', struct(), 'summary', struct(), 'summary_table', table(), 'export_grade_table', table());

if nargin < 2 || isempty(paths) || isempty(run_outputs)
    return;
end
if nargin < 3 || isempty(plot_options)
    plot_options = struct();
end

summary_chunks = {};
summary_cursor = 0;
grade_chunks = {};
grade_cursor = 0;

[legacy_artifacts, legacy_summary, legacy_grade] = local_export_mode_family(run_outputs, paths, "legacyDG", plot_options);
artifacts.tables = milestone_common_merge_structs(artifacts.tables, legacy_artifacts.tables);
artifacts.figures = milestone_common_merge_structs(artifacts.figures, legacy_artifacts.figures);
if ~isempty(legacy_summary)
    summary_cursor = summary_cursor + 1;
    summary_chunks{summary_cursor, 1} = legacy_summary; %#ok<AGROW>
end
if ~isempty(legacy_grade)
    grade_cursor = grade_cursor + 1;
    grade_chunks{grade_cursor, 1} = legacy_grade; %#ok<AGROW>
end

[closed_artifacts, closed_summary, closed_grade] = local_export_mode_family(run_outputs, paths, "closedD", plot_options);
artifacts.tables = milestone_common_merge_structs(artifacts.tables, closed_artifacts.tables);
artifacts.figures = milestone_common_merge_structs(artifacts.figures, closed_artifacts.figures);
if ~isempty(closed_summary)
    summary_cursor = summary_cursor + 1;
    summary_chunks{summary_cursor, 1} = closed_summary; %#ok<AGROW>
end
if ~isempty(closed_grade)
    grade_cursor = grade_cursor + 1;
    grade_chunks{grade_cursor, 1} = closed_grade; %#ok<AGROW>
end

[dg_artifacts, dg_summary, dg_grade] = local_export_legacy_dg_overlays(run_outputs, paths);
artifacts.tables = milestone_common_merge_structs(artifacts.tables, dg_artifacts.tables);
artifacts.figures = milestone_common_merge_structs(artifacts.figures, dg_artifacts.figures);
if ~isempty(dg_summary)
    summary_cursor = summary_cursor + 1;
    summary_chunks{summary_cursor, 1} = dg_summary; %#ok<AGROW>
end
if ~isempty(dg_grade)
    grade_cursor = grade_cursor + 1;
    grade_chunks{grade_cursor, 1} = dg_grade; %#ok<AGROW>
end

if summary_cursor > 0
    artifacts.summary_table = vertcat(summary_chunks{1:summary_cursor});
    summary_csv = fullfile(paths.tables, 'MB_profileCompare_summary.csv');
    milestone_common_save_table(artifacts.summary_table, summary_csv);
    artifacts.tables.summary = string(summary_csv);
end
if grade_cursor > 0
    artifacts.export_grade_table = vertcat(grade_chunks{1:grade_cursor});
    grade_csv = fullfile(paths.tables, 'MB_profileCompare_export_grade.csv');
    milestone_common_save_table(artifacts.export_grade_table, grade_csv);
    artifacts.tables.export_grade = string(grade_csv);
end

artifacts.summary = struct( ...
    'legacyDG_groups', {local_collect_sensor_groups(run_outputs, "legacyDG")}, ...
    'closedD_groups', {local_collect_sensor_groups(run_outputs, "closedD")}, ...
    'has_strict_stage05_reference', any(strcmp(local_collect_sensor_groups(run_outputs, "legacyDG"), 'stage05_strict_reference')));
end

function [artifacts, summary_table, grade_table] = local_export_mode_family(run_outputs, paths, semantic_mode, plot_options)
artifacts = struct('tables', struct(), 'figures', struct());
summary_table = table();
grade_table = table();

mode_runs = run_outputs(arrayfun(@(r) r.mode == semantic_mode, run_outputs));
if isempty(mode_runs)
    return;
end

contexts = local_collect_contexts(mode_runs);
summary_chunks = {};
summary_cursor = 0;
grade_chunks = {};
grade_cursor = 0;
for idx_ctx = 1:size(contexts, 1)
    h_km = contexts{idx_ctx, 1};
    family_name = contexts{idx_ctx, 2};
    context_runs = local_pick_runs(mode_runs, h_km, family_name);
    if isempty(context_runs)
        continue;
    end

    [pass_table, pass_summary] = local_build_passratio_overlay_table(context_runs, semantic_mode, h_km, family_name);
    context_tag = local_context_tag(h_km, family_name, contexts);
    if ~isempty(pass_table)
        plot_mode_profile = local_resolve_plot_mode_profile(plot_options);
        pass_csv = fullfile(paths.tables, sprintf('MB_profileCompare_%s_passratio_%s.csv', char(semantic_mode), context_tag));
        pass_primary_csv = fullfile(paths.tables, sprintf('MB_profileCompare_%s_passratio_primary_%s.csv', char(semantic_mode), context_tag));
        pass_history_csv = fullfile(paths.tables, sprintf('MB_profileCompare_%s_passratio_historyFull_%s.csv', char(semantic_mode), context_tag));
        pass_effective_csv = fullfile(paths.tables, sprintf('MB_profileCompare_%s_passratio_effectiveFullRange_%s.csv', char(semantic_mode), context_tag));
        pass_zoom_csv = fullfile(paths.tables, sprintf('MB_profileCompare_%s_passratio_frontierZoom_%s.csv', char(semantic_mode), context_tag));
        pass_padding_csv = fullfile(paths.tables, sprintf('MB_profileCompare_%s_passratio_historyPadding_%s.csv', char(semantic_mode), context_tag));
        pass_summary_csv = fullfile(paths.tables, sprintf('MB_profileCompare_%s_passratioSummary_%s.csv', char(semantic_mode), context_tag));
        milestone_common_save_table(pass_table, pass_csv);
        milestone_common_save_table(pass_summary, pass_summary_csv);
        search_domain = local_build_cross_profile_search_domain(context_runs, pass_table);
        pass_windows = resolve_mb_passratio_plot_windows(pass_table, search_domain, struct('y_fields', "overlay_pass_ratio"));
        pass_view_spec = struct( ...
            'group_fields', {{'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name'}}, ...
            'value_fields', {{'overlay_pass_ratio'}}, ...
            'fill_values', struct('overlay_pass_ratio', 0), ...
            'history_fill_mode', "zero", ...
            'history_origin', "initial_ns_min", ...
            'resolver_options', struct('y_fields', "overlay_pass_ratio"));
        history_view_spec = pass_view_spec;
        history_view_spec.domain_view = "history_full";
        history_view_spec.figure_name = sprintf('MB_profileCompare_%s_passratio_historyFull_%s.png', char(semantic_mode), context_tag);
        effective_view_spec = pass_view_spec;
        effective_view_spec.domain_view = "effective_full_range";
        effective_view_spec.figure_name = sprintf('MB_profileCompare_%s_passratio_effectiveFullRange_%s.png', char(semantic_mode), context_tag);
        zoom_view_spec = pass_view_spec;
        zoom_view_spec.domain_view = "frontier_zoom";
        zoom_view_spec.plot_window = pass_windows.frontier_zoom;
        zoom_view_spec.figure_name = sprintf('MB_profileCompare_%s_passratio_frontierZoom_%s.png', char(semantic_mode), context_tag);
        [pass_history_table, pass_padding_summary, pass_history_meta] = build_mb_passratio_domain_view(pass_table, search_domain, history_view_spec);
        [pass_effective_table, ~, pass_effective_meta] = build_mb_passratio_domain_view(pass_table, search_domain, effective_view_spec);
        [pass_zoom_table, ~, pass_zoom_meta] = build_mb_passratio_domain_view(pass_table, search_domain, zoom_view_spec);
        milestone_common_save_table(pass_history_table, pass_history_csv);
        milestone_common_save_table(pass_effective_table, pass_effective_csv);
        milestone_common_save_table(pass_zoom_table, pass_zoom_csv);
        milestone_common_save_table(pass_padding_summary, pass_padding_csv);

        fig_pass_history = plot_mb_cross_profile_passratio_overlay(pass_history_table, pass_summary, h_km, semantic_mode, family_name, struct( ...
            'plot_xlim_ns', pass_windows.history_full, ...
            'plot_domain_label', "history_full", ...
            'plot_domain_source', "history_full", ...
            'subtitle_text', "Cross-profile envelope from the original search-history lower bound"));
        history_xlim = local_capture_axis_xlim(fig_pass_history);
        pass_history_png = fullfile(paths.figures, sprintf('MB_profileCompare_%s_passratio_historyFull_%s.png', char(semantic_mode), context_tag));
        milestone_common_save_figure(fig_pass_history, pass_history_png);
        write_mb_plot_domain_sidecar(pass_history_png, "history_full", "initial_search_domain_lower_bound", history_xlim, ...
            build_mb_passratio_view_sidecar_fields(fig_pass_history, pass_history_table, pass_history_csv, "history_full", pass_windows.history_full, pass_history_meta, struct( ...
            'figure_family', string(semantic_mode) + "_cross_profile_passratio", ...
            'expected_domain_behavior', "history_full_from_initial_ns_min_with_zero_padding", ...
            'actual_domain_behavior', "history_full_padded_table")));
        close(fig_pass_history);

        fig_pass_effective = plot_mb_cross_profile_passratio_overlay(pass_effective_table, pass_summary, h_km, semantic_mode, family_name, struct( ...
            'plot_xlim_ns', pass_windows.effective_full_range, ...
            'plot_domain_label', "effective_full_range", ...
            'plot_domain_source', "effective_full_range", ...
            'subtitle_text', "Cross-profile envelope over the final effective expanded domain"));
        effective_xlim = local_capture_axis_xlim(fig_pass_effective);
        pass_effective_png = fullfile(paths.figures, sprintf('MB_profileCompare_%s_passratio_effectiveFullRange_%s.png', char(semantic_mode), context_tag));
        milestone_common_save_figure(fig_pass_effective, pass_effective_png);
        write_mb_plot_domain_sidecar(pass_effective_png, "effective_full_range", "effective_search_domain", effective_xlim, ...
            build_mb_passratio_view_sidecar_fields(fig_pass_effective, pass_effective_table, pass_effective_csv, "effective_full_range", pass_windows.effective_full_range, pass_effective_meta, struct( ...
            'figure_family', string(semantic_mode) + "_cross_profile_passratio", ...
            'expected_domain_behavior', "effective_domain_only_without_history_padding", ...
            'actual_domain_behavior', "effective_domain_view")));
        close(fig_pass_effective);

        fig_pass_zoom = plot_mb_cross_profile_passratio_overlay(pass_zoom_table, pass_summary, h_km, semantic_mode, family_name, struct( ...
            'plot_xlim_ns', pass_windows.frontier_zoom, ...
            'plot_domain_label', "frontier_zoom", ...
            'plot_domain_source', "frontier_zoom", ...
            'subtitle_text', "Cross-profile envelope focused on the local frontier neighborhood"));
        zoom_xlim = local_capture_axis_xlim(fig_pass_zoom);
        pass_zoom_png = fullfile(paths.figures, sprintf('MB_profileCompare_%s_passratio_frontierZoom_%s.png', char(semantic_mode), context_tag));
        milestone_common_save_figure(fig_pass_zoom, pass_zoom_png);
        write_mb_plot_domain_sidecar(pass_zoom_png, "frontier_zoom", "frontier_zoom_window", zoom_xlim, ...
            build_mb_passratio_view_sidecar_fields(fig_pass_zoom, pass_zoom_table, pass_zoom_csv, "frontier_zoom", pass_windows.frontier_zoom, pass_zoom_meta, struct( ...
            'figure_family', string(semantic_mode) + "_cross_profile_passratio", ...
            'expected_domain_behavior', "frontier_zoom_local_window", ...
            'actual_domain_behavior', "frontier_zoom_view")));
        close(fig_pass_zoom);

        primary_mode = plot_mode_profile.cross_profile_primary_mode;
        pass_mode_files = struct( ...
            'historyFull', struct('csv', string(pass_history_csv), 'png', string(pass_history_png), 'table', pass_history_table), ...
            'effectiveFullRange', struct('csv', string(pass_effective_csv), 'png', string(pass_effective_png), 'table', pass_effective_table), ...
            'frontierZoom', struct('csv', string(pass_zoom_csv), 'png', string(pass_zoom_png), 'table', pass_zoom_table));
        primary_pass = pass_mode_files.(char(primary_mode));
        milestone_common_save_table(primary_pass.table, pass_primary_csv);
        pass_primary_png = fullfile(paths.figures, sprintf('MB_profileCompare_%s_passratio_primary_%s.png', char(semantic_mode), context_tag));
        local_copy_figure_with_sidecar(primary_pass.png, string(pass_primary_png));
        pass_alias_png = fullfile(paths.figures, sprintf('MB_profileCompare_%s_passratio_fullRange_%s.png', char(semantic_mode), context_tag));
        local_copy_figure_with_sidecar(primary_pass.png, string(pass_alias_png));
        legacy_alias_png = fullfile(paths.figures, sprintf('MB_profileCompare_%s_passratio_%s.png', char(semantic_mode), context_tag));
        local_copy_figure_with_sidecar(primary_pass.png, string(legacy_alias_png));

        pass_summary = local_apply_passratio_render_summary(pass_summary, pass_history_meta, history_xlim, effective_xlim, zoom_xlim);
        milestone_common_save_table(pass_summary, pass_summary_csv);

        artifacts.tables.(matlab.lang.makeValidName(sprintf('%s_passratio_%s', char(semantic_mode), context_tag))) = string(pass_csv);
        artifacts.tables.(matlab.lang.makeValidName(sprintf('%s_passratioPrimary_%s', char(semantic_mode), context_tag))) = string(pass_primary_csv);
        artifacts.tables.(matlab.lang.makeValidName(sprintf('%s_passratioHistory_%s', char(semantic_mode), context_tag))) = string(pass_history_csv);
        artifacts.tables.(matlab.lang.makeValidName(sprintf('%s_passratioEffective_%s', char(semantic_mode), context_tag))) = string(pass_effective_csv);
        artifacts.tables.(matlab.lang.makeValidName(sprintf('%s_passratioZoom_%s', char(semantic_mode), context_tag))) = string(pass_zoom_csv);
        artifacts.tables.(matlab.lang.makeValidName(sprintf('%s_passratioHistoryPadding_%s', char(semantic_mode), context_tag))) = string(pass_padding_csv);
        artifacts.tables.(matlab.lang.makeValidName(sprintf('%s_passratioSummary_%s', char(semantic_mode), context_tag))) = string(pass_summary_csv);
        artifacts.figures.(matlab.lang.makeValidName(sprintf('%s_passratioPrimary_%s', char(semantic_mode), context_tag))) = string(pass_primary_png);
        artifacts.figures.(matlab.lang.makeValidName(sprintf('%s_passratioHistory_%s', char(semantic_mode), context_tag))) = string(pass_history_png);
        artifacts.figures.(matlab.lang.makeValidName(sprintf('%s_passratioEffective_%s', char(semantic_mode), context_tag))) = string(pass_effective_png);
        artifacts.figures.(matlab.lang.makeValidName(sprintf('%s_passratioZoom_%s', char(semantic_mode), context_tag))) = string(pass_zoom_png);
        summary_cursor = summary_cursor + 1;
        summary_chunks{summary_cursor, 1} = local_normalize_summary(pass_summary, "passratio_overlay"); %#ok<AGROW>
        grade_cursor = grade_cursor + 1;
        grade_chunks{grade_cursor, 1} = local_build_cross_profile_grade(pass_summary, "passratio_overlay", semantic_mode, h_km, family_name); %#ok<AGROW>
    end

    [frontier_table, frontier_summary] = local_build_frontier_overlay_table(context_runs, semantic_mode, h_km, family_name);
    if ~isempty(frontier_table)
        frontier_csv = fullfile(paths.tables, sprintf('MB_profileCompare_%s_frontier_%s.csv', char(semantic_mode), context_tag));
        frontier_summary_csv = fullfile(paths.tables, sprintf('MB_profileCompare_%s_frontierSummary_%s.csv', char(semantic_mode), context_tag));
        milestone_common_save_table(frontier_table, frontier_csv);
        milestone_common_save_table(frontier_summary, frontier_summary_csv);
        fig_frontier = plot_mb_cross_profile_frontier_overlay(frontier_table, frontier_summary, h_km, semantic_mode, family_name);
        frontier_png = fullfile(paths.figures, sprintf('MB_profileCompare_%s_frontier_%s.png', char(semantic_mode), context_tag));
        milestone_common_save_figure(fig_frontier, frontier_png);
        close(fig_frontier);

        artifacts.tables.(matlab.lang.makeValidName(sprintf('%s_frontier_%s', char(semantic_mode), context_tag))) = string(frontier_csv);
        artifacts.tables.(matlab.lang.makeValidName(sprintf('%s_frontierSummary_%s', char(semantic_mode), context_tag))) = string(frontier_summary_csv);
        artifacts.figures.(matlab.lang.makeValidName(sprintf('%s_frontier_%s', char(semantic_mode), context_tag))) = string(frontier_png);
        summary_cursor = summary_cursor + 1;
        summary_chunks{summary_cursor, 1} = local_normalize_summary(frontier_summary, "frontier_summary"); %#ok<AGROW>
        grade_cursor = grade_cursor + 1;
        grade_chunks{grade_cursor, 1} = local_build_cross_profile_grade(frontier_summary, "frontier_summary", semantic_mode, h_km, family_name); %#ok<AGROW>
    end
end

if summary_cursor > 0
    summary_table = vertcat(summary_chunks{1:summary_cursor});
end
if grade_cursor > 0
    grade_table = vertcat(grade_chunks{1:grade_cursor});
end
end

function [artifacts, summary_table, grade_table] = local_export_legacy_dg_overlays(run_outputs, paths)
artifacts = struct('tables', struct(), 'figures', struct());
summary_table = table();
grade_table = table();

mode_runs = run_outputs(arrayfun(@(r) r.mode == "legacyDG", run_outputs));
if isempty(mode_runs)
    return;
end

contexts = local_collect_contexts(mode_runs);
summary_chunks = {};
summary_cursor = 0;
grade_chunks = {};
grade_cursor = 0;
for idx_ctx = 1:size(contexts, 1)
    h_km = contexts{idx_ctx, 1};
    family_name = contexts{idx_ctx, 2};
    context_runs = local_pick_runs(mode_runs, h_km, family_name);
    if isempty(context_runs)
        continue;
    end

    [dg_table, dg_summary, dg_table_normalized] = local_build_dg_overlay_table(context_runs, h_km, family_name);
    if isempty(dg_table)
        continue;
    end

    context_tag = local_context_tag(h_km, family_name, contexts);
    dg_csv = fullfile(paths.tables, sprintf('MB_profileCompare_legacyDG_DG_envelope_%s.csv', context_tag));
    dg_summary_csv = fullfile(paths.tables, sprintf('MB_profileCompare_legacyDG_DG_summary_%s.csv', context_tag));
    milestone_common_save_table(dg_table, dg_csv);
    milestone_common_save_table(dg_summary, dg_summary_csv);
    fig_dg = plot_mb_cross_profile_dg_overlay(dg_table, dg_summary, h_km, family_name);
    dg_png = fullfile(paths.figures, sprintf('MB_profileCompare_legacyDG_DG_envelope_%s.png', context_tag));
    milestone_common_save_figure(fig_dg, dg_png);
    close(fig_dg);
    dg_norm_csv = fullfile(paths.tables, sprintf('MB_profileCompare_legacyDG_DG_envelopeNormalized_%s.csv', context_tag));
    milestone_common_save_table(dg_table_normalized, dg_norm_csv);
    fig_dg_norm = plot_mb_cross_profile_dg_overlay(dg_table_normalized, dg_summary, h_km, family_name, struct( ...
        'value_field', 'overlay_D_G_min_normalized', ...
        'y_label', 'normalized max D_G^{min} over i', ...
        'title_prefix', 'legacyDG cross-profile normalized D_G envelope', ...
        'note_override', 'normalized DG candidate'));
    dg_norm_png = fullfile(paths.figures, sprintf('MB_profileCompare_legacyDG_DG_envelopeNormalized_%s.png', context_tag));
    milestone_common_save_figure(fig_dg_norm, dg_norm_png);
    close(fig_dg_norm);

    artifacts.tables.(matlab.lang.makeValidName(sprintf('legacyDG_DG_envelope_%s', context_tag))) = string(dg_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('legacyDG_DG_envelopeNormalized_%s', context_tag))) = string(dg_norm_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('legacyDG_DG_summary_%s', context_tag))) = string(dg_summary_csv);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('legacyDG_DG_envelope_%s', context_tag))) = string(dg_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('legacyDG_DG_envelopeNormalized_%s', context_tag))) = string(dg_norm_png);
    summary_cursor = summary_cursor + 1;
    summary_chunks{summary_cursor, 1} = local_normalize_summary(dg_summary, "DG_envelope"); %#ok<AGROW>
    grade_cursor = grade_cursor + 1;
    grade_chunks{grade_cursor, 1} = local_build_cross_profile_grade(dg_summary, "DG_envelope", "legacyDG", h_km, family_name); %#ok<AGROW>
end

if summary_cursor > 0
    summary_table = vertcat(summary_chunks{1:summary_cursor});
end
if grade_cursor > 0
    grade_table = vertcat(grade_chunks{1:grade_cursor});
end
end

function [overlay_table, summary_table] = local_build_passratio_overlay_table(context_runs, semantic_mode, h_km, family_name)
rows = {};
summary_rows = {};
cursor = 0;
summary_cursor = 0;

for idx = 1:numel(context_runs)
    run = context_runs(idx).run;
    sensor_group = context_runs(idx).sensor_group;
    sensor_label = context_runs(idx).sensor_label;
    phasecurve = local_getfield_or(run.aggregate, 'passratio_phasecurve', table());
    if isempty(phasecurve) || ~all(ismember({'Ns', 'max_pass_ratio'}, phasecurve.Properties.VariableNames))
        continue;
    end

    env = groupsummary(phasecurve(:, {'Ns', 'max_pass_ratio'}), 'Ns', 'max', 'max_pass_ratio');
    env.Properties.VariableNames{'max_max_pass_ratio'} = 'overlay_pass_ratio';
    env = sortrows(env, 'Ns');

    for idx_row = 1:height(env)
        cursor = cursor + 1;
        rows{cursor, 1} = { ...
            string(semantic_mode), string(sensor_group), string(sensor_label), h_km, string(family_name), ...
            env.Ns(idx_row), env.overlay_pass_ratio(idx_row)}; %#ok<AGROW>
    end

    plateau_reached = local_curve_plateau_reached(env.overlay_pass_ratio);
    note = "";
    if ~plateau_reached
        note = "search domain may still be insufficient for full saturation";
    end
    initial_range = local_getfield_or(context_runs(idx), 'initial_range', []);
    history_ns_min = local_pick_initial(initial_range, 1);
    if ~isfinite(history_ns_min)
        history_ns_min = env.Ns(1);
    end
    summary_cursor = summary_cursor + 1;
    summary_rows{summary_cursor, 1} = { ...
        string(semantic_mode), string(sensor_group), string(sensor_label), h_km, string(family_name), ...
        env.Ns(1), env.Ns(end), env.overlay_pass_ratio(end), max(env.overlay_pass_ratio), plateau_reached, note, ...
        "effective_full_range", "effective_search_domain", history_ns_min, env.Ns(end)}; %#ok<AGROW>
end

overlay_table = local_cell_rows_to_table(rows, ...
    {'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name', 'Ns', 'overlay_pass_ratio'}, ...
    {'string', 'string', 'string', 'double', 'string', 'double', 'double'});
summary_table = local_cell_rows_to_table(summary_rows, ...
    {'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name', 'search_ns_min', 'search_ns_max', 'final_pass_ratio', 'peak_pass_ratio', 'right_plateau_reached', 'note', 'plot_domain_mode', 'x_domain_origin', 'x_min_rendered', 'x_max_rendered'}, ...
    {'string', 'string', 'string', 'double', 'string', 'double', 'double', 'double', 'double', 'logical', 'string', 'string', 'string', 'double', 'double'});
summary_table = local_sort_sensor_groups(summary_table);
overlay_table = local_sort_sensor_groups(overlay_table);
end

function [frontier_table, summary_table] = local_build_frontier_overlay_table(context_runs, semantic_mode, h_km, family_name)
rows = {};
summary_rows = {};
cursor = 0;
summary_cursor = 0;

for idx = 1:numel(context_runs)
    run = context_runs(idx).run;
    sensor_group = context_runs(idx).sensor_group;
    sensor_label = context_runs(idx).sensor_label;
    i_values = unique(run.design_table.i_deg, 'sorted');
    frontier = local_getfield_or(run.aggregate, 'frontier_vs_i', table());

    defined_count = 0;
    for idx_i = 1:numel(i_values)
        i_deg = i_values(idx_i);
        hit = [];
        if ~isempty(frontier) && ismember('i_deg', frontier.Properties.VariableNames)
            hit = frontier(frontier.i_deg == i_deg, :);
        end
        if isempty(hit)
            status = "undefined_no_feasible_point";
            min_ns = NaN;
            note = "No feasible frontier point found within current search domain";
        else
            status = "defined";
            min_ns = hit.minimum_feasible_Ns(1);
            note = "";
            defined_count = defined_count + 1;
        end
        cursor = cursor + 1;
        rows{cursor, 1} = { ...
            string(semantic_mode), string(sensor_group), string(sensor_label), h_km, string(family_name), ...
            i_deg, min_ns, status, note}; %#ok<AGROW>
    end

    summary_note = "";
    if defined_count == 0
        summary_note = "No feasible frontier point found within current search domain";
    elseif defined_count < numel(i_values)
        summary_note = "Frontier is only partially defined within current search domain";
    end
    summary_cursor = summary_cursor + 1;
    summary_rows{summary_cursor, 1} = { ...
        string(semantic_mode), string(sensor_group), string(sensor_label), h_km, string(family_name), ...
        numel(i_values), defined_count, local_safe_ratio(defined_count, max(numel(i_values), 1)), defined_count > 0, defined_count <= 1, summary_note}; %#ok<AGROW>
end

frontier_table = local_cell_rows_to_table(rows, ...
    {'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name', 'i_deg', 'minimum_feasible_Ns', 'frontier_status', 'note'}, ...
    {'string', 'string', 'string', 'double', 'string', 'double', 'double', 'string', 'string'});
summary_table = local_cell_rows_to_table(summary_rows, ...
    {'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name', 'sampled_inclination_count', 'frontier_defined_count', 'frontier_coverage_ratio', 'frontier_any_defined', 'frontier_single_point_only', 'note'}, ...
    {'string', 'string', 'string', 'double', 'string', 'double', 'double', 'double', 'logical', 'logical', 'string'});
summary_table = local_sort_sensor_groups(summary_table);
frontier_table = local_sort_sensor_groups(frontier_table);
end

function [dg_table, summary_table, dg_table_normalized] = local_build_dg_overlay_table(context_runs, h_km, family_name)
rows = {};
summary_rows = {};
cursor = 0;
summary_cursor = 0;

for idx = 1:numel(context_runs)
    run = context_runs(idx).run;
    sensor_group = context_runs(idx).sensor_group;
    sensor_label = context_runs(idx).sensor_label;
    dg_envelope = local_getfield_or(run.aggregate, 'dg_envelope', table());
    if isempty(dg_envelope) || ~all(ismember({'Ns', 'max_D_G_min', 'max_pass_ratio'}, dg_envelope.Properties.VariableNames))
        continue;
    end

    env = groupsummary(dg_envelope(:, {'Ns', 'max_D_G_min', 'max_pass_ratio'}), 'Ns', 'max', {'max_D_G_min', 'max_pass_ratio'});
    env.Properties.VariableNames{'max_max_D_G_min'} = 'overlay_D_G_min';
    env.Properties.VariableNames{'max_max_pass_ratio'} = 'overlay_pass_ratio';
    env = sortrows(env, 'Ns');

    for idx_row = 1:height(env)
        cursor = cursor + 1;
        rows{cursor, 1} = { ...
            "legacyDG", string(sensor_group), string(sensor_label), h_km, string(family_name), ...
            env.Ns(idx_row), env.overlay_D_G_min(idx_row), env.overlay_pass_ratio(idx_row)}; %#ok<AGROW>
    end

    plateau_reached = local_curve_plateau_reached(env.overlay_pass_ratio);
    note = "";
    if ~plateau_reached
        note = "search domain may still be insufficient for full saturation";
    end
    summary_cursor = summary_cursor + 1;
    summary_rows{summary_cursor, 1} = { ...
        "legacyDG", string(sensor_group), string(sensor_label), h_km, string(family_name), ...
        env.Ns(end), max(env.overlay_D_G_min), env.overlay_D_G_min(end), env.overlay_pass_ratio(end), plateau_reached, note}; %#ok<AGROW>
end

dg_table = local_cell_rows_to_table(rows, ...
    {'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name', 'Ns', 'overlay_D_G_min', 'overlay_pass_ratio'}, ...
    {'string', 'string', 'string', 'double', 'string', 'double', 'double', 'double'});
summary_table = local_cell_rows_to_table(summary_rows, ...
    {'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name', 'search_ns_max', 'max_raw_D_G', 'final_overlay_D_G_min', 'final_pass_ratio', 'right_plateau_reached', 'note'}, ...
    {'string', 'string', 'string', 'double', 'string', 'double', 'double', 'double', 'double', 'logical', 'string'});
summary_table = local_sort_sensor_groups(summary_table);
dg_table = local_sort_sensor_groups(dg_table);
dg_table_normalized = dg_table;
global_max = max(dg_table.overlay_D_G_min, [], 'omitnan');
if ~isfinite(global_max) || global_max <= 0
    global_max = 1;
end
dg_table_normalized.overlay_D_G_min_normalized = dg_table.overlay_D_G_min ./ global_max;
end

function contexts = local_collect_contexts(mode_runs)
contexts = cell(0, 2);
for idx = 1:numel(mode_runs)
    runs = mode_runs(idx).run_output.runs;
    for idx_run = 1:numel(runs)
        entry = {runs(idx_run).h_km, char(string(runs(idx_run).family_name))};
        if isempty(contexts)
            contexts = entry;
        else
            already = cellfun(@(h, f) isequal(h, entry{1}) && strcmp(f, entry{2}), contexts(:, 1), contexts(:, 2));
            if ~any(already)
                contexts(end + 1, :) = entry; %#ok<AGROW>
            end
        end
    end
end
contexts = sortrows(contexts, [1, 2]);
end

function context_runs = local_pick_runs(mode_runs, h_km, family_name)
context_runs = struct('sensor_group', {}, 'sensor_label', {}, 'run', {}, 'initial_range', {});
cursor = 0;
for idx = 1:numel(mode_runs)
    wrapper = mode_runs(idx);
    for idx_run = 1:numel(wrapper.run_output.runs)
        run = wrapper.run_output.runs(idx_run);
        if ~isequal(run.h_km, h_km) || ~strcmp(char(string(run.family_name)), char(string(family_name)))
            continue;
        end
        cursor = cursor + 1;
        context_runs(cursor, 1).sensor_group = char(string(wrapper.run_output.sensor_group.name)); %#ok<AGROW>
        context_runs(cursor, 1).sensor_label = char(format_mb_sensor_group_label(wrapper.run_output.sensor_group, "short"));
        context_runs(cursor, 1).run = run;
        context_runs(cursor, 1).initial_range = reshape(local_getfield_or(local_getfield_or(wrapper.run_output, 'options', struct()), 'Ns_initial_range', ...
            local_getfield_or(local_getfield_or(local_getfield_or(wrapper.run_output, 'options', struct()), 'search_domain', struct()), 'Ns_initial_range', [])), 1, []);
        break;
    end
end
if cursor > 0
    [~, order] = sort(local_sensor_rank({context_runs.sensor_group}));
    context_runs = context_runs(order);
end
end

function tag = local_context_tag(h_km, family_name, contexts)
tag = sprintf('h%d', round(h_km));
family_names = string(contexts(:, 2));
if numel(unique(family_names)) > 1
    tag = sprintf('%s_%s', tag, matlab.lang.makeValidName(char(string(family_name))));
end
end

function search_domain = local_build_cross_profile_search_domain(context_runs, overlay_table)
initial_candidates = [];
effective_max_candidates = [];
effective_min_candidates = [];
for idx = 1:numel(context_runs)
    run = context_runs(idx).run;
    expansion_state = local_getfield_or(run, 'expansion_state', struct());
    effective_domain = local_getfield_or(expansion_state, 'effective_search_domain', struct());
    effective_min_candidates(end + 1) = local_getfield_or(effective_domain, 'ns_search_min', NaN); %#ok<AGROW>
    effective_max_candidates(end + 1) = local_getfield_or(effective_domain, 'ns_search_max', NaN); %#ok<AGROW>
    initial_range = reshape(local_getfield_or(context_runs(idx), 'initial_range', []), 1, []);
    if numel(initial_range) >= 1 && isfinite(initial_range(1))
        initial_candidates(end + 1) = initial_range(1); %#ok<AGROW>
    end
end
search_domain = struct();
search_domain.Ns_initial_range = [local_non_nan_min(initial_candidates), NaN, local_non_nan_max(effective_max_candidates)];
search_domain.history_ns_min = local_non_nan_min(initial_candidates);
search_domain.history_ns_max = local_non_nan_max(effective_max_candidates);
search_domain.effective_ns_min = local_non_nan_min([effective_min_candidates, local_min_vector(overlay_table.Ns)]);
search_domain.effective_ns_max = local_non_nan_max([effective_max_candidates, local_max_vector(overlay_table.Ns)]);
end

function groups = local_collect_sensor_groups(run_outputs, semantic_mode)
hits = run_outputs(arrayfun(@(r) r.mode == semantic_mode, run_outputs));
if isempty(hits)
    groups = {};
    return;
end
groups = unique(arrayfun(@(r) string(r.sensor_group), hits), 'stable');
groups = cellstr(groups);
end

function plateau_reached = local_curve_plateau_reached(pass_values)
pass_values = pass_values(isfinite(pass_values));
if isempty(pass_values)
    plateau_reached = false;
    return;
end
tail = pass_values(max(1, end - 1):end);
plateau_reached = median(tail) >= 0.98;
end

function order = local_sensor_rank(groups)
preferred = ["stage05_strict_reference", "baseline", "optimistic", "robust"];
order = zeros(1, numel(groups));
for idx = 1:numel(groups)
    hit = find(preferred == string(groups{idx}), 1);
    if isempty(hit)
        order(idx) = numel(preferred) + idx;
    else
        order(idx) = hit;
    end
end
end

function T = local_sort_sensor_groups(T)
if isempty(T) || ~ismember('sensor_group', T.Properties.VariableNames)
    return;
end
rank = local_sensor_rank(cellstr(string(T.sensor_group)));
T.sensor_rank_tmp = rank(:);
sort_keys = {'sensor_rank_tmp'};
if ismember('i_deg', T.Properties.VariableNames)
    sort_keys{end + 1} = 'i_deg'; %#ok<AGROW>
elseif ismember('Ns', T.Properties.VariableNames)
    sort_keys{end + 1} = 'Ns'; %#ok<AGROW>
end
T = sortrows(T, sort_keys);
T.sensor_rank_tmp = [];
end

function T = local_cell_rows_to_table(rows, variable_names, variable_types)
if isempty(rows)
    T = table('Size', [0, numel(variable_names)], ...
        'VariableTypes', variable_types, ...
        'VariableNames', variable_names);
    return;
end
T = cell2table(vertcat(rows{:}), 'VariableNames', variable_names);
for idx = 1:numel(variable_names)
    if strcmp(variable_types{idx}, 'string')
        T.(variable_names{idx}) = string(T.(variable_names{idx}));
    elseif strcmp(variable_types{idx}, 'double')
        T.(variable_names{idx}) = double(T.(variable_names{idx}));
    elseif strcmp(variable_types{idx}, 'logical')
        T.(variable_names{idx}) = logical(T.(variable_names{idx}));
    end
end
end

function summary_table = local_normalize_summary(T, summary_kind)
summary_table = table('Size', [height(T), 15], ...
    'VariableTypes', {'string', 'string', 'string', 'string', 'double', 'string', 'double', 'double', 'logical', 'string', 'double', 'double', 'double', 'logical', 'logical'}, ...
    'VariableNames', {'summary_kind', 'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name', 'metric_primary', 'metric_secondary', 'status_flag', 'note', 'history_full_rendered_min_ns', 'effective_full_rendered_min_ns', 'frontier_zoom_rendered_min_ns', 'history_padding_applied', 'domain_consistency_pass'});
summary_table.summary_kind = repmat(string(summary_kind), height(T), 1);
summary_table.semantic_mode = string(local_pick_or_repeat(T, 'semantic_mode', "", height(T)));
summary_table.sensor_group = string(local_pick_or_repeat(T, 'sensor_group', "", height(T)));
summary_table.sensor_label = string(local_pick_or_repeat(T, 'sensor_label', "", height(T)));
summary_table.h_km = double(local_pick_or_repeat(T, 'h_km', NaN, height(T)));
summary_table.family_name = string(local_pick_or_repeat(T, 'family_name', "", height(T)));
summary_table.note = string(local_pick_or_repeat(T, 'note', "", height(T)));
summary_table.history_full_rendered_min_ns = double(local_pick_or_repeat(T, 'history_full_rendered_min_ns', NaN, height(T)));
summary_table.effective_full_rendered_min_ns = double(local_pick_or_repeat(T, 'effective_full_rendered_min_ns', NaN, height(T)));
summary_table.frontier_zoom_rendered_min_ns = double(local_pick_or_repeat(T, 'frontier_zoom_rendered_min_ns', NaN, height(T)));
summary_table.history_padding_applied = logical(local_pick_or_repeat(T, 'history_padding_applied', false, height(T)));
summary_table.domain_consistency_pass = logical(local_pick_or_repeat(T, 'domain_consistency_pass', false, height(T)));

switch char(string(summary_kind))
    case 'passratio_overlay'
        summary_table.metric_primary = double(local_pick_or_repeat(T, 'final_pass_ratio', NaN, height(T)));
        summary_table.metric_secondary = double(local_pick_or_repeat(T, 'peak_pass_ratio', NaN, height(T)));
        summary_table.status_flag = logical(local_pick_or_repeat(T, 'right_plateau_reached', false, height(T)));
    case 'frontier_summary'
        summary_table.metric_primary = double(local_pick_or_repeat(T, 'frontier_defined_count', NaN, height(T)));
        summary_table.metric_secondary = double(local_pick_or_repeat(T, 'frontier_coverage_ratio', NaN, height(T)));
        summary_table.status_flag = logical(local_pick_or_repeat(T, 'frontier_any_defined', false, height(T)));
    case 'DG_envelope'
        summary_table.metric_primary = double(local_pick_or_repeat(T, 'max_raw_D_G', NaN, height(T)));
        summary_table.metric_secondary = double(local_pick_or_repeat(T, 'final_pass_ratio', NaN, height(T)));
        summary_table.status_flag = logical(local_pick_or_repeat(T, 'right_plateau_reached', false, height(T)));
    otherwise
        summary_table.metric_primary = NaN(height(T), 1);
        summary_table.metric_secondary = NaN(height(T), 1);
        summary_table.status_flag = false(height(T), 1);
end
summary_table = local_sort_sensor_groups(summary_table);
end

function grade_table = local_build_cross_profile_grade(summary_table, summary_kind, semantic_mode, h_km, family_name)
group_count = numel(unique(summary_table.sensor_group));
single_group_only = group_count < 2;
switch char(string(summary_kind))
    case {'passratio_overlay', 'DG_envelope'}
        plateau_ok = all(logical(local_pick_or_repeat(summary_table, 'right_plateau_reached', false, height(summary_table))));
        paper_candidate = (~single_group_only) && plateau_ok;
        note = "";
        if single_group_only
            note = "single-group diagnostic only";
        elseif ~plateau_ok
            note = "search domain may still be insufficient for full saturation";
        end
    case 'frontier_summary'
        defined_counts = double(local_pick_or_repeat(summary_table, 'frontier_defined_count', 0, height(summary_table)));
        coverage_ratio = double(local_pick_or_repeat(summary_table, 'frontier_coverage_ratio', 0, height(summary_table)));
        frontier_ok = all(coverage_ratio >= 0.75 & defined_counts > 1);
        paper_candidate = (~single_group_only) && frontier_ok;
        note = "";
        if single_group_only
            note = "single-group diagnostic only";
        elseif ~frontier_ok
            note = "frontier remains weakly defined for at least one sensor group";
        end
    otherwise
        paper_candidate = false;
        note = "unsupported summary kind";
end

grade_table = table( ...
    repmat(string(summary_kind), height(summary_table), 1), ...
    repmat(string(semantic_mode), height(summary_table), 1), ...
    repmat(h_km, height(summary_table), 1), ...
    repmat(string(family_name), height(summary_table), 1), ...
    summary_table.sensor_group, ...
    repmat(group_count, height(summary_table), 1), ...
    repmat(single_group_only, height(summary_table), 1), ...
    repmat(string(local_grade_label(paper_candidate)), height(summary_table), 1), ...
    repmat(logical(paper_candidate), height(summary_table), 1), ...
    repmat(string(note), height(summary_table), 1), ...
    'VariableNames', {'summary_kind', 'semantic_mode', 'h_km', 'family_name', 'sensor_group', ...
    'group_count', 'single_group_only', 'export_grade', 'paper_candidate', 'note'});
grade_table = local_sort_sensor_groups(grade_table);
end

function grade = local_grade_label(flag)
if logical(flag)
    grade = "paper_candidate";
else
    grade = "diagnostic_only";
end
end

function values = local_pick_or_repeat(T, var_name, fallback, row_count)
if ismember(var_name, T.Properties.VariableNames)
    values = T.(var_name);
else
    values = repmat(fallback, row_count, 1);
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function value = local_safe_ratio(a, b)
if b == 0
    value = 0;
else
    value = a / b;
end
end

function value = local_non_nan_min(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = min(values);
end
end

function value = local_non_nan_max(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = max(values);
end
end

function value = local_min_vector(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = min(values);
end
end

function value = local_max_vector(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = max(values);
end
end

function value = local_pick_initial(initial_range, idx_pick)
if numel(initial_range) >= idx_pick && isfinite(initial_range(idx_pick))
    value = initial_range(idx_pick);
else
    value = NaN;
end
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
source_meta = [source_png, '.meta.json'];
target_meta = [target_png, '.meta.json'];
if isfile(source_meta)
    copyfile(source_meta, target_meta);
end
end

function summary_table = local_apply_passratio_render_summary(summary_table, pass_history_meta, history_xlim, effective_xlim, zoom_xlim)
if isempty(summary_table)
    return;
end

history_min = local_pick_x(history_xlim, 1);
effective_min = local_pick_x(effective_xlim, 1);
zoom_min = local_pick_x(zoom_xlim, 1);
initial_ns_min = double(local_getfield_or(pass_history_meta, 'initial_ns_min', NaN));
history_padding_applied = logical(local_getfield_or(pass_history_meta, 'history_padding_applied', false));
domain_consistency_pass = isfinite(history_min) && isfinite(initial_ns_min) && history_min <= initial_ns_min + 1.0e-9;

summary_table.history_full_rendered_min_ns = repmat(history_min, height(summary_table), 1);
summary_table.effective_full_rendered_min_ns = repmat(effective_min, height(summary_table), 1);
summary_table.frontier_zoom_rendered_min_ns = repmat(zoom_min, height(summary_table), 1);
summary_table.history_padding_applied = repmat(history_padding_applied, height(summary_table), 1);
summary_table.domain_consistency_pass = repmat(domain_consistency_pass, height(summary_table), 1);
end

function value = local_pick_x(xlim_values, idx_pick)
value = NaN;
if isnumeric(xlim_values) && numel(xlim_values) >= idx_pick && isfinite(xlim_values(idx_pick))
    value = xlim_values(idx_pick);
end
end
