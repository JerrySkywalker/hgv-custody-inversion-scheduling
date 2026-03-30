function out = plot_stage09_metric_stack3d_over_h(base, metric_name, mode_tag)
%PLOT_STAGE09_METRIC_STACK3D_OVER_H
% Plot one metric as a 3D stack over altitude h.
%
% Axes:
%   x = inclination i
%   y = P
%   z = stacked altitude layers
%
% Supported metric_name:
%   'joint' / 'joint_feasible_ratio'
%   'DG'
%   'DA'
%   'DT'

    if nargin < 2 || isempty(metric_name)
        error('plot_stage09_metric_stack3d_over_h:MissingMetric', ...
            'metric_name is required.');
    end
    if nargin < 3 || isempty(mode_tag)
        mode_tag = 'phase5_stack3d';
    end

    if ~isstruct(base) || ~isfield(base, 'cubes')
        error('plot_stage09_metric_stack3d_over_h:InvalidInput', ...
            'Input base must contain field base.cubes.');
    end

    [cube_metric, cube_closure, h_vals, i_vals, P_vals, metric_names, closure_names] = ...
        local_unpack_cubes(base.cubes);

    if numel(h_vals) < 2
        error('plot_stage09_metric_stack3d_over_h:InsufficientHLevels', ...
            '3D stacked-over-h plot requires at least 2 altitude levels, but current data has only %d.', ...
            numel(h_vals));
    end

    metric_name = string(metric_name);
    [cube_this, canonical_name, metric_label] = ...
        local_resolve_metric_cube(metric_name, cube_metric, cube_closure, metric_names, closure_names);

    run_tag = local_resolve_run_tag(base);
    [out_dir_fig, out_dir_tbl] = local_resolve_output_dirs(base, canonical_name);

    if ~exist(out_dir_fig, 'dir')
        mkdir(out_dir_fig);
    end
    if ~exist(out_dir_tbl, 'dir')
        mkdir(out_dir_tbl);
    end

    plot_cfg = local_resolve_plot_cfg(base);

    timestamp = local_nowstamp();
    z_gap = plot_cfg.z_gap;

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', plot_cfg.figure_position);
    ax = axes(fig, 'Position', plot_cfg.axes_position);
    hold(ax, 'on');

    [X, Y] = meshgrid(i_vals, P_vals);

    global_vals = cube_this(isfinite(cube_this));
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

    layer_summary = table('Size', [numel(h_vals), 4], ...
        'VariableTypes', {'double','double','double','string'}, ...
        'VariableNames', {'h_km','layer_min','layer_max','layer_label'});

    for ih = 1:numel(h_vals)
        mat = squeeze(cube_this(ih, :, :)); % i x P
        mat_plot = mat.';                   % P x i
        feasible_mask = isfinite(mat_plot);

        vals = mat_plot(feasible_mask);
        if isempty(vals)
            layer_summary.layer_min(ih) = NaN;
            layer_summary.layer_max(ih) = NaN;
        else
            layer_summary.layer_min(ih) = min(vals);
            layer_summary.layer_max(ih) = max(vals);
        end
        layer_summary.h_km(ih) = h_vals(ih);
        layer_summary.layer_label(ih) = sprintf('h=%g km', h_vals(ih));

        Z = ones(size(X)) * ((ih - 1) * z_gap);
        C = mat_plot;
        C(~feasible_mask) = NaN;

        s = surf(ax, X, Y, Z, C, ...
            'FaceColor', 'interp', ...
            'FaceAlpha', plot_cfg.face_alpha, ...
            'LineWidth', plot_cfg.edge_linewidth);

        if plot_cfg.edge_alpha <= 0
            set(s, 'EdgeColor', 'none');
        else
            set(s, 'EdgeColor', plot_cfg.edge_color);
            try
                set(s, 'EdgeAlpha', plot_cfg.edge_alpha);
            catch
                set(s, 'EdgeColor', plot_cfg.edge_color);
            end
        end

        local_plot_infeasible_marks_3d(ax, feasible_mask, i_vals, P_vals, ...
            (ih - 1) * z_gap, plot_cfg);

        text(ax, max(i_vals) + plot_cfg.h_label_x_offset, mean(P_vals), (ih - 1) * z_gap, ...
            sprintf('h=%g', h_vals(ih)), ...
            'FontSize', plot_cfg.h_label_fontsize, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle', ...
            'Color', plot_cfg.h_label_color);
    end

    hold(ax, 'off');

    colormap(ax, parula(256));
    caxis(ax, clim);
    cb = colorbar(ax, 'eastoutside');
    cb.Label.String = sprintf('%s value', metric_label);

    view(ax, plot_cfg.view_az, plot_cfg.view_el);
    xlabel(ax, 'Inclination i [deg]');
    ylabel(ax, 'P');
    zlabel(ax, 'Altitude stack');
    title(ax, sprintf('Stage09 %s stacked over altitude h', metric_label), ...
        'FontWeight', 'bold');

    xticks(ax, i_vals);
    yticks(ax, P_vals);
    zticks(ax, (0:numel(h_vals)-1) * z_gap);
    zticklabels(ax, compose('%g km', h_vals));

    % ------------------------------------------------------------
    % IMPORTANT:
    % Do NOT use pbaspect / daspect here.
    %
    % Earlier versions over-constrained the 3D box shape and caused the
    % x-y surfaces to collapse visually into thin slivers.
    %
    % The current strategy is:
    %   1) use z_gap to separate layers in data space
    %   2) use a taller figure canvas
    %   3) use a larger/taller axes position
    %   4) use a milder viewing angle
    %
    % If layers still look crowded, tune:
    %   plot_cfg.z_gap
    %   plot_cfg.figure_position
    %   plot_cfg.axes_position
    %   plot_cfg.view_az / plot_cfg.view_el
    % ------------------------------------------------------------

    grid(ax, 'on');
    ax.GridAlpha = plot_cfg.grid_alpha;
    ax.LineWidth = plot_cfg.axis_linewidth;
    ax.Box = 'on';

    fig_name = sprintf('stage09_%s_stack3d_over_h_%s_%s_%s.png', ...
        lower(canonical_name), run_tag, mode_tag, timestamp);
    fig_path = fullfile(out_dir_fig, fig_name);
    exportgraphics(fig, fig_path, 'Resolution', 240);
    close(fig);

    figure_index = table( ...
        string(run_tag), ...
        string(mode_tag), ...
        string(timestamp), ...
        canonical_name, ...
        string(fig_path), ...
        'VariableNames', {'run_tag','mode_tag','timestamp','metric_name','fig_metric_stack3d'});

    figure_index_csv = fullfile(out_dir_tbl, ...
        sprintf('stage09_%s_stack3d_over_h_figure_index_%s_%s_%s.csv', ...
        lower(canonical_name), run_tag, mode_tag, timestamp));
    writetable(figure_index, figure_index_csv);

    layer_summary_csv = fullfile(out_dir_tbl, ...
        sprintf('stage09_%s_stack3d_over_h_layer_summary_%s_%s_%s.csv', ...
        lower(canonical_name), run_tag, mode_tag, timestamp));
    writetable(layer_summary, layer_summary_csv);

    out = struct();
    out.files = struct( ...
        'figure_index_csv', figure_index_csv, ...
        'layer_summary_csv', layer_summary_csv);
    out.figure_index = figure_index;
    out.layer_summary = layer_summary;
    out.metric_name = canonical_name;

    fprintf('\n');
    fprintf('================ Stage09 Metric Stack3D Summary ================\n');
    fprintf('metric       : %s\n', canonical_name);
    fprintf('run_tag      : %s\n', run_tag);
    fprintf('mode_tag     : %s\n', mode_tag);
    fprintf('z_gap        : %.4f\n', plot_cfg.z_gap);
    fprintf('view_az      : %.4f\n', plot_cfg.view_az);
    fprintf('view_el      : %.4f\n', plot_cfg.view_el);
    fprintf('figure index : %s\n', figure_index_csv);
    fprintf('layer table  : %s\n', layer_summary_csv);
    fprintf('===============================================================\n\n');
