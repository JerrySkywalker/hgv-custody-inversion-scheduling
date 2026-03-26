function tf = should_log(logger, level)
%SHOULD_LOG Decide whether a message at LEVEL should be emitted.

tf = false;

if nargin < 2 || isempty(level)
    return;
end

level = upper(char(string(level)));

if isempty(logger) || ~isstruct(logger)
    tf = true;
    return;
end

if ~isfield(logger, 'level_rank') || isempty(logger.level_rank)
    tf = true;
    return;
end

if ~isfield(logger.level_rank, level)
    tf = true;
    return;
end

threshold = 'INFO';
if isfield(logger, 'console_level') && ~isempty(logger.console_level)
    threshold = upper(char(string(logger.console_level)));
end

if ~isfield(logger.level_rank, threshold)
    tf = true;
    return;
end

tf = logger.level_rank.(level) >= logger.level_rank.(threshold);
end
