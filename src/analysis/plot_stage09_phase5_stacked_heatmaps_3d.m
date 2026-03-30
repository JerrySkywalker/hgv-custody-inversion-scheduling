function out = plot_stage09_phase5_stacked_heatmaps_3d(base, mode_tag)
%PLOT_STAGE09_PHASE5_STACKED_HEATMAPS_3D
% Phase5:
% Render a 3D stacked heatmap figure for Stage09 closure layers.
%
% Current design:
%   - Uses fixed h slice (single-h compatible)
%   - Stacks 4 closure layers along z
%   - x-axis: inclination i
%   - y-axis: P
%   - z-axis: layer index
%
% Layers:
%   1. joint_feasible_ratio
%   2. DG_best
%   3. DA_best
%   4. DT_best

    if nargin < 2 || isempty(mode_tag)
        mode_tag = 'phase5_stack3d';
    end

    if ~isstruct(base) || ~isfield(base, 'cubes')
        error('plot_stage09_phase5_stacked_heatmaps_3d:InvalidInput', ...
            'Input base must contain field base.cubes.');
    end

    [cube_closure, h_vals, i_vals, P_vals, closure_names] = local_unpack_closure_cube(base.cubes);

    run_tag = local_resolve_run_tag(base);
    [out_dir_fig, out_dir_tbl] = local_resolve_output_dirs(base);

    if ~exist(out_dir_fig, 'dir')
        mkdir(out_dir_fig);
    end
    if ~exist(out_dir_tbl, 'dir')
        mkdir(out_dir_tbl);
    end

    timestamp = local_nowstamp();
    h_idx = local_resolve_h_index(base, h_vals);

    layer_specs = { ...
        struct('layer_name','joint_feasible_ratio','label','joint feasible ratio'), ...
        struct('layer_name','DG_best','label','DG best'), ...
        struct('layer_name','DA_best','label','DA best'), ...
        struct('layer_name','DT_best','label','DT best') ...
    };

    nLayers = numel(layer_specs);
    z_gap = 1.0;

    fig = figure('Visible','off','Color','w','Position',[100 100 1200 860]);
    ax = axes(fig);
    hold(ax, 'on');

    [X, Y] = meshgrid(i_vals, P_vals);

    fig_index = table();
    layer_names = strings(nLayers,1);
    layer_min = nan(nLayers,1);
    layer_max = nan(nLayers,1);

    for k = 1:nLayers
        spec = layer_specs{k};
        layer_idx = local_find_name(closure_names, spec.layer_name);

        mat = squeeze(cube_closure(layer_idx, h_idx, :, :)); % i x P
        mat_plot = mat.';                                    % P x i
        feasible_mask = isfinite(mat_plot);

        vals = mat_plot(feasible_mask);
        if isempty(vals)
            clim = [0, 1];
            layer_min(k) = NaN;
            layer_max(k) = NaN;
        else
            vmin = min(vals);
            vmax = max(vals);
            if abs(vmax - vmin) < 1e-12
                epsv = max(1, abs(vmax)) * 1e-6;
                clim = [vmin - epsv, vmax + epsv];
            else
                clim = [vmin, vmax];
            end
            layer_min(k) = vmin;
            layer_max(k) = vmax;
        end

        Z = ones(size(X)) * ((k - 1) * z_gap);
        C = mat_plot;
        C(~feasible_mask) = NaN;

        s = surf(ax, X, Y, Z, C, ...
            'EdgeColor', [0.55 0.55 0.55], ...
            'LineWidth', 0.6, ...
            'FaceColor', 'interp');

        colormap(ax, parula(256));

        local_plot_infeasible_crosses_3d(ax, feasible_mask, i_vals, P_vals, (k - 1) * z_gap);

        text(ax, max(i_vals) + 2, mean(P_vals), (k - 1) * z_gap, ...
            sprintf('%d: %s', k, spec.label), ...
            'FontSize', 11, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle');

        layer_names(k) = string(spec.layer_name);
    end

    hold(ax, 'off');
    view(ax, [-35 24]);
    xlabel(ax, 'Inclination i [deg]');
    ylabel(ax, 'P');
    zlabel(ax, 'Layer stack');
    title(ax, sprintf('Stage09 3D stacked closure heatmaps at h = %g km', h_vals(h_idx)), ...
        'FontWeight', 'bold');

    xticks(ax, i_vals);
    yticks(ax, P_vals);
    zticks(ax, (0:nLayers-1) * z_gap);
    zticklabels(ax, cellstr(layer_names));
    grid(ax, 'on');
    ax.GridAlpha = 0.18;
    ax.LineWidth = 0.9;
    ax.Box = 'on';

    cb = colorbar(ax, 'eastoutside');
    cb.Label.String = 'Layer value';

    fig_name = sprintf('stage09_phase5_stack3d_%s_%s_%s.png', run_tag, mode_tag, timestamp);
    fig_path = fullfile(out_dir_fig, fig_name);
    exportgraphics(fig, fig_path, 'Resolution', 240);
    close(fig);

    figure_index = table( ...
        string(run_tag), ...
        string(mode_tag), ...
        string(timestamp), ...
        h_vals(h_idx), ...
        string(fig_path), ...
        'VariableNames', {'run_tag','mode_tag','timestamp','h_km','fig_phase5_stack3d'});

    figure_index_csv = fullfile(out_dir_tbl, ...
        sprintf('stage09_phase5_stack3d_figure_index_%s_%s_%s.csv', run_tag, mode_tag, timestamp));
    writetable(figure_index, figure_index_csv);

    out = struct();
    out.files = struct('figure_index_csv', figure_index_csv);
    out.figure_index = figure_index;
    out.layer_names = layer_names;
    out.layer_min = layer_min;
    out.layer_max = layer_max;

    fprintf('\n');
    fprintf('================ Stage09 Phase5 3D Stack Summary ================\n');
    fprintf('run_tag      : %s\n', run_tag);
    fprintf('mode_tag     : %s\n', mode_tag);
    fprintf('h selected   : %g km\n', h_vals(h_idx));
    fprintf('figure index : %s\n', figure_index_csv);
    fprintf('================================================================\n\n');
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

function h_idx = local_resolve_h_index(base, h_vals)
    h_idx = 1;

    if isstruct(base) && isfield(base, 'cfg') && isstruct(base.cfg) ...
            && isfield(base.cfg, 'stage09') && isstruct(base.cfg.stage09)
        if isfield(base.cfg.stage09, 'plot_h_slice_km') && ~isempty(base.cfg.stage09.plot_h_slice_km)
            target_h = base.cfg.stage09.plot_h_slice_km;
            [~, h_idx] = min(abs(h_vals - target_h));
            return;
        end
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
                out_dir_fig = fullfile(base.cfg.paths.outputs.stage09_figs, 'phase5_stack3d');
            end
            if isfield(base.cfg.paths.outputs, 'stage09_tables')
                out_dir_tbl = fullfile(base.cfg.paths.outputs.stage09_tables, 'phase5_stack3d');
            end
        end
    end

    if isempty(out_dir_fig) || isempty(out_dir_tbl)
        project_root = local_resolve_project_root();
        if isempty(out_dir_fig)
            out_dir_fig = fullfile(project_root, 'outputs', 'stage', 'stage09', 'figs', 'phase5_stack3d');
        end
        if isempty(out_dir_tbl)
            out_dir_tbl = fullfile(project_root, 'outputs', 'stage', 'stage09', 'tables', 'phase5_stack3d');
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
    error('plot_stage09_phase5_stacked_heatmaps_3d:MissingField', ...
        'Missing required field. Checked: %s', strjoin(names, ', '));
end

function vals = local_extract_axis_vector(obj, fallback_name)
    if isempty(obj)
        error('plot_stage09_phase5_stacked_heatmaps_3d:MissingAxis', ...
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
        error('plot_stage09_phase5_stacked_heatmaps_3d:NameNotFound', ...
            'Cannot find name "%s" in {%s}.', target, strjoin(names, ', '));
    end
end

function local_plot_infeasible_crosses_3d(ax, feasible_mask, i_vals, P_vals, z0)
    [PP, II] = ndgrid(P_vals, i_vals);
    infeasible_mask = ~feasible_mask;
    if any(infeasible_mask(:))
        ZZ = ones(size(II(infeasible_mask))) * z0;
        plot3(ax, II(infeasible_mask), PP(infeasible_mask), ZZ, 'x', ...
            'Color', [0.18 0.18 0.18], 'LineWidth', 1.0, 'MarkerSize', 7);
    end
end

function stamp = local_nowstamp()
    c = clock;
    stamp = sprintf('%04d%02d%02d_%02d%02d%02d', ...
        c(1), c(2), c(3), c(4), c(5), floor(c(6)));
end
