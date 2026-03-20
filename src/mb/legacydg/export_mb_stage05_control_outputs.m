function artifacts = export_mb_stage05_control_outputs(run_output, paths, plot_options)
%EXPORT_MB_STAGE05_CONTROL_OUTPUTS Export Stage05-style control figures under MB layout.

if nargin < 3 || isempty(plot_options)
    plot_options = struct();
end

sensor_group = char(string(run_output.sensor_group.name));

artifacts = struct();
artifacts.tables = struct();
artifacts.figures = struct();

summary_table = local_build_summary_table(run_output);
summary_csv = fullfile(paths.tables, sprintf('MB_control_stage05_summary_%s.csv', sensor_group));
milestone_common_save_table(summary_table, summary_csv);
artifacts.tables.summary = string(summary_csv);

for idx = 1:numel(run_output.runs)
    run = run_output.runs(idx);
    h_label = sprintf('h%d', round(run.h_km));

    pass_csv = fullfile(paths.tables, sprintf('MB_control_stage05_passratio_envelope_%s_%s.csv', h_label, sensor_group));
    dg_csv = fullfile(paths.tables, sprintf('MB_control_stage05_DG_envelope_%s_%s.csv', h_label, sensor_group));
    frontier_csv = fullfile(paths.tables, sprintf('MB_control_stage05_frontier_summary_%s_%s.csv', h_label, sensor_group));
    pareto_csv = fullfile(paths.tables, sprintf('MB_control_stage05_pareto_frontier_%s_%s.csv', h_label, sensor_group));
    milestone_common_save_table(run.aggregate.dg_envelope(:, {'h_km', 'i_deg', 'Ns', 'max_pass_ratio'}), pass_csv);
    milestone_common_save_table(run.aggregate.dg_envelope, dg_csv);
    milestone_common_save_table(run.aggregate.frontier_summary, frontier_csv);
    milestone_common_save_table(run.aggregate.pareto_frontier, pareto_csv);

    fig_pass = plot_mb_stage05_semantic_passratio_envelope(run.aggregate.dg_envelope, run.h_km, struct( ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    pass_png = fullfile(paths.figures, sprintf('MB_control_stage05_passratio_envelope_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pass, pass_png);
    close(fig_pass);

    fig_dg = plot_mb_stage05_semantic_DG_envelope(run.aggregate.dg_envelope, run.h_km, struct( ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    dg_png = fullfile(paths.figures, sprintf('MB_control_stage05_DG_envelope_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_dg, dg_png);
    close(fig_dg);

    fig_frontier = plot_mb_stage05_semantic_frontier_summary(run.aggregate.frontier_summary, run.h_km, struct( ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    frontier_png = fullfile(paths.figures, sprintf('MB_control_stage05_frontier_summary_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_frontier, frontier_png);
    close(fig_frontier);

    fig_pareto = plot_mb_stage05_semantic_pareto_frontier(run.aggregate.pareto_frontier, run.h_km, struct( ...
        'figure_style', local_getfield_or(plot_options, 'figure_style', struct())));
    pareto_png = fullfile(paths.figures, sprintf('MB_control_stage05_pareto_frontier_%s_%s.png', h_label, sensor_group));
    milestone_common_save_figure(fig_pareto, pareto_png);
    close(fig_pareto);

    artifacts.tables.(matlab.lang.makeValidName(sprintf('passratio_envelope_%s', h_label))) = string(pass_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('DG_envelope_%s', h_label))) = string(dg_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('frontier_summary_%s', h_label))) = string(frontier_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('pareto_frontier_%s', h_label))) = string(pareto_csv);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('passratio_envelope_%s', h_label))) = string(pass_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('DG_envelope_%s', h_label))) = string(dg_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('frontier_summary_%s', h_label))) = string(frontier_png);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('pareto_frontier_%s', h_label))) = string(pareto_png);

    diagnostics = struct( ...
        'passratio_saturation_table', build_mb_passratio_saturation_diagnostics(run.aggregate.dg_envelope(:, intersect({'h_km', 'i_deg', 'Ns', 'max_pass_ratio'}, run.aggregate.dg_envelope.Properties.VariableNames, 'stable')), struct( ...
            'ns_search_min', min(run.aggregate.dg_envelope.Ns, [], 'omitnan'), ...
            'ns_search_max', max(run.aggregate.dg_envelope.Ns, [], 'omitnan')), struct( ...
            'value_fields', {{'max_pass_ratio'}}, ...
            'semantic_labels', {{'legacyDG'}}, ...
            'h_km', run.h_km, ...
            'family_name', string(run.family_name))), ...
        'frontier_truncation_table', build_mb_frontier_truncation_diagnostics(run.aggregate.frontier_summary(:, {'i_deg', 'frontier_Ns'}), struct( ...
            'ns_search_min', min(run.aggregate.dg_envelope.Ns, [], 'omitnan'), ...
            'ns_search_max', max(run.aggregate.dg_envelope.Ns, [], 'omitnan')), struct( ...
            'value_fields', {{'frontier_Ns'}}, ...
            'semantic_labels', {{'legacyDG'}}, ...
            'h_km', run.h_km, ...
            'family_name', string(run.family_name))));

    local_maybe_export_paper_ready(@() plot_mb_stage05_semantic_passratio_envelope(run.aggregate.dg_envelope, run.h_km, struct('figure_style', resolve_mb_figure_style_mode('paper_ready'))), ...
        fullfile(paths.figures, sprintf('MB_control_stage05_passratio_envelope_%s_%s_paperReady.png', h_label, sensor_group)), ...
        "control_stage05_passratio", diagnostics, plot_options);
    local_maybe_export_paper_ready(@() plot_mb_stage05_semantic_DG_envelope(run.aggregate.dg_envelope, run.h_km, struct('figure_style', resolve_mb_figure_style_mode('paper_ready'))), ...
        fullfile(paths.figures, sprintf('MB_control_stage05_DG_envelope_%s_%s_paperReady.png', h_label, sensor_group)), ...
        "control_stage05_dg_envelope", diagnostics, plot_options);
    local_maybe_export_paper_ready(@() plot_mb_stage05_semantic_frontier_summary(run.aggregate.frontier_summary, run.h_km, struct('figure_style', resolve_mb_figure_style_mode('paper_ready'))), ...
        fullfile(paths.figures, sprintf('MB_control_stage05_frontier_summary_%s_%s_paperReady.png', h_label, sensor_group)), ...
        "control_stage05_frontier", diagnostics, plot_options);
    local_maybe_export_paper_ready(@() plot_mb_stage05_semantic_pareto_frontier(run.aggregate.pareto_frontier, run.h_km, struct('figure_style', resolve_mb_figure_style_mode('paper_ready'))), ...
        fullfile(paths.figures, sprintf('MB_control_stage05_pareto_frontier_%s_%s_paperReady.png', h_label, sensor_group)), ...
        "control_stage05_frontier", diagnostics, plot_options);
end
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

function summary_table = local_build_summary_table(run_output)
summary_table = table('Size', [numel(run_output.runs), 6], ...
    'VariableTypes', {'string', 'double', 'string', 'double', 'double', 'double'}, ...
    'VariableNames', {'sensor_group', 'h_km', 'family_name', 'minimum_feasible_Ns', 'feasible_count', 'pareto_count'});
for idx = 1:numel(run_output.runs)
    run = run_output.runs(idx);
    summary_table(idx, :) = { ...
        string(run_output.sensor_group.name), ...
        run.h_km, ...
        string(run.family_name), ...
        local_getfield_or(run.summary, 'minimum_feasible_Ns', missing), ...
        height(run.feasible_table), ...
        height(run.aggregate.pareto_frontier)};
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
