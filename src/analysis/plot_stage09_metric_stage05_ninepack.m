function pack = plot_stage09_metric_stage05_ninepack(metric_view, metric_frontiers, metric_name, cfg, mode_tag)
%PLOT_STAGE09_METRIC_STAGE05_NINEPACK
% Draw Stage05-style 9 figures for a single Stage09 metric layer.
%
% Inputs
%   metric_view      : standardized metric view table
%   metric_frontiers : struct from build_stage09_metric_frontiers.(metric)
%   metric_name      : 'DG' | 'DA' | 'DT' | 'joint'
%   cfg              : stage09 cfg
%   mode_tag         : optional suffix
%
% Output
%   pack.files.*
%   pack.figure_index

    if nargin < 5 || isempty(mode_tag)
        mode_tag = 'phase2';
    end

    metric_name = char(string(metric_name));
    valid_names = {'DG','DA','DT','joint'};
    if ~ismember(metric_name, valid_names)
        error('plot_stage09_metric_stage05_ninepack:InvalidMetric', ...
            'metric_name must be one of: DG, DA, DT, joint');
    end

    if ~istable(metric_view)
        error('plot_stage09_metric_stage05_ninepack:InvalidMetricView', ...
            'metric_view must be a table.');
    end
    if ~isstruct(metric_frontiers)
        error('plot_stage09_metric_stage05_ninepack:InvalidFrontiers', ...
            'metric_frontiers must be a struct.');
    end
    if nargin < 4 || isempty(cfg)
        error('plot_stage09_metric_stage05_ninepack:MissingCfg', 'cfg is required.');
    end

    run_tag = char(string(cfg.stage09.run_tag));
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    metric_slug = local_metric_slug(metric_name);
    figs_root = cfg.paths.figs;
    tables_root = cfg.paths.tables;
    fig_subdir = fullfile(figs_root, sprintf('%s_stage05_pack', metric_slug));
    table_subdir = fullfile(tables_root, sprintf('%s_stage05_pack', metric_slug));
    if ~exist(fig_subdir, 'dir'); mkdir(fig_subdir); end
    if ~exist(table_subdir, 'dir'); mkdir(table_subdir); end

    metric_label_plain = local_metric_label_plain(metric_name);
    metric_label_tex = local_metric_label_tex(metric_name);
    metric_threshold = local_threshold_for_metric(metric_name, cfg);

    V = metric_view;
    F = metric_frontiers;

    % restrict to h-slice if available
    h_slice = NaN;
    if isfield(cfg.stage09, 'plot_h_slice_km') && ~isempty(cfg.stage09.plot_h_slice_km)
        h_slice = cfg.stage09.plot_h_slice_km;
    end
    if isfinite(h_slice)
        Vslice = V(V.h_km == h_slice, :);
    else
        Vslice = V;
    end

    fig_files = strings(9,1);
    fig_names = [
        "feasible_scatter"
        "inclination_frontier"
        "heatmap_minNs"
        "heatmap_bestMetric"
        "passratio_profile"
        "pareto_frontier"
        "transition_passratio"
        "transition_metric"
        "transition_summary"];

    theta_min = local_theta_min_rows(Vslice);

    % ---------------------------------------------------------
    % 1. feasible_scatter
    % ---------------------------------------------------------
    f1 = figure('Visible','off');
    hold on;

    Tall = Vslice;
    TmetricPass = Vslice(Vslice.metric_pass, :);
    Tfeas = Vslice(Vslice.feasible_flag, :);

    h_all = scatter(Tall.Ns, Tall.metric_value, 22, [0.65 0.65 0.65], 'filled', ...
        'MarkerFaceAlpha', 0.35, 'MarkerEdgeAlpha', 0.20, 'DisplayName', 'All scanned');

    if ~isempty(TmetricPass)
        h_metric = scatter(TmetricPass.Ns, TmetricPass.metric_value, 52, 'o', ...
            'MarkerEdgeColor', [0.20 0.20 0.20], 'MarkerFaceColor', 'none', ...
            'LineWidth', 1.0, 'DisplayName', 'Metric-pass');
    else
        h_metric = plot(nan, nan, 'o', 'MarkerFaceColor', 'none', 'DisplayName', 'Metric-pass');
    end

    if ~isempty(Tfeas)
        h_feas = scatter(Tfeas.Ns, Tfeas.metric_value, 68, double(Tfeas.i_deg), 'filled', ...
            'MarkerEdgeColor', 'k', 'LineWidth', 0.7, 'DisplayName', 'Feasible');
    else
        h_feas = plot(nan, nan, 'o', 'DisplayName', 'Feasible');
    end

    if ~isempty(theta_min)
        h_theta = scatter(theta_min.Ns, theta_min.metric_value, 160, ...
            'p', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k', ...
            'LineWidth', 1.1, 'DisplayName', '\Theta_{Nmin}');
        for k = 1:height(theta_min)
            text(theta_min.Ns(k), theta_min.metric_value(k), sprintf(' (%d,%d)', theta_min.P(k), theta_min.T(k)), ...
                'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
        end
    else
        h_theta = plot(nan, nan, 'p', 'MarkerFaceColor', 'y', 'DisplayName', '\Theta_{Nmin}');
    end

    yline(metric_threshold, '--', 'Threshold', ...
        'Color', [0.35 0.35 0.35], 'LineWidth', 1.0, 'HandleVisibility', 'off');

    xlabel('Total satellites N_s');
    ylabel(metric_label_plain);
    title(sprintf('Stage09 %s feasible scatter at h=%g km', metric_label_plain, local_display_h(h_slice)));
    cb = colorbar;
    cb.Label.String = 'Inclination i [deg]';
    grid on; box on;
    legend([h_all, h_metric, h_feas, h_theta], 'Location', 'best');
    hold off;
    fig_files(1) = local_save_figure(f1, fig_subdir, sprintf('stage09_%s_feasible_scatter_%s_%s.png', metric_slug, run_tag, timestamp));

    % ---------------------------------------------------------
    % 2. inclination_frontier
    % ---------------------------------------------------------
    f2 = figure('Visible','off');
    hold on;
    Tfront = F.frontier_by_i;
    if ~isempty(Tfront)
        yyaxis left;
        plot(Tfront.i_deg, Tfront.frontier_Ns, '-o', 'LineWidth', 1.7, 'DisplayName', 'Minimum feasible N_s');
        ylabel('Minimum feasible N_s');
        yyaxis right;
        plot(Tfront.i_deg, Tfront.frontier_metric, '-s', 'LineWidth', 1.7, 'DisplayName', metric_label_plain);
        ylabel(metric_label_plain);

        for k = 1:height(Tfront)
            text(Tfront.i_deg(k), Tfront.frontier_metric(k), sprintf('(%d,%d)', Tfront.P(k), Tfront.T(k)), ...
                'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center');
        end
    end
    xlabel('Inclination i [deg]');
    title(sprintf('Stage09 %s inclination frontier at h=%g km', metric_label_plain, local_display_h(h_slice)));
    grid on; box on;
    hold off;
    fig_files(2) = local_save_figure(f2, fig_subdir, sprintf('stage09_%s_inclination_frontier_%s_%s.png', metric_slug, run_tag, timestamp));

    % ---------------------------------------------------------
    % 3. heatmap_minNs
    % ---------------------------------------------------------
    f3 = figure('Visible','off');
    [X_i, Y_P, Z_minNs, txt_minNs, mask_minNs] = local_heatmap_minNs(F.minNs_by_iP, Vslice);
    local_plot_masked_heatmap(X_i, Y_P, Z_minNs, txt_minNs, mask_minNs, ...
        sprintf('Stage09 %s minimum feasible N_s over (i,P) at h=%g km', metric_label_plain, local_display_h(h_slice)), ...
        'Inclination i [deg]', 'P');
    fig_files(3) = local_save_figure(f3, fig_subdir, sprintf('stage09_%s_heatmap_minNs_%s_%s.png', metric_slug, run_tag, timestamp));

    % ---------------------------------------------------------
    % 4. heatmap_bestMetric
    % ---------------------------------------------------------
    f4 = figure('Visible','off');
    [X_i2, Y_P2, Z_best, txt_best, mask_best] = local_heatmap_bestMetric(F.bestMetric_by_iP, Vslice);
    local_plot_masked_heatmap(X_i2, Y_P2, Z_best, txt_best, mask_best, ...
        sprintf('Stage09 %s best feasible metric over (i,P) at h=%g km', metric_label_plain, local_display_h(h_slice)), ...
        'Inclination i [deg]', 'P');
    fig_files(4) = local_save_figure(f4, fig_subdir, sprintf('stage09_%s_heatmap_bestMetric_%s_%s.png', metric_slug, run_tag, timestamp));

    % ---------------------------------------------------------
    % 5. passratio_profile
    % ---------------------------------------------------------
    f5 = figure('Visible','off');
    hold on;
    Tpr = F.transition_passratio;
    iu = unique(Tpr.i_deg(:));
    for k = 1:numel(iu)
        Ti = Tpr(Tpr.i_deg == iu(k), :);
        plot(Ti.Ns, Ti.pass_ratio, '-o', 'LineWidth', 1.2, 'DisplayName', sprintf('i=%d', iu(k)));
    end
    yline(1, '--', 'pass=1', 'Color', [0.35 0.35 0.35], 'HandleVisibility', 'off');
    xlabel('Total satellites N_s');
    ylabel('Pass ratio');
    title(sprintf('Stage09 %s pass-ratio profile at h=%g km', metric_label_plain, local_display_h(h_slice)));
    grid on; box on;
    legend('Location','eastoutside');
    hold off;
    fig_files(5) = local_save_figure(f5, fig_subdir, sprintf('stage09_%s_passratio_profile_%s_%s.png', metric_slug, run_tag, timestamp));

    % ---------------------------------------------------------
    % 6. pareto_frontier
    % ---------------------------------------------------------
    f6 = figure('Visible','off');
    hold on;
    Tp = F.pareto_frontier;
    if ~isempty(Tp)
        plot(Tp.Ns, Tp.metric_value, '-o', 'LineWidth', 1.6);
        for k = 1:height(Tp)
            text(Tp.Ns(k), Tp.metric_value(k), sprintf('(%d,%d)', Tp.P(k), Tp.T(k)), ...
                'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center');
        end
        if ismember('is_degenerate_pareto', Tp.Properties.VariableNames) && any(Tp.is_degenerate_pareto)
            text(Tp.Ns(1), Tp.metric_value(1), ' degenerate pareto', 'VerticalAlignment', 'top');
        end
    end
    xlabel('Total satellites N_s');
    ylabel(metric_label_plain);
    title(sprintf('Stage09 %s global Pareto frontier', metric_label_plain));
    grid on; box on;
    hold off;
    fig_files(6) = local_save_figure(f6, fig_subdir, sprintf('stage09_%s_pareto_frontier_%s_%s.png', metric_slug, run_tag, timestamp));

    % ---------------------------------------------------------
    % 7. transition_passratio
    % ---------------------------------------------------------
    f7 = figure('Visible','off');
    hold on;
    Ts = F.transition_summary;
    Tvalid = Ts(~isnan(Ts.first_Ns_passratio1), :);
    if ~isempty(Tvalid)
        plot(Tvalid.i_deg, Tvalid.first_Ns_passratio1, '-o', 'LineWidth', 1.5, 'DisplayName', 'First N_s with pass-ratio=1');
        for k = 1:height(Tvalid)
            text(Tvalid.i_deg(k), Tvalid.first_Ns_passratio1(k), sprintf(' %d', Tvalid.first_Ns_passratio1(k)), ...
                'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center');
        end
    end

    Tinfeas = Ts(isnan(Ts.first_Ns_passratio1), :);
    if ~isempty(Tinfeas)
        refv = Ts.first_Ns_feasible(~isnan(Ts.first_Ns_feasible));
        if isempty(refv), refy = 1; else, refy = min(refv) * 0.9; end
        scatter(Tinfeas.i_deg, ones(height(Tinfeas),1)*refy, ...
            50, 'x', 'MarkerEdgeColor', [0.4 0.4 0.4], 'LineWidth', 1.2, 'DisplayName', 'No pass-ratio crossing');
    end

    xlabel('Inclination i [deg]');
    ylabel('First N_s with pass-ratio=1');
    title(sprintf('Threshold crossing diagnostic: first pass-ratio=1 versus i (%s)', metric_label_plain));
    grid on; box on;
    legend('Location','eastoutside');
    hold off;
    fig_files(7) = local_save_figure(f7, fig_subdir, sprintf('stage09_%s_transition_passratio_%s_%s.png', metric_slug, run_tag, timestamp));

    % ---------------------------------------------------------
    % 8. transition_metric
    % ---------------------------------------------------------
    f8 = figure('Visible','off');
    hold on;
    Tm = F.transition_metric;
    iu = unique(Tm.i_deg(:));
    for k = 1:numel(iu)
        Ti = Tm(Tm.i_deg == iu(k), :);
        plot(Ti.Ns, Ti.metric_value, '-o', 'LineWidth', 1.2, 'DisplayName', sprintf('i=%d', iu(k)));
    end
    yline(metric_threshold, '--', 'Threshold', 'Color', [0.35 0.35 0.35], 'HandleVisibility', 'off');
    xlabel('Total satellites N_s');
    ylabel(metric_label_plain);
    title(sprintf('Threshold diagnostic: %s envelope versus N_s', metric_label_tex));
    grid on; box on;
    legend('Location','eastoutside');
    hold off;
    fig_files(8) = local_save_figure(f8, fig_subdir, sprintf('stage09_%s_transition_metric_%s_%s.png', metric_slug, run_tag, timestamp));

    % ---------------------------------------------------------
    % 9. transition_summary
    % ---------------------------------------------------------
    f9 = figure('Visible','off');
    hold on;
    Ts = F.transition_summary;

    if strcmpi(metric_name, 'DG') || strcmpi(metric_name, 'joint')
        yyaxis left;
        h_nf = plot(Ts.i_deg, Ts.first_Ns_feasible, '-^', 'LineWidth', 1.8, 'DisplayName', 'first N_s feasible');
        ylabel('N_s');

        yyaxis right;
        h_fm = plot(Ts.i_deg, Ts.frontier_metric, '-v', 'LineWidth', 1.8, 'DisplayName', 'frontier metric');
        ylabel(metric_label_plain);

        xlabel('Inclination i [deg]');
        title(sprintf('Stage09 %s inclination-wise frontier summary', metric_label_plain));
        grid on; box on;
        legend([h_nf, h_fm], 'Location', 'eastoutside');
    else
        yyaxis left;
        h1 = plot(Ts.i_deg, Ts.first_Ns_passratio1, '-o', 'LineWidth', 1.2, 'DisplayName', 'first N_s pass=1');
        h2 = plot(Ts.i_deg, Ts.first_Ns_metric_pass, '-s', 'LineWidth', 1.2, 'DisplayName', 'first N_s metric pass');
        h3 = plot(Ts.i_deg, Ts.first_Ns_feasible, '-d', 'LineWidth', 1.2, 'DisplayName', 'first N_s feasible');
        h4 = plot(Ts.i_deg, Ts.frontier_Ns, '-^', 'LineWidth', 1.5, 'DisplayName', 'frontier N_s');
        ylabel('N_s');

        yyaxis right;
        h5 = plot(Ts.i_deg, Ts.frontier_metric, '-v', 'LineWidth', 1.5, 'DisplayName', 'frontier metric');
        ylabel(metric_label_plain);

        xlabel('Inclination i [deg]');
        title(sprintf('Stage09 %s inclination-wise frontier summary', metric_label_plain));
        grid on; box on;
        legend([h1,h2,h3,h4,h5], 'Location', 'eastoutside');
    end

    hold off;
    fig_files(9) = local_save_figure(f9, fig_subdir, sprintf('stage09_%s_transition_summary_%s_%s.png', metric_slug, run_tag, timestamp));

    % ---------------------------------------------------------
    % figure index
    % ---------------------------------------------------------
    fig_table = table(fig_names, fig_files, 'VariableNames', {'figure_name','figure_path'});
    fig_index_csv = fullfile(table_subdir, sprintf('stage09_%s_stage05_pack_figure_index_%s_%s_%s.csv', metric_slug, run_tag, mode_tag, timestamp));
    writetable(fig_table, fig_index_csv);

    fprintf('\n');
    fprintf('======= Stage09 %s Stage05-Ninepack =======\n', metric_label_plain);
    fprintf('run_tag      : %s\n', run_tag);
    fprintf('mode_tag     : %s\n', mode_tag);
    fprintf('fig subdir   : %s\n', fig_subdir);
    fprintf('index csv    : %s\n', fig_index_csv);
    fprintf('===========================================\n\n');

    pack = struct();
    pack.metric_name = metric_name;
    pack.figure_index = fig_table;
    pack.files = struct();
    pack.files.figure_index_csv = fig_index_csv;
    pack.files.figures = fig_files;
end


function slug = local_metric_slug(metric_name)
    switch metric_name
        case 'DG'
            slug = 'dg';
        case 'DA'
            slug = 'da';
        case 'DT'
            slug = 'dt';
        case 'joint'
            slug = 'joint';
        otherwise
            slug = lower(char(string(metric_name)));
    end
end


function threshold = local_threshold_for_metric(metric_name, cfg)
    switch metric_name
        case 'DG'
            threshold = cfg.stage09.require_DG_min;
        case 'DA'
            threshold = cfg.stage09.require_DA_min;
        case 'DT'
            threshold = cfg.stage09.require_DT_min;
        case 'joint'
            threshold = 0;
        otherwise
            threshold = NaN;
    end
end


function label = local_metric_label_plain(metric_name)
    switch metric_name
        case 'DG'
            label = 'D_G';
        case 'DA'
            label = 'D_A';
        case 'DT'
            label = 'D_T';
        case 'joint'
            label = 'Joint';
        otherwise
            label = 'metric';
    end
end


function label = local_metric_label_tex(metric_name)
    switch metric_name
        case 'DG'
            label = 'D_G^{min}';
        case 'DA'
            label = 'D_A';
        case 'DT'
            label = 'D_T';
        case 'joint'
            label = 'Joint';
        otherwise
            label = 'metric';
    end
end


function out = local_save_figure(fig, fig_dir, filename)
    out = fullfile(fig_dir, filename);
    exportgraphics(fig, out, 'Resolution', 180);
    close(fig);
end


function h = local_display_h(h_in)
    if isfinite(h_in)
        h = h_in;
    else
        h = NaN;
    end
end


function Ttheta = local_theta_min_rows(V)
    Tfeas = V(V.feasible_flag, :);
    if isempty(Tfeas)
        Ttheta = Tfeas;
        return;
    end
    nsmin = min(Tfeas.Ns);
    Ttheta = Tfeas(Tfeas.Ns == nsmin, :);
    Ttheta = sortrows(Ttheta, {'metric_value','P','T','h_km'}, {'descend','ascend','ascend','ascend'});
end


function [X_i, Y_P, Z, txt, mask] = local_heatmap_minNs(T, Vslice)
    X_i = unique(Vslice.i_deg(:)).';
    Y_P = unique(Vslice.P(:)).';
    Z = nan(numel(Y_P), numel(X_i));
    txt = strings(numel(Y_P), numel(X_i));
    mask = false(numel(Y_P), numel(X_i));

    for pp = 1:numel(Y_P)
        for ii = 1:numel(X_i)
            mask(pp, ii) = any(Vslice.i_deg == X_i(ii) & Vslice.P == Y_P(pp) & Vslice.feasible_flag);
        end
    end

    for r = 1:height(T)
        ii = find(X_i == T.i_deg(r), 1);
        pp = find(Y_P == T.P(r), 1);
        Z(pp, ii) = T.min_feasible_Ns(r);
        txt(pp, ii) = string(T.min_feasible_Ns(r));
    end
end


function [X_i, Y_P, Z, txt, mask] = local_heatmap_bestMetric(T, Vslice)
    X_i = unique(Vslice.i_deg(:)).';
    Y_P = unique(Vslice.P(:)).';
    Z = nan(numel(Y_P), numel(X_i));
    txt = strings(numel(Y_P), numel(X_i));
    mask = false(numel(Y_P), numel(X_i));

    for pp = 1:numel(Y_P)
        for ii = 1:numel(X_i)
            mask(pp, ii) = any(Vslice.i_deg == X_i(ii) & Vslice.P == Y_P(pp) & Vslice.feasible_flag);
        end
    end

    for r = 1:height(T)
        ii = find(X_i == T.i_deg(r), 1);
        pp = find(Y_P == T.P(r), 1);
        Z(pp, ii) = T.best_metric(r);
        txt(pp, ii) = sprintf('%.2f', T.best_metric(r));
    end
end


function local_plot_masked_heatmap(X_i, Y_P, Z, txt, mask, ttl, xlbl, ylbl)
    if isempty(X_i) || isempty(Y_P)
        axis off;
        title(ttl);
        return;
    end

    base = ones(size(Z));
    imagesc(X_i, Y_P, base);
    axis xy;
    colormap(gca, gray(2));
    caxis([0 1]);
    set(gca, 'Color', 'w');
    hold on;

    Zoverlay = Z;
    Zoverlay(~mask) = NaN;
    imagesc(X_i, Y_P, Zoverlay, 'AlphaData', double(mask));
    axis xy;
    colormap(gca, parula);

    xlabel(xlbl);
    ylabel(ylbl);
    title(ttl);
    colorbar;
    grid on; box on;

    for pp = 1:numel(Y_P)
        for ii = 1:numel(X_i)
            if mask(pp, ii) && strlength(txt(pp,ii)) > 0
                text(X_i(ii), Y_P(pp), txt(pp,ii), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle');
            elseif ~mask(pp, ii)
                plot(X_i(ii), Y_P(pp), 'x', 'Color', [0.15 0.15 0.15], 'LineWidth', 1.2, 'MarkerSize', 9);
            end
        end
    end

    hold off;
end
