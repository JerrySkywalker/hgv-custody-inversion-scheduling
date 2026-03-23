function figure_map = mb_vgeom_plot_bundle(scene_best_table, scene_agg_table, output_paths, cfg_vgeom)
%MB_VGEOM_PLOT_BUNDLE Export the minimal figure set for the geometry ensemble run.

if nargin < 4 || isempty(cfg_vgeom)
    cfg_vgeom = struct();
end

figure_map = struct();
if isempty(scene_agg_table)
    return;
end

semantic_values = unique(string(scene_agg_table.semantic), 'stable');
for idx_sem = 1:numel(semantic_values)
    semantic_name = semantic_values(idx_sem);
    semantic_token = char(semantic_name);

    if logical(local_getfield_or(cfg_vgeom, 'output_scene_cloud', true))
        fig = local_plot_scene_cloud(scene_best_table, semantic_name);
        file_path = fullfile(output_paths.figures, sprintf('MB_vgeom_sceneCloud_%s_h1000_baseline.png', semantic_token));
        milestone_common_save_figure(fig, file_path);
        close(fig);
        figure_map.(sprintf('%s_scene_cloud', semantic_token)) = string(file_path);
    end

    if logical(local_getfield_or(cfg_vgeom, 'output_scene_median', true))
        fig = local_plot_stat_curve(scene_agg_table, semantic_name, 'scene_best_median', 'Scene-best median');
        file_path = fullfile(output_paths.figures, sprintf('MB_vgeom_sceneMedian_%s_h1000_baseline.png', semantic_token));
        milestone_common_save_figure(fig, file_path);
        close(fig);
        figure_map.(sprintf('%s_scene_median', semantic_token)) = string(file_path);
    end

    if logical(local_getfield_or(cfg_vgeom, 'output_scene_q25', true))
        fig = local_plot_stat_curve(scene_agg_table, semantic_name, 'scene_best_q25', 'Scene-best q25');
        file_path = fullfile(output_paths.figures, sprintf('MB_vgeom_sceneQ25_%s_h1000_baseline.png', semantic_token));
        milestone_common_save_figure(fig, file_path);
        close(fig);
        figure_map.(sprintf('%s_scene_q25', semantic_token)) = string(file_path);
    end

    if logical(local_getfield_or(cfg_vgeom, 'output_scene_q25_envelope', true))
        fig = local_plot_stat_curve(scene_agg_table, semantic_name, 'scene_best_q25_envelope', 'Scene-best q25 envelope');
        file_path = fullfile(output_paths.figures, sprintf('MB_vgeom_sceneQ25Envelope_%s_h1000_baseline.png', semantic_token));
        milestone_common_save_figure(fig, file_path);
        close(fig);
        figure_map.(sprintf('%s_scene_q25_envelope', semantic_token)) = string(file_path);
    end
end
end

function fig = local_plot_scene_cloud(scene_best_table, semantic_name)
fig = figure('Visible', 'off', 'Color', 'w');
tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
inclinations = [50, 60, 70, 80];
for idx = 1:numel(inclinations)
    ax = nexttile(tl);
    mask = string(scene_best_table.semantic) == semantic_name & abs(double(scene_best_table.inclination_deg) - inclinations(idx)) < 1e-9;
    sub = scene_best_table(mask, :);
    scatter(ax, sub.Ns, sub.best_pass_ratio, 22, [0.12 0.47 0.71], 'filled', 'MarkerFaceAlpha', 0.55);
    grid(ax, 'on');
    xlabel(ax, 'N_s');
    ylabel(ax, 'Scene-best pass ratio');
    title(ax, sprintf('%s i = %d deg', char(semantic_name), inclinations(idx)), 'Interpreter', 'none');
    ylim(ax, [0, 1.05]);
end
sgtitle(fig, sprintf('MB vgeom scene cloud (%s, h = 1000 km, baseline)', char(semantic_name)), 'Interpreter', 'none');
end

function fig = local_plot_stat_curve(scene_agg_table, semantic_name, field_name, title_prefix)
fig = figure('Visible', 'off', 'Color', 'w');
tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
inclinations = [50, 60, 70, 80];
cmap = lines(numel(inclinations));
for idx = 1:numel(inclinations)
    ax = nexttile(tl);
    mask = string(scene_agg_table.semantic) == semantic_name & abs(double(scene_agg_table.inclination_deg) - inclinations(idx)) < 1e-9;
    sub = sortrows(scene_agg_table(mask, :), 'Ns');
    plot(ax, sub.Ns, sub.(field_name), '-o', 'Color', cmap(idx, :), 'LineWidth', 1.5, 'MarkerSize', 5);
    grid(ax, 'on');
    xlabel(ax, 'N_s');
    ylabel(ax, strrep(field_name, '_', '\_'));
    title(ax, sprintf('%s i = %d deg', char(semantic_name), inclinations(idx)), 'Interpreter', 'none');
    ylim(ax, [0, 1.05]);
end
sgtitle(fig, sprintf('%s (%s, h = 1000 km, baseline)', title_prefix, char(semantic_name)), 'Interpreter', 'none');
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
