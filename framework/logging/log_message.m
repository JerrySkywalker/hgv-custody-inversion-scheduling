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

level_tag = local_level_tag(level);
line_plain = sprintf('[%s][%s] %s', timestamp, level_tag, plain_msg);

% console
if logger.enable_console
    switch lower(string(logger.color_backend))
        case "cprintf"
            try
                cprintf(local_cprintf_style(level), '%s\n', line_plain);
            catch ME
                fprintf('[log_message][WARN ] cprintf failed, fallback to plain text: %s\n', ME.message);
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

function tag = local_level_tag(level)
switch upper(string(level))
    case "DEBUG"
        tag = 'DEBUG';
    case "INFO"
        tag = 'INFO ';
    case "WARN"
        tag = 'WARN ';
    case "ERROR"
        tag = 'ERROR';
    otherwise
        s = upper(char(string(level)));
        if strlength(string(s)) < 5
            tag = char(pad(string(s), 5, 'right'));
        else
            tag = s;
        end
end
end

function style = local_cprintf_style(level)
switch upper(string(level))
    case "DEBUG"
        style = 'Comments';
    case "INFO"
        style = 'Text';
    case "WARN"
        style = 'SystemCommands';
    case "ERROR"
        style = '*Errors';
    otherwise
        style = 'Text';
end
end

function out = local_apply_ansi_color(text_in, level)
switch upper(string(level))
    case "DEBUG"
        code = '32'; % green
    case "INFO"
        code = '37'; % white
    case "WARN"
        code = '33'; % yellow
    case "ERROR"
        code = '31'; % red
    otherwise
        code = '';
end

if isempty(code)
    out = text_in;
else
    out = sprintf('\x1b[%sm%s\x1b[0m', code, text_in);
end
end
