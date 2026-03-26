function startup(varargin)
%LEGACY/STARTUP Initialize legacy project paths.
%
% Can be run in two modes:
% 1) Standalone, by entering legacy/ and calling startup
% 2) Delegated from root startup, reusing shared logger via appdata

opts = local_parse_options(varargin{:});

logger = [];
if isappdata(0, 'HGV_STARTUP_LOGGER')
    logger = getappdata(0, 'HGV_STARTUP_LOGGER');
elseif ~isempty(opts.logger)
    logger = opts.logger;
else
    logger = local_try_build_local_logger(opts);
end

enable_timing = opts.enable_timing;
if isappdata(0, 'HGV_STARTUP_ENABLE_TIMING')
    enable_timing = getappdata(0, 'HGV_STARTUP_ENABLE_TIMING');
end

legacy_root = fileparts(mfilename('fullpath'));

t_total = tic;
local_log(logger, 'INFO', '[legacy/startup] Initializing legacy paths.');
local_log(logger, 'INFO', '[legacy/startup] Project root: %s', legacy_root);

try
    t = tic;
    local_add_subtree_if_exists(legacy_root, logger);
    if enable_timing
        local_log(logger, 'INFO', '[legacy/startup] Add legacy subtree done in %.3f s.', toc(t));
    else
        local_log(logger, 'INFO', '[legacy/startup] Add legacy subtree done.');
    end

    local_log(logger, 'INFO', '[legacy/startup] Paths initialized successfully.');
    if enable_timing
        local_log(logger, 'INFO', '[legacy/startup] Initialization complete in %.3f s.', toc(t_total));
    else
        local_log(logger, 'INFO', '[legacy/startup] Initialization complete.');
    end

catch ME
    local_log(logger, 'ERROR', '[legacy/startup] Initialization failed: %s', ME.message);
    for k = 1:numel(ME.stack)
        local_log(logger, 'ERROR', '[legacy/startup]   at %s (%d)', ME.stack(k).name, ME.stack(k).line);
    end
    rethrow(ME);
end
end

function opts = local_parse_options(varargin)
p = inputParser;
addParameter(p, 'logger', [], @(x) isempty(x) || isstruct(x));
addParameter(p, 'enable_timing', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'enable_console', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'console_level', 'INFO', @(x) ischar(x) || isstring(x));
addParameter(p, 'enable_file_log', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'log_file', '', @(x) ischar(x) || isstring(x));
addParameter(p, 'use_color', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'color_mode', 'auto', @(x) ischar(x) || isstring(x));
parse(p, varargin{:});
opts = p.Results;
end

function logger = local_try_build_local_logger(opts)
logger = [];
try
    if exist('make_logger', 'file') ~= 2
        return;
    end
    cfg = struct();
    cfg.enable_console = logical(opts.enable_console);
    cfg.console_level = char(string(opts.console_level));
    cfg.enable_file = logical(opts.enable_file_log);
    cfg.use_color = logical(opts.use_color);
    cfg.color_mode = char(string(opts.color_mode));
    if ~isempty(opts.log_file)
        cfg.file_path = char(string(opts.log_file));
    end
    logger = make_logger(cfg);
catch
    logger = [];
end
end

function local_add_subtree_if_exists(root_dir, logger)
if exist(root_dir, 'dir') == 7
    addpath(genpath(root_dir));
    local_log(logger, 'DEBUG', '[legacy/startup] Added path subtree: %s', root_dir);
else
    local_log(logger, 'WARN', '[legacy/startup] Path subtree not found: %s', root_dir);
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
