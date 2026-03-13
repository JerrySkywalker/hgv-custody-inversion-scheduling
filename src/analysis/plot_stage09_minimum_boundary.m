function fig_files = plot_stage09_minimum_boundary(pdata, cfg, timestamp)
%PLOT_STAGE09_MINIMUM_BOUNDARY
% Plot Stage09 minimum-boundary figures.
%
% Outputs:
%   fig_files.Ns_vs_margin
%   fig_files.theta_min_hi

    if nargin < 3 || isempty(timestamp)
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    end

    ensure_dir(cfg.paths.figs);

    Tfull = pdata.out9_4.full_theta_table;
    Tfeas = pdata.out9_4.feasible_theta_table;
    Tmin = pdata.out9_5.theta_min_table_sorted;

    % ------------------------------------------------------------
    % Figure 1: Ns vs joint margin
    % ------------------------------------------------------------
    f1 = figure('Visible', 'off');
    hold on;

    if ~isempty(Tfull)
        scatter(Tfull.Ns, Tfull.joint_margin, 30, 'x', 'DisplayName', 'All scanned');
    end
    if ~isempty(Tfeas)
        scatter(Tfeas.Ns, Tfeas.joint_margin, 70, 'filled', 'DisplayName', 'Feasible');
    end

    if isfinite(pdata.out9_5.N_min_rob)
        xline(pdata.out9_5.N_min_rob, '--', 'DisplayName', 'N_{min}^{rob}');
    end

    xlabel('Total satellites N_s');
    ylabel('Joint margin');
    title('Stage09 robust joint margin versus total satellites');
    grid on;
    legend('Location', 'best');

    fig_files.Ns_vs_margin = fullfile(cfg.paths.figs, ...
        sprintf('stage09_Ns_vs_margin_%s_%s.png', cfg.stage09.run_tag, timestamp));
    exportgraphics(f1, fig_files.Ns_vs_margin, 'Resolution', 200);
    close(f1);

    % ------------------------------------------------------------
    % Figure 2: theta_min set in h-i plane
    % ------------------------------------------------------------
    f2 = figure('Visible', 'off');
    hold on;

    if ~isempty(Tfeas)
        scatter(Tfeas.i_deg, Tfeas.h_km, 30, 'x', 'DisplayName', 'All feasible');
    end
    if ~isempty(Tmin)
        scatter(Tmin.i_deg, Tmin.h_km, 100, 'filled', 'DisplayName', '\Theta_{Nmin}');
    end

    xlabel('Inclination i [deg]');
    ylabel('Altitude h [km]');
    title('Stage09 minimum-size feasible set in h-i plane');
    grid on;
    legend('Location', 'best');

    fig_files.theta_min_hi = fullfile(cfg.paths.figs, ...
        sprintf('stage09_theta_min_hi_%s_%s.png', cfg.stage09.run_tag, timestamp));
    exportgraphics(f2, fig_files.theta_min_hi, 'Resolution', 200);
    close(f2);
end