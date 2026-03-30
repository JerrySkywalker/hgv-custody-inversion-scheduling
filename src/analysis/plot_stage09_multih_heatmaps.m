function pack = plot_stage09_multih_heatmaps(base, mode_tag)
%PLOT_STAGE09_MULTIH_HEATMAPS
% Phase4-A:
% Plot multi-height heatmaps from precomputed Stage09 cubes.
% Works even when only one height slice is available.

    if nargin < 2 || isempty(mode_tag)
        mode_tag = 'phase4_multih';
    end
    if isstring(mode_tag)
        mode_tag = char(mode_tag);
    end

    if ~isstruct(base) || ~isfield(base, 'cubes')
        error('plot_stage09_multih_heatmaps:InvalidBase', ...
            'Input base must contain precomputed cubes from Phase1-B.');
    end

    cfg = local_pick_cfg(base);
    run_tag = local_get_run_tag(cfg);
    time_tag = datestr(now, 'yyyymmdd_HHMMSS');

    fig_dir = fullfile(cfg.paths.figs, 'multih_heatmaps');
    tab_dir = fullfile(cfg.paths.tables, 'multih_heatmaps');
    if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
    if ~exist(tab_dir, 'dir'); mkdir(tab_dir); end

    cube_metric = base.cubes.cube_metric;
    cube_closure = base.cubes.cube_closure;
    h_vals = base.cubes.h_values_km(:)';
    i_vals = base.cubes.i_values_deg(:)';
    P_vals = base.cubes.P_values(:)';

    fig_DG_minNs = local_plot_metric_multih( ...
        squeeze(cube_metric(1,:,:,:)), h_vals, i_vals, P_vals, ...
        'DG minimum feasible N_s over (i,P)', 'DG minimum feasible N_s', ...
        fullfile(fig_dir, sprintf('stage09_multih_DG_minNs_%s_%s_%s.png', run_tag, mode_tag, time_tag)));

    fig_DA_best = local_plot_metric_multih( ...
        squeeze(cube_metric(2,:,:,:)), h_vals, i_vals, P_vals, ...
        'DA best feasible metric over (i,P)', 'DA best feasible metric', ...
        fullfile(fig_dir, sprintf('stage09_multih_DA_bestMetric_%s_%s_%s.png', run_tag, mode_tag, time_tag)));

    fig_DT_best = local_plot_metric_multih( ...
        squeeze(cube_metric(3,:,:,:)), h_vals, i_vals, P_vals, ...
        'DT best feasible metric over (i,P)', 'DT best feasible metric', ...
        fullfile(fig_dir, sprintf('stage09_multih_DT_bestMetric_%s_%s_%s.png', run_tag, mode_tag, time_tag)));

    fig_joint = local_plot_metric_multih( ...
        squeeze(cube_closure(1,:,:,:)), h_vals, i_vals, P_vals, ...
        'Joint feasible over (i,P)', 'Joint feasible', ...
        fullfile(fig_dir, sprintf('stage09_multih_joint_feasible_%s_%s_%s.png', run_tag, mode_tag, time_tag)));

    figure_index = table( ...
        string(fig_DG_minNs), ...
        string(fig_DA_best), ...
        string(fig_DT_best), ...
        string(fig_joint), ...
        'VariableNames', { ...
            'fig_multih_DG_minNs', ...
            'fig_multih_DA_bestMetric', ...
            'fig_multih_DT_bestMetric', ...
            'fig_multih_joint_feasible'});

    figure_index_csv = fullfile(tab_dir, ...
        sprintf('stage09_multih_heatmaps_figure_index_%s_%s_%s.csv', run_tag, mode_tag, time_tag));
    writetable(figure_index, figure_index_csv);

    pack = struct();
    pack.figure_index = figure_index;
    pack.files = struct();
    pack.files.figure_index_csv = figure_index_csv;
    pack.files.fig_multih_DG_minNs = fig_DG_minNs;
    pack.files.fig_multih_DA_bestMetric = fig_DA_best;
    pack.files.fig_multih_DT_bestMetric = fig_DT_best;
    pack.files.fig_multih_joint_feasible = fig_joint;

    fprintf('\n');
    fprintf('================ Stage09 Multi-H Heatmaps Summary ================\n');
    fprintf('run_tag      : %s\n', run_tag);
    fprintf('mode_tag     : %s\n', mode_tag);
    fprintf('figure index : %s\n', figure_index_csv);
    fprintf('===============================================================\n\n');
