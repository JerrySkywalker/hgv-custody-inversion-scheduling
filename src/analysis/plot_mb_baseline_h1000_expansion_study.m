function fig = plot_mb_baseline_h1000_expansion_study(case_results)
%PLOT_MB_BASELINE_H1000_EXPANSION_STUDY Plot before/after pass-ratio diagnostics for baseline h=1000 expansion.

style = milestone_common_plot_style();
fig = figure('Visible', 'off', 'Color', 'w', 'Position', [120 120 1320 860]);
tiled = tiledlayout(fig, numel(case_results), 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tiled, 'MB Baseline h=1000 Expansion Study: initial versus expanded domains');

for idx = 1:numel(case_results)
    entry = case_results(idx);
    x_all = [local_getfield_or(entry.initial.snapshot.passratio_phasecurve, 'Ns', []); ...
             local_getfield_or(entry.expanded.snapshot.passratio_phasecurve, 'Ns', [])];
    guard = compute_mb_plot_window_from_data(x_all, struct( ...
        'empty_message', 'No valid pass-ratio point found within current search domain'));

    ax_left = nexttile(tiled, 2 * idx - 1);
    local_plot_phasecurve(ax_left, entry.initial.snapshot.passratio_phasecurve, style);
    title(ax_left, sprintf('%s initial domain', char(entry.semantic_mode)));
    ylabel(ax_left, 'max pass ratio');
    apply_mb_plot_domain_guardrail(ax_left, local_getfield_or(entry.initial.snapshot.passratio_phasecurve, 'Ns', []), ...
        local_getfield_or(entry.initial.snapshot.passratio_phasecurve, 'max_pass_ratio', []), struct( ...
        'plot_xlim_ns', guard.xlim, ...
        'ylim', [0, 1.05], ...
        'empty_message', 'No valid pass-ratio point found within initial search domain', ...
        'domain_summary', char(local_snapshot_summary(entry.initial.snapshot)), ...
        'plot_domain_source', "baseline_h1000_initial"));
    local_add_note(ax_left, entry.initial.snapshot);

    ax_right = nexttile(tiled, 2 * idx);
    local_plot_phasecurve(ax_right, entry.expanded.snapshot.passratio_phasecurve, style);
    title(ax_right, sprintf('%s expanded domain', char(entry.semantic_mode)));
    apply_mb_plot_domain_guardrail(ax_right, local_getfield_or(entry.expanded.snapshot.passratio_phasecurve, 'Ns', []), ...
        local_getfield_or(entry.expanded.snapshot.passratio_phasecurve, 'max_pass_ratio', []), struct( ...
        'plot_xlim_ns', guard.xlim, ...
        'ylim', [0, 1.05], ...
        'empty_message', 'No valid pass-ratio point found within expanded search domain', ...
        'domain_summary', char(local_snapshot_summary(entry.expanded.snapshot)), ...
        'plot_domain_source', "baseline_h1000_expanded"));
    local_add_note(ax_right, entry.expanded.snapshot);

    if idx == numel(case_results)
        xlabel(ax_left, 'N_s');
        xlabel(ax_right, 'N_s');
    end
end
end

function local_plot_phasecurve(ax, phasecurve_table, style)
hold(ax, 'on');
if isempty(phasecurve_table) || ~all(ismember({'i_deg', 'Ns', 'max_pass_ratio'}, phasecurve_table.Properties.VariableNames))
    hold(ax, 'off');
    return;
end

unique_i = unique(phasecurve_table.i_deg, 'sorted');
cmap = turbo(max(2, numel(unique_i)));
for idx = 1:numel(unique_i)
    sub = phasecurve_table(phasecurve_table.i_deg == unique_i(idx), :);
    sub = sortrows(sub, 'Ns');
    valid_mask = isfinite(sub.Ns) & isfinite(sub.max_pass_ratio);
    sub = sub(valid_mask, :);
    if isempty(sub)
        continue;
    elseif numel(unique(sub.Ns)) < 2
        plot(ax, sub.Ns, sub.max_pass_ratio, 'o', 'Color', cmap(idx, :), ...
            'LineWidth', style.line_width, 'MarkerSize', style.marker_size + 1, ...
            'MarkerFaceColor', cmap(idx, :));
    else
        plot(ax, sub.Ns, sub.max_pass_ratio, '-o', 'Color', cmap(idx, :), ...
            'LineWidth', style.line_width, 'MarkerSize', style.marker_size);
    end
end
grid(ax, 'on');
hold(ax, 'off');
end

function txt = local_snapshot_summary(snapshot)
txt = sprintf('search: Ns[%g,%g], maxPR=%.2f, frontier=%d', ...
    local_getfield_or(snapshot.search_domain, 'ns_search_min', NaN), ...
    local_getfield_or(snapshot.search_domain, 'ns_search_max', NaN), ...
    snapshot.max_passratio, snapshot.frontier_points);
end

function local_add_note(ax, snapshot)
notes = strings(0, 1);
if snapshot.right_unity_reached
    notes(end + 1, 1) = "unity plateau reached"; %#ok<AGROW>
else
    notes(end + 1, 1) = "unity plateau not reached"; %#ok<AGROW>
end
if snapshot.boundary_dominated
    notes(end + 1, 1) = "boundary dominated"; %#ok<AGROW>
end
if snapshot.frontier_truncated
    notes(end + 1, 1) = "frontier still truncated"; %#ok<AGROW>
end
if strlength(string(snapshot.stop_reason)) > 0
    notes(end + 1, 1) = "stop: " + string(snapshot.stop_reason); %#ok<AGROW>
end
if isempty(notes)
    return;
end
text(ax, 0.02, 0.10, char(strjoin(notes, " | ")), 'Units', 'normalized', ...
    'VerticalAlignment', 'bottom', 'FontSize', 9.5, 'Color', [0.35 0.35 0.35], ...
    'Interpreter', 'none');
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
elseif istable(S) && ismember(field_name, S.Properties.VariableNames)
    value = S.(field_name);
else
    value = fallback;
end
end
