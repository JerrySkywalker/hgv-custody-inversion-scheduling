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
    incr_history_csv = fullfile(paths.tables, sprintf('MB_incremental_search_history_legacyDG_%s_%s.csv', h_label, sensor_group));
    incr_stop_csv = fullfile(paths.tables, sprintf('MB_incremental_search_stop_reason_legacyDG_%s_%s.csv', h_label, sensor_group));
    milestone_common_save_table(run.aggregate.passratio_phasecurve, pass_csv);
    milestone_common_save_table(run.aggregate.requirement_surface_iP.surface_table, heat_csv);
    milestone_common_save_table(run.incremental_search_history, incr_history_csv);
    milestone_common_save_table(local_build_incremental_stop_reason(run), incr_stop_csv);
    diag_artifacts = export_mb_boundary_hit_outputs(diagnostics, paths, sprintf('legacyDG_%s_%s', h_label, sensor_group));

    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_%s', h_label))) = string(pass_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('minimumNs_heatmap_iP_%s', h_label))) = string(heat_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('incremental_history_%s', h_label))) = string(incr_history_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('incremental_stop_%s', h_label))) = string(incr_stop_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('boundary_hit_%s', h_label))) = diag_artifacts.boundary_hit_csv;
    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_saturation_%s', h_label))) = diag_artifacts.passratio_csv;
    artifacts.tables.(matlab.lang.makeValidName(sprintf('frontier_truncation_%s', h_label))) = diag_artifacts.frontier_csv;

    pass_plot_options = plot_options;
    pass_plot_options.passratio_saturation_table = diagnostics.passratio_saturation_table;
    pass_plot_options.boundary_hit_table = diagnostics.boundary_hit_table;
    fig_pass = plot_mb_fixed_h_passratio_phasecurve(run.aggregate.passratio_phasecurve, run.h_km, style, pass_plot_options);
    local_retitle(fig_pass, sprintf('legacyDG Pass-Ratio Profile versus N_s at h = %.0f km [%s]', run.h_km, sensor_label));
    pass_png = fullfile(paths.figures, sprintf('MB_legacyDG_passratio_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass, pass_png);
    close(fig_pass);
    local_maybe_export_paper_ready(@() plot_mb_fixed_h_passratio_phasecurve(run.aggregate.passratio_phasecurve, run.h_km, style, local_build_paper_options(pass_plot_options)), ...
        fullfile(paths.figures, sprintf('MB_legacyDG_passratio_%s_%s_paperReady.png', h_label, sensor_group)), ...
        "legacyDG_passratio", diagnostics, plot_options);

    fig_heat = plot_mb_fixed_h_requirement_heatmap_iP(run.aggregate.requirement_surface_iP, style, struct( ...
        'boundary_hit_table', diagnostics.boundary_hit_table, ...
        'domain_summary', char(string(local_getfield_or(plot_options, 'search_domain_label', ""))), ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    local_retitle(fig_heat, sprintf('legacyDG Minimum Feasible Constellation Requirement over (i, P) at h = %.0f km [%s]', run.h_km, sensor_label));
    heat_png = fullfile(paths.figures, sprintf('MB_legacyDG_minimumNs_heatmap_iP_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_heat, heat_png);
    close(fig_heat);
    local_maybe_export_paper_ready(@() plot_mb_fixed_h_requirement_heatmap_iP(run.aggregate.requirement_surface_iP, style, struct( ...
        'boundary_hit_table', diagnostics.boundary_hit_table, ...
        'domain_summary', char(string(local_getfield_or(plot_options, 'search_domain_label', ""))), ...
        'figure_style', resolve_mb_figure_style_mode('paper_ready'))), ...
        fullfile(paths.figures, sprintf('MB_legacyDG_minimumNs_heatmap_iP_%s_%s_paperReady.png', h_label, sensor_group)), ...
        "legacyDG_heatmap", diagnostics, plot_options);

    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratio_%s', h_label))) = string(pass_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('minimumNs_heatmap_iP_%s', h_label))) = string(heat_png);
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
search_domain = struct( ...
    'ns_search_min', local_getfield_or(effective_domain, 'ns_search_min', local_min_or_nan(run.design_table, 'Ns')), ...
    'ns_search_max', local_getfield_or(effective_domain, 'ns_search_max', local_max_or_nan(run.design_table, 'Ns')), ...
    'ns_search_step', local_getfield_or(effective_domain, 'ns_search_step', local_min_spacing(run.design_table, 'Ns')), ...
    'P_grid', reshape(local_getfield_or(effective_domain, 'P_grid', unique(run.design_table.P, 'sorted')), 1, []), ...
    'T_grid', reshape(local_getfield_or(effective_domain, 'T_grid', unique(run.design_table.T, 'sorted')), 1, []));
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

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
