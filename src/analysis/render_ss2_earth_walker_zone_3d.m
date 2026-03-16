function fig = render_ss2_earth_walker_zone_3d(geom, cfg, style)
%RENDER_SS2_EARTH_WALKER_ZONE_3D Render dissertation-style SS2 figure.

if nargin < 3 || isempty(style)
    style = milestone_common_plot_style();
end
cfg = shared_scenario_common_defaults(cfg);

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [120, 80, 1180, 840]);
ax = axes(fig);
hold(ax, 'on');

[xs, ys, zs] = sphere(96);
earth_radius_km = geom.earth_radius_km;
surf(ax, earth_radius_km * xs, earth_radius_km * ys, earth_radius_km * zs, ...
    'FaceColor', [0.88, 0.92, 0.96], 'EdgeColor', 'none', 'FaceAlpha', 1.0, 'AmbientStrength', 0.55, 'SpecularStrength', 0.08);
lighting(ax, 'gouraud');
camlight(ax, 'headlight');

plot3(ax, geom.zone.ring_ecef_km(:, 1), geom.zone.ring_ecef_km(:, 2), geom.zone.ring_ecef_km(:, 3), ...
    '-', 'Color', style.colors(2, :), 'LineWidth', 2.6, 'DisplayName', '防区边界');
scatter3(ax, geom.zone.center_ecef_km(1), geom.zone.center_ecef_km(2), geom.zone.center_ecef_km(3), ...
    80, style.colors(2, :), 'filled', 'DisplayName', '防区中心');

for k = 1:numel(geom.tracks.plane_tracks)
    plane_track = geom.tracks.plane_tracks(k);
    label = sprintf('代表轨道面 %d', plane_track.plane_id);
    plot3(ax, plane_track.track_ecef_km(:, 1), plane_track.track_ecef_km(:, 2), plane_track.track_ecef_km(:, 3), ...
        '-', 'Color', style.colors(1, :), 'LineWidth', 1.6, 'DisplayName', label);

    markers = plane_track.marker_ecef_km;
    scatter3(ax, markers(:, 1), markers(:, 2), markers(:, 3), ...
        18, style.colors(1, :), 'filled', ...
        'HandleVisibility', local_visibility_label(k == 1), ...
        'DisplayName', '代表卫星');
end

if cfg.shared_scenarios.render.show_target_trajectory && ~isempty(geom.target_ecef_km)
    target_km = local_decimate_track(geom.target_ecef_km, 140);
    plot3(ax, target_km(:, 1), target_km(:, 2), target_km(:, 3), ...
        '--', 'Color', style.colors(4, :), 'LineWidth', 2.0, 'DisplayName', '代表目标轨迹');
end

text(ax, geom.zone.center_ecef_km(1), geom.zone.center_ecef_km(2), geom.zone.center_ecef_km(3), ...
    ' 防区中心', 'Interpreter', 'tex', 'FontSize', style.annotation_font_size);

xlabel(ax, 'ECEF-x (km)', 'Interpreter', 'tex');
ylabel(ax, 'ECEF-y (km)', 'Interpreter', 'tex');
zlabel(ax, 'ECEF-z (km)', 'Interpreter', 'tex');
title(ax, '共享场景 SS2: Earth / Walker / 防区空间关系', 'Interpreter', 'tex', 'FontSize', style.title_font_size);
legend(ax, 'Location', 'northeastoutside', 'Interpreter', 'tex');
axis(ax, 'equal');
view(ax, 34, 22);

apply_dissertation_plot_style(fig, style);
end

function value = local_visibility_label(flag)
if flag
    value = 'on';
else
    value = 'off';
end
end

function track = local_decimate_track(track, max_points)
if size(track, 1) <= max_points
    return;
end
idx = round(linspace(1, size(track, 1), max_points));
track = track(idx, :);
end
