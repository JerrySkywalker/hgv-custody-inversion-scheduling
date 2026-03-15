function milestone_common_log(message, varargin)
%MILESTONE_COMMON_LOG Lightweight milestone console logger.

timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
if nargin < 1 || isempty(message)
    message = 'milestone event';
end
fprintf('[milestones][%s] %s\n', timestamp, sprintf(message, varargin{:}));
end
