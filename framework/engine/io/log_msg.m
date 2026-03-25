function log_msg(log_fid, level, msg, varargin)
%LOG_MSG Print a timestamped message to console and optional file handle.
% Inputs:
%   log_fid : file id, or [] to disable file logging
%   level   : message level label, e.g. 'INFO'
%   msg     : sprintf-style message template

if nargin < 3
    error('log_msg requires at least log_fid, level, and msg.');
end

timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
body = sprintf(msg, varargin{:});
line = sprintf('[%s][%s] %s\n', timestamp, upper(level), body);

fprintf('%s', line);

if ~isempty(log_fid) && isnumeric(log_fid) && log_fid > 0
    fprintf(log_fid, '%s', line);
    try
        fflush(log_fid);
    catch
    end
end
end
