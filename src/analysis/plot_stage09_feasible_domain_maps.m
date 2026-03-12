function fig_files = plot_stage09_feasible_domain_maps(pdata, cfg, timestamp)
%PLOT_STAGE09_FEASIBLE_DOMAIN_MAPS
% Plot feasible/infeasible domain maps for Stage09.6.
%
% Outputs:
%   fig_files.feasible_hi
%   fig_files.fail_hi
%   fig_files.feasible_PT

    if nargin < 3 || isempty(timestamp)
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    end

    ensure_dir(cfg.paths.figs);

    Tfull = pdata.full_theta_table;
    Tfeas = pdata.feasible_theta_table;

    % ------------------------------------------------------------
    % Figure 1: h-i feasible map
    % ------------------------------------------------------------
    f1 = figure('Visible', 'off');
    hold on;
    Tinfeas = pdata.infeasible_theta_table;

    if ~isempty(Tinfeas)
        scatter(Tinfeas.i_deg, Tinfeas.h_km, 36, 'x');
    end
    if ~isempty(Tfeas)
        scatter(Tfeas.i_deg, Tfeas.h_km, 60, 'filled');
    end

    xlabel('Inclination i [deg]');
    ylabel('Altitude h [km]');
    title('Stage09 feasible domain in h-i plane');
    grid on;
    legend({'Infeasible','Feasible'}, 'Location', 'best');

    fig_files.feasible_hi = fullfile(cfg.paths.figs, ...
        sprintf('stage09_feasible_hi_%s_%s.png', cfg.stage09.run_tag, timestamp));
    exportgraphics(f1, fig_files.feasible_hi, 'Resolution', 200);
    close(f1);

    % ------------------------------------------------------------
    % Figure 2: dominant fail-tag map in h-i plane
    % ------------------------------------------------------------
    f2 = figure('Visible', 'off');
    hold on;

    tags = string(Tfull.dominant_fail_tag);
    uTags = unique(tags);

    for k = 1:numel(uTags)
        tk = uTags(k);
        mask = tags == tk;
        scatter(Tfull.i_deg(mask), Tfull.h_km(mask), 40, 'DisplayName', char(tk));
    end

    xlabel('Inclination i [deg]');
    ylabel('Altitude h [km]');
    title('Stage09 dominant fail partition in h-i plane');
    grid on;
    legend('Location', 'bestoutside');

    fig_files.fail_hi = fullfile(cfg.paths.figs, ...
        sprintf('stage09_fail_partition_hi_%s_%s.png', cfg.stage09.run_tag, timestamp));
    exportgraphics(f2, fig_files.fail_hi, 'Resolution', 200);
    close(f2);

    % ------------------------------------------------------------
    % Figure 3: feasible map in P-T plane
    % ------------------------------------------------------------
    f3 = figure('Visible', 'off');
    hold on;

    if ~isempty(Tinfeas)
        scatter(Tinfeas.P, Tinfeas.T, 36, 'x');
    end
    if ~isempty(Tfeas)
        scatter(Tfeas.P, Tfeas.T, 60, 'filled');
    end

    xlabel('Number of planes P');
    ylabel('Satellites per plane T');
    title('Stage09 feasible domain in P-T plane');
    grid on;
    legend({'Infeasible','Feasible'}, 'Location', 'best');

    fig_files.feasible_PT = fullfile(cfg.paths.figs, ...
        sprintf('stage09_feasible_PT_%s_%s.png', cfg.stage09.run_tag, timestamp));
    exportgraphics(f3, fig_files.feasible_PT, 'Resolution', 200);
    close(f3);
end