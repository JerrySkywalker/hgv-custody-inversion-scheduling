function result = milestone_B_inverse_slices(cfg)
%MILESTONE_B_INVERSE_SLICES Chapter 4 Milestone B inverse-slice wrapper.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end

meta = cfg.milestones.MB;
paths = milestone_common_output_paths(cfg, meta.milestone_id, meta.title);
style = milestone_common_plot_style();

result = struct();
result.milestone_id = meta.milestone_id;
result.title = meta.title;
result.config = cfg;
result.purpose = 'Truth-based parameter slicing and minimum configuration extraction.';
result.reused_modules = meta.reuse_stages;
result.tables = struct();
result.figures = struct();
result.artifacts = struct();

summary = struct( ...
    'slice_axes', {meta.slice_axes}, ...
    'num_grid_points', 0, ...
    'num_feasible_points', 0, ...
    'minimum_design', struct(), ...
    'near_optimal_region_size', 0, ...
    'dominant_constraint_distribution', struct(), ...
    'key_counts', struct('num_tables', 0, 'num_figures', 0), ...
    'success_flags', struct('stage09_build_feasible_domain', false, 'stage09_extract_minimum_boundary', false), ...
    'main_conclusion', "Milestone B scaffold executed.");

slice_cfg = meta.slice_settings;
feasible_table = table();
boundary_table = table();
slice_table = local_make_placeholder_slice_table(slice_cfg);

try
    cfg_stage = cfg;
    cfg_stage.stage09.run_tag = 'milestoneB';
    cfg_stage.stage09.search_domain.h_grid_km = slice_cfg.h_km;
    cfg_stage.stage09.search_domain.i_grid_deg = slice_cfg.i_deg;
    cfg_stage.stage09.search_domain.P_grid = slice_cfg.P;
    cfg_stage.stage09.search_domain.T_grid = slice_cfg.T;
    cfg_stage.stage09.scan_case_limit = 12;
    cfg_stage.stage09.write_csv = false;

    out_scan = stage09_build_feasible_domain(cfg_stage);
    out_boundary = stage09_extract_minimum_boundary(out_scan, cfg_stage);

    feasible_table = out_scan.feasible_theta_table;
    boundary_table = out_boundary.boundary_table;
    slice_table = local_build_slice_sensitivity_table(out_scan.full_theta_table, feasible_table);

    summary.num_grid_points = height(out_scan.full_theta_table);
    summary.num_feasible_points = height(feasible_table);
    summary.minimum_design = local_pick_minimum_design(out_boundary);
    summary.near_optimal_region_size = height(out_boundary.theta_min_table_sorted);
    summary.dominant_constraint_distribution = local_fail_distribution(out_scan.fail_partition_table);
    summary.success_flags.stage09_build_feasible_domain = true;
    summary.success_flags.stage09_extract_minimum_boundary = true;
    summary.main_conclusion = local_make_mb_conclusion(summary);

    result.artifacts.stage09_feasible_domain_cache = string(out_scan.files.cache_file);
    result.artifacts.stage09_minimum_boundary_cache = string(out_boundary.files.cache_file);
catch ME
    result.artifacts.stage09_inverse_slice_error = string(ME.message);
    summary.main_conclusion = "Milestone B completed with placeholder slice summaries because stage09 scan reuse was unavailable.";
end

feasible_csv = fullfile(paths.tables, 'MB_inverse_slices_feasible_domain_map.csv');
boundary_csv = fullfile(paths.tables, 'MB_inverse_slices_minimum_boundary_map.csv');
slice_csv = fullfile(paths.tables, 'MB_inverse_slices_slice_sensitivity.csv');
milestone_common_save_table(feasible_table, feasible_csv);
milestone_common_save_table(boundary_table, boundary_csv);
milestone_common_save_table(slice_table, slice_csv);
result.tables.feasible_domain_map = string(feasible_csv);
result.tables.minimum_boundary_map = string(boundary_csv);
result.tables.slice_sensitivity = string(slice_csv);

fig1 = figure('Visible', 'off', 'Color', 'w');
ax1 = axes(fig1);
local_plot_feasible_map(ax1, feasible_table, style);
fig1_path = fullfile(paths.figures, 'MB_inverse_slices_feasible_domain_map.png');
milestone_common_save_figure(fig1, fig1_path);
close(fig1);
result.figures.feasible_domain_map = string(fig1_path);

