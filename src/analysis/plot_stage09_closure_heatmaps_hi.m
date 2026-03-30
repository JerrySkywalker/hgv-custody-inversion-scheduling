function out = plot_stage09_closure_heatmaps_hi(base, mode_tag)
%PLOT_STAGE09_CLOSURE_HEATMAPS_HI
% Phase4-C:
% Plot four-layer closure heatmaps on the h-i plane at a selected P slice.
%
% Guarded feature:
%   Requires at least 2 altitude levels in closure_over_h_i_P.

    if nargin < 2 || isempty(mode_tag)
        mode_tag = 'phase4_closure_hi';
    end

    if ~isstruct(base) || ~isfield(base, 'cubes')
        error('plot_stage09_closure_heatmaps_hi:InvalidInput', ...
            'Input base must contain field base.cubes.');
    end

    [cube_closure, h_vals, i_vals, P_vals, closure_names] = local_unpack_closure_cube(base.cubes); %#ok<ASGLU>

    if numel(h_vals) < 2
        error('plot_stage09_closure_heatmaps_hi:InsufficientHLevels', ...
            ['Phase4-C requires at least 2 altitude levels in closure_over_h_i_P, ' ...
             'but current data has only %d. This feature is guarded and will not plot ' ...
             'single-h pseudo heatmaps.'], numel(h_vals));
    end

    run_tag = local_resolve_run_tag(base);
    [out_dir_fig, out_dir_tbl] = local_resolve_output_dirs(base);

    if ~exist(out_dir_fig, 'dir')
        mkdir(out_dir_fig);
    end
    if ~exist(out_dir_tbl, 'dir')
        mkdir(out_dir_tbl);
    end

    timestamp = local_nowstamp();
    P_idx = local_resolve_P_index(base, P_vals);

    layer_specs = { ...
        struct('layer_name','joint_feasible_ratio','title','Joint feasible ratio over (h,i)','cbar','Joint feasible ratio'), ...
        struct('layer_name','DG_best','title','DG best over (h,i)','cbar','DG best'), ...
        struct('layer_name','DA_best','title','DA best over (h,i)','cbar','DA best'), ...
        struct('layer_name','DT_best','title','DT best over (h,i)','cbar','DT best') ...
    };

    fig = figure('Visible','off','Color','w','Position',[100 100 760 1200]);
    tl = tiledlayout(fig, 4, 1, 'TileSpacing','compact', 'Padding','compact');

    for k = 1:numel(layer_specs)
        spec = layer_specs{k};
        layer_idx = local_find_name(closure_names, spec.layer_name);

        mat = squeeze(cube_closure(layer_idx, :, :, P_idx)); % h x i
        feasible_mask = isfinite(mat);

        vals = mat(feasible_mask);
        if isempty(vals)
            clim = [0, 1];
        else
            vmin = min(vals);
            vmax = max(vals);
            if abs(vmax - vmin) < 1e-12
                epsv = max(1, abs(vmax)) * 1e-6;
                clim = [vmin - epsv, vmax + epsv];
            else
                clim = [vmin, vmax];
            end
        end

        ax = nexttile(tl);
        imagesc(ax, i_vals, h_vals, mat, 'AlphaData', double(feasible_mask));
        set(ax, 'YDir', 'normal');
        colormap(ax, parula(256));
        caxis(ax, clim);

        hold(ax, 'on');
        local_plot_infeasible_crosses_hi(ax, feasible_mask, i_vals, h_vals);
        hold(ax, 'off');

        xlim(ax, [min(i_vals)-0.5, max(i_vals)+0.5]);
        ylim(ax, [min(h_vals)-0.5, max(h_vals)+0.5]);
        xticks(ax, i_vals);
        yticks(ax, h_vals);
        xlabel(ax, 'Inclination i [deg]');
        ylabel(ax, 'Altitude h [km]');
        title(ax, sprintf('%s (P = %g)', spec.title, P_vals(P_idx)));
        grid(ax, 'on');
        ax.GridAlpha = 0.18;
        ax.LineWidth = 0.8;
        ax.Layer = 'top';
        ax.Box = 'on';

        cb = colorbar(ax, 'eastoutside');
        cb.Label.String = spec.cbar;
    end

    title(tl, sprintf('Stage09 closure heatmaps on h-i plane at P = %g', P_vals(P_idx)), 'FontWeight', 'bold');

    fig_name = sprintf('stage09_closure_heatmaps_hi_%s_%s_%s.png', run_tag, mode_tag, timestamp);
    fig_path = fullfile(out_dir_fig, fig_name);
    exportgraphics(fig, fig_path, 'Resolution', 220);
    close(fig);

    figure_index = table( ...
        string(run_tag), ...
        string(mode_tag), ...
        string(timestamp), ...
        P_vals(P_idx), ...
        string(fig_path), ...
        'VariableNames', {'run_tag','mode_tag','timestamp','P_selected','fig_closure_heatmaps_hi'});

    figure_index_csv = fullfile(out_dir_tbl, ...
        sprintf('stage09_closure_heatmaps_hi_figure_index_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    writetable(figure_index, figure_index_csv);

    out = struct();
    out.files = struct('figure_index_csv', figure_index_csv);
    out.figure_index = figure_index;

    fprintf('\n');
    fprintf('================ Stage09 Closure HI Heatmaps Summary ================\n');
    fprintf('run_tag      : %s\n', run_tag);
    fprintf('mode_tag     : %s\n', mode_tag);
    fprintf('P selected   : %g\n', P_vals(P_idx));
    fprintf('figure index : %s\n', figure_index_csv);
    fprintf('===================================================================\n\n');
end

function [cube_closure, h_vals, i_vals, P_vals, closure_names] = local_unpack_closure_cube(cubes)
    cube_closure = local_pick_first_existing_field(cubes, ...
        {'closure_over_h_i_P','cube_closure_over_h_i_P'}, []);

    idx = local_pick_first_existing_field(cubes, {'index_tables'}, struct());

    h_vals = local_extract_axis_vector(local_pick_first_existing_field(idx, {'h'}, []), 'h');
    i_vals = local_extract_axis_vector(local_pick_first_existing_field(idx, {'i'}, []), 'i');
    P_vals = local_extract_axis_vector(local_pick_first_existing_field(idx, {'P'}, []), 'P');

    closure_names = local_extract_name_list(local_pick_first_existing_field(idx, {'closure'}, []), ...
        {'joint_feasible_ratio','DG_best','DA_best','DT_best'});
end

function P_idx = local_resolve_P_index(base, P_vals)
    P_idx = 1;

    if isstruct(base) && isfield(base, 'cfg') && isstruct(base.cfg) ...
            && isfield(base.cfg, 'stage09') && isstruct(base.cfg.stage09)
        if isfield(base.cfg.stage09, 'plot_P_slice') && ~isempty(base.cfg.stage09.plot_P_slice)
            target_P = base.cfg.stage09.plot_P_slice;
            [~, P_idx] = min(abs(P_vals - target_P));
            return;
        end
    end

    if numel(P_vals) >= 1
        P_idx = 1;
    end
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
                out_dir_fig = fullfile(base.cfg.paths.outputs.stage09_figs, 'closure_heatmaps_hi');
            end
            if isfield(base.cfg.paths.outputs, 'stage09_tables')
                out_dir_tbl = fullfile(base.cfg.paths.outputs.stage09_tables, 'closure_heatmaps_hi');
            end
        end
    end

    if isempty(out_dir_fig) || isempty(out_dir_tbl)
        project_root = local_resolve_project_root();
        if isempty(out_dir_fig)
            out_dir_fig = fullfile(project_root, 'outputs', 'stage', 'stage09', 'figs', 'closure_heatmaps_hi');
        end
        if isempty(out_dir_tbl)
            out_dir_tbl = fullfile(project_root, 'outputs', 'stage', 'stage09', 'tables', 'closure_heatmaps_hi');
        end
    end
end

function project_root = local_resolve_project_root()
    project_root = '';

    startup_path = which('startup.m');
    if ~isempty(startup_path)
        project_root = fileparts(startup_path);
    end

    if isempty(project_root)
        project_root = pwd;
    end
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
    error('plot_stage09_closure_heatmaps_hi:MissingField', ...
        'Missing required field. Checked: %s', strjoin(names, ', '));
end

function vals = local_extract_axis_vector(obj, fallback_name)
    if isempty(obj)
        error('plot_stage09_closure_heatmaps_hi:MissingAxis', ...
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

    raw = [];

    if istable(obj)
        vars = obj.Properties.VariableNames;
        preferred_vars = {'name','metric_name','layer_name','metric','layer','label'};

        hit = '';
        for k = 1:numel(preferred_vars)
            idx = find(strcmpi(vars, preferred_vars{k}), 1, 'first');
            if ~isempty(idx)
                hit = vars{idx};
                break;
            end
        end

        if isempty(hit)
            raw = table2array(obj(:,1));
        else
            raw = obj.(hit);
        end
    else
        raw = obj;
    end

    if isstring(raw)
        names = cellstr(raw(:).');
        return;
    end

    if ischar(raw)
        names = {raw};
        return;
    end

    if isnumeric(raw) || islogical(raw)
        n = min(numel(raw), numel(default_names));
        names = default_names(1:n);
        return;
    end

    if iscell(raw)
        if all(cellfun(@ischar, raw))
            names = raw(:).';
            return;
        end

        if all(cellfun(@(x) isstring(x) && isscalar(x), raw))
            names = cellfun(@char, raw(:).', 'UniformOutput', false);
            return;
        end

        if all(cellfun(@(x) isnumeric(x) || islogical(x), raw))
            n = min(numel(raw), numel(default_names));
            names = default_names(1:n);
            return;
        end
    end

    names = default_names;
end

function idx = local_find_name(names, target)
    idx = find(strcmpi(names, target), 1, 'first');
    if isempty(idx)
        error('plot_stage09_closure_heatmaps_hi:NameNotFound', ...
            'Cannot find name "%s" in {%s}.', target, strjoin(names, ', '));
    end
end

function local_plot_infeasible_crosses_hi(ax, feasible_mask, i_vals, h_vals)
    [HH, II] = ndgrid(h_vals, i_vals);
    infeasible_mask = ~feasible_mask;
    if any(infeasible_mask(:))
        plot(ax, II(infeasible_mask), HH(infeasible_mask), 'x', ...
            'Color', [0.15 0.15 0.15], 'LineWidth', 1.2, 'MarkerSize', 8);
    end
end

function stamp = local_nowstamp()
    c = clock;
    stamp = sprintf('%04d%02d%02d_%02d%02d%02d', ...
        c(1), c(2), c(3), c(4), c(5), floor(c(6)));
end
