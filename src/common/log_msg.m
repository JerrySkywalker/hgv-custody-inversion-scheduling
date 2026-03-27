function log_msg(log_fid, level, msg, varargin)
%LOG_MSG Backward-compatible logging shim.
%
% Legacy signature:
%   log_msg(log_fid, level, msg, varargin{:})
%
% Behavior:
%   - If project logger is initialized, route to project_log(...)
%   - Preserve legacy file sink via log_fid when provided
%   - If project logger is unavailable, fall back to legacy screen/file output

    if nargin < 3
        error('log_msg requires at least log_fid, level, and msg.');
    end

    logger = [];
    try
        logger = get_project_logger();
    catch
        logger = [];
    end

    if ~isempty(logger)
        % Unified logging path: console + session file
        project_log(level, msg, varargin{:});

        % Preserve explicit legacy file sink if caller still passes fid
        if ~isempty(log_fid) && isnumeric(log_fid) && log_fid > 0
            timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
            body = sprintf(msg, varargin{:});
            line = sprintf('[%s][%s] %s\n', timestamp, upper(char(string(level))), body);
            fprintf(log_fid, '%s', line);
            try
                fflush(log_fid);
            catch
            end
        end

        return;
    end

    % Fallback to legacy behavior if project logger not initialized
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    body = sprintf(msg, varargin{:});
    line = sprintf('[%s][%s] %s\n', timestamp, upper(char(string(level))), body);

    fprintf('%s', line);

    if ~isempty(log_fid) && isnumeric(log_fid) && log_fid > 0
        fprintf(log_fid, '%s', line);
        try
            fflush(log_fid);
        catch
        end
    end
end
