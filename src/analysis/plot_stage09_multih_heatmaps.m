function out = plot_stage09_multih_heatmaps(base, mode_tag)
%PLOT_STAGE09_MULTIH_HEATMAPS
% Multi-height heatmap pack for Stage09 Phase4-A.

    if nargin < 2 || isempty(mode_tag)
        mode_tag = 'phase4_multih';
    end

    if ~isstruct(base) || ~isfield(base, 'cubes')
        error('plot_stage09_multih_heatmaps:InvalidInput', ...
            'Input base must contain field base.cubes.');
    end

    [cube_metric, cube_closure, h_vals, i_vals, P_vals, metric_names, closure_names] = ...
        local_unpack_cubes(base.cubes);

    run_tag = local_resolve_run_tag(base);
    [out_dir_fig, out_dir_tbl] = local_resolve_output_dirs(base);

    if ~exist(out_dir_fig, 'dir'); mkdir(out_dir_fig); end
    if ~exist(out_dir_tbl, 'dir'); mkdir(out_dir_tbl); end

    timestamp = local_nowstamp();

    fig_index = table();

    spec_list = { ...
        struct('name','DG_minNs',        'kind','metric_minNs', 'metric_name','DG',    'title','DG minimum feasible N_s over (i,P)', 'cbar','DG minimum feasible N_s'), ...
        struct('name','DA_bestMetric',   'kind','metric_best',  'metric_name','DA',    'title','DA best feasible metric over (i,P)',  'cbar','DA best feasible metric'), ...
        struct('name','DT_bestMetric',   'kind','metric_best',  'metric_name','DT',    'title','DT best feasible metric over (i,P)',  'cbar','DT best feasible metric'), ...
        struct('name','joint_feasible',  'kind','closure',      'layer_name','joint',  'title','Joint feasible ratio over (i,P)',     'cbar','Joint feasible ratio') ...
    };

    for k = 1:numel(spec_list)
        spec = spec_list{k};
        fig = figure('Visible','off','Color','w');

        nH = numel(h_vals);
        [nRows, nCols] = local_tile_shape(nH);
        tl = tiledlayout(fig, nRows, nCols, 'TileSpacing','compact', 'Padding','compact');

        switch spec.kind
            case 'metric_best'
                metric_idx = local_find_name(metric_names, spec.metric_name);
                cube_this = squeeze(cube_metric(metric_idx, :, :, :)); % h x i x P
                global_vals = cube_this(isfinite(cube_this));

            case 'metric_minNs'
                cube_this = local_resolve_metric_minNs_cube(base, cube_metric, metric_names, spec.metric_name);
                global_vals = cube_this(isfinite(cube_this));

            case 'closure'
                layer_idx = local_find_name(closure_names, spec.layer_name);
                cube_this = squeeze(cube_closure(layer_idx, :, :, :)); % h x i x P
                global_vals = cube_this(isfinite(cube_this));

            otherwise
                error('plot_stage09_multih_heatmaps:UnknownSpec', ...
                    'Unknown spec.kind %s', spec.kind);
        end

        if isempty(global_vals)
            clim = [0, 1];
        else
            vmin = min(global_vals);
            vmax = max(global_vals);
            if abs(vmax - vmin) < 1e-12
                epsv = max(1, abs(vmax)) * 1e-6;
                clim = [vmin - epsv, vmax + epsv];
            else
                clim = [vmin, vmax];
            end
        end

        ax_list = gobjects(1, nH);

        for ih = 1:nH
            ax = nexttile(tl);
            ax_list(ih) = ax;

            mat = squeeze(cube_this(ih, :, :)); % i x P
            mat_plot = mat.';                   % P x i
            feasible_mask = isfinite(mat_plot);

            imagesc(ax, i_vals, P_vals, mat_plot, 'AlphaData', double(feasible_mask));
            set(ax, 'YDir', 'normal');

            hold(ax, 'on');
            local_plot_infeasible_crosses(ax, feasible_mask, i_vals, P_vals);
            hold(ax, 'off');

            xlim(ax, [min(i_vals)-0.5, max(i_vals)+0.5]);
            ylim(ax, [min(P_vals)-0.5, max(P_vals)+0.5]);
            xticks(ax, i_vals);
            yticks(ax, P_vals);
            xlabel(ax, 'Inclination i [deg]');
            ylabel(ax, 'P');
            title(ax, sprintf('h = %g km', h_vals(ih)));

            colormap(ax, parula(256));
            caxis(ax, clim);
            grid(ax, 'on');
            ax.GridAlpha = 0.18;
            ax.LineWidth = 0.8;
            ax.Layer = 'top';
            ax.Box = 'on';
        end

        title(tl, spec.title, 'FontWeight','bold');

        cb = colorbar(ax_list(end), 'eastoutside');
        cb.Label.String = spec.cbar;

        fig_name = sprintf('stage09_multih_%s_%s_%s_%s.png', ...
            spec.name, run_tag, mode_tag, timestamp);
        fig_path = fullfile(out_dir_fig, fig_name);
        exportgraphics(fig, fig_path, 'Resolution', 220);
        close(fig);

        fig_index.(sprintf('fig_multih_%s', spec.name)) = string(fig_path);
    end

    fig_index.run_tag = string(run_tag);
    fig_index.mode_tag = string(mode_tag);
    fig_index.timestamp = string(timestamp);
    fig_index = movevars(fig_index, {'run_tag','mode_tag','timestamp'}, 'Before', 1);

    figure_index_csv = fullfile(out_dir_tbl, ...
        sprintf('stage09_multih_heatmaps_figure_index_%s_%s_%s.csv', ...
        run_tag, mode_tag, timestamp));
    writetable(fig_index, figure_index_csv);

    out = struct();
    out.files = struct('figure_index_csv', figure_index_csv);
    out.figure_index = fig_index;

    fprintf('\n');
    fprintf('================ Stage09 Multi-H Heatmaps Summary ================\n');
    fprintf('run_tag      : %s\n', run_tag);
    fprintf('mode_tag     : %s\n', mode_tag);
    fprintf('figure index : %s\n', figure_index_csv);
    fprintf('===============================================================\n\n');
