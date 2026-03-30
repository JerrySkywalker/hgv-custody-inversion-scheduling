function pack = plot_stage09_joint_closure_pack(in, mode_tag)
%PLOT_STAGE09_JOINT_CLOSURE_PACK
% Phase3-A:
%   Export Stage09 joint-closure formal plots into an isolated pack.
%
% Inputs
%   in       : either
%              (1) base struct with s4 / s5 / cfg / views / frontiers
%              (2) struct with out9_4 / out9_5 / cfg
%   mode_tag : optional suffix tag
%
% Outputs
%   pack.figure_index
%   pack.files.*

    if nargin < 2 || isempty(mode_tag)
        mode_tag = 'phase3_joint';
    end

    [pdata, frontiers, cfg] = local_unpack_inputs(in, mode_tag);

    cfg = stage09_prepare_cfg(cfg);
    cfg_pack = cfg;
    cfg_pack.paths.figs = fullfile(cfg.paths.figs, 'joint_closure_pack');
    cfg_pack.paths.tables = fullfile(cfg.paths.tables, 'joint_closure_pack');
    ensure_dir(cfg_pack.paths.figs);
    ensure_dir(cfg_pack.paths.tables);

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    run_tag = char(string(cfg_pack.stage09.run_tag));

    fprintf('\n');
    fprintf('=========== Stage09 Joint Closure Pack (Phase3-A) ===========\n');
    fprintf('run_tag  : %s\n', run_tag);
    fprintf('mode_tag : %s\n', string(mode_tag));
    fprintf('fig dir  : %s\n', cfg_pack.paths.figs);
    fprintf('table dir: %s\n', cfg_pack.paths.tables);
    fprintf('=============================================================\n\n');

    fig_domain = plot_stage09_feasible_domain_maps(pdata, cfg_pack, timestamp);
    fig_boundary = plot_stage09_minimum_boundary(pdata, cfg_pack, timestamp);
    fig_extra = local_plot_joint_frontier_family(frontiers.joint, cfg_pack, timestamp, mode_tag);

    figure_index = table( ...
        string(fig_domain.minNs_hi), ...
        string(fig_domain.fail_hi_refPT), ...
        string(fig_domain.feasible_PT), ...
        string(fig_boundary.Ns_vs_margin), ...
        string(fig_boundary.theta_min_hi), ...
        string(fig_extra.inclination_frontier), ...
        string(fig_extra.pareto_frontier), ...
        string(fig_extra.transition_summary), ...
        'VariableNames', { ...
            'fig_joint_minNs_hi', ...
            'fig_joint_fail_hi_refPT', ...
            'fig_joint_feasible_PT', ...
            'fig_joint_Ns_vs_margin', ...
            'fig_joint_theta_min_hi', ...
            'fig_joint_inclination_frontier', ...
            'fig_joint_pareto_frontier', ...
            'fig_joint_transition_summary'});

    figure_index_csv = fullfile(cfg_pack.paths.tables, ...
        sprintf('stage09_joint_closure_pack_figure_index_%s_%s_%s.csv', run_tag, char(string(mode_tag)), timestamp));
    writetable(figure_index, figure_index_csv);

    pack = struct();
    pack.figure_index = figure_index;
    pack.files = struct();
    pack.files.figure_index_csv = figure_index_csv;
    pack.files.fig_joint_minNs_hi = fig_domain.minNs_hi;
    pack.files.fig_joint_fail_hi_refPT = fig_domain.fail_hi_refPT;
    pack.files.fig_joint_feasible_PT = fig_domain.feasible_PT;
    pack.files.fig_joint_Ns_vs_margin = fig_boundary.Ns_vs_margin;
    pack.files.fig_joint_theta_min_hi = fig_boundary.theta_min_hi;
    pack.files.fig_joint_inclination_frontier = fig_extra.inclination_frontier;
    pack.files.fig_joint_pareto_frontier = fig_extra.pareto_frontier;
    pack.files.fig_joint_transition_summary = fig_extra.transition_summary;

    fprintf('\n');
    fprintf('================ Joint Closure Pack Summary ================\n');
    disp(figure_index);
    fprintf('Figure index CSV : %s\n', figure_index_csv);
    fprintf('===========================================================\n\n');
