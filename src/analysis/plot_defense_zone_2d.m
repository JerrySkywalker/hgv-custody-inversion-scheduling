function fig = plot_defense_zone_2d(geom, scenario_cases, style)
%PLOT_DEFENSE_ZONE_2D Plot dissertation-facing 2D defense-zone explanation.

if nargin < 3 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [120, 120, 980, 760]);
ax = axes(fig);
hold(ax, 'on');

th = linspace(0, 2 * pi, 360);
fill(ax, geom.zone_radius_km * cos(th), geom.zone_radius_km * sin(th), [0.88, 0.94, 0.98], ...
    'EdgeColor', style.colors(1, :), 'LineWidth', style.line_width, 'FaceAlpha', 0.65);
scatter(ax, 0, 0, 56, style.colors(1, :), 'filled');

local_plot_case(ax, scenario_cases.nominal, style.colors(1, :), '-', '名义来袭');
local_plot_case(ax, scenario_cases.heading, style.colors(2, :), '--', '航向偏置来袭');
local_plot_case(ax, scenario_cases.critical, style.colors(4, :), '-.', '临界来袭');

text(ax, 80, 120, '防区中心', 'Interpreter', 'tex', 'FontSize', style.annotation_font_size);
text(ax, geom.zone_radius_km * 0.72, -120, '防区半径 R_d', 'Interpreter', 'tex', 'FontSize', style.annotation_font_size);

quiver(ax, -0.7 * geom.zone_radius_km, 0, 0.55 * geom.zone_radius_km, 0, 0, ...
    'Color', style.threshold_color, 'LineWidth', style.marker_line_width, 'MaxHeadSize', 0.45);

xlabel(ax, '局部东向坐标 (km)', 'Interpreter', 'tex');
ylabel(ax, '局部北向坐标 (km)', 'Interpreter', 'tex');
title(ax, '共享场景 SS1: 防区与代表性来袭轨迹二维示意', 'Interpreter', 'tex', 'FontSize', style.title_font_size);
legend(ax, 'Location', 'northeast', 'Interpreter', 'tex');
axis(ax, 'equal');
lim = max(geom.zone_radius_km * 3.2, 3400);
xlim(ax, [-lim, lim]);
ylim(ax, [-lim, lim]);

annotation(fig, 'textbox', [0.58, 0.80, 0.30, 0.11], ...
    'String', { ...
        sprintf('防区中心: (%.1f^\\circ, %.1f^\\circ)', geom.zone_center_lat_deg, geom.zone_center_lon_deg), ...
        '共享说明用于第四章/第五章', ...
        '轨迹采用真实基线案例投影'}, ...
    'Interpreter', 'tex', ...
    'FitBoxToText', 'on', ...
    'BackgroundColor', 'w', ...
    'EdgeColor', 0.8 * [1, 1, 1], ...
    'FontSize', style.annotation_font_size);

apply_dissertation_plot_style(fig, style);
end

function local_plot_case(ax, item, color_value, line_style, label_text)
if isempty(item)
    return;
end
xy = item.traj.xy_km;
plot(ax, xy(:, 1), xy(:, 2), line_style, 'Color', color_value, 'LineWidth', 2.0, 'DisplayName', label_text);
head_idx = max(2, floor(size(xy, 1) * 0.12));
quiver(ax, xy(head_idx, 1), xy(head_idx, 2), ...
    xy(head_idx - 1, 1) - xy(head_idx, 1), xy(head_idx - 1, 2) - xy(head_idx, 2), 0, ...
    'Color', color_value, 'LineWidth', 1.4, 'MaxHeadSize', 0.7, 'HandleVisibility', 'off');
end
