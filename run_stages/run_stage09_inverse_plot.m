%% run_stage09_inverse_plot.m
% 一键运行 Stage09 作图部分
%
% 双模式：
%   1) legacy10      -> 旧 Stage09.6 十图导出
%   2) layered_suite -> 新分层图谱导出
%
% 当前 layered_suite 设计：
%   - run_stage09_inverse_plot 只负责：
%       1) 读取 Stage09 cache
%       2) 构造 base
%       3) 调用 master bundle dispatcher
%
%   - plot_stage09_bundle_all_packs 负责：
%       1) DG/DA/DT/joint packs
%       2) closure heatmaps
%       3) multih heatmaps
%       4) phase5 stack3d
%       5) 统一 master index / suite summary

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

    fprintf('[run_stages] === Stage09 作图入口 ===\n');
    fprintf('[run_stages] scheme_type : %s\n', string(cfg.stage09.scheme_type));
    fprintf('[run_stages] run_tag     : %s\n', string(cfg.stage09.run_tag));
    fprintf('[run_stages] plot_mode   : %s\n', string(plot_mode));

    switch lower(plot_mode)
        case 'legacy10'
            out = stage09_plot_inverse_design_results([], [], cfg);

        case 'layered_suite'
            out = local_run_layered_suite(cfg, opts);

        otherwise
            error('run_stage09_inverse_plot:UnknownPlotMode', ...
                'Unknown opts.stage09_plot_mode = %s', string(plot_mode));
    end

    fprintf('[run_stages] === Stage09 作图完成 ===\n');
end


function out = local_run_layered_suite(cfg, opts)

    run_tag = char(string(cfg.stage09.run_tag));

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

    bundle_opts = struct();
    bundle_opts.enable_closure_heatmaps = local_get_opt_logical(opts, 'stage09_enable_closure_heatmaps', true);
    bundle_opts.enable_multih_heatmaps  = local_get_opt_logical(opts, 'stage09_enable_multih', true);
    bundle_opts.enable_stack3d          = local_get_opt_logical(opts, 'stage09_enable_stack3d', false);

    fprintf('[run_stages] [layered_suite] call master bundle dispatcher...\n');
    bundle = plot_stage09_bundle_all_packs(base, 'run_stage09_inverse_plot', bundle_opts);

    out = struct();
    out.mode = 'layered_suite';
    out.cfg = cfg;
    out.base = base;

    % Compatibility aliases
    out.bundle = bundle;
    out.closure = bundle.closure;
    out.multih = bundle.multih;
    out.stack3d = bundle.stack3d;
    out.summary = bundle.summary;

    out.files = struct();
    out.files.summary_csv = bundle.files.summary_csv;
    out.files.pack_index_csv = bundle.files.pack_index_csv;
    out.files.master_index_csv = bundle.files.master_index_csv;

    fprintf('\n');
    fprintf('================ Stage09 Layered Suite Summary ================\n');
    fprintf('run_tag            : %s\n', run_tag);
    fprintf('bundle master CSV  : %s\n', bundle.files.master_index_csv);
    fprintf('suite summary CSV  : %s\n', bundle.files.summary_csv);
    fprintf('==============================================================\n');
    fprintf('\n');
end


function cache_dir = local_resolve_stage09_cache_dir(cfg)

    cache_dir = '';

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

    startup_path = which('startup.m');
    if ~isempty(startup_path)
        project_root = fileparts(startup_path);
        candidate = fullfile(project_root, 'outputs', 'stage', 'stage09', 'cache');
        if isfolder(candidate)
            cache_dir = candidate;
            return;
        end
    end

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
