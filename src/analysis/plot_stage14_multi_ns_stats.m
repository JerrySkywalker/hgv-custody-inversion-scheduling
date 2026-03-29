function files = plot_stage14_multi_ns_stats(summary_table_all, cfg, opts)
%PLOT_STAGE14_MULTI_NS_STATS
% Plot Stage14.3 multi-Ns aggregate statistics.
%
% Required columns in summary_table_all:
%   Ns
%   DG_env_mean, DG_env_min, DG_env_span
%   pass_env_mean, pass_env_min, pass_env_span
%
% Output:
%   files.fig_dir
%   files.DG_mean_png
%   files.DG_min_png
%   files.DG_span_png
%   files.pass_mean_png
%   files.pass_min_png
%   files.pass_span_png

    arguments
        summary_table_all table
        cfg struct
        opts.visible (1,1) string = "on"
        opts.save_fig (1,1) logical = true
        opts.tag (1,1) string = ""
    end

    assert(height(summary_table_all) >= 1, 'summary_table_all is empty.');

    requiredVars = { ...
        'h_km','i_deg','F','Ns', ...
        'DG_env_mean','DG_env_min','DG_env_span', ...
        'pass_env_mean','pass_env_min','pass_env_span', ...
        'is_valid'};
    for k = 1:numel(requiredVars)
        assert(ismember(requiredVars{k}, summary_table_all.Properties.VariableNames), ...
            'Missing required column: %s', requiredVars{k});
    end

    T = summary_table_all(summary_table_all.is_valid, :);
    assert(height(T) >= 1, 'No valid rows to plot.');

    T = sortrows(T, 'Ns');

    h_km = T.h_km(1);
    i_deg = T.i_deg(1);
    F = T.F(1);

    fig_dir = cfg.paths.stage_figs;
    ensure_dir(fig_dir);

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    tag = strtrim(char(opts.tag));
    if isempty(tag)
        tag = sprintf('h%d_i%.0f_F%d', round(h_km), i_deg, F);
    end
    tag = regexprep(tag, '[^\w\-\.]', '_');

    title_suffix = sprintf('h=%g km, i=%g deg, F=%d', h_km, i_deg, F);

    files = struct();
    files.fig_dir = fig_dir;
    files.DG_mean_png = '';
    files.DG_min_png = '';
    files.DG_span_png = '';
    files.pass_mean_png = '';
    files.pass_min_png = '';
    files.pass_span_png = '';

    % -----------------------------
    % DG_env_mean vs Ns
    % -----------------------------
    fig1 = figure('Name', 'Stage14 DG env mean vs Ns', ...
        'NumberTitle', 'off', 'Visible', char(opts.visible));
    plot(T.Ns, T.DG_env_mean, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
    grid on; box on;
    xlabel('N_s', 'Interpreter', 'tex');
    ylabel('DG env mean', 'Interpreter', 'tex');
    title(sprintf('Stage14.3 multi-N_s stats: DG env mean vs N_s\n%s', title_suffix), ...
        'Interpreter', 'tex');

    % -----------------------------
    % DG_env_min vs Ns
    % -----------------------------
    fig2 = figure('Name', 'Stage14 DG env min vs Ns', ...
        'NumberTitle', 'off', 'Visible', char(opts.visible));
    plot(T.Ns, T.DG_env_min, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
    hold on;
    yline(1.0, '--', 'LineWidth', 1.0);
    hold off;
    grid on; box on;
    xlabel('N_s', 'Interpreter', 'tex');
    ylabel('DG env min', 'Interpreter', 'tex');
    title(sprintf('Stage14.3 multi-N_s stats: DG env min vs N_s\n%s', title_suffix), ...
        'Interpreter', 'tex');

    % -----------------------------
    % DG_env_span vs Ns
    % -----------------------------
    fig3 = figure('Name', 'Stage14 DG env span vs Ns', ...
        'NumberTitle', 'off', 'Visible', char(opts.visible));
    plot(T.Ns, T.DG_env_span, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
    grid on; box on;
    xlabel('N_s', 'Interpreter', 'tex');
    ylabel('DG env span', 'Interpreter', 'tex');
    title(sprintf('Stage14.3 multi-N_s stats: DG env span vs N_s\n%s', title_suffix), ...
        'Interpreter', 'tex');

    % -----------------------------
    % pass_env_mean vs Ns
    % -----------------------------
    fig4 = figure('Name', 'Stage14 pass env mean vs Ns', ...
        'NumberTitle', 'off', 'Visible', char(opts.visible));
    plot(T.Ns, T.pass_env_mean, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
    grid on; box on;
    ylim([0, 1]);
    xlabel('N_s', 'Interpreter', 'tex');
    ylabel('pass env mean', 'Interpreter', 'tex');
    title(sprintf('Stage14.3 multi-N_s stats: pass env mean vs N_s\n%s', title_suffix), ...
        'Interpreter', 'tex');

    % -----------------------------
    % pass_env_min vs Ns
    % -----------------------------
    fig5 = figure('Name', 'Stage14 pass env min vs Ns', ...
        'NumberTitle', 'off', 'Visible', char(opts.visible));
    plot(T.Ns, T.pass_env_min, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
    grid on; box on;
    ylim([0, 1]);
    xlabel('N_s', 'Interpreter', 'tex');
    ylabel('pass env min', 'Interpreter', 'tex');
    title(sprintf('Stage14.3 multi-N_s stats: pass env min vs N_s\n%s', title_suffix), ...
        'Interpreter', 'tex');

    % -----------------------------
    % pass_env_span vs Ns
    % -----------------------------
    fig6 = figure('Name', 'Stage14 pass env span vs Ns', ...
        'NumberTitle', 'off', 'Visible', char(opts.visible));
    plot(T.Ns, T.pass_env_span, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
    grid on; box on;
    ylim([0, 1]);
    xlabel('N_s', 'Interpreter', 'tex');
    ylabel('pass env span', 'Interpreter', 'tex');
    title(sprintf('Stage14.3 multi-N_s stats: pass env span vs N_s\n%s', title_suffix), ...
        'Interpreter', 'tex');

    if opts.save_fig
        files.DG_mean_png = fullfile(fig_dir, sprintf('stage14_DGenv_mean_vs_Ns_%s_%s.png', tag, timestamp));
        files.DG_min_png = fullfile(fig_dir, sprintf('stage14_DGenv_min_vs_Ns_%s_%s.png', tag, timestamp));
        files.DG_span_png = fullfile(fig_dir, sprintf('stage14_DGenv_span_vs_Ns_%s_%s.png', tag, timestamp));
        files.pass_mean_png = fullfile(fig_dir, sprintf('stage14_passenv_mean_vs_Ns_%s_%s.png', tag, timestamp));
        files.pass_min_png = fullfile(fig_dir, sprintf('stage14_passenv_min_vs_Ns_%s_%s.png', tag, timestamp));
        files.pass_span_png = fullfile(fig_dir, sprintf('stage14_passenv_span_vs_Ns_%s_%s.png', tag, timestamp));

        exportgraphics(fig1, files.DG_mean_png, 'Resolution', 220);
        exportgraphics(fig2, files.DG_min_png, 'Resolution', 220);
        exportgraphics(fig3, files.DG_span_png, 'Resolution', 220);
        exportgraphics(fig4, files.pass_mean_png, 'Resolution', 220);
        exportgraphics(fig5, files.pass_min_png, 'Resolution', 220);
        exportgraphics(fig6, files.pass_span_png, 'Resolution', 220);
    end
end