end

function run_tag = local_resolve_run_tag(base)
    run_tag = '';

    if isstruct(base) && isfield(base, 'cfg') && isstruct(base.cfg) ...
            && isfield(base.cfg, 'stage09') && isstruct(base.cfg.stage09)
        run_tag = local_pick_first_existing_field(base.cfg.stage09, ...
            {'run_tag','mode_tag','export_tag'}, '');
    end

    if isempty(run_tag) && isstruct(base) && isfield(base, 'cubes') ...
            && isstruct(base.cubes) && isfield(base.cubes, 'files') ...
            && isstruct(base.cubes.files)
        run_tag = local_pick_first_existing_field(base.cubes.files, ...
            {'run_tag','mode_tag','export_tag'}, '');
    end

    if isempty(run_tag)
        run_tag = 'inverse_aligned';
    end
end

function [out_dir_fig, out_dir_tbl] = local_resolve_output_dirs(base)
    out_dir_fig = '';
    out_dir_tbl = '';

    if isstruct(base) && isfield(base, 'cfg') && isstruct(base.cfg) ...
            && isfield(base.cfg, 'paths') && isstruct(base.cfg.paths)
        if isfield(base.cfg.paths, 'outputs') && isstruct(base.cfg.paths.outputs)
            if isfield(base.cfg.paths.outputs, 'stage09_figs')
                out_dir_fig = fullfile(base.cfg.paths.outputs.stage09_figs, 'multih_heatmaps');
            end
            if isfield(base.cfg.paths.outputs, 'stage09_tables')
                out_dir_tbl = fullfile(base.cfg.paths.outputs.stage09_tables, 'multih_heatmaps');
            end
        end
    end

    if isempty(out_dir_fig)
        out_dir_fig = fullfile(pwd, 'outputs', 'stage', 'stage09', 'figs', 'multih_heatmaps');
    end
    if isempty(out_dir_tbl)
        out_dir_tbl = fullfile(pwd, 'outputs', 'stage', 'stage09', 'tables', 'multih_heatmaps');
    end
end

