function fig = plot_mb_cross_profile_frontier_overlay(frontier_table, summary_table, h_km, semantic_mode, family_name)
%PLOT_MB_CROSS_PROFILE_FRONTIER_OVERLAY Plot frontier summaries across sensor groups.

if nargin < 5 || strlength(string(family_name)) == 0
    family_name = "nominal";
end

fig = create_managed_figure(struct(), 'Color', 'w', 'Position', [160 160 1100 720]);
ax = axes(fig);
hold(ax, 'on');

if isempty(frontier_table)
    apply_mb_plot_domain_guardrail(ax, [], [], struct( ...
        'empty_message', 'No valid frontier points in current search domain', ...
        'domain_summary', sprintf('%s cross-profile frontier unavailable at h = %.0f km', char(string(semantic_mode)), h_km), ...
        'plot_domain_source', "cross_profile_frontier"));
    title(ax, sprintf('%s frontier summary across sensor groups at h = %.0f km', char(string(semantic_mode)), h_km));
    return;
end

groups = unique(frontier_table.sensor_group, 'stable');
cmap = lines(max(3, numel(groups)));
all_x = [];
all_y = [];
for idx = 1:numel(groups)
    sensor_group = groups(idx);
    sub = frontier_table(frontier_table.sensor_group == sensor_group & frontier_table.frontier_status == "defined", :);
    sub = sortrows(sub, 'i_deg');
    if isempty(sub)
        continue;
    end
    label = char(format_mb_sensor_group_label(char(string(sensor_group)), "short"));
    if numel(unique(sub.i_deg)) < 2
        plot(ax, sub.i_deg, sub.minimum_feasible_Ns, 'o', ...
            'Color', cmap(idx, :), 'LineWidth', 2.0, 'MarkerSize', 8, ...
            'MarkerFaceColor', cmap(idx, :), 'DisplayName', sprintf('%s (single point)', label));
    else
        plot(ax, sub.i_deg, sub.minimum_feasible_Ns, '-o', ...
            'Color', cmap(idx, :), 'LineWidth', 2.0, 'MarkerSize', 7, ...
            'DisplayName', label);
    end
    all_x = [all_x; sub.i_deg]; %#ok<AGROW>
    all_y = [all_y; sub.minimum_feasible_Ns]; %#ok<AGROW>
end

xlabel(ax, 'inclination i (deg)');
ylabel(ax, 'minimum feasible N_s');
title(ax, sprintf('%s frontier summary across sensor groups at h = %.0f km [%s]', char(string(semantic_mode)), h_km, char(string(family_name))));
grid(ax, 'on');
box(ax, 'on');
legend(ax, 'Location', 'eastoutside');
set(ax, 'FontSize', 13);

note = local_frontier_note(summary_table);
apply_mb_plot_domain_guardrail(ax, all_x, all_y, struct( ...
    'min_span', 10, ...
    'auto_ylim', true, ...
    'empty_message', 'No valid frontier points in current search domain', ...
    'domain_summary', char(note), ...
    'plot_domain_source', "cross_profile_frontier"));
if strlength(note) > 0
    text(ax, 0.02, 0.90, char(note), 'Units', 'normalized', ...
        'FontSize', 10, 'Color', [0.28 0.28 0.28], 'VerticalAlignment', 'top');
end
end

function note = local_frontier_note(summary_table)
note = "";
if isempty(summary_table) || ~all(ismember({'sensor_group', 'frontier_defined_count', 'sampled_inclination_count'}, summary_table.Properties.VariableNames))
    return;
end
if numel(unique(summary_table.sensor_group)) < 2
    note = "diag: single-group only";
    return;
end
for idx = 1:height(summary_table)
    if summary_table.frontier_defined_count(idx) < summary_table.sampled_inclination_count(idx)
        note = "diag: partial frontier coverage";
        return;
    end
end
note = "";
end
