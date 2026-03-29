function files = plot_stage14_ns_envelopes(envelope_table, cfg, opts)
%PLOT_STAGE14_NS_ENVELOPES
% Plot fixed-(i,Ns,F) RAAN envelope curves for Stage14.2 second step.
%
% Required columns in envelope_table:
%   h_km, i_deg, F, Ns, RAAN_deg,
%   DG_env_max, pass_env_max

    arguments
        envelope_table table
        cfg struct
        opts.visible (1,1) string = "on"
        opts.save_fig (1,1) logical = true
        opts.tag (1,1) string = ""
    end

    assert(height(envelope_table) >= 1, 'envelope_table is empty.');

    requiredVars = {'h_km','i_deg','F','Ns','RAAN_deg','DG_env_max','pass_env_max'};
    for k = 1:numel(requiredVars)
        assert(ismember(requiredVars{k}, envelope_table.Properties.VariableNames), ...
            'Missing required column: %s', requiredVars{k});
    end

    envelope_table = sortrows(envelope_table, 'RAAN_deg');

    h_km = envelope_table.h_km(1);
    i_deg = envelope_table.i_deg(1);
    F = envelope_table.F(1);
    Ns = envelope_table.Ns(1);

    fig_dir = cfg.paths.stage_figs;
    ensure_dir(fig_dir);

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    tag = strtrim(char(opts.tag));
    if isempty(tag)
        tag = sprintf('h%d_i%.0f_Ns%d_F%d', round(h_km), i_deg, Ns, F);
    end
    tag = regexprep(tag, '[^\w\-\.]', '_');

    title_suffix = sprintf('h=%g km, i=%g deg, F=%d, Ns=%d', h_km, i_deg, F, Ns);

    % Figure 1: max_PT D_G_min vs RAAN
    fig1 = figure('Name', 'Stage14 max_PT D_G_min vs RAAN', ...
        'NumberTitle', 'off', 'Visible', char(opts.visible));
    plot(envelope_table.RAAN_deg, envelope_table.DG_env_max, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
    hold on;
    yline(1.0, '--', 'LineWidth', 1.0);
    hold off;
    grid on; box on;
    xlabel('RAAN_{rel} (deg)', 'Interpreter', 'tex');
    ylabel('max_{PT} D_G min', 'Interpreter', 'tex');
    title(sprintf('Stage14.2 Ns-envelope: max_{PT} D_G min vs RAAN_{rel}\n%s', title_suffix), ...
        'Interpreter', 'tex');

    dg_min = min(envelope_table.DG_env_max, [], 'omitnan');
    dg_max = max(envelope_table.DG_env_max, [], 'omitnan');
    if isfinite(dg_min) && isfinite(dg_max)
        if abs(dg_max - dg_min) < 1e-12
            pad = max(0.05, 0.1 * max(abs(dg_max), 1));
        else
            pad = 0.08 * (dg_max - dg_min);
        end
        ymin = min(dg_min - pad, 1 - pad);
        ymax = max(dg_max + pad, 1 + pad);
        if ymin == ymax
            ymax = ymin + 1;
        end
        ylim([ymin, ymax]);
    end

    % Figure 2: max_PT pass_ratio vs RAAN
    fig2 = figure('Name', 'Stage14 max_PT pass ratio vs RAAN', ...
        'NumberTitle', 'off', 'Visible', char(opts.visible));
    plot(envelope_table.RAAN_deg, envelope_table.pass_env_max, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
    grid on; box on;
    xlabel('RAAN_{rel} (deg)', 'Interpreter', 'tex');
    ylabel('max_{PT} pass ratio', 'Interpreter', 'tex');

    pr_min = min(envelope_table.pass_env_max, [], 'omitnan');
    pr_max = max(envelope_table.pass_env_max, [], 'omitnan');
    pr_span = pr_max - pr_min;

    if pr_span < 1e-12
        title(sprintf('Stage14.2 Ns-envelope: max_{PT} pass ratio vs RAAN_{rel} (constant profile)\n%s', title_suffix), ...
            'Interpreter', 'tex');
    else
        title(sprintf('Stage14.2 Ns-envelope: max_{PT} pass ratio vs RAAN_{rel}\n%s', title_suffix), ...
            'Interpreter', 'tex');
    end

    ylim([0, 1]);

    files = struct();
    files.fig_dir = fig_dir;
    files.DG_env_png = '';
    files.pass_env_png = '';

    if opts.save_fig
        files.DG_env_png = fullfile(fig_dir, sprintf('stage14_DGenv_vs_RAAN_%s_%s.png', tag, timestamp));
        files.pass_env_png = fullfile(fig_dir, sprintf('stage14_passenv_vs_RAAN_%s_%s.png', tag, timestamp));

        exportgraphics(fig1, files.DG_env_png, 'Resolution', 220);
        exportgraphics(fig2, files.pass_env_png, 'Resolution', 220);
    end
end