end

function plot_cfg = local_resolve_plot_cfg(base)
    plot_cfg = struct();

    % ============================================================
    % MAIN TUNING KNOB 1:
    % z_gap controls the separation between altitude layers.
    %
    % Increase this if layers overlap too much.
    %
    % Recommended range:
    %   2.0 ~ 4.5
    %
    % Current default:
    %   3.2
    % ============================================================
    plot_cfg.z_gap = 3.2;

    % ============================================================
    % MAIN TUNING KNOB 2:
    % face_alpha controls surface transparency.
    %
    % Recommended range:
    %   0.80 ~ 0.92
    %
    % Current default:
    %   0.84
    % ============================================================
    plot_cfg.face_alpha = 0.84;

    % ============================================================
    % MAIN TUNING KNOB 3:
    % edge_alpha controls layer grid-line visibility.
    %
    %   0.0  -> hidden
    %   >0   -> visible
    %
    % Current default:
    %   0.0
    % ============================================================
    plot_cfg.edge_alpha = 0.0;
    plot_cfg.edge_color = [0.55 0.55 0.55];
    plot_cfg.edge_linewidth = 0.55;

    % ============================================================
    % MAIN TUNING KNOB 4:
    % grid_alpha controls background grid visibility.
    %
    % Current default:
    %   0.06
    % ============================================================
    plot_cfg.grid_alpha = 0.06;

    % ============================================================
    % MAIN TUNING KNOB 5:
    % view_az / view_el control camera angle.
    %
    % Avoid too edge-on a view, otherwise each layer may visually collapse
    % into a thin strip.
    %
    % Current default:
    %   az = -38
    %   el = 22
    % ============================================================
    plot_cfg.view_az = -38;
    plot_cfg.view_el = 22;

    % ============================================================
    % MAIN TUNING KNOB 6:
    % Make the canvas taller and let axes occupy a taller area.
    % This improves vertical readability without forcing pbaspect.
    %
    % Current defaults:
    %   figure_position = [100 60 1500 1100]
    %   axes_position   = [0.07 0.08 0.72 0.84]
    % ============================================================
    plot_cfg.figure_position = [100 60 1500 1100];
    plot_cfg.axes_position = [0.07 0.08 0.72 0.84];

    plot_cfg.axis_linewidth = 0.9;

    plot_cfg.h_label_x_offset = 2.0;
    plot_cfg.h_label_fontsize = 11;
    plot_cfg.h_label_color = [0.15 0.15 0.15];

    % infeasible marker policy:
    %   'none'   : do not plot infeasible marks (recommended default)
    %   'gray_x' : plot light-gray x marks
    plot_cfg.infeasible_style = 'none';
    plot_cfg.infeasible_color = [0.60 0.60 0.60];
    plot_cfg.infeasible_marker_size = 5.5;
    plot_cfg.infeasible_linewidth = 0.8;

    if isstruct(base) && isfield(base, 'cfg') && isstruct(base.cfg) ...
            && isfield(base.cfg, 'stage09') && isstruct(base.cfg.stage09)
        s9 = base.cfg.stage09;

        if isfield(s9, 'plot3d_stack') && isstruct(s9.plot3d_stack)
            p = s9.plot3d_stack;

            if isfield(p, 'z_gap') && ~isempty(p.z_gap)
                plot_cfg.z_gap = p.z_gap;
            end
            if isfield(p, 'face_alpha') && ~isempty(p.face_alpha)
                plot_cfg.face_alpha = p.face_alpha;
            end
            if isfield(p, 'edge_alpha') && ~isempty(p.edge_alpha)
                plot_cfg.edge_alpha = p.edge_alpha;
            end
            if isfield(p, 'grid_alpha') && ~isempty(p.grid_alpha)
                plot_cfg.grid_alpha = p.grid_alpha;
            end
            if isfield(p, 'view_az') && ~isempty(p.view_az)
                plot_cfg.view_az = p.view_az;
            end
            if isfield(p, 'view_el') && ~isempty(p.view_el)
                plot_cfg.view_el = p.view_el;
            end
            if isfield(p, 'figure_position') && ~isempty(p.figure_position)
                plot_cfg.figure_position = p.figure_position;
            end
            if isfield(p, 'axes_position') && ~isempty(p.axes_position)
                plot_cfg.axes_position = p.axes_position;
            end
            if isfield(p, 'infeasible_style') && ~isempty(p.infeasible_style)
                plot_cfg.infeasible_style = char(string(p.infeasible_style));
            end
        end
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
        {'joint_feasible_ratio','DG_best','DA_best','DT_best'});
