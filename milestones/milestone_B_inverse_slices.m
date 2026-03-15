function result = milestone_B_inverse_slices(cfg)
%MILESTONE_B_INVERSE_SLICES Dissertation-grade Chapter 4 Milestone B pipeline.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end

meta = cfg.milestones.MB;
paths = milestone_common_output_paths(cfg, meta.milestone_id, meta.title);
style = milestone_common_plot_style();

slice_hi = stage12C_inverse_slice_packager(cfg, 'hi', meta);
slice_pt = stage12C_inverse_slice_packager(cfg, 'PT', meta);
task_nominal = stage12D_task_slice_packager(cfg, 'nominal', meta);
task_heading = stage12D_task_slice_packager(cfg, 'heading', meta);
task_critical = stage12D_task_slice_packager(cfg, 'critical', meta);
minimum_pack = stage12E_minimum_design_packager( ...
    {slice_hi, slice_pt, task_nominal, task_heading, task_critical}, cfg, meta);

slice_summary_table = build_milestone_B_slice_summary({slice_hi, slice_pt});
task_summary_table = table( ...
    ["nominal"; "heading"; "critical"], ...
    [task_nominal.summary.num_grid_points; task_heading.summary.num_grid_points; task_critical.summary.num_grid_points], ...
    [task_nominal.summary.num_feasible_points; task_heading.summary.num_feasible_points; task_critical.summary.num_feasible_points], ...
    [task_nominal.summary.feasible_ratio; task_heading.summary.feasible_ratio; task_critical.summary.feasible_ratio], ...
    'VariableNames', {'task_slice_id', 'num_grid_points', 'num_feasible_points', 'feasible_ratio'});

feasible_domain_table = minimum_pack.full_theta_table;
minimum_design_table = minimum_pack.minimum_design_table;
near_optimal_table = minimum_pack.near_optimal_table;

slice_summary_csv = fullfile(paths.tables, 'MB_inverse_slices_slice_grid_summary.csv');
feasible_csv = fullfile(paths.tables, 'MB_inverse_slices_feasible_domain_table.csv');
minimum_csv = fullfile(paths.tables, 'MB_inverse_slices_minimum_design_table.csv');
near_optimal_csv = fullfile(paths.tables, 'MB_inverse_slices_near_optimal_design_table.csv');
task_summary_csv = fullfile(paths.tables, 'MB_inverse_slices_task_slice_summary.csv');
milestone_common_save_table(slice_summary_table, slice_summary_csv);
milestone_common_save_table(feasible_domain_table, feasible_csv);
milestone_common_save_table(minimum_design_table, minimum_csv);
milestone_common_save_table(near_optimal_table, near_optimal_csv);
milestone_common_save_table(task_summary_table, task_summary_csv);

fig1 = local_plot_feasible_domain(slice_hi.feasible_theta_table, slice_pt.feasible_theta_table, style);
fig1_path = fullfile(paths.figures, 'MB_inverse_slices_feasible_domain_map.png');
milestone_common_save_figure(fig1, fig1_path);
close(fig1);

fig2 = local_plot_minimum_boundary(minimum_pack.boundary_table, minimum_design_table, style);
fig2_path = fullfile(paths.figures, 'MB_inverse_slices_minimum_boundary_map.png');
milestone_common_save_figure(fig2, fig2_path);
close(fig2);

fig3 = plot_milestone_B_task_slice_compare(task_summary_table, style);
fig3_path = fullfile(paths.figures, 'MB_inverse_slices_task_family_slice_comparison.png');
milestone_common_save_figure(fig3, fig3_path);
close(fig3);

result = struct();
result.milestone_id = meta.milestone_id;
result.title = meta.title;
result.config = cfg;
result.purpose = 'Truth-based parameter slicing, task-side comparison, and minimum configuration extraction.';
result.reused_modules = {'Constellation slice packager', 'Task-side slice packager', 'Minimum-design extractor'};
result.tables = struct();
result.figures = struct();
result.artifacts = struct();
result.tables.slice_grid_summary = string(slice_summary_csv);
result.tables.feasible_domain_table = string(feasible_csv);
result.tables.minimum_design_table = string(minimum_csv);
result.tables.near_optimal_design_table = string(near_optimal_csv);
result.tables.task_slice_summary = string(task_summary_csv);
result.figures.feasible_domain_map = string(fig1_path);
result.figures.minimum_boundary_map = string(fig2_path);
result.figures.task_family_slice_comparison = string(fig3_path);

