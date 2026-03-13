function [cfg, stage_opts, mode] = rs_apply_parallel_policy(stage_name, cfg, opts, mode_override)
%RS_APPLY_PARALLEL_POLICY Apply centralized serial/parallel defaults.
%
% The run_stages wrappers and benchmark entrypoints call this helper so the
% default execution mode for each stage is controlled in one place.

    if nargin < 2 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 3 || isempty(opts)
        opts = struct();
    end
    if nargin < 4
        mode_override = '';
    end

    stage_key = lower(char(string(stage_name)));
    default_modes = local_default_modes();
    mode = default_modes.(stage_key);

    forced_mode = local_normalize_mode(mode_override);
    if ~isempty(forced_mode)
        mode = forced_mode;
    else
        override_mode = local_get_override_mode(stage_key, cfg, opts);
        if ~isempty(override_mode)
            mode = override_mode;
        end
    end

    if ~isfield(cfg, 'run_stages') || ~isstruct(cfg.run_stages)
        cfg.run_stages = struct();
    end
    if ~isfield(cfg.run_stages, 'parallel_modes') || ~isstruct(cfg.run_stages.parallel_modes)
        cfg.run_stages.parallel_modes = struct();
    end
    cfg.run_stages.parallel_modes.(stage_key) = mode;

    stage_opts = struct('mode', mode);

    switch stage_key
        case {'stage00', 'stage01', 'stage02', 'stage03'}
            parallel_cfg = local_get_parallel_config(cfg, stage_key);
            if ~isempty(parallel_cfg)
                stage_opts.parallel_config = parallel_cfg;
            end

        case 'stage04'
            cfg.stage04.use_parallel = strcmp(mode, 'parallel');

        case 'stage05'
            cfg.stage05.use_parallel = strcmp(mode, 'parallel');

        case 'stage06'
            cfg.stage06.use_parallel = strcmp(mode, 'parallel');

        case 'stage07'
            cfg.stage07.use_parallel = strcmp(mode, 'parallel');

        case 'stage08'
            use_parallel = strcmp(mode, 'parallel');
            cfg.stage08.smallgrid.use_parallel = use_parallel;
            cfg.stage08c.use_parallel = use_parallel;
    end
end


function modes = local_default_modes()
    modes = struct( ...
        'stage00', 'serial', ...
        'stage01', 'serial', ...
        'stage02', 'serial', ...
        'stage03', 'parallel', ...
        'stage04', 'serial', ...
        'stage05', 'serial', ...
        'stage06', 'serial', ...
        'stage07', 'serial', ...
        'stage08', 'serial', ...
        'stage09', 'serial', ...
        'stage10', 'serial');
end


function mode = local_get_override_mode(stage_key, cfg, opts)
    mode = '';

    if isfield(opts, 'parallel_modes') && isstruct(opts.parallel_modes) ...
            && isfield(opts.parallel_modes, stage_key)
        mode = local_normalize_mode(opts.parallel_modes.(stage_key));
        if ~isempty(mode)
            return;
        end
    end

    if isfield(cfg, 'run_stages') && isstruct(cfg.run_stages) ...
            && isfield(cfg.run_stages, 'parallel_modes') ...
            && isstruct(cfg.run_stages.parallel_modes) ...
            && isfield(cfg.run_stages.parallel_modes, stage_key)
        mode = local_normalize_mode(cfg.run_stages.parallel_modes.(stage_key));
    end
end


function mode = local_normalize_mode(value)
    mode = '';
    token = lower(strtrim(char(string(value))));
    switch token
        case {'serial', 's', 'off', 'false', '0'}
            mode = 'serial';
        case {'parallel', 'p', 'on', 'true', '1'}
            mode = 'parallel';
    end
end


function parallel_cfg = local_get_parallel_config(cfg, stage_key)
    parallel_cfg = [];

    if isfield(cfg, stage_key) && isstruct(cfg.(stage_key)) ...
            && isfield(cfg.(stage_key), 'parallel') ...
            && isstruct(cfg.(stage_key).parallel)
        parallel_cfg = cfg.(stage_key).parallel;
    end
end
