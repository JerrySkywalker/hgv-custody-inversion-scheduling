function fig = plot_mb_stage05_semantic_pareto_frontier(pareto_table, h_km, options)
%PLOT_MB_STAGE05_SEMANTIC_PARETO_FRONTIER Plot Stage05-semantic Pareto frontier under MB outputs.

if nargin < 3 || isempty(options)
    options = struct();
end

fig = figure('Color', 'w', 'Name', 'MB Stage05 Semantic Pareto', 'Position', [180 180 1100 700]);
ax = axes(fig);
hold(ax, 'on');

if isempty(pareto_table)
    text(ax, 0.5, 0.5, 'No feasible frontier point', 'HorizontalAlignment', 'center', 'FontSize', 14);
else
    plot(ax, pareto_table.Ns, pareto_table.D_G_min, '-o', ...
        'Color', [0.15 0.35 0.75], 'LineWidth', 2.2, 'MarkerSize', 8, ...
        'MarkerFaceColor', [0.15 0.35 0.75]);
    if local_show_annotations(options)
        for idx = 1:height(pareto_table)
            text(ax, pareto_table.Ns(idx) + 1.0, pareto_table.D_G_min(idx), ...
                sprintf('(i=%g,P=%g,T=%g)', pareto_table.i_deg(idx), pareto_table.P(idx), pareto_table.T(idx)), ...
                'FontSize', 10, 'Color', [0.1 0.1 0.1]);
        end
    end
end

xlabel(ax, 'total satellites N_s');
ylabel(ax, 'D_G^{min}');
title(ax, sprintf('MB Control (Stage05 Semantics): Pareto frontier at h = %.0f km', h_km));
grid(ax, 'on');
box(ax, 'on');
set(ax, 'FontSize', 13);
hold(ax, 'off');
end

function tf = local_show_annotations(options)
style_mode = local_getfield_or(options, 'figure_style', struct());
if isstruct(style_mode) && isfield(style_mode, 'show_diagnostic_annotation')
    tf = logical(style_mode.show_diagnostic_annotation);
else
    tf = true;
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
