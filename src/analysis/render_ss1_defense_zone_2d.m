function fig = render_ss1_defense_zone_2d(geom, cfg, style)
%RENDER_SS1_DEFENSE_ZONE_2D Render dissertation-style SS1 figure.

if nargin < 3 || isempty(style)
    style = milestone_common_plot_style();
end
cfg = shared_scenario_common_defaults(cfg);

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [120, 110, 980, 760]);
ax = axes(fig);
hold(ax, 'on');

th = linspace(0, 2 * pi, 360);
radius_km = geom.zone.radius_km;
fill(ax, radius_km * cos(th), radius_km * sin(th), [0.89, 0.95, 0.98], ...
    'EdgeColor', style.colors(1, :), 'LineWidth', 1.8, 'FaceAlpha', 0.85, 'HandleVisibility', 'off');
scatter(ax, 0, 0, 48, style.colors(1, :), 'filled', 'DisplayName', '防区中心');

local_plot_family(ax, geom.scenario_cases.nominal, geom.zone, style.colors(1, :), '-', '标称来袭');
local_plot_family(ax, geom.scenario_cases.heading, geom.zone, style.colors(2, :), '--', '航向偏置来袭');
local_plot_family(ax, geom.scenario_cases.critical, geom.zone, style.colors(4, :), '-.', '临界擦边来袭');

text(ax, 90, 120, '防区中心', 'Interpreter', 'tex', 'FontSize', style.annotation_font_size);
text(ax, 0.60 * radius_km, -0.08 * radius_km, 'R_d', 'Interpreter', 'tex', 'FontSize', style.annotation_font_size);
quiver(ax, 0, 0, 0.78 * radius_km, 0, 0, 'Color', style.threshold_color, 'LineWidth', 1.2, 'MaxHeadSize', 0.42, 'HandleVisibility', 'off');

xlabel(ax, '局部东向坐标 (km)', 'Interpreter', 'tex');
ylabel(ax, '局部北向坐标 (km)', 'Interpreter', 'tex');
title(ax, '共享场景 SS1: 防区与代表性来袭轨迹二维说明', 'Interpreter', 'tex', 'FontSize', style.title_font_size);
legend(ax, 'Location', 'northeast', 'Interpreter', 'tex');
axis(ax, 'equal');
lim = max(3200, radius_km * 3.2);
xlim(ax, [-lim, lim]);
ylim(ax, [-lim, lim]);

apply_dissertation_plot_style(fig, style);
end

function local_plot_family(ax, item, zone, color_value, line_style, label_text)
if isempty(item)
    return;
end
xy_km = project_case_trajectory_to_local_plane(item.traj.r_ecef_m, zone);
xy_km = local_decimate_track(xy_km, 110);
plot(ax, xy_km(:, 1), xy_km(:, 2), line_style, 'Color', color_value, 'LineWidth', 2.0, 'DisplayName', label_text);

head_idx = max(2, floor(size(xy_km, 1) * 0.18));
delta = xy_km(head_idx - 1, :) - xy_km(head_idx, :);
quiver(ax, xy_km(head_idx, 1), xy_km(head_idx, 2), delta(1), delta(2), 0, ...
    'Color', color_value, 'LineWidth', 1.2, 'MaxHeadSize', 0.7, 'HandleVisibility', 'off');
end

function track = local_decimate_track(track, max_points)
if size(track, 1) <= max_points
    return;
end
idx = round(linspace(1, size(track, 1), max_points));
track = track(idx, :);
end