function [cube_metric, cube_closure, h_vals, i_vals, P_vals, metric_names, closure_names] = local_unpack_cubes(cubes)
    cube_metric = local_pick_first_existing_field(cubes, ...
        {'metric_over_h_i_P','cube_metric_over_h_i_P'}, []);
    cube_closure = local_pick_first_existing_field(cubes, ...
        {'closure_over_h_i_P','cube_closure_over_h_i_P'}, []);

    idx = local_pick_first_existing_field(cubes, {'index_tables'}, struct());

    h_vals = local_extract_axis_vector(local_pick_first_existing_field(idx, {'h'}, []), 'h');
    i_vals = local_extract_axis_vector(local_pick_first_existing_field(idx, {'i'}, []), 'i');
    P_vals = local_extract_axis_vector(local_pick_first_existing_field(idx, {'P'}, []), 'P');

    metric_names = local_extract_name_list(local_pick_first_existing_field(idx, {'metric'}, []), ...
        {'DG','DA','DT'});
    closure_names = local_extract_name_list(local_pick_first_existing_field(idx, {'closure'}, []), ...
        {'joint','DG','DA','DT'});
end

function value = local_pick_first_existing_field(s, names, default_value)
    value = [];
    for ii = 1:numel(names)
        name = names{ii};
        if isstruct(s) && isfield(s, name)
            value = s.(name);
            return;
        end
    end
    if nargin >= 3
        value = default_value;
        return;
    end
    error('plot_stage09_multih_heatmaps:MissingField', ...
        'Missing required field. Checked: %s', strjoin(names, ', '));
end

function vals = local_extract_axis_vector(obj, fallback_name)
    if isempty(obj)
        error('plot_stage09_multih_heatmaps:MissingAxis', ...
            'Missing axis table/vector for %s.', fallback_name);
    end

    if istable(obj)
        vars = obj.Properties.VariableNames;
        if numel(vars) == 1
            vals = obj.(vars{1});
        else
            hit = find(strcmpi(vars, fallback_name), 1, 'first');
            if isempty(hit)
                hit = find(contains(lower(vars), lower(fallback_name)), 1, 'first');
            end
            if isempty(hit)
                vals = table2array(obj(:,1));
            else
                vals = obj.(vars{hit});
            end
        end
    else
        vals = obj;
    end

    vals = vals(:).';
end

function names = local_extract_name_list(obj, default_names)
    if isempty(obj)
        names = default_names;
        return;
    end

    if istable(obj)
        vars = obj.Properties.VariableNames;
        if any(strcmpi(vars, 'name'))
            raw = obj.('name');
        elseif any(strcmpi(vars, 'metric'))
            raw = obj.('metric');
        elseif any(strcmpi(vars, 'layer'))
            raw = obj.('layer');
        else
            raw = table2cell(obj(:,1));
        end
    else
        raw = obj;
    end

    if isstring(raw)
        names = cellstr(raw(:).');
    elseif iscell(raw)
        names = cellfun(@char, raw(:).', 'UniformOutput', false);
    elseif ischar(raw)
        names = {raw};
    else
        names = default_names;
    end
end

function idx = local_find_name(names, target)
    idx = find(strcmpi(names, target), 1, 'first');
    if isempty(idx)
        error('plot_stage09_multih_heatmaps:NameNotFound', ...
            'Cannot find name "%s" in {%s}.', target, strjoin(names, ', '));
    end
end

function cube_this = local_resolve_metric_minNs_cube(base, cube_metric, metric_names, metric_name)
    if isstruct(base.cubes) && isfield(base.cubes, 'metric_minNs_over_h_i_P')
        raw = base.cubes.metric_minNs_over_h_i_P;
        if ndims(raw) == 4
            metric_idx = local_find_name(metric_names, metric_name);
            cube_this = squeeze(raw(metric_idx, :, :, :));
            return;
        end
    end

    metric_idx = local_find_name(metric_names, metric_name);
    cube_this = squeeze(cube_metric(metric_idx, :, :, :));
end

function [nRows, nCols] = local_tile_shape(n)
    nCols = ceil(sqrt(n));
    nRows = ceil(n / nCols);
end

function local_plot_infeasible_crosses(ax, feasible_mask, i_vals, P_vals)
    [PP, II] = ndgrid(P_vals, i_vals);
    infeasible_mask = ~feasible_mask;
    if any(infeasible_mask(:))
        plot(ax, II(infeasible_mask), PP(infeasible_mask), 'x', ...
            'Color', [0.15 0.15 0.15], 'LineWidth', 1.2, 'MarkerSize', 8);
    end
end

function stamp = local_nowstamp()
    c = clock;
    stamp = sprintf('%04d%02d%02d_%02d%02d%02d', ...
        c(1), c(2), c(3), c(4), c(5), floor(c(6)));
end
