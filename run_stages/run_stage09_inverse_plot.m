%% run_stage09_inverse_plot.m
% 一键运行 Stage09 作图部分
%
% 双模式：
%   1) legacy10      -> 旧 Stage09.6 十图导出
%   2) layered_suite -> 新分层图谱导出

function out = run_stage09_inverse_plot(cfg, interactive, opts)
    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root)
        addpath(proj_root);
        addpath(fullfile(proj_root, 'run_stages'));
    end

    cfg_missing = (nargin < 1 || isempty(cfg));
    if cfg_missing
        evalc('startup(''force'', false);');
        cfg = default_params();
    end
    if nargin < 2 || isempty(interactive)
        interactive = (nargin == 0);
    end
    if nargin < 3 || isempty(opts)
        opts = struct();
    end

    [cfg, opts] = rs_cli_configure('stage09', cfg, interactive, opts);
    [cfg, ~] = rs_apply_parallel_policy('stage09', cfg, opts);
    cfg = stage09_prepare_cfg(cfg);

    plot_mode = local_get_opt_string(opts, 'stage09_plot_mode', 'layered_suite');
    enable_multih = local_get_opt_logical(opts, 'stage09_enable_multih', true);
    enable_stack3d = local_get_opt_logical(opts, 'stage09_enable_stack3d', false);

    fprintf('[run_stages] === Stage09 作图入口 ===\n');
    fprintf('[run_stages] scheme_type : %s\n', string(cfg.stage09.scheme_type));
    fprintf('[run_stages] run_tag     : %s\n', string(cfg.stage09.run_tag));
    fprintf('[run_stages] plot_mode   : %s\n', string(plot_mode));

    switch lower(plot_mode)
        case 'legacy10'
            out = stage09_plot_inverse_design_results([], [], cfg);

        case 'layered_suite'
            out = local_run_layered_suite(cfg, enable_multih, enable_stack3d);

        otherwise
            error('run_stage09_inverse_plot:UnknownPlotMode', ...
                'Unknown opts.stage09_plot_mode = %s', string(plot_mode));
    end

    fprintf('[run_stages] === Stage09 作图完成 ===\n');
end


function out = local_run_layered_suite(cfg, enable_multih, enable_stack3d)

    run_tag = char(string(cfg.stage09.run_tag));
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    stage09_cache_dir = local_resolve_stage09_cache_dir(cfg);
    fprintf('[run_stages] [layered_suite] stage09 cache dir : %s\n', stage09_cache_dir);

    out9_4 = local_load_latest_cache(stage09_cache_dir, ...
        sprintf('stage09_build_feasible_domain_%s_*.mat', run_tag), ...
        'stage09_build_feasible_domain_*.mat');

    out9_5 = local_load_latest_cache(stage09_cache_dir, ...
        sprintf('stage09_extract_minimum_boundary_%s_*.mat', run_tag), ...
        'stage09_extract_minimum_boundary_*.mat');

    base = struct();
    base.s4 = out9_4;
    base.s5 = out9_5;
    base.cfg = out9_4.cfg;

    fprintf('[run_stages] [layered_suite] build metric views...\n');
    base.views = build_stage09_metric_views(base, 'run_stage09_inverse_plot');

    fprintf('[run_stages] [layered_suite] build metric frontiers...\n');
    base.frontiers = build_stage09_metric_frontiers(base.views, base.cfg, 'run_stage09_inverse_plot');

    fprintf('[run_stages] [layered_suite] build multilayer cubes...\n');
    base.cubes = build_stage09_multilayer_heatmaps(base.views, base.cfg, 'run_stage09_inverse_plot');

    fprintf('[run_stages] [layered_suite] bundle DG/DA/DT/joint packs...\n');
    bundle = plot_stage09_bundle_all_packs(base, 'run_stage09_inverse_plot');

    fprintf('[run_stages] [layered_suite] export closure heatmaps...\n');
    closure = plot_stage09_closure_heatmaps(base, 'run_stage09_inverse_plot');

    h_count = local_get_h_count(base.cubes);

    multih = struct();
    multih_skipped = false;
    multih_skip_reason = "";

    if enable_multih && h_count >= 2
        fprintf('[run_stages] [layered_suite] export multi-height heatmaps...\n');
        multih = plot_stage09_multih_heatmaps(base, 'run_stage09_inverse_plot');
    else
        multih_skipped = true;
        if ~enable_multih
            multih_skip_reason = "disabled_by_option";
        else
            multih_skip_reason = "insufficient_h_levels";
        end
        fprintf('[run_stages] [layered_suite] skip multi-height heatmaps: %s\n', multih_skip_reason);
    end

    stack3d = struct();
    stack3d_skipped = false;
    stack3d_skip_reason = "";

    if enable_stack3d && h_count >= 2
        fprintf('[run_stages] [layered_suite] export Phase5 stack3d pack...\n');
        stack3d = manual_smoke_stage09_phase5_stack3d_plots(base);
    else
        stack3d_skipped = true;
        if ~enable_stack3d
            stack3d_skip_reason = "disabled_by_option";
        else
            stack3d_skip_reason = "insufficient_h_levels";
        end
        fprintf('[run_stages] [layered_suite] skip stack3d: %s\n', stack3d_skip_reason);
    end

    summary_rows = table( ...
        ["bundle_all_packs"; "closure_heatmaps"; "multih_heatmaps"; "phase5_stack3d"], ...
        [false; false; multih_skipped; stack3d_skipped], ...
        [""; ""; multih_skip_reason; stack3d_skip_reason], ...
        [string(bundle.files.master_index_csv); ...
         string(closure.files.figure_index_csv); ...
         local_struct_figure_index_csv(multih); ...
         local_phase5_pack_csv(stack3d)], ...
        'VariableNames', {'component', 'skipped', 'skip_reason', 'primary_index_csv'});

    table_dir = fullfile(cfg.paths.tables, 'layered_suite');
    if ~exist(table_dir, 'dir')
        mkdir(table_dir);
    end

    summary_csv = fullfile(table_dir, ...
        sprintf('stage09_layered_suite_summary_%s_%s.csv', run_tag, timestamp));
    writetable(summary_rows, summary_csv);

    out = struct();
    out.mode = 'layered_suite';
    out.cfg = cfg;
    out.base = base;
    out.bundle = bundle;
    out.closure = closure;
    out.multih = multih;
    out.stack3d = stack3d;
    out.summary = summary_rows;
    out.files = struct();
    out.files.summary_csv = summary_csv;

    fprintf('\n');
    fprintf('================ Stage09 Layered Suite Summary ================\n');
    fprintf('run_tag            : %s\n', run_tag);
    fprintf('bundle master CSV  : %s\n', bundle.files.master_index_csv);
    fprintf('closure index CSV  : %s\n', closure.files.figure_index_csv);
    fprintf('multih status      : %s\n', string(local_skip_status(multih_skipped, multih_skip_reason)));
    fprintf('stack3d status     : %s\n', string(local_skip_status(stack3d_skipped, stack3d_skip_reason)));
    fprintf('suite summary CSV  : %s\n', summary_csv);
    fprintf('==============================================================\n');
    fprintf('\n');
