function fig = plot_earth_walker_zone_3d(geom, scenario_cases, style)
%PLOT_EARTH_WALKER_ZONE_3D Plot Earth / Walker / defense-zone relationship.

if nargin < 3 || isempty(style)
    style = milestone_common_plot_style();
end

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [140, 80, 1100, 820]);
ax = axes(fig);
hold(ax, 'on');

[xs, ys, zs] = sphere(72);
surf(ax, geom.earth_radius_km * xs, geom.earth_radius_km * ys, geom.earth_radius_km * zs, ...
    'FaceColor', [0.83, 0.90, 0.96], 'EdgeColor', 'none', 'FaceAlpha', 0.95);
lighting(ax, 'gouraud');
camlight(ax, 'headlight');

plot3(ax, geom.zone_ring_ecef_km(:, 1), geom.zone_ring_ecef_km(:, 2), geom.zone_ring_ecef_km(:, 3), ...
    'Color', style.colors(2, :), 'LineWidth', 2.2, 'DisplayName', '防区边界');
scatter3(ax, geom.center_ecef_km(1), geom.center_ecef_km(2), geom.center_ecef_km(3), ...
    70, style.colors(2, :), 'filled', 'DisplayName', '防区中心');

sat_positions = squeeze(geom.satbank.r_eci_km(1, :, :)).';
plane_ids = [geom.walker.sat.plane_id];
for plane_id = unique(plane_ids)
    idx = find(plane_ids == plane_id);
    plane_ring = sat_positions(idx, :);
    plane_ring(end + 1, :) = plane_ring(1, :); %#ok<AGROW>
    plot3(ax, plane_ring(:, 1), plane_ring(:, 2), plane_ring(:, 3), '-', ...
        'Color', style.colors(1, :), 'LineWidth', 1.0, 'HandleVisibility', 'off');
end
scatter3(ax, sat_positions(:, 1), sat_positions(:, 2), sat_positions(:, 3), ...
    16, style.colors(1, :), 'filled', 'DisplayName', 'Walker 卫星');

if ~isempty(scenario_cases.nominal)
    traj3 = scenario_cases.nominal.traj.r_ecef_km;
    plot3(ax, traj3(:, 1), traj3(:, 2), traj3(:, 3), '--', 'Color', style.colors(4, :), ...
        'LineWidth', 2.0, 'DisplayName', '代表性目标路径');
end

text(ax, geom.center_ecef_km(1), geom.center_ecef_km(2), geom.center_ecef_km(3), ...
    ' 防区中心', 'Interpreter', 'tex', 'FontSize', style.annotation_font_size);

xlabel(ax, 'ECEF-x (km)', 'Interpreter', 'tex');
ylabel(ax, 'ECEF-y (km)', 'Interpreter', 'tex');
zlabel(ax, 'ECEF-z (km)', 'Interpreter', 'tex');
title(ax, '共享场景 SS2: Earth / Walker / 防区空间关系示意', 'Interpreter', 'tex', 'FontSize', style.title_font_size);
legend(ax, 'Location', 'northeastoutside');
axis(ax, 'equal');
view(ax, 36, 24);

annotation(fig, 'textbox', [0.63, 0.80, 0.26, 0.11], ...
    'String', { ...
        sprintf('Walker 参数: h = %.0f km, i = %.0f^\\circ, P = %d, T = %d', ...
            geom.walker.h_km, geom.walker.i_deg, geom.walker.P, geom.walker.T), ...
        '防区以地球表面圆形足迹示意', ...
        '目标路径采用真实基线案例的 ECEF 轨迹'}, ...
    'Interpreter', 'tex', ...
    'FitBoxToText', 'on', ...
    'BackgroundColor', 'w', ...
    'EdgeColor', 0.8 * [1, 1, 1], ...
    'FontSize', style.annotation_font_size);

apply_dissertation_plot_style(fig, style);
end