fig2 = figure('Visible', 'off', 'Color', 'w');
ax2 = axes(fig2);
local_plot_boundary_map(ax2, boundary_table, style);
fig2_path = fullfile(paths.figures, 'MB_inverse_slices_minimum_boundary_map.png');
milestone_common_save_figure(fig2, fig2_path);
close(fig2);
result.figures.minimum_boundary_map = string(fig2_path);

summary.key_counts.num_tables = numel(fieldnames(result.tables));
summary.key_counts.num_figures = numel(fieldnames(result.figures));
result.summary = summary;

files = milestone_common_export_summary(result, paths);
result.artifacts.summary_report = files.report_md;
result.artifacts.summary_mat = files.summary_mat;
end

function T = local_make_placeholder_slice_table(slice_cfg)
T = table( ...
    ["h"; "i"; "P"; "T"], ...
    [numel(slice_cfg.h_km); numel(slice_cfg.i_deg); numel(slice_cfg.P); numel(slice_cfg.T)], ...
    zeros(4, 1), ...
    'VariableNames', {'slice_axis', 'num_levels', 'feasible_levels'});
end

function T = local_build_slice_sensitivity_table(full_table, feasible_table)
axes = {'h_km', 'i_deg', 'P', 'T'};
num_levels = zeros(numel(axes), 1);
feasible_levels = zeros(numel(axes), 1);
for k = 1:numel(axes)
    axis_name = axes{k};
    num_levels(k) = numel(unique(full_table.(axis_name)));
    if isempty(feasible_table)
        feasible_levels(k) = 0;
    else
        feasible_levels(k) = numel(unique(feasible_table.(axis_name)));
    end
end
T = table(string({'h', 'i', 'P', 'T'}).', num_levels, feasible_levels, ...
    'VariableNames', {'slice_axis', 'num_levels', 'feasible_levels'});
end

function minimum_design = local_pick_minimum_design(out_boundary)
minimum_design = struct();
if isfield(out_boundary, 'theta_min_table_sorted') && ~isempty(out_boundary.theta_min_table_sorted)
    row = out_boundary.theta_min_table_sorted(1, :);
    minimum_design = table2struct(row);
end
end

function distribution = local_fail_distribution(fail_partition_table)
distribution = struct();
if isempty(fail_partition_table)
    distribution.none = 0;
    return;
end
for k = 1:height(fail_partition_table)
    key = matlab.lang.makeValidName(char(string(fail_partition_table{k, 1})));
    distribution.(key) = fail_partition_table{k, 2};
end
end

function txt = local_make_mb_conclusion(summary)
txt = sprintf('Feasible points=%d/%d; near-optimal region size=%d.', ...
    summary.num_feasible_points, summary.num_grid_points, summary.near_optimal_region_size);
end

function local_plot_feasible_map(ax, feasible_table, style)
if isempty(feasible_table) || ~all(ismember({'Ns', 'i_deg'}, feasible_table.Properties.VariableNames))
    plot(ax, 0, 0, 'o', 'Color', style.colors(1, :), 'MarkerFaceColor', style.colors(1, :));
    title(ax, 'Milestone B Feasible-Domain Map (placeholder)');
    xlabel(ax, 'Ns');
    ylabel(ax, 'i (deg)');
    grid(ax, 'on');
    return;
end

scatter(ax, feasible_table.Ns, feasible_table.i_deg, 36, feasible_table.h_km, 'filled');
title(ax, 'Milestone B Feasible-Domain Map');
xlabel(ax, 'Ns');
ylabel(ax, 'i (deg)');
grid(ax, 'on');
end

function local_plot_boundary_map(ax, boundary_table, style)
if isempty(boundary_table) || ~all(ismember({'Ns', 'h_km_min', 'h_km_max'}, boundary_table.Properties.VariableNames))
    plot(ax, 0, 0, 's', 'Color', style.colors(2, :), 'MarkerFaceColor', style.colors(2, :));
    title(ax, 'Milestone B Minimum-Boundary Map (placeholder)');
    xlabel(ax, 'Ns');
    ylabel(ax, 'h (km)');
    grid(ax, 'on');
    return;
end

plot(ax, boundary_table.Ns, boundary_table.h_km_min, '-o', 'LineWidth', style.line_width, 'Color', style.colors(2, :));
hold(ax, 'on');
plot(ax, boundary_table.Ns, boundary_table.h_km_max, '--s', 'LineWidth', style.line_width, 'Color', style.colors(3, :));
hold(ax, 'off');
title(ax, 'Milestone B Minimum-Boundary Map');
xlabel(ax, 'Ns');
ylabel(ax, 'h (km)');
legend(ax, {'h min', 'h max'}, 'Location', 'best');
grid(ax, 'on');
end
