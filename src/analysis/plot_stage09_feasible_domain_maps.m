function fig_files = plot_stage09_feasible_domain_maps(pdata, cfg, timestamp)
%PLOT_STAGE09_FEASIBLE_DOMAIN_MAPS
% Plot Stage09 paper-oriented domain maps.
%
% Outputs:
%   fig_files.minNs_hi
%   fig_files.fail_hi_refPT
%   fig_files.feasible_PT

    if nargin < 3 || isempty(timestamp)
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    end

    ensure_dir(cfg.paths.figs);

    S = build_stage09_paper_plot_tables(pdata.out9_4, pdata.out9_5);

    % ------------------------------------------------------------
    % Figure 1: h-i plane minimum feasible Ns projection
    % ------------------------------------------------------------
    f1 = figure('Visible', 'off');
    hold on;

    Thi = S.hi_minNs_table;
    infeas = Thi(~Thi.has_feasible, :);
    feas   = Thi(Thi.has_feasible, :);

    if ~isempty(infeas)
        scatter(infeas.i_deg, infeas.h_km, 40, 'x', 'DisplayName', 'No feasible design');
    end
    if ~isempty(feas)
        scatter(feas.i_deg, feas.h_km, 80, feas.Ns_min_feasible, 'filled', ...
            'DisplayName', 'Min feasible N_s');
        for k = 1:height(feas)
            text(feas.i_deg(k)+0.5, feas.h_km(k)+5, sprintf('%d', round(feas.Ns_min_feasible(k))), ...
                'FontSize', 8);
        end
        colorbar;
    end

    xlabel('Inclination i [deg]');
    ylabel('Altitude h [km]');
    title('Stage09 minimum feasible N_s projected on h-i plane');
    grid on;
    legend('Location', 'best');

    fig_files.minNs_hi = fullfile(cfg.paths.figs, ...
        sprintf('stage09_minNs_hi_%s_%s.png', cfg.stage09.run_tag, timestamp));
    exportgraphics(f1, fig_files.minNs_hi, 'Resolution', 200);
    close(f1);

    % ------------------------------------------------------------
    % Figure 2: fail partition in h-i plane at representative PT
    % ------------------------------------------------------------
    f2 = figure('Visible', 'off');
    hold on;

    Tref = S.fail_hi_refPT_table;
    if ~isempty(Tref)
        tags = string(Tref.dominant_fail_tag);
        uTags = unique(tags);

        for k = 1:numel(uTags)
            tk = uTags(k);
            mask = tags == tk;
            scatter(Tref.i_deg(mask), Tref.h_km(mask), 60, 'DisplayName', char(tk));
        end

        xlabel('Inclination i [deg]');
        ylabel('Altitude h [km]');

        if ~isempty(S.PT_ref)
            title(sprintf('Stage09 fail partition in h-i plane at P=%d, T=%d', ...
                S.PT_ref.P(1), S.PT_ref.T(1)));
        else
            title('Stage09 fail partition in h-i plane (representative PT)');
        end
        grid on;
        legend('Location', 'bestoutside');
    else
        title('Stage09 fail partition in h-i plane (representative PT unavailable)');
        grid on;
    end

    fig_files.fail_hi_refPT = fullfile(cfg.paths.figs, ...
        sprintf('stage09_fail_partition_hi_refPT_%s_%s.png', cfg.stage09.run_tag, timestamp));
    exportgraphics(f2, fig_files.fail_hi_refPT, 'Resolution', 200);
    close(f2);

    % ------------------------------------------------------------
    % Figure 3: feasible domain in P-T plane
    % ------------------------------------------------------------
    f3 = figure('Visible', 'off');
    hold on;

    Tpt = S.pt_minNs_table;
    Tinfeas = Tpt(~Tpt.has_feasible, :);
    Tfeas = Tpt(Tpt.has_feasible, :);

    if ~isempty(Tinfeas)
        scatter(Tinfeas.P, Tinfeas.T, 40, 'x', 'DisplayName', 'Infeasible');
    end
    if ~isempty(Tfeas)
        scatter(Tfeas.P, Tfeas.T, 80, 'filled', 'DisplayName', 'Feasible');
    end

    if ~isempty(S.theta_min_table)
        PTmin = unique(S.theta_min_table(:, {'P','T'}), 'rows');
        scatter(PTmin.P, PTmin.T, 120, 'o', 'LineWidth', 1.5, ...
            'DisplayName', '\Theta_{Nmin}');
    end

    xlabel('Number of planes P');
    ylabel('Satellites per plane T');
    title('Stage09 feasible domain in P-T plane');
    grid on;
    legend('Location', 'best');

    fig_files.feasible_PT = fullfile(cfg.paths.figs, ...
        sprintf('stage09_feasible_PT_%s_%s.png', cfg.stage09.run_tag, timestamp));
    exportgraphics(f3, fig_files.feasible_PT, 'Resolution', 200);
    close(f3);
end