end


function cache_dir = local_resolve_stage09_cache_dir(cfg)

    cache_dir = '';

    % Preferred: explicit stage09 cache fields, if present
    if isfield(cfg, 'paths') && isstruct(cfg.paths)
        if isfield(cfg.paths, 'outputs') && isstruct(cfg.paths.outputs)
            outputs = cfg.paths.outputs;

            candidate_fields = {'stage09_cache', 'cache_stage09'};
            for k = 1:numel(candidate_fields)
                f = candidate_fields{k};
                if isfield(outputs, f) && ~isempty(outputs.(f))
                    candidate = outputs.(f);
                    if isfolder(candidate)
                        cache_dir = candidate;
                        return;
                    end
                end
            end
        end
    end

    % Robust fallback: project-root-based canonical Stage09 cache dir
    startup_path = which('startup.m');
    if ~isempty(startup_path)
        project_root = fileparts(startup_path);
        candidate = fullfile(project_root, 'outputs', 'stage', 'stage09', 'cache');
        if isfolder(candidate)
            cache_dir = candidate;
            return;
        end
    end

    % Last fallback: generic cfg.paths.cache
    if isfield(cfg, 'paths') && isstruct(cfg.paths) && isfield(cfg.paths, 'cache')
        candidate = cfg.paths.cache;
        if isfolder(candidate)
            cache_dir = candidate;
            return;
        end
    end

    error('run_stage09_inverse_plot:Stage09CacheDirNotFound', ...
        'Cannot resolve Stage09 cache directory.');
end


function out = local_load_latest_cache(cache_dir, pattern1, pattern2)

    listing = dir(fullfile(cache_dir, pattern1));
    if isempty(listing)
        listing = dir(fullfile(cache_dir, pattern2));
    end
    if isempty(listing)
        error('run_stage09_inverse_plot:NoCacheMatched', ...
            'No cache matched patterns in %s : %s / %s', cache_dir, pattern1, pattern2);
    end

    [~, idx] = max([listing.datenum]);
    cache_file = fullfile(listing(idx).folder, listing(idx).name);

    fprintf('[run_stages] [layered_suite] load cache : %s\n', cache_file);

    S = load(cache_file);
    if ~isfield(S, 'out')
        error('run_stage09_inverse_plot:InvalidCache', ...
            'Invalid cache file (missing variable out): %s', cache_file);
    end
    out = S.out;
end


function h_count = local_get_h_count(cubes)
    h_count = 0;

    if ~isstruct(cubes) || ~isfield(cubes, 'index_tables') || ~isstruct(cubes.index_tables)
        return;
    end
    if ~isfield(cubes.index_tables, 'h')
        return;
    end

    htab = cubes.index_tables.h;
    if istable(htab)
        h_count = height(htab);
    else
        h_count = numel(htab);
    end
end


function s = local_struct_figure_index_csv(S)
    s = "";
    if isstruct(S) && isfield(S, 'files') && isstruct(S.files) && isfield(S.files, 'figure_index_csv')
        value = S.files.figure_index_csv;
        if isstring(value)
            s = value;
        elseif ischar(value)
            s = string(value);
        end
    end
end


function s = local_phase5_pack_csv(S)
    s = "";
    if isstruct(S) && isfield(S, 'joint') && isstruct(S.joint) ...
            && isfield(S.joint, 'files') && isstruct(S.joint.files) ...
            && isfield(S.joint.files, 'figure_index_csv')
        value = S.joint.files.figure_index_csv;
        if isstring(value)
            s = value;
        elseif ischar(value)
            s = string(value);
        end
    end
end


function status = local_skip_status(skipped, reason)
    if skipped
        status = "skipped:" + string(reason);
    else
        status = "enabled";
    end
end


function value = local_get_opt_logical(opts, field_name, default_value)
    value = default_value;
    if isstruct(opts) && isfield(opts, field_name) && ~isempty(opts.(field_name))
        value = logical(opts.(field_name));
    end
end


function value = local_get_opt_string(opts, field_name, default_value)
    value = string(default_value);
    if isstruct(opts) && isfield(opts, field_name) && ~isempty(opts.(field_name))
        value = string(opts.(field_name));
    end
    value = char(value);
end
