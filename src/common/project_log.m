function project_log(level, fmt, varargin)
%PROJECT_LOG Unified project logging entry.
%
% Usage:
%   project_log('INFO', 'hello %s', name)

    if nargin < 2
        error('project_log:InvalidInput', ...
            'Expected at least level and fmt.');
    end

    logger = get_project_logger();

    if isempty(logger)
        % Fallback: no logger initialized yet
        fprintf('[%s] ', upper(char(level)));
        fprintf([fmt '\n'], varargin{:});
        return;
    end

    log_message(logger, upper(char(level)), fmt, varargin{:});
end