end


function [pdata, frontiers, cfg] = local_unpack_inputs(in, mode_tag)

    if ~isstruct(in)
        error('plot_stage09_joint_closure_pack:InvalidInput', 'Input must be a struct.');
    end

    pdata = struct();

    if isfield(in, 'out9_4') && isfield(in, 'out9_5')
        pdata.out9_4 = in.out9_4;
        pdata.out9_5 = in.out9_5;
    elseif isfield(in, 's4') && isfield(in, 's5')
        pdata.out9_4 = in.s4;
        pdata.out9_5 = in.s5;
    else
        error('plot_stage09_joint_closure_pack:MissingStageOutputs', ...
            ['Input must contain either:' newline ...
             '  (1) out9_4 + out9_5' newline ...
             '  (2) s4 + s5']);
    end

    cfg = local_pick_cfg(in, pdata);

    if isfield(in, 'frontiers') && isstruct(in.frontiers) && isfield(in.frontiers, 'joint')
        frontiers = in.frontiers;
        return;
    end

    if isfield(in, 'views') && isstruct(in.views) && isfield(in.views, 'joint')
        frontiers = build_stage09_metric_frontiers(in.views, cfg, ['joint_closure_' char(string(mode_tag))]);
        return;
    end

    tmp = struct();
    tmp.s4 = pdata.out9_4;
    tmp.s5 = pdata.out9_5;
    views = build_stage09_metric_views(tmp, ['joint_closure_' char(string(mode_tag))]);
    frontiers = build_stage09_metric_frontiers(views, cfg, ['joint_closure_' char(string(mode_tag))]);
end


function cfg = local_pick_cfg(in, pdata)

    if isfield(in, 'cfg') && isstruct(in.cfg)
        cfg = in.cfg;
        return;
    end

    if isfield(in, 's4') && isstruct(in.s4) && isfield(in.s4, 'cfg') && isstruct(in.s4.cfg)
        cfg = in.s4.cfg;
        return;
    end

    if isfield(in, 'out9_4') && isstruct(in.out9_4) && isfield(in.out9_4, 'cfg') && isstruct(in.out9_4.cfg)
        cfg = in.out9_4.cfg;
        return;
    end

    if isfield(pdata, 'out9_4') && isstruct(pdata.out9_4) && isfield(pdata.out9_4, 'cfg') && isstruct(pdata.out9_4.cfg)
        cfg = pdata.out9_4.cfg;
        return;
    end

    error('plot_stage09_joint_closure_pack:MissingCfg', ...
        'Unable to locate cfg in input struct.');
end


function fig_files = local_plot_joint_frontier_family(Fjoint, cfg, timestamp, mode_tag)

    fig_files = struct();
    run_tag = char(string(cfg.stage09.run_tag));

    fig_files.inclination_frontier = local_plot_joint_inclination_frontier( ...
        Fjoint.frontier_by_i, cfg, timestamp, run_tag, mode_tag);

    fig_files.pareto_frontier = local_plot_joint_pareto_frontier( ...
        Fjoint.pareto_frontier, cfg, timestamp, run_tag, mode_tag);

    fig_files.transition_summary = local_plot_joint_transition_summary( ...
        Fjoint.transition_summary, cfg, timestamp, run_tag, mode_tag);
end


