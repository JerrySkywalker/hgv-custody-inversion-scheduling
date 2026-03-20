function fig = plot_mb_stage05_semantic_passratio_envelope(envelope_table, h_km, options)
%PLOT_MB_STAGE05_SEMANTIC_PASSRATIO_ENVELOPE Plot the Stage05-semantic pass-ratio envelope under MB outputs.

if nargin < 3 || isempty(options)
    options = struct();
end

i_list = unique(envelope_table.i_deg, 'sorted');
fig = figure('Color', 'w', 'Name', 'MB Stage05 Semantic PassRatio', 'Position', [120 120 1100 700]);
ax = axes(fig);
hold(ax, 'on');

if isempty(envelope_table)
    apply_mb_plot_domain_guardrail(ax, [], [], struct( ...
        'empty_message', 'No feasible point found within current search domain', ...
        'domain_summary', sprintf('Search domain summary unavailable at h = %.0f km', h_km), ...
        'ylim', [0, 1.05], ...
        'plot_domain_source', "no_valid_points", ...
        'figure_style', local_getfield_or(options, 'figure_style', struct())));
    title(ax, sprintf('MB Control (Stage05 Semantics): pass-ratio envelope versus N_s at h = %.0f km', h_km));
    return;
end

cmap = lines(numel(i_list));
for idx = 1:numel(i_list)
    i_deg = i_list(idx);
    Ti = envelope_table(envelope_table.i_deg == i_deg, :);
    Ti = sortrows(Ti, 'Ns');
    valid_mask = isfinite(Ti.Ns) & isfinite(Ti.max_pass_ratio);
    Ti = Ti(valid_mask, :);
    if isempty(Ti)
        continue;
    elseif numel(unique(Ti.Ns)) < 2
        plot(ax, Ti.Ns, Ti.max_pass_ratio, 'o', ...
            'Color', cmap(idx, :), 'LineWidth', 2.0, 'MarkerSize', 8, ...
            'MarkerFaceColor', cmap(idx, :), 'DisplayName', sprintf('i=%g deg (single point)', i_deg));
    else
        plot(ax, Ti.Ns, Ti.max_pass_ratio, '-o', ...
            'Color', cmap(idx, :), 'LineWidth', 2.0, 'MarkerSize', 8, ...
            'DisplayName', sprintf('i=%g deg', i_deg));
    end
end

xlabel(ax, 'total satellites N_s');
ylabel(ax, 'max pass ratio under fixed i');
title(ax, sprintf('MB Control (Stage05 Semantics): pass-ratio envelope versus N_s at h = %.0f km', h_km));
legend(ax, 'Location', 'eastoutside');
grid(ax, 'on');
box(ax, 'on');
set(ax, 'FontSize', 13);
apply_mb_plot_domain_guardrail(ax, envelope_table.Ns, envelope_table.max_pass_ratio, struct( ...
    'ylim', [0, 1.05], ...
    'empty_message', 'No feasible point found within current search domain', ...
    'domain_summary', sprintf('Search domain: h = %.0f km', h_km), ...
    'plot_domain_source', "stage05_envelope", ...
    'figure_style', local_getfield_or(options, 'figure_style', struct())));
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
