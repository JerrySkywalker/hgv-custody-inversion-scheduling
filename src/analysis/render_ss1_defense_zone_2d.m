function fig = render_ss1_defense_zone_2d(stage_context, cfg, style)
%RENDER_SS1_DEFENSE_ZONE_2D Render SS1 from Stage01/02-style context.

if nargin < 3 || isempty(style)
    style = milestone_common_plot_style();
end
cfg = shared_scenario_common_defaults(cfg);

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [120, 110, 980, 760]);
tl = tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

ax1 = nexttile(tl);
hold(ax1, 'on');

R_D = cfg.shared_scenarios.zone.radius_km;
R_in = cfg.stage01.R_in_km;
th = linspace(0, 2 * pi, 360);
plot(ax1, R_D * cos(th), R_D * sin(th), 'LineWidth', 2.0, 'Color', style.colors(1, :), 'DisplayName', '防区边界');
plot(ax1, R_in * cos(th), R_in * sin(th), '--', 'LineWidth', 1.2, 'Color', style.threshold_color, 'DisplayName', '进入边界');
scatter(ax1, 0, 0, 44, style.colors(1, :), 'filled', 'DisplayName', '防区中心');

local_plot_stage01_casebank(ax1, stage_context.casebank, style);
text(ax1, 90, 120, '防区中心', 'Interpreter', 'tex', 'FontSize', style.annotation_font_size);
xlabel(ax1, '局部东向坐标 (km)', 'Interpreter', 'tex');
ylabel(ax1, '局部北向坐标 (km)', 'Interpreter', 'tex');
title(ax1, 'Stage01 场景定义', 'Interpreter', 'tex');
axis(ax1, 'equal');
grid(ax1, 'on');

ax2 = nexttile(tl);
hold(ax2, 'on');

radius_km = cfg.shared_scenarios.zone.radius_km;
fill(ax2, radius_km * cos(th), radius_km * sin(th), [0.89, 0.95, 0.98], ...
    'EdgeColor', style.colors(1, :), 'LineWidth', 1.8, 'FaceAlpha', 0.85, 'HandleVisibility', 'off');
scatter(ax2, 0, 0, 48, style.colors(1, :), 'filled', 'DisplayName', '防区中心');

local_plot_family(ax2, stage_context.scenario_cases.nominal, stage_context.zone, style.colors(1, :), '-', '标称来袭');
local_plot_family(ax2, stage_context.scenario_cases.heading, stage_context.zone, style.colors(2, :), '--', '航向偏置来袭');
local_plot_family(ax2, stage_context.scenario_cases.critical, stage_context.zone, style.colors(4, :), '-.', '临界擦边来袭');

text(ax2, 90, 120, '防区中心', 'Interpreter', 'tex', 'FontSize', style.annotation_font_size);
text(ax2, 0.60 * radius_km, -0.08 * radius_km, 'R_d', 'Interpreter', 'tex', 'FontSize', style.annotation_font_size);
quiver(ax2, 0, 0, 0.78 * radius_km, 0, 0, 'Color', style.threshold_color, 'LineWidth', 1.2, 'MaxHeadSize', 0.42, 'HandleVisibility', 'off');

xlabel(ax2, '局部东向坐标 (km)', 'Interpreter', 'tex');
ylabel(ax2, '局部北向坐标 (km)', 'Interpreter', 'tex');
title(ax2, 'Stage02 代表性 HGV 相对轨迹', 'Interpreter', 'tex');
legend(ax2, 'Location', 'northeast', 'Interpreter', 'tex');
axis(ax2, 'equal');
lim = max(3200, radius_km * 3.2);
xlim(ax1, [-lim, lim]);
ylim(ax1, [-lim, lim]);
xlim(ax2, [-lim, lim]);
ylim(ax2, [-lim, lim]);
grid(ax2, 'on');

title(tl, '共享场景 SS1: 防区与 HGV 相对关系说明', 'Interpreter', 'tex', 'FontSize', style.title_font_size);

apply_dissertation_plot_style(fig, style);
end

function local_plot_stage01_casebank(ax, casebank, style)
for k = 1:numel(casebank.nominal)
    c = casebank.nominal(k);
    p = c.entry_point_enu_km(:).';
    scatter(ax, p(1), p(2), 18, style.colors(1, :), 'filled', 'HandleVisibility', 'off');
end

if ~isempty(casebank.heading)
    ids = string({casebank.heading.case_id});
    idx = startsWith(ids, "H01_");
    H = casebank.heading(idx);
    if isempty(H)
        H = casebank.heading(1:min(5, numel(casebank.heading)));
    end
    p = H(1).entry_point_enu_km(:).';
    for i = 1:numel(H)
        u = H(i).heading_unit_enu(:).';
        quiver(ax, p(1), p(2), 900 * u(1), 900 * u(2), 0, ...
            'Color', style.colors(2, :), 'LineWidth', 1.0, 'MaxHeadSize', 0.45, 'HandleVisibility', local_vis(i == 1), ...
            'DisplayName', '航向偏置方向族');
    end
end

for k = 1:numel(casebank.critical)
    c = casebank.critical(k);
    p = c.entry_point_enu_km(:).';
    u = c.heading_unit_enu(:).';
    quiver(ax, p(1), p(2), 1200 * u(1), 1200 * u(2), 0, ...
        'Color', style.colors(4, :), 'LineWidth', 1.4, 'MaxHeadSize', 0.48, 'HandleVisibility', local_vis(k == 1), ...
        'DisplayName', '临界入射方向');
end
end

function value = local_vis(flag)
if flag
    value = 'on';
else
    value = 'off';
end
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