function fig_path = local_plot_joint_inclination_frontier(Tfront, cfg, timestamp, run_tag, mode_tag)

    f = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 980, 560]);

    if isempty(Tfront)
        text(0.5, 0.5, 'No joint frontier available', 'HorizontalAlignment', 'center');
        axis off;
    else
        yyaxis left;
        plot(Tfront.i_deg, Tfront.frontier_Ns, '-o', 'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', 'frontier N_s');
        ylabel('Minimum feasible N_s');

        yyaxis right;
        plot(Tfront.i_deg, Tfront.frontier_metric, '-s', 'LineWidth', 2, 'MarkerSize', 8, ...
            'DisplayName', 'frontier joint margin');
        ylabel('Joint margin');

        grid on;
        box on;
        xlabel('Inclination i [deg]');
        title('Stage09 joint inclination frontier');

        yyaxis right;
        for k = 1:height(Tfront)
            text(Tfront.i_deg(k), Tfront.frontier_metric(k), ...
                sprintf('(%d,%d)', Tfront.P(k), Tfront.T(k)), ...
                'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 10);
        end
        legend('Location', 'best');
    end

    fig_path = fullfile(cfg.paths.figs, ...
        sprintf('stage09_joint_inclination_frontier_%s_%s_%s.png', run_tag, char(string(mode_tag)), timestamp));
    exportgraphics(f, fig_path, 'Resolution', 200);
    close(f);
end


function fig_path = local_plot_joint_pareto_frontier(Tpareto, cfg, timestamp, run_tag, mode_tag)

    f = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 980, 560]);

    if isempty(Tpareto)
        text(0.5, 0.5, 'No joint Pareto frontier available', 'HorizontalAlignment', 'center');
        axis off;
    else
        plot(Tpareto.Ns, Tpareto.metric_value, '-o', 'LineWidth', 2, 'MarkerSize', 8);
        grid on;
        box on;
        xlabel('Total satellites N_s');
        ylabel('Joint margin');
        title('Stage09 joint global Pareto frontier');

        for k = 1:height(Tpareto)
            text(Tpareto.Ns(k), Tpareto.metric_value(k), ...
                sprintf('(%d,%d)', Tpareto.P(k), Tpareto.T(k)), ...
                'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 10);
        end
    end

    fig_path = fullfile(cfg.paths.figs, ...
        sprintf('stage09_joint_pareto_frontier_%s_%s_%s.png', run_tag, char(string(mode_tag)), timestamp));
    exportgraphics(f, fig_path, 'Resolution', 200);
    close(f);
end


function fig_path = local_plot_joint_transition_summary(Tsum, cfg, timestamp, run_tag, mode_tag)

    f = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 980, 560]);

    if isempty(Tsum)
        text(0.5, 0.5, 'No joint transition summary available', 'HorizontalAlignment', 'center');
        axis off;
    else
        yyaxis left;
        hold on;
        mask1 = isfinite(Tsum.first_Ns_feasible);
        if any(mask1)
            plot(Tsum.i_deg(mask1), Tsum.first_Ns_feasible(mask1), '-o', 'LineWidth', 2, 'MarkerSize', 8, ...
                'DisplayName', 'first N_s feasible');
        end
        mask2 = isfinite(Tsum.frontier_Ns);
        if any(mask2)
            plot(Tsum.i_deg(mask2), Tsum.frontier_Ns(mask2), '-d', 'LineWidth', 2, 'MarkerSize', 8, ...
                'DisplayName', 'frontier N_s');
        end
        ylabel('N_s');
        xlabel('Inclination i [deg]');
        grid on;
        box on;

        yyaxis right;
        mask3 = isfinite(Tsum.frontier_metric);
        if any(mask3)
            plot(Tsum.i_deg(mask3), Tsum.frontier_metric(mask3), '-s', 'LineWidth', 2, 'MarkerSize', 8, ...
                'DisplayName', 'frontier joint margin');
        end
        ylabel('Joint margin');
        title('Stage09 joint transition summary');
        legend('Location', 'best');
        hold off;
    end

    fig_path = fullfile(cfg.paths.figs, ...
        sprintf('stage09_joint_transition_summary_%s_%s_%s.png', run_tag, char(string(mode_tag)), timestamp));
    exportgraphics(f, fig_path, 'Resolution', 200);
    close(f);
end