end

function [cube_this, canonical_name, metric_label] = local_resolve_metric_cube(metric_name, cube_metric, cube_closure, metric_names, closure_names)
    name = lower(char(metric_name));

    switch name
        case {'joint','joint_feasible_ratio'}
            idx = local_find_name(closure_names, 'joint_feasible_ratio');
            cube_this = squeeze(cube_closure(idx, :, :, :)); % h x i x P
            canonical_name = "joint";
            metric_label = "joint feasible ratio";

        case {'dg'}
            idx = local_find_name(metric_names, 'DG');
            cube_this = squeeze(cube_metric(idx, :, :, :));
            canonical_name = "DG";
            metric_label = "DG";

        case {'da'}
            idx = local_find_name(metric_names, 'DA');
            cube_this = squeeze(cube_metric(idx, :, :, :));
            canonical_name = "DA";
            metric_label = "DA";

        case {'dt'}
            idx = local_find_name(metric_names, 'DT');
            cube_this = squeeze(cube_metric(idx, :, :, :));
            canonical_name = "DT";
            metric_label = "DT";

        otherwise
            error('plot_stage09_metric_stack3d_over_h:UnsupportedMetric', ...
                'Unsupported metric_name: %s', metric_name);
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

function [out_dir_fig, out_dir_tbl] = local_resolve_output_dirs(base, canonical_name)
    out_dir_fig = '';
    out_dir_tbl = '';

    subdir = sprintf('phase5_stack3d_%s', lower(canonical_name));

    if isstruct(base) && isfield(base, 'cfg') && isstruct(base.cfg) ...
            && isfield(base.cfg, 'paths') && isstruct(base.cfg.paths)
        if isfield(base.cfg.paths, 'outputs') && isstruct(base.cfg.paths.outputs)
            if isfield(base.cfg.paths.outputs, 'stage09_figs')
                out_dir_fig = fullfile(base.cfg.paths.outputs.stage09_figs, subdir);
            end
            if isfield(base.cfg.paths.outputs, 'stage09_tables')
                out_dir_tbl = fullfile(base.cfg.paths.outputs.stage09_tables, subdir);
            end
        end
    end

    if isempty(out_dir_fig) || isempty(out_dir_tbl)
        project_root = local_resolve_project_root();
        if isempty(out_dir_fig)
            out_dir_fig = fullfile(project_root, 'outputs', 'stage', 'stage09', 'figs', subdir);
        end
        if isempty(out_dir_tbl)
            out_dir_tbl = fullfile(project_root, 'outputs', 'stage', 'stage09', 'tables', subdir);
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
    error('plot_stage09_metric_stack3d_over_h:MissingField', ...
        'Missing required field. Checked: %s', strjoin(names, ', '));
