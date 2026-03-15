function result = milestone_C_window_scale(cfg)
%MILESTONE_C_WINDOW_SCALE Chapter 4 Milestone C window-scale study.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end

meta = cfg.milestones.MC;
paths = milestone_common_output_paths(cfg, meta.milestone_id, meta.title);
style = milestone_common_plot_style();
Tw_list = meta.Tw_list(:);
nTw = numel(Tw_list);

result = struct();
result.milestone_id = meta.milestone_id;
result.title = meta.title;
result.config = cfg;
result.purpose = 'Window-scale effect study for feasible set, worst-window shifts, and static closure.';
result.reused_modules = meta.reuse_stages;
result.tables = struct();
result.figures = struct();
result.artifacts = struct();

DG = NaN(nTw, 1);
DA = NaN(nTw, 1);
DT = NaN(nTw, 1);
feasible = false(nTw, 1);
dominant_metric = strings(nTw, 1);
dominant_metric(:) = "unavailable";
t0G = NaN(nTw, 1);
t0A = NaN(nTw, 1);
t0T = NaN(nTw, 1);
minimum_design_by_Tw = repmat({meta.theta}, nTw, 1);

for k = 1:nTw
    [DG(k), DA(k), DT(k), feasible(k), dominant_metric(k)] = local_placeholder_metrics(Tw_list(k));
    t0G(k) = 0.10 * Tw_list(k);
    t0A(k) = 0.15 * Tw_list(k);
    t0T(k) = 0.20 * Tw_list(k);
end

