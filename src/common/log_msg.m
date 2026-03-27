function log_msg(log_fid, level, msg, varargin)
%LOG_MSG Backward-compatible logging shim.
%
% Legacy signature:
%   log_msg(log_fid, level, msg, varargin{:})
%
% New behavior:
%   - If project logger is initialized, route message through project_log
%   - Preserve optional legacy file write to log_fid
%   - If project logger is not initialized, fall back to old screen/file behavior

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
        % New unified logging path
        project_log(level, msg, varargin{:});

        % Preserve legacy file sink if caller still passes log_fid
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

    % Fallback to legacy behavior if project logger is unavailable
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
