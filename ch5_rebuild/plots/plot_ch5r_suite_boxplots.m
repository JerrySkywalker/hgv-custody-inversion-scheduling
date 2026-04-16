function out = plot_ch5r_suite_boxplots(T, metrics, outdir, visible_mode)
%PLOT_CH5R_SUITE_BOXPLOTS
% Plot boxplots with:
% - raw sample points overlay
% - explanatory legend
% - nonnegative axis guard for nonnegative metrics

if nargin < 2 || isempty(metrics)
    metrics = {'LoC_ratio','bubble_time_s','max_bubble_depth','switch_count', ...
               'mean_rmse_pos_km','final_rmse_pos_km'};
end
if nargin < 3 || isempty(outdir)
    outdir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'multicase_suite', 'figs');
end
if nargin < 4 || isempty(visible_mode)
    visible_mode = 'off';
end

if ~exist(outdir, 'dir')
    mkdir(outdir);
end

method_order = {'R4','R5','R9','R10'};
methods_present = unique(cellstr(string(T.method)), 'stable');
method_order = method_order(ismember(method_order, methods_present));

out = struct();
out.files = struct();

for i = 1:numel(metrics)
    metric = metrics{i};
    assert(ismember(metric, T.Properties.VariableNames), 'Missing metric column: %s', metric);

    vals = [];
    grp = {};
    method_vals = cell(numel(method_order), 1);

    for j = 1:numel(method_order)
        m = method_order{j};
        x = T{strcmp(string(T.method), m), metric};
        x = x(isfinite(x));
        method_vals{j} = x(:);
        vals = [vals; x(:)]; %#ok<AGROW>
        grp = [grp; repmat({m}, numel(x), 1)]; %#ok<AGROW>
    end

    fig = figure('Visible', visible_mode, 'Color', 'w');
    ax = axes(fig);
    boxplot(ax, vals, grp, 'LabelOrientation', 'inline');
    hold(ax, 'on');
    grid(ax, 'on');

    % overlay raw sample points
    for j = 1:numel(method_order)
        xj = method_vals{j};
        if isempty(xj)
            continue;
        end
        if numel(xj) == 1
            jitter = 0;
        else
            jitter = linspace(-0.08, 0.08, numel(xj)).';
        end
        scatter(ax, j + jitter, xj, 28, ...
            'o', ...
            'MarkerFaceColor', [0.25 0.25 0.25], ...
            'MarkerEdgeColor', [0.25 0.25 0.25], ...
            'MarkerFaceAlpha', 0.8, ...
            'MarkerEdgeAlpha', 0.8);
    end

    xlabel(ax, 'Method');
    ylabel(ax, local_pretty_metric(metric), 'Interpreter', 'none');
    title(ax, [local_pretty_metric(metric) ' boxplot'], 'Interpreter', 'none');

    % sample-size subtitle
    count_parts = cell(1, numel(method_order));
    for j = 1:numel(method_order)
        count_parts{j} = sprintf('%s: n=%d', method_order{j}, numel(method_vals{j}));
    end
    subtitle(ax, strjoin(count_parts, '   |   '), 'Interpreter', 'none');

    % legend
    hSample = scatter(ax, nan, nan, 28, 'o', ...
        'MarkerFaceColor', [0.25 0.25 0.25], ...
        'MarkerEdgeColor', [0.25 0.25 0.25], ...
        'DisplayName', 'Sample points');
    hBox = patch(ax, nan, nan, [0.85 0.85 0.85], ...
        'EdgeColor', [0 0 0], ...
        'FaceAlpha', 0.25, ...
        'DisplayName', 'IQR box');
    hMed = plot(ax, nan, nan, '-', ...
        'Color', [0.85 0.33 0.10], ...
        'LineWidth', 1.5, ...
        'DisplayName', 'Median');
    legend(ax, [hSample hBox hMed], {'Sample points','IQR box','Median'}, ...
        'Location', 'eastoutside');

    % if all values are nonnegative, keep lower bound at 0
    if ~isempty(vals) && all(vals >= 0)
        ymax = max(vals);
        pad = max(0.05 * max(ymax, 1), 0.02);
        ylim(ax, [0, ymax + pad]);
    end

    tag = lower(regexprep(metric, '[^A-Za-z0-9]+', '_'));
    png_file = fullfile(outdir, ['ch5r_multicase_' tag '_boxplot.png']);
    fig_file = fullfile(outdir, ['ch5r_multicase_' tag '_boxplot.fig']);
    saveas(fig, png_file);
    savefig(fig, fig_file);
    close(fig);

    out.files.(tag) = struct('png', png_file, 'fig', fig_file);
end
end

function s = local_pretty_metric(metric)
switch char(string(metric))
    case 'LoC_ratio'
        s = 'LoC ratio';
    case 'bubble_time_s'
        s = 'Bubble time (s)';
    case 'max_bubble_depth'
        s = 'Max bubble depth';
    case 'switch_count'
        s = 'Switch count';
    case 'mean_rmse_pos_km'
        s = 'Mean RMSE pos (km)';
    case 'final_rmse_pos_km'
        s = 'Final RMSE pos (km)';
    otherwise
        s = char(string(metric));
end
end