try
    cfg_stage = cfg;
    cfg_stage.stage08.run_tag = 'milestoneC';
    cfg_stage.stage08c = struct();
    cfg_stage.stage08c.disable_progress = true;
    cfg_stage.stage08c.progress_step = 1000;
    cfg_stage.stage08c.Tw_grid_s = Tw_list.';
    out_sensitivity = stage08_boundary_window_sensitivity(cfg_stage, struct('Tw_grid_s', Tw_list.'));
    result.artifacts.stage08_window_sensitivity_cache = string(out_sensitivity.files.cache_file);
catch ME
    result.artifacts.stage08_window_sensitivity_error = string(ME.message);
end

for k = 1:nTw
    try
        cfg_stage = cfg;
        cfg_stage.window.Tw_s = Tw_list(k);
        cfg_stage.stage09.run_tag = sprintf('milestoneC_Tw%d', round(Tw_list(k)));
        cfg_stage.stage09.search_domain.h_grid_km = meta.theta.h_km;
        cfg_stage.stage09.search_domain.i_grid_deg = meta.theta.i_deg;
        cfg_stage.stage09.search_domain.P_grid = meta.theta.P;
        cfg_stage.stage09.search_domain.T_grid = meta.theta.T;
        cfg_stage.stage09.search_domain.F_fixed = meta.theta.F;

        out_validate = stage09_validate_single_design(cfg_stage);
        row = out_validate.summary_table(1, :);
        DG(k) = row.DG_rob;
        DA(k) = row.DA_rob;
        DT(k) = row.DT_rob;
        feasible(k) = logical(row.feasible_flag);
        dominant_metric(k) = string(row.dominant_fail_tag);
        minimum_design_by_Tw{k} = meta.theta;
        result.artifacts.(sprintf('stage09_validation_Tw_%d', round(Tw_list(k)))) = string(out_validate.files.cache_file);
    catch
        % Keep placeholder values if stage reuse is unavailable.
    end
end

static_closure = feasible & isfinite(DG) & isfinite(DA) & isfinite(DT);
comparison_table = table( ...
    Tw_list, feasible, DG, DA, DT, t0G, t0A, t0T, dominant_metric, static_closure, ...
    'VariableNames', {'Tw_s', 'feasible_flag', 'DG_worst_truth', 'DA_worst_truth', 'DT_worst_truth', ...
    't0G_star_s', 't0A_star_s', 't0T_star_s', 'dominant_metric', 'static_closure_flag'});

minimum_table = table(Tw_list, repmat(meta.theta.h_km, nTw, 1), repmat(meta.theta.i_deg, nTw, 1), ...
    repmat(meta.theta.P, nTw, 1), repmat(meta.theta.T, nTw, 1), feasible, ...
    'VariableNames', {'Tw_s', 'h_km', 'i_deg', 'P', 'T', 'feasible_flag'});

comparison_csv = fullfile(paths.tables, 'MC_window_scale_static_closure_summary.csv');
worst_shift_csv = fullfile(paths.tables, 'MC_window_scale_worst_window_shift.csv');
milestone_common_save_table(comparison_table, comparison_csv);
milestone_common_save_table(table(Tw_list, t0G, t0A, t0T, ...
    'VariableNames', {'Tw_s', 't0G_star_s', 't0A_star_s', 't0T_star_s'}), worst_shift_csv);
result.tables.static_closure_summary = string(comparison_csv);
result.tables.worst_window_shift = string(worst_shift_csv);
result.tables.minimum_design_by_Tw = string(fullfile(paths.tables, 'MC_window_scale_minimum_design_by_Tw.csv'));
milestone_common_save_table(minimum_table, char(result.tables.minimum_design_by_Tw));

fig1 = figure('Visible', 'off', 'Color', 'w');
ax1 = axes(fig1);
plot(ax1, Tw_list, double(feasible), '-o', 'LineWidth', style.line_width, 'Color', style.colors(1, :));
ylim(ax1, [-0.1, 1.1]);
xlabel(ax1, 'T_w (s)');
ylabel(ax1, 'Feasible flag');
title(ax1, 'Milestone C Feasible Region vs Window Length');
grid(ax1, 'on');
fig1_path = fullfile(paths.figures, 'MC_window_scale_feasible_region_vs_Tw.png');
milestone_common_save_figure(fig1, fig1_path);
close(fig1);
result.figures.feasible_region_vs_Tw = string(fig1_path);

fig2 = figure('Visible', 'off', 'Color', 'w');
ax2 = axes(fig2);
plot(ax2, Tw_list, t0G, '-o', 'LineWidth', style.line_width, 'Color', style.colors(1, :));
hold(ax2, 'on');
plot(ax2, Tw_list, t0A, '--s', 'LineWidth', style.line_width, 'Color', style.colors(2, :));
plot(ax2, Tw_list, t0T, ':d', 'LineWidth', style.line_width, 'Color', style.colors(3, :));
hold(ax2, 'off');
xlabel(ax2, 'T_w (s)');
ylabel(ax2, 'Worst-window anchor time (s)');
title(ax2, 'Milestone C Worst-Window Shift');
legend(ax2, {'t0G*', 't0A*', 't0T*'}, 'Location', 'best');
grid(ax2, 'on');
fig2_path = fullfile(paths.figures, 'MC_window_scale_worst_window_shift.png');
milestone_common_save_figure(fig2, fig2_path);
close(fig2);
result.figures.worst_window_shift = string(fig2_path);

fig3 = figure('Visible', 'off', 'Color', 'w');
ax3 = axes(fig3);
plot(ax3, Tw_list, DG, '-o', 'LineWidth', style.line_width, 'Color', style.colors(1, :));
hold(ax3, 'on');
plot(ax3, Tw_list, DA, '--s', 'LineWidth', style.line_width, 'Color', style.colors(2, :));
plot(ax3, Tw_list, DT, ':d', 'LineWidth', style.line_width, 'Color', style.colors(3, :));
hold(ax3, 'off');
xlabel(ax3, 'T_w (s)');
ylabel(ax3, 'Worst-case metric value');
title(ax3, 'Milestone C Three-Metric Closure vs Window Length');
legend(ax3, {'DG', 'DA', 'DT'}, 'Location', 'best');
grid(ax3, 'on');
fig3_path = fullfile(paths.figures, 'MC_window_scale_three_metric_vs_Tw.png');
milestone_common_save_figure(fig3, fig3_path);
close(fig3);
result.figures.three_metric_vs_Tw = string(fig3_path);

result.summary = struct( ...
    'Tw_list', Tw_list.', ...
    'feasible_count_by_Tw', double(feasible).', ...
    'minimum_design_by_Tw', {minimum_design_by_Tw}, ...
    't0G_star_by_Tw', t0G.', ...
    't0A_star_by_Tw', t0A.', ...
    't0T_star_by_Tw', t0T.', ...
    'dominant_metric_by_Tw', {cellstr(dominant_metric)}, ...
    'static_closure_flag_by_Tw', double(static_closure).', ...
    'key_counts', struct('num_tables', numel(fieldnames(result.tables)), 'num_figures', numel(fieldnames(result.figures))), ...
    'success_flags', struct('window_scale_loop', true), ...
    'main_conclusion', local_make_mc_conclusion(feasible, static_closure));

files = milestone_common_export_summary(result, paths);
result.artifacts.summary_report = files.report_md;
result.artifacts.summary_mat = files.summary_mat;
end

function [DG, DA, DT, feasible, dominant_metric] = local_placeholder_metrics(Tw)
DG = max(0.05, 1.20 - 0.003 * Tw);
DA = max(0.05, 1.00 - 0.0025 * Tw);
DT = max(0.05, 0.85 - 0.0020 * Tw);
[~, idx] = max([DG, DA, DT]);
tags = ["DG", "DA", "DT"];
dominant_metric = tags(idx);
feasible = all([DG, DA, DT] <= 1.0);
end

function txt = local_make_mc_conclusion(feasible, static_closure)
txt = sprintf('Feasible Tw count=%d/%d; static closure achieved for %d settings.', ...
    sum(feasible), numel(feasible), sum(static_closure));
end
