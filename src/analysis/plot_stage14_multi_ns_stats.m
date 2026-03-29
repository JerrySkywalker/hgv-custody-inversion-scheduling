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

    title_suffix = sprintf('$h=%g\\ \\mathrm{km},\\ i=%g^\\circ,\\ F=%d$', h_km, i_deg, F);

    files = struct();
    files.fig_dir = fig_dir;
    files.DG_mean_png = '';
    files.DG_min_png = '';
    files.DG_span_png = '';
    files.pass_mean_png = '';
    files.pass_min_png = '';
    files.pass_span_png = '';

    figs = struct();
    metric_defs = { ...
        'DG_env_mean',   '$D_G$ env mean',             false, false, 'DG_mean_png',   'stage14_DGenv_mean_vs_Ns'; ...
        'DG_env_min',    '$D_G$ env min',              true,  false, 'DG_min_png',    'stage14_DGenv_min_vs_Ns'; ...
        'DG_env_span',   '$D_G$ env span',             false, false, 'DG_span_png',   'stage14_DGenv_span_vs_Ns'; ...
        'pass_env_mean', '$\mathrm{pass\ env\ mean}$', false, true,  'pass_mean_png', 'stage14_passenv_mean_vs_Ns'; ...
        'pass_env_min',  '$\mathrm{pass\ env\ min}$',  false, true,  'pass_min_png',  'stage14_passenv_min_vs_Ns'; ...
        'pass_env_span', '$\mathrm{pass\ env\ span}$', false, true,  'pass_span_png', 'stage14_passenv_span_vs_Ns' ...
        };

    for m = 1:size(metric_defs, 1)
        metric_name = metric_defs{m, 1};
        ylabel_text = metric_defs{m, 2};
        add_threshold = metric_defs{m, 3};
        clamp_unit_interval = metric_defs{m, 4};
        out_field = metric_defs{m, 5};
        fig_name = metric_defs{m, 6};

        fig = figure('Name', sprintf('Stage14 %s vs Ns', metric_name), ...
            'NumberTitle', 'off', 'Visible', char(opts.visible));
        plot(T.Ns, T.(metric_name), '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
        if add_threshold
            hold on;
            yline(1.0, '--', 'LineWidth', 1.0);
            hold off;
        end
        grid on; box on;
        xlabel('$N_s$', 'Interpreter', 'latex');
        ylabel(ylabel_text, 'Interpreter', 'latex');
        title({ ...
            sprintf('Stage14.3 multi-$N_s$ stats: %s vs $N_s$', ylabel_text), ...
            title_suffix}, 'Interpreter', 'latex');

        if clamp_unit_interval
            ylim([0, 1]);
        end

        figs.(out_field) = fig;
        files.(out_field) = '';
        metric_defs{m, 6} = fig_name;
    end

    if opts.save_fig
        for m = 1:size(metric_defs, 1)
            out_field = metric_defs{m, 5};
            file_prefix = metric_defs{m, 6};
            files.(out_field) = fullfile(fig_dir, sprintf('%s_%s_%s.png', file_prefix, tag, timestamp));
            exportgraphics(figs.(out_field), files.(out_field), 'Resolution', 220);
        end
    end
end
