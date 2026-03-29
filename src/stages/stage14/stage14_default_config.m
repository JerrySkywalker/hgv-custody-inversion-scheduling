function cfg = stage14_default_config(base_cfg, overrides)
%STAGE14_DEFAULT_CONFIG Build Stage14 mainline default config.
%
% Mainline Stage14.1 positioning:
%   - this is the "Stage05-upgraded" mainline
%   - keep Walker intrinsic parameters fixed at (h,i,P,T,F_ref)
%   - only expand over relative RAAN/orientation variable
%   - preserve Stage05-compatible DG-only pass criterion
%
% Current scope:
%   - openD / DG-only
%   - raw grid scan over (i,P,T,RAAN)
%   - optional explicit PT pair list
%   - no Ns-envelope yet
%   - no joint (F,RAAN) expansion yet

    if nargin < 1 || isempty(base_cfg)
        cfg = default_params();
    else
        cfg = base_cfg;
    end
    if nargin < 2 || isempty(overrides)
        overrides = struct();
    end

    existing_stage14 = struct();
    if isfield(cfg, 'stage14') && isstruct(cfg.stage14)
        existing_stage14 = cfg.stage14;
    end

    cfg.stage14 = struct();
    cfg.stage14.stage_name = 'stage14';
    cfg.stage14.mode = 'openD_mainline_raan';
    cfg.stage14.family_scope = 'nominal';
    cfg.stage14.gamma_source = 'stage04_nominal_quantile';

    % Inherit Stage05 search domain
    cfg.stage14.h_fixed_km = cfg.stage05.h_fixed_km;
    cfg.stage14.F_fixed = cfg.stage05.F_fixed;
    cfg.stage14.i_grid_deg = cfg.stage05.i_grid_deg;
    cfg.stage14.P_grid = cfg.stage05.P_grid;
    cfg.stage14.T_grid = cfg.stage05.T_grid;

    % New optional explicit PT pair list:
    %   each row is [P, T]
    %   if non-empty, build_stage14_search_grid should use this instead of P_grid x T_grid
    cfg.stage14.PT_pairs = [];

    % New outer variable: relative RAAN/orientation
    cfg.stage14.RAAN_scan_deg = 0:30:330;

    % DG-only threshold policy: same as Stage05
    cfg.stage14.require_pass_ratio = cfg.stage05.require_pass_ratio;
    cfg.stage14.require_D_G_min = cfg.stage05.require_D_G_min;
    cfg.stage14.rank_rule = cfg.stage05.rank_rule;

    % Execution controls
    cfg.stage14.use_parallel = false;
    cfg.stage14.auto_start_pool = true;
    cfg.stage14.parallel_pool_profile = 'local';
    cfg.stage14.parallel_num_workers = [];
    cfg.stage14.prefer_thread_pool_for_batch = true;
    cfg.stage14.use_live_progress = true;
    cfg.stage14.progress_every = 10;
    cfg.stage14.parallel = struct();
    cfg.stage14.parallel.enable = cfg.stage14.use_parallel;
    cfg.stage14.parallel.prefer_threads = strcmpi(cfg.stage14.parallel_pool_profile, 'threads');
    cfg.stage14.parallel.max_workers = cfg.stage14.parallel_num_workers;
    cfg.stage14.parallel.progress_every = cfg.stage14.progress_every;
    cfg.stage14.use_early_stop = cfg.stage05.use_early_stop;
    cfg.stage14.hard_case_first = cfg.stage05.hard_case_first;
    cfg.stage14.case_limit = inf;

    % Output controls
    cfg.stage14.save_cache = true;
    cfg.stage14.save_table = true;
    cfg.stage14.make_plot = false;

    % Merge existing + overrides
    cfg.stage14 = local_merge_struct(cfg.stage14, existing_stage14);
    cfg.stage14 = local_merge_struct(cfg.stage14, overrides);

    % Normalize vectors
    cfg.stage14.i_grid_deg = reshape(cfg.stage14.i_grid_deg, 1, []);
    cfg.stage14.P_grid = reshape(cfg.stage14.P_grid, 1, []);
    cfg.stage14.T_grid = reshape(cfg.stage14.T_grid, 1, []);
    cfg.stage14.RAAN_scan_deg = reshape(cfg.stage14.RAAN_scan_deg, 1, []);

    has_override_parallel = isfield(overrides, 'parallel') && isstruct(overrides.parallel);
    if has_override_parallel
        if ~isfield(overrides, 'use_parallel') && isfield(overrides.parallel, 'enable')
            cfg.stage14.use_parallel = logical(overrides.parallel.enable);
        end
        if ~isfield(overrides, 'parallel_pool_profile') && isfield(overrides.parallel, 'prefer_threads')
            if logical(overrides.parallel.prefer_threads)
                cfg.stage14.parallel_pool_profile = 'threads';
            else
                cfg.stage14.parallel_pool_profile = 'local';
            end
        end
        if ~isfield(overrides, 'parallel_num_workers') && isfield(overrides.parallel, 'max_workers')
            cfg.stage14.parallel_num_workers = overrides.parallel.max_workers;
        end
        if ~isfield(overrides, 'progress_every') && isfield(overrides.parallel, 'progress_every')
            cfg.stage14.progress_every = overrides.parallel.progress_every;
        end
    end

    if ~isfield(cfg.stage14, 'parallel') || ~isstruct(cfg.stage14.parallel)
        cfg.stage14.parallel = struct();
    end

    if ~isfield(cfg.stage14, 'use_parallel') || isempty(cfg.stage14.use_parallel)
        if isfield(cfg.stage14.parallel, 'enable') && ~isempty(cfg.stage14.parallel.enable)
            cfg.stage14.use_parallel = logical(cfg.stage14.parallel.enable);
        else
            cfg.stage14.use_parallel = false;
        end
    end
    cfg.stage14.use_parallel = logical(cfg.stage14.use_parallel);

    if ~isfield(cfg.stage14, 'auto_start_pool') || isempty(cfg.stage14.auto_start_pool)
        cfg.stage14.auto_start_pool = true;
    end
    cfg.stage14.auto_start_pool = logical(cfg.stage14.auto_start_pool);

    if ~isfield(cfg.stage14, 'parallel_pool_profile') || isempty(cfg.stage14.parallel_pool_profile)
        if isfield(cfg.stage14.parallel, 'prefer_threads') && ~isempty(cfg.stage14.parallel.prefer_threads) && logical(cfg.stage14.parallel.prefer_threads)
            cfg.stage14.parallel_pool_profile = 'threads';
        else
            cfg.stage14.parallel_pool_profile = 'local';
        end
    end
    cfg.stage14.parallel_pool_profile = char(string(cfg.stage14.parallel_pool_profile));

    if ~isfield(cfg.stage14, 'parallel_num_workers')
        if isfield(cfg.stage14.parallel, 'max_workers')
            cfg.stage14.parallel_num_workers = cfg.stage14.parallel.max_workers;
        else
            cfg.stage14.parallel_num_workers = [];
        end
    end

    if isempty(cfg.stage14.parallel_num_workers)
        cfg.stage14.parallel_num_workers = [];
    else
        assert(isnumeric(cfg.stage14.parallel_num_workers) && isscalar(cfg.stage14.parallel_num_workers) && ...
            isfinite(cfg.stage14.parallel_num_workers) && cfg.stage14.parallel_num_workers >= 1, ...
            'cfg.stage14.parallel_num_workers must be empty or a finite scalar >= 1.');
        cfg.stage14.parallel_num_workers = round(cfg.stage14.parallel_num_workers);
    end

    if ~isfield(cfg.stage14, 'prefer_thread_pool_for_batch') || isempty(cfg.stage14.prefer_thread_pool_for_batch)
        cfg.stage14.prefer_thread_pool_for_batch = true;
    end
    cfg.stage14.prefer_thread_pool_for_batch = logical(cfg.stage14.prefer_thread_pool_for_batch);

    if ~isfield(cfg.stage14, 'use_live_progress') || isempty(cfg.stage14.use_live_progress)
        cfg.stage14.use_live_progress = true;
    end
    cfg.stage14.use_live_progress = logical(cfg.stage14.use_live_progress);

    cfg.stage14.parallel.enable = cfg.stage14.use_parallel;
    cfg.stage14.progress_every = local_validate_positive_integer(cfg.stage14.progress_every, 10, 'cfg.stage14.progress_every');
    cfg.stage14.parallel.prefer_threads = strcmpi(cfg.stage14.parallel_pool_profile, 'threads');
    cfg.stage14.parallel.max_workers = cfg.stage14.parallel_num_workers;
    cfg.stage14.parallel.progress_every = cfg.stage14.progress_every;

    % Normalize PT_pairs
    if isempty(cfg.stage14.PT_pairs)
        cfg.stage14.PT_pairs = [];
    else
        assert(isnumeric(cfg.stage14.PT_pairs) && size(cfg.stage14.PT_pairs,2) == 2, ...
            'cfg.stage14.PT_pairs must be an N-by-2 numeric matrix [P, T].');
    end
end

function out = local_merge_struct(base, patch)
    out = base;
    if nargin < 2 || isempty(patch) || ~isstruct(patch)
        return;
    end

    fn = fieldnames(patch);
    for k = 1:numel(fn)
        key = fn{k};
        val = patch.(key);
        if isstruct(val) && isfield(out, key) && isstruct(out.(key))
            out.(key) = local_merge_struct(out.(key), val);
        else
            out.(key) = val;
        end
    end
end

function value = local_validate_positive_integer(value, fallback, label)
    if nargin < 2 || isempty(fallback)
        fallback = 1;
    end
    if nargin < 3 || isempty(label)
        label = 'value';
    end

    if isempty(value)
        value = fallback;
    end

    assert(isnumeric(value) && isscalar(value) && isfinite(value) && value >= 1, ...
        '%s must be a finite scalar >= 1.', label);
    value = round(value);
end
