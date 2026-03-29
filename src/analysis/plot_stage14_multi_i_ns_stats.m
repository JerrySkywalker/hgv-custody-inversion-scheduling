function files = plot_stage14_multi_i_ns_stats(summary_table_all, cfg, opts)
%PLOT_STAGE14_MULTI_I_NS_STATS
% Plot Stage14 mainline-A multi-i vs Ns comparison charts.
%
% Required columns:
%   h_km, i_deg, F, Ns,
%   DG_env_mean, DG_env_min, DG_env_span,
%   pass_env_mean, pass_env_min, pass_env_span,
%   is_valid

    arguments
        summary_table_all table
        cfg struct
        opts.visible (1,1) string = "on"
        opts.save_fig (1,1) logical = true
        opts.tag (1,1) string = ""
    end

    assert(height(summary_table_all) >= 1, 'summary_table_all is empty.');

    req = { ...
        'h_km','i_deg','F','Ns', ...
        'DG_env_mean','DG_env_min','DG_env_span', ...
        'pass_env_mean','pass_env_min','pass_env_span', ...
        'is_valid'};
    for k = 1:numel(req)
        assert(ismember(req{k}, summary_table_all.Properties.VariableNames), ...
            'Missing required column: %s', req{k});
    end

    T = summary_table_all(summary_table_all.is_valid, :);
    assert(height(T) >= 1, 'No valid rows to plot.');

    T = sortrows(T, {'i_deg','Ns'});

    h_km = T.h_km(1);
    F = T.F(1);
    i_list = unique(T.i_deg).';
    fig_dir = cfg.paths.stage_figs;
    ensure_dir(fig_dir);

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    tag = strtrim(char(opts.tag));
    if isempty(tag)
        tag = sprintf('h%d_F%d', round(h_km), F);
    end
    tag = regexprep(tag, '[^\w\-\.]', '_');

    i_text = sprintf('%g_', i_list);
    i_text(end) = [];
    title_suffix = sprintf('h=%g km, F=%d, i in [%s] deg', h_km, F, i_text);

    files = struct();
    files.fig_dir = fig_dir;
    files.DG_mean_png = '';
    files.DG_min_png = '';
    files.DG_span_png = '';
    files.pass_mean_png = '';
    files.pass_min_png = '';
    files.pass_span_png = '';

    % helper
    metric_defs = { ...
        'DG_env_mean',  'DG env mean',  true,  'DG_mean_png',   'stage14_multii_DGenv_mean_vs_Ns'; ...
        'DG_env_min',   'DG env min',   true,  'DG_min_png',    'stage14_multii_DGenv_min_vs_Ns'; ...
        'DG_env_span',  'DG env span',  false, 'DG_span_png',   'stage14_multii_DGenv_span_vs_Ns'; ...
        'pass_env_mean','pass env mean',false, 'pass_mean_png', 'stage14_multii_passenv_mean_vs_Ns'; ...
        'pass_env_min', 'pass env min', false, 'pass_min_png',  'stage14_multii_passenv_min_vs_Ns'; ...
        'pass_env_span','pass env span',false, 'pass_span_png', 'stage14_multii_passenv_span_vs_Ns' ...
        };

    for m = 1:size(metric_defs,1)
        metric_name = metric_defs{m,1};
        ylabel_text = metric_defs{m,2};
        add_threshold = metric_defs{m,3};
        out_field = metric_defs{m,4};
        file_prefix = metric_defs{m,5};

        fig = figure('Name', sprintf('Stage14 %s vs Ns (multi-i)', metric_name), ...
            'NumberTitle', 'off', 'Visible', char(opts.visible));
        hold on;

        legends = cell(1, numel(i_list));
        for ii = 1:numel(i_list)
            i_deg = i_list(ii);
            Ti = T(T.i_deg == i_deg, :);
            Ti = sortrows(Ti, 'Ns');
            plot(Ti.Ns, Ti.(metric_name), '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
            legends{ii} = sprintf('i=%g deg', i_deg);
        end

        if add_threshold
            yline(1.0, '--', 'LineWidth', 1.0);
        end

        hold off;
        grid on; box on;
        xlabel('N_s', 'Interpreter', 'tex');
        ylabel(ylabel_text, 'Interpreter', 'tex');

        if startsWith(metric_name, 'pass_')
            ylim([0,1]);
        end

        title(sprintf('Stage14.3 multi-i comparison: %s vs N_s\n%s', ylabel_text, title_suffix), ...
            'Interpreter', 'tex');
        legend(legends, 'Location', 'best');

        if opts.save_fig
            out_path = fullfile(fig_dir, sprintf('%s_%s_%s.png', file_prefix, tag, timestamp));
            files.(out_field) = out_path;
            exportgraphics(fig, out_path, 'Resolution', 220);
        end
    end
end
