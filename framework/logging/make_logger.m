function logger = make_logger(opts)
if nargin < 1 || isempty(opts)
    opts = struct();
end

if ~isfield(opts, 'console_level'), opts.console_level = 'INFO'; end
if ~isfield(opts, 'file_level'), opts.file_level = 'DEBUG'; end
if ~isfield(opts, 'enable_console'), opts.enable_console = true; end
if ~isfield(opts, 'enable_file'), opts.enable_file = false; end
if ~isfield(opts, 'file_path'), opts.file_path = ''; end

logger = struct();
logger.opts = opts;
logger.log = @(level, msg, varargin) local_log(opts, level, msg, varargin{:});
end

function local_log(opts, level, msg, varargin)
timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
level = upper(string(level));
text = sprintf(msg, varargin{:});
line = sprintf('[%s][%s] %s', timestamp, level, text);

if opts.enable_console && should_log(level, opts.console_level)
    fprintf('%s\n', line);
end

if opts.enable_file && strlength(string(opts.file_path)) > 0 && should_log(level, opts.file_level)
    fid = fopen(opts.file_path, 'a');
    if fid ~= -1
        fprintf(fid, '%s\n', line);
        fclose(fid);
    end
end
end
