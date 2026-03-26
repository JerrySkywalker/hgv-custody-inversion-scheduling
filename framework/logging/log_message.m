function log_message(logger, level, fmt, varargin)
%LOG_MESSAGE Write a formatted log message to console/file.

if nargin < 3
    return;
end

level = upper(char(string(level)));

do_log = true;
try
    do_log = should_log(logger, level);
catch
    do_log = true;
end

if ~do_log
    return;
end

timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
plain_msg = sprintf(fmt, varargin{:});
line_plain = sprintf('[%s][%s] %s', timestamp, level, plain_msg);

% console
if logger.enable_console
    switch lower(string(logger.color_backend))
        case "cprintf"
            try
                cprintf(local_cprintf_style(level), '%s\n', line_plain);
            catch ME
                fprintf('[log_message][WARN] cprintf failed, fallback to plain text: %s\n', ME.message);
                fprintf('%s\n', line_plain);
            end

        case "ansi"
            fprintf('%s\n', local_apply_ansi_color(line_plain, level));

        otherwise
            fprintf('%s\n', line_plain);
    end
end

% file
if logger.enable_file && ~isempty(logger.file_path)
    fid = fopen(logger.file_path, 'a');
    if fid ~= -1
        fprintf(fid, '%s\n', line_plain);
        fclose(fid);
    end
end
end

function style = local_cprintf_style(level)
switch upper(string(level))
    case "DEBUG"
        style = [0, 0.5, 0.5];
    case "INFO"
        style = [0, 0.5, 0];
    case "WARN"
        style = [0.85, 0.55, 0];
    case "ERROR"
        style = [1, 0, 0];
    otherwise
        style = [0, 0, 0];
end
end

function out = local_apply_ansi_color(text_in, level)
switch upper(string(level))
    case "DEBUG"
        code = '36';
    case "INFO"
        code = '32';
    case "WARN"
        code = '33';
    case "ERROR"
        code = '31';
    otherwise
        code = '';
end

if isempty(code)
    out = text_in;
else
    out = sprintf('\x1b[%sm%s\x1b[0m', code, text_in);
end
end
