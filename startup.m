function startup(varargin)
%STARTUP Initialize project paths with unified logger + timing.
%
% Examples:
%   startup
%   startup('enable_file_log', true)
%   startup('console_level', 'DEBUG')
%   startup('force_reinit', true)
%   logger = make_logger(struct('enable_console', true, 'console_level', 'INFO'));
%   startup('logger', logger)

persistent STARTUP_STATE

opts = local_parse_options(varargin{:});
repo_root = local_find_repo_root();

% Ensure logger functions are reachable before building logger.
local_bootstrap_logging_path(repo_root);

logger = local_build_logger(repo_root, opts);

if ~isempty(STARTUP_STATE) && isfield(STARTUP_STATE, 'initialized') && STARTUP_STATE.initialized ...
        && isfield(STARTUP_STATE, 'repo_root') && strcmpi(STARTUP_STATE.repo_root, repo_root) ...
        && ~opts.force_reinit
    local_log(logger, 'WARN', '[startup] Already initialized. Root: %s', repo_root);
    local_log(logger, 'WARN', '[startup] Skipping repeated initialization.');
    return;
end

t_total = tic;
local_log(logger, 'INFO', '[startup] Initializing project paths.');

try
    t = local_stage_begin(logger, 'Resolve repository root');
    local_log(logger, 'INFO', '[startup] Repository root: %s', repo_root);
    local_stage_end(logger, 'Resolve repository root', t, opts.enable_timing);

    t = local_stage_begin(logger, 'Add framework paths');
    local_add_subtree_if_exists(fullfile(repo_root, 'framework'), logger);
    local_stage_end(logger, 'Add framework paths', t, opts.enable_timing);

    t = local_stage_begin(logger, 'Add experiments paths');
    local_add_subtree_if_exists(fullfile(repo_root, 'experiments'), logger);
    local_stage_end(logger, 'Add experiments paths', t, opts.enable_timing);

    t = local_stage_begin(logger, 'Add tests paths');
    local_add_subtree_if_exists(fullfile(repo_root, 'tests'), logger);
    local_stage_end(logger, 'Add tests paths', t, opts.enable_timing);

    t = local_stage_begin(logger, 'Add tools paths');
    local_add_subtree_if_exists(fullfile(repo_root, 'tools'), logger);
    local_stage_end(logger, 'Add tools paths', t, opts.enable_timing);

    t = local_stage_begin(logger, 'Delegate to legacy startup');
    legacy_startup = fullfile(repo_root, 'legacy', 'startup.m');
    if exist(legacy_startup, 'file') == 2
        run(legacy_startup);
    else
        local_log(logger, 'WARN', '[startup] legacy/startup.m not found: %s', legacy_startup);
    end
    local_stage_end(logger, 'Delegate to legacy startup', t, opts.enable_timing);

    STARTUP_STATE = struct();
    STARTUP_STATE.initialized = true;
    STARTUP_STATE.repo_root = repo_root;
    STARTUP_STATE.initialized_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');

    local_log(logger, 'INFO', '[startup] Paths initialized successfully.');
    if opts.enable_timing
        local_log(logger, 'INFO', '[startup] Initialization complete in %.3f s', toc(t_total));
    else
        local_log(logger, 'INFO', '[startup] Initialization complete.');
    end

catch ME
    local_log(logger, 'ERROR', '[startup] Initialization failed: %s', ME.message);
    for k = 1:numel(ME.stack)
        local_log(logger, 'ERROR', '[startup]   at %s (%d)', ME.stack(k).name, ME.stack(k).line);
    end
    rethrow(ME);
end
end

function opts = local_parse_options(varargin)
p = inputParser;
addParameter(p, 'logger', [], @(x) isempty(x) || isstruct(x));
addParameter(p, 'enable_console', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'console_level', 'INFO', @(x) ischar(x) || isstring(x));
addParameter(p, 'enable_file_log', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'log_file', '', @(x) ischar(x) || isstring(x));
addParameter(p, 'enable_timing', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'force_reinit', false, @(x) islogical(x) || isnumeric(x));
parse(p, varargin{:});
opts = p.Results;
end

function repo_root = local_find_repo_root()
this_file = mfilename('fullpath');
if isempty(this_file)
    error('startup:CannotResolvePath', 'Cannot resolve startup.m full path.');
end
repo_root = fileparts(this_file);
end

function local_bootstrap_logging_path(repo_root)
logging_dir = fullfile(repo_root, 'framework', 'logging');
if exist(logging_dir, 'dir') == 7
    if ~contains(path, [logging_dir pathsep]) && ~endsWith(path, logging_dir)
        addpath(logging_dir);
    end
end
end

function logger = local_build_logger(repo_root, opts)
if ~isempty(opts.logger)
    logger = opts.logger;
    return;
end

logger = [];
try
    if exist('make_logger', 'file') ~= 2
        return;
    end

    log_file = char(string(opts.log_file));
    if logical(opts.enable_file_log) && isempty(log_file)
        log_dir = fullfile(repo_root, 'outputs', 'logs', 'startup');
        if exist(log_dir, 'dir') ~= 7
            mkdir(log_dir);
        end
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        log_file = fullfile(log_dir, sprintf('startup_%s.log', timestamp));
    end

    logger_cfg = struct();
    logger_cfg.enable_console = logical(opts.enable_console);
    logger_cfg.console_level = char(string(opts.console_level));
    logger_cfg.enable_file = logical(opts.enable_file_log);
    if ~isempty(log_file)
        logger_cfg.file_path = log_file;
    end

    logger = make_logger(logger_cfg);
catch
    logger = [];
end
end

function t = local_stage_begin(logger, stage_name)
t = tic;
local_log(logger, 'INFO', '[startup] %s.', stage_name);
end

function local_stage_end(logger, stage_name, t, enable_timing)
if enable_timing
    local_log(logger, 'INFO', '[startup] %s done in %.3f s.', stage_name, toc(t));
else
    local_log(logger, 'INFO', '[startup] %s done.', stage_name);
end
end

function local_add_subtree_if_exists(root_dir, logger)
if exist(root_dir, 'dir') == 7
    addpath(genpath(root_dir));
    local_log(logger, 'DEBUG', '[startup] Added path subtree: %s', root_dir);
else
    local_log(logger, 'WARN', '[startup] Path subtree not found: %s', root_dir);
end
end

function local_log(logger, level, fmt, varargin)
try
    if ~isempty(logger) && exist('log_message', 'file') == 2
        log_message(logger, level, fmt, varargin{:});
    else
        fprintf([fmt '\n'], varargin{:});
    end
catch
    fprintf([fmt '\n'], varargin{:});
end
end
