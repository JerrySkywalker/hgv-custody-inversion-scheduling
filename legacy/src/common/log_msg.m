function log_msg(log_fid, level, msg, varargin)
    %LOG_MSG Write formatted log message to screen and file.
    %
    % Usage:
    %   log_msg(fid, 'INFO', 'value = %d', 3);
    
    if nargin < 3
        error('log_msg requires at least log_fid, level, and msg.');
    end
    
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    body = sprintf(msg, varargin{:});
    line = sprintf('[%s][%s] %s\n', timestamp, upper(level), body);
    
    % print to screen
    fprintf('%s', line);
    
    % print to file if valid
    if ~isempty(log_fid) && isnumeric(log_fid) && log_fid > 0
        fprintf(log_fid, '%s', line);
        % force flush so that log file is updated in real time
        try
            fflush(log_fid);
        catch
            % ignore flush errors to avoid breaking main flow
        end
    end
end