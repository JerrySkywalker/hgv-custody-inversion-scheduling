function figs = stage14_plot_joint_phase_orientation(summary_table, analysis, cfg, opts)
%STAGE14_PLOT_JOINT_PHASE_ORIENTATION
% Official plotting layer for Stage14.4 joint phase-orientation analysis.

    if nargin < 3 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 4 || isempty(opts)
        opts = struct();
    end

    local = struct();
    local.scope_name = "A1";
    local.visible = "on";
    local.save_fig = true;
    local.output_dir = fullfile(cfg.paths.outputs, 'stage', 'stage14', 'figs');
    local.timestamp = string(datestr(now, 'yyyymmdd_HHMMSS'));
    local.quiet = false;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    if ~exist(local.output_dir, 'dir')
        mkdir(local.output_dir);
    end

    assert(istable(summary_table) && ~isempty(summary_table), ...
        'summary_table must be a non-empty table.');
    assert(isstruct(analysis) && isfield(analysis, 'bestF_by_RAAN'), ...
        'analysis must be a valid stage14_analyze_joint_phase_orientation output.');

    F_values = unique(summary_table.F(:))';
    RAAN_values = unique(summary_table.RAAN_deg(:))';

    [F_grid, RAAN_grid] = ndgrid(F_values, RAAN_values);
    pass_grid = nan(size(F_grid));
    dgmean_grid = nan(size(F_grid));
    dgmin_grid = nan(size(F_grid));

    for i = 1:numel(F_grid)
        rows = summary_table(summary_table.F == F_grid(i) & summary_table.RAAN_deg == RAAN_grid(i), :);
        if ~isempty(rows)
            pass_grid(i) = rows.pass_ratio(1);
            dgmean_grid(i) = rows.D_G_mean(1);
            dgmin_grid(i) = rows.D_G_min(1);
        end
    end

    scope = char(local.scope_name);
    tag = char(local.timestamp);

    figs = struct();
    figs.out_dir = local.output_dir;

    figs.pass_heatmap_png = i_plot_heatmap( ...
        RAAN_values, F_values, pass_grid, ...
        '$\mathrm{RAAN}_{\mathrm{rel}}\ (\mathrm{deg})$', '$F$', '$\mathrm{pass\ ratio}$', ...
        sprintf('Stage14.4 %s: $\\mathrm{pass\\ ratio}(F,\\Omega)$', scope), ...
        fullfile(local.output_dir, sprintf('stage14_%s_pass_ratio_F_RAAN_%s.png', scope, tag)), ...
        local);

    figs.dgmean_heatmap_png = i_plot_heatmap( ...
        RAAN_values, F_values, dgmean_grid, ...
        '$\mathrm{RAAN}_{\mathrm{rel}}\ (\mathrm{deg})$', '$F$', '$D_G^{\mathrm{mean}}$', ...
        sprintf('Stage14.4 %s: $D_G^{\\mathrm{mean}}(F,\\Omega)$', scope), ...
        fullfile(local.output_dir, sprintf('stage14_%s_DG_mean_F_RAAN_%s.png', scope, tag)), ...
        local);

    figs.dgmin_heatmap_png = i_plot_heatmap( ...
        RAAN_values, F_values, dgmin_grid, ...
        '$\mathrm{RAAN}_{\mathrm{rel}}\ (\mathrm{deg})$', '$F$', '$D_G^{\min}$', ...
        sprintf('Stage14.4 %s: $D_G^{\\min}(F,\\Omega)$', scope), ...
        fullfile(local.output_dir, sprintf('stage14_%s_DG_min_F_RAAN_%s.png', scope, tag)), ...
        local);

    figs.bestF_by_RAAN_png = i_plot_bestF_by_RAAN(analysis.bestF_by_RAAN, scope, tag, local);
    figs.robust_stats_png = i_plot_robust_stats(analysis.robust_stats_by_F, scope, tag, local);
    figs.dgmin_switch_png = i_plot_dgmin_switch(analysis.dgmin_switch_table, scope, tag, local);

    if ~local.quiet
        fprintf('\n=== Stage14.4 Plotting Layer (%s) ===\n', scope);
        fprintf('output dir         : %s\n', figs.out_dir);
        fprintf('pass heatmap       : %s\n', figs.pass_heatmap_png);
        fprintf('DG_mean heatmap    : %s\n', figs.dgmean_heatmap_png);
        fprintf('DG_min heatmap     : %s\n', figs.dgmin_heatmap_png);
        fprintf('bestF_by_RAAN plot : %s\n', figs.bestF_by_RAAN_png);
        fprintf('robust stats plot  : %s\n', figs.robust_stats_png);
        fprintf('switch-count plot  : %s\n', figs.dgmin_switch_png);
    end
end

function outpng = i_plot_heatmap(xvals, yvals, zmat, xlab, ylab, cbarlab, ttl, outpng, local)
    fig = figure('Visible', char(local.visible));
    imagesc(xvals, yvals, zmat);
    axis xy;
    grid on;
    xlabel(xlab, 'Interpreter', 'latex');
    ylabel(ylab, 'Interpreter', 'latex');
    title({ttl}, 'Interpreter', 'latex');
    cb = colorbar;
    ylabel(cb, cbarlab, 'Interpreter', 'latex');

    if local.save_fig
        exportgraphics(fig, outpng, 'Resolution', 220);
    else
        outpng = "";
    end