end


function fig_path = local_plot_metric_multih(cube_h_i_P, h_vals, i_vals, P_vals, ttl, cbar_label, fig_path)

    if ndims(cube_h_i_P) == 2
        cube_h_i_P = reshape(cube_h_i_P, [1, size(cube_h_i_P,1), size(cube_h_i_P,2)]);
    end

    nH = size(cube_h_i_P, 1);
    nCols = ceil(sqrt(nH));
    nRows = ceil(nH / nCols);

    f = figure('Visible', 'off', 'Color', 'w', ...
        'Position', [100, 100, 420*nCols, 320*nRows]);

    vals = cube_h_i_P(isfinite(cube_h_i_P));
    if isempty(vals)
        vals = [0 1];
    end
    vmin = min(vals(:));
    vmax = max(vals(:));
    if abs(vmax - vmin) < 1e-12
        pad = max(1, 0.05 * max(abs(vmax), 1));
        vmin = vmin - pad;
        vmax = vmax + pad;
    end

    tl = tiledlayout(nRows, nCols, 'TileSpacing', 'compact', 'Padding', 'compact');

    for k = 1:nH
        nexttile;
        Z = squeeze(cube_h_i_P(k,:,:));   % i x P
        Z = Z.';                          % P x i
        valid = isfinite(Z);

        Zplot = Z;
        Zplot(~valid) = NaN;

        imagesc(i_vals, P_vals, Zplot, 'AlphaData', double(valid));
        axis xy;
        set(gca, 'Color', 'w');
        colormap(gca, parula);
        caxis([vmin, vmax]);
        colorbar;
        xlabel('Inclination i [deg]');
        ylabel('P');
        title(sprintf('h = %g km', h_vals(k)));
        xticks(i_vals);
        yticks(P_vals);
        grid on;
        box on;

        hold on;
        for pp = 1:numel(P_vals)
            for ii = 1:numel(i_vals)
                if ~valid(pp, ii)
                    plot(i_vals(ii), P_vals(pp), 'x', ...
                        'Color', [0.15 0.15 0.15], ...
                        'LineWidth', 1.0, ...
                        'MarkerSize', 8);
                end
            end
        end
        hold off;
    end

    title(tl, ttl);
    cb = colorbar;
    cb.Layout.Tile = 'east';
    cb.Label.String = cbar_label;

    exportgraphics(f, fig_path, 'Resolution', 200);
    close(f);
end


function cfg = local_pick_cfg(base)

    if isfield(base, 'cfg') && isstruct(base.cfg)
        cfg = base.cfg;
        return;
    end

    if isfield(base, 's5') && isstruct(base.s5) && isfield(base.s5, 'cfg') && isstruct(base.s5.cfg)
        cfg = base.s5.cfg;
        return;
    end

    if isfield(base, 's4') && isstruct(base.s4) && isfield(base.s4, 'cfg') && isstruct(base.s4.cfg)
        cfg = base.s4.cfg;
        return;
    end

    if isfield(base, 's1') && isstruct(base.s1) && isfield(base.s1, 'cfg') && isstruct(base.s1.cfg)
        cfg = base.s1.cfg;
        return;
    end

    error('plot_stage09_multih_heatmaps:MissingCfg', ...
        'Unable to locate cfg from Phase1-B base.');
end


function run_tag = local_get_run_tag(cfg)
    run_tag = 'stage09';
    try
        if isfield(cfg, 'stage09') && isfield(cfg.stage09, 'run_tag')
            value = cfg.stage09.run_tag;
            if isstring(value)
                run_tag = char(value);
            elseif ischar(value)
                run_tag = value;
            end
        end
    catch
    end
end
