function log_message(logger, level, msg, varargin)
if nargin < 1 || isempty(logger) || ~isfield(logger, 'log')
    return;
end
logger.log(level, msg, varargin{:});
end
