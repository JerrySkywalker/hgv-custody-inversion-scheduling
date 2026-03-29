function files = plot_stage14_raan_profiles(profile_table, cfg, opts)
%PLOT_STAGE14_RAAN_PROFILES
% Plot fixed-design RAAN profiles for Stage14.2 first step.
%
% Required columns in profile_table:
%   h_km, i_deg, P, T, F, RAAN_deg, D_G_min, pass_ratio
%
% Output:
%   files.DG_min_png
%   files.pass_ratio_png

    arguments
        profile_table table
        cfg struct
        opts.visible (1,1) string = "on"
        opts.save_fig (1,1) logical = true
        opts.tag (1,1) string = ""
    end

    assert(height(profile_table) >= 1, 'profile_table is empty.');
    requiredVars = {'h_km','i_deg','P','T','F','RAAN_deg','D_G_min','pass_ratio'};
    for k = 1:numel(requiredVars)
        assert(ismember(requiredVars{k}, profile_table.Properties.VariableNames), ...
            'Missing required column: %s', requiredVars{k});
    end

    profile_table = sortrows(profile_table, 'RAAN_deg');

    h_km = profile_table.h_km(1);
    i_deg = profile_table.i_deg(1);
    P = profile_table.P(1);
    TperPlane = profile_table.T(1);
    F = profile_table.F(1);
    Ns = profile_table.P(1) * profile_table.T(1);

    fig_dir = cfg.paths.stage_figs;
    ensure_dir(fig_dir);

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    tag = strtrim(char(opts.tag));
    if isempty(tag)
        tag = sprintf('h%d_i%.0f_P%d_T%d_F%d', round(h_km), i_deg, P, TperPlane, F);
    end
    tag = regexprep(tag, '[^\w\-\.]', '_');

    title_suffix = sprintf('h=%g km, i=%g deg, P=%d, T=%d, F=%d, Ns=%d', ...
        h_km, i_deg, P, TperPlane, F, Ns);

    % -----------------------------
    % Figure 1: D_G_min vs RAAN
    % -----------------------------
    fig1 = figure('Name', 'Stage14 D_G_min vs RAAN', ...
        'NumberTitle', 'off', 'Visible', char(opts.visible));
    plot(profile_table.RAAN_deg, profile_table.D_G_min, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
    hold on;
    yline(1.0, '--', 'LineWidth', 1.0);
    hold off;
    grid on; box on;
    xlabel('RAAN_{rel} (deg)', 'Interpreter', 'tex');
    ylabel('D_G min', 'Interpreter', 'tex');
    title(sprintf('Stage14.2 fixed-design profile: D_G min vs RAAN_{rel}\n%s', title_suffix), ...
        'Interpreter', 'tex');

    dg_min = min(profile_table.D_G_min, [], 'omitnan');
    dg_max = max(profile_table.D_G_min, [], 'omitnan');
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

    % -----------------------------
    % Figure 2: pass_ratio vs RAAN
    % -----------------------------
    fig2 = figure('Name', 'Stage14 pass ratio vs RAAN', ...
        'NumberTitle', 'off', 'Visible', char(opts.visible));
    plot(profile_table.RAAN_deg, profile_table.pass_ratio, '-o', 'LineWidth', 1.5, 'MarkerSize', 6);
    grid on; box on;
    xlabel('RAAN_{rel} (deg)', 'Interpreter', 'tex');
    ylabel('pass ratio', 'Interpreter', 'tex');

    pr_min = min(profile_table.pass_ratio, [], 'omitnan');
    pr_max = max(profile_table.pass_ratio, [], 'omitnan');
    pr_span = pr_max - pr_min;

    if pr_span < 1e-12
        title(sprintf('Stage14.2 fixed-design profile: pass ratio vs RAAN_{rel} (constant profile)\n%s', title_suffix), ...
            'Interpreter', 'tex');
    else
        title(sprintf('Stage14.2 fixed-design profile: pass ratio vs RAAN_{rel}\n%s', title_suffix), ...
            'Interpreter', 'tex');
    end

    ylim([0, 1]);

    files = struct();
    files.fig_dir = fig_dir;
    files.DG_min_png = '';
    files.pass_ratio_png = '';

    if opts.save_fig
        files.DG_min_png = fullfile(fig_dir, sprintf('stage14_DGmin_vs_RAAN_%s_%s.png', tag, timestamp));
        files.pass_ratio_png = fullfile(fig_dir, sprintf('stage14_passratio_vs_RAAN_%s_%s.png', tag, timestamp));

        exportgraphics(fig1, files.DG_min_png, 'Resolution', 220);
        exportgraphics(fig2, files.pass_ratio_png, 'Resolution', 220);
    end
end