end

function outpng = i_plot_bestF_by_RAAN(bestF_table, scope, tag, local)
    fig = figure('Visible', char(local.visible));

    subplot(3,1,1);
    plot(bestF_table.RAAN_deg, bestF_table.bestF_pass_ratio, '-o', 'LineWidth', 1.2);
    grid on;
    ylabel('$F^*_{\mathrm{pass}}$', 'Interpreter', 'latex');
    title({sprintf('Stage14.4 %s: best $F$ by $\\Omega$', scope)}, 'Interpreter', 'latex');

    subplot(3,1,2);
    plot(bestF_table.RAAN_deg, bestF_table.bestF_DG_mean, '-o', 'LineWidth', 1.2);
    grid on;
    ylabel('$F^*_{D_G^{\mathrm{mean}}}$', 'Interpreter', 'latex');

    subplot(3,1,3);
    plot(bestF_table.RAAN_deg, bestF_table.bestF_DG_min, '-o', 'LineWidth', 1.2);
    grid on;
    ylabel('$F^*_{D_G^{\min}}$', 'Interpreter', 'latex');
    xlabel('$\mathrm{RAAN}_{\mathrm{rel}}\ (\mathrm{deg})$', 'Interpreter', 'latex');

    outpng = fullfile(local.output_dir, sprintf('stage14_%s_bestF_by_RAAN_%s.png', scope, tag));
    if local.save_fig
        exportgraphics(fig, outpng, 'Resolution', 220);
    else
        outpng = "";
    end
end

function outpng = i_plot_robust_stats(robust_stats_table, scope, tag, local)
    fig = figure('Visible', char(local.visible));

    subplot(3,1,1);
    plot(robust_stats_table.F, robust_stats_table.pass_ratio_mean, '-o', 'LineWidth', 1.2);
    hold on;
    plot(robust_stats_table.F, robust_stats_table.pass_ratio_min, '--s', 'LineWidth', 1.0);
    plot(robust_stats_table.F, robust_stats_table.pass_ratio_max, ':d', 'LineWidth', 1.0);
    grid on;
    ylabel('$\mathrm{pass\ ratio}$', 'Interpreter', 'latex');
    title({sprintf('Stage14.4 %s: robust stats by $F$', scope)}, 'Interpreter', 'latex');
    legend({'mean','min','max'}, 'Interpreter', 'latex', 'Location', 'best');

    subplot(3,1,2);
    plot(robust_stats_table.F, robust_stats_table.DG_mean_mean, '-o', 'LineWidth', 1.2);
    hold on;
    plot(robust_stats_table.F, robust_stats_table.DG_mean_min, '--s', 'LineWidth', 1.0);
    plot(robust_stats_table.F, robust_stats_table.DG_mean_max, ':d', 'LineWidth', 1.0);
    grid on;
    ylabel('$D_G^{\mathrm{mean}}$', 'Interpreter', 'latex');
    legend({'mean','min','max'}, 'Interpreter', 'latex', 'Location', 'best');

    subplot(3,1,3);
    plot(robust_stats_table.F, robust_stats_table.DG_min_mean, '-o', 'LineWidth', 1.2);
    hold on;
    plot(robust_stats_table.F, robust_stats_table.DG_min_min, '--s', 'LineWidth', 1.0);
    plot(robust_stats_table.F, robust_stats_table.DG_min_max, ':d', 'LineWidth', 1.0);
    grid on;
    ylabel('$D_G^{\min}$', 'Interpreter', 'latex');
    xlabel('$F$', 'Interpreter', 'latex');
    legend({'mean','min','max'}, 'Interpreter', 'latex', 'Location', 'best');

    outpng = fullfile(local.output_dir, sprintf('stage14_%s_robust_stats_by_F_%s.png', scope, tag));
    if local.save_fig
        exportgraphics(fig, outpng, 'Resolution', 220);
    else
        outpng = "";
    end
end

function outpng = i_plot_dgmin_switch(dgmin_switch_table, scope, tag, local)
    fig = figure('Visible', char(local.visible));
    bar(dgmin_switch_table.F, dgmin_switch_table.bestF_DG_min_count_over_RAAN);
    grid on;
    xlabel('$F$', 'Interpreter', 'latex');
    ylabel('$\#\{\Omega: F^*_{D_G^{\min}}=F\}$', 'Interpreter', 'latex');
    title({sprintf('Stage14.4 %s: switch count of $F^*_{D_G^{\\min}}$ over $\\Omega$', scope)}, ...
        'Interpreter', 'latex');

    outpng = fullfile(local.output_dir, sprintf('stage14_%s_DGmin_switch_by_F_%s.png', scope, tag));
    if local.save_fig
        exportgraphics(fig, outpng, 'Resolution', 220);
    else
        outpng = "";
    end
end
