function fig = plot_mb_stage05_semantic_frontier_summary(summary_table, h_km, options)
%PLOT_MB_STAGE05_SEMANTIC_FRONTIER_SUMMARY Plot the inclination-wise Stage05-semantic frontier summary.

if nargin < 3 || isempty(options)
    options = struct();
end

fig = create_managed_figure(struct(), 'Color', 'w', 'Name', 'MB Stage05 Semantic Frontier', 'Position', [160 160 1100 700]);

valid_frontier = summary_table.frontier_Ns(isfinite(summary_table.frontier_Ns));
if isempty(valid_frontier)
    ax_empty = axes(fig);
    x_span = local_i_span_string(summary_table);
    apply_mb_plot_domain_guardrail(ax_empty, [], [], struct( ...
        'empty_message', 'No feasible point found within current search domain', ...
        'domain_summary', sprintf('Search domain: h = %.0f km, i = %s', h_km, x_span), ...
        'plot_domain_source', "no_valid_frontier", ...
        'figure_style', local_getfield_or(options, 'figure_style', struct())));
    title(ax_empty, sprintf('MB Control (Stage05 Semantics): inclination-wise frontier summary at h = %.0f km', h_km));
    return;
end

yyaxis left;
if numel(unique(summary_table.i_deg(isfinite(summary_table.frontier_Ns)))) < 2
    plot(summary_table.i_deg, summary_table.frontier_Ns, 'o', 'LineWidth', 2.5, 'MarkerSize', 10, 'MarkerFaceColor', [0.15 0.35 0.75]);
else
    plot(summary_table.i_deg, summary_table.frontier_Ns, '-o', 'LineWidth', 2.5, 'MarkerSize', 10);
end
ylabel('minimum feasible N_s');

ylim([max(0, min(valid_frontier) - 10), max(valid_frontier) + 10]);

yyaxis right;
if numel(unique(summary_table.i_deg(isfinite(summary_table.frontier_D_G_min)))) < 2
    plot(summary_table.i_deg, summary_table.frontier_D_G_min, 's', 'LineWidth', 2.5, 'MarkerSize', 9, 'MarkerFaceColor', [0.8 0.25 0.15]);
else
    plot(summary_table.i_deg, summary_table.frontier_D_G_min, '-s', 'LineWidth', 2.5, 'MarkerSize', 9);
end
ylabel('D_G^{min} of frontier point');

hold on;
if local_show_annotations(options)
    for idx = 1:height(summary_table)
        if isfinite(summary_table.frontier_Ns(idx))
            yyaxis left;
            text(summary_table.i_deg(idx) + 0.3, summary_table.frontier_Ns(idx) + 1.0, ...
                sprintf('(P=%g,T=%g)', summary_table.frontier_P(idx), summary_table.frontier_T(idx)), ...
                'FontSize', 11, 'Color', [0.1 0.1 0.1]);
        end
    end
end

xlabel('inclination i (deg)');
title(sprintf('MB Control (Stage05 Semantics): inclination-wise frontier summary at h = %.0f km', h_km));
grid on;
box on;
set(gca, 'FontSize', 13);
yyaxis left;
apply_mb_plot_domain_guardrail(gca, summary_table.i_deg, summary_table.frontier_Ns, struct( ...
    'min_span', 10, ...
    'empty_message', 'No valid frontier point found within current search domain', ...
    'domain_summary', sprintf('Search domain: h = %.0f km, i = %s', h_km, local_i_span_string(summary_table)), ...
    'plot_domain_source', "frontier_summary", ...
    'figure_style', local_getfield_or(options, 'figure_style', struct())));
end

function span_text = local_i_span_string(summary_table)
if isempty(summary_table) || ~ismember('i_deg', summary_table.Properties.VariableNames)
    span_text = 'unknown';
    return;
end
i_vals = summary_table.i_deg(:);
i_vals = i_vals(isfinite(i_vals));
if isempty(i_vals)
    span_text = 'unknown';
else
    span_text = sprintf('[%.0f, %.0f] deg', min(i_vals), max(i_vals));
end
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