end

function vals = local_extract_axis_vector(obj, axis_name)
    if isempty(obj)
        error('plot_stage09_metric_stack3d_over_h:MissingAxis', ...
            'Missing axis table/vector for %s.', axis_name);
    end

    if istable(obj)
        vars = obj.Properties.VariableNames;
        vars_lower = lower(vars);

        switch lower(axis_name)
            case 'h'
                preferred = {'h_km','altitude_km','height_km','h'};
            case 'i'
                preferred = {'i_deg','inclination_deg','inclination','i'};
            case 'p'
                preferred = {'p'};
            otherwise
                preferred = {axis_name};
        end

        hit = local_find_first_var(vars, vars_lower, preferred);

        if isempty(hit)
            non_index = ~contains(vars_lower, 'idx');
            if any(non_index)
                idx_first = find(non_index, 1, 'first');
                vals = obj.(vars{idx_first});
            else
                vals = table2array(obj(:,1));
            end
        else
            vals = obj.(hit);
        end
    else
        vals = obj;
    end

    vals = vals(:).';
end

function hit = local_find_first_var(vars, vars_lower, preferred)
    hit = '';

    for k = 1:numel(preferred)
        idx = find(strcmpi(vars, preferred{k}), 1, 'first');
        if ~isempty(idx)
            hit = vars{idx};
            return;
        end
    end

    for k = 1:numel(preferred)
        idx = find(contains(vars_lower, lower(preferred{k})), 1, 'first');
        if ~isempty(idx)
            hit = vars{idx};
            return;
        end
    end
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
        error('plot_stage09_metric_stack3d_over_h:NameNotFound', ...
            'Cannot find name "%s" in {%s}.', target, strjoin(names, ', '));
    end
end

function local_plot_infeasible_marks_3d(ax, feasible_mask, i_vals, P_vals, z0, plot_cfg)
    style = lower(string(plot_cfg.infeasible_style));

    switch style
        case "none"
            return;

        case "gray_x"
            [PP, II] = ndgrid(P_vals, i_vals);
            infeasible_mask = ~feasible_mask;
            if any(infeasible_mask(:))
                ZZ = ones(size(II(infeasible_mask))) * z0;
                plot3(ax, II(infeasible_mask), PP(infeasible_mask), ZZ, 'x', ...
                    'Color', plot_cfg.infeasible_color, ...
                    'LineWidth', plot_cfg.infeasible_linewidth, ...
                    'MarkerSize', plot_cfg.infeasible_marker_size);
            end

        otherwise
            error('plot_stage09_metric_stack3d_over_h:UnsupportedInfeasibleStyle', ...
                'Unsupported infeasible_style: %s', plot_cfg.infeasible_style);
    end
end

function stamp = local_nowstamp()
    c = clock;
    stamp = sprintf('%04d%02d%02d_%02d%02d%02d', ...
        c(1), c(2), c(3), c(4), c(5), floor(c(6)));
end
