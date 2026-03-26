function log_message(logger, level, fmt, varargin)
%LOG_MESSAGE Write a formatted log message to console/file.

if nargin < 3
    return;
end

level = upper(char(string(level)));

% Decide log gating conservatively.
do_log = true;
try
    do_log = should_log(logger, level);
catch ME
    fprintf('[log_message][WARN] should_log failed: %s\n', ME.message);
    do_log = true;
end

if ~do_log
    return;
end

timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');

try
    plain_msg = sprintf(fmt, varargin{:});
catch ME
    plain_msg = sprintf('[log_message format error] %s | fmt=%s', ME.message, fmt);
end

line_plain = sprintf('[%s][%s] %s', timestamp, level, plain_msg);

% Console branch
try
    enable_console = true;
    if isstruct(logger) && isfield(logger, 'enable_console') && ~isempty(logger.enable_console)
        enable_console = logical(logger.enable_console);
    end

    if enable_console
        line_console = line_plain;
        try
            line_console = local_apply_color(line_plain, level, logger);
        catch
            line_console = line_plain;
        end
        fprintf('%s\n', line_console);
    end
catch ME
    fprintf('[log_message][ERROR] console logging failed: %s\n', ME.message);
    fprintf('%s\n', line_plain);
end

% File branch
try
    enable_file = false;
    file_path = '';

    if isstruct(logger) && isfield(logger, 'enable_file') && ~isempty(logger.enable_file)
        enable_file = logical(logger.enable_file);
    end
    if isstruct(logger) && isfield(logger, 'file_path') && ~isempty(logger.file_path)
        file_path = char(string(logger.file_path));
    end

    if enable_file && ~isempty(file_path)
        file_dir = fileparts(file_path);
        if ~isempty(file_dir) && exist(file_dir, 'dir') ~= 7
            mkdir(file_dir);
        end

        fid = fopen(file_path, 'a');
        if fid ~= -1
            fprintf(fid, '%s\n', line_plain);
            fclose(fid);
        else
            fprintf('[log_message][ERROR] failed to open log file: %s\n', file_path);
        end
    end
catch ME
    fprintf('[log_message][ERROR] file logging failed: %s\n', ME.message);
end
end

function out = local_apply_color(text_in, level, logger)
out = text_in;

if ~isstruct(logger) || ~isfield(logger, 'use_color') || ~logger.use_color
    return;
end

mode = 'auto';
if isfield(logger, 'color_mode') && ~isempty(logger.color_mode)
    mode = char(string(logger.color_mode));
end

if strcmpi(mode, 'never')
    return;
end

% Stay conservative in auto mode for MATLAB command window.
if strcmpi(mode, 'auto')
    return;
end

color_code = local_level_color(level);
if isempty(color_code)
    return;
end

out = sprintf('\x1b[%sm%s\x1b[0m', color_code, text_in);
end

function code = local_level_color(level)
switch upper(string(level))
    case "DEBUG"
        code = '36'; % cyan
    case "INFO"
        code = '32'; % green
    case "WARN"
        code = '33'; % yellow
    case "ERROR"
        code = '31'; % red
    otherwise
        code = '';
end
end