result.summary = struct( ...
    'slice_axes', {{'h-i', 'P-T'}}, ...
    'num_grid_points', height(minimum_pack.full_theta_table), ...
    'num_feasible_points', height(minimum_pack.feasible_theta_table), ...
    'minimum_design', minimum_pack.minimum_design, ...
    'near_optimal_region_size', height(near_optimal_table), ...
    'dominant_constraint_distribution', minimum_pack.dominant_constraint_distribution, ...
    'key_counts', struct('num_tables', numel(fieldnames(result.tables)), 'num_figures', numel(fieldnames(result.figures))), ...
    'success_flags', struct('constellation_slice_packager', true, 'task_slice_packager', true, 'minimum_design_extractor', true), ...
    'main_conclusion', local_make_conclusion(minimum_pack, task_summary_table));

files = milestone_common_export_summary(result, paths);
result.artifacts.summary_report = files.report_md;
result.artifacts.summary_mat = files.summary_mat;
end

function fig = local_plot_feasible_domain(T_hi, T_pt, style)
fig = figure('Visible', 'off', 'Color', 'w');
tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

ax1 = nexttile;
if isempty(T_hi)
    plot(ax1, 0, 0, 'o', 'Color', style.colors(1, :));
else
    scatter(ax1, T_hi.i_deg, T_hi.h_km, 36, T_hi.Ns, 'filled');
end
xlabel(ax1, 'i (deg)');
ylabel(ax1, 'h (km)');
title(ax1, 'Milestone B h-i feasible slice');
grid(ax1, 'on');

ax2 = nexttile;
if isempty(T_pt)
    plot(ax2, 0, 0, 's', 'Color', style.colors(2, :));
else
    scatter(ax2, T_pt.P, T_pt.T, 48, T_pt.Ns, 'filled');
end
xlabel(ax2, 'P');
ylabel(ax2, 'T');
title(ax2, 'Milestone B P-T feasible slice');
grid(ax2, 'on');
end

function fig = local_plot_minimum_boundary(boundary_table, minimum_design_table, style)
fig = figure('Visible', 'off', 'Color', 'w');
ax = axes(fig);
if isempty(minimum_design_table)
    plot(ax, 0, 0, 'o', 'Color', style.colors(3, :));
else
    scatter(ax, minimum_design_table.i_deg, minimum_design_table.h_km, 60, minimum_design_table.Ns, 'filled');
end
hold(ax, 'on');
if ~isempty(boundary_table) && ismember('N_min_rob', boundary_table.Properties.VariableNames)
    y_center = local_mean_omitnan([boundary_table.h_min_km(1), boundary_table.h_max_km(1)]);
    if ~isnan(y_center)
        yline(ax, y_center, '--', 'Boundary center', 'Color', style.threshold_color);
    end
end
hold(ax, 'off');
xlabel(ax, 'i (deg)');
ylabel(ax, 'h (km)');
title(ax, 'Milestone B Minimum Design / Boundary Map');
grid(ax, 'on');
end

function value = local_mean_omitnan(x)
x = x(~isnan(x));
if isempty(x)
    value = NaN;
else
    value = mean(x);
end
end

function txt = local_make_conclusion(minimum_pack, task_summary_table)
task_text = sprintf('nominal=%.2f, heading=%.2f, critical=%.2f', ...
    task_summary_table.feasible_ratio(1), task_summary_table.feasible_ratio(2), task_summary_table.feasible_ratio(3));
if isempty(minimum_pack.minimum_design_table)
    txt = sprintf('No feasible minimum design was extracted; task-side feasible ratios are %s.', task_text);
else
    txt = sprintf('Minimum design extracted at N_s=%g; task-side feasible ratios are %s.', ...
        minimum_pack.minimum_design_table.Ns(1), task_text);
end
end
