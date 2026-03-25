function run_tag = make_run_tag(prefix, timestamp)
%MAKE_RUN_TAG Build a simple run tag from a prefix and timestamp.
% Inputs:
%   prefix    : optional tag prefix
%   timestamp : optional datestr-compatible string
%
% Output:
%   run_tag   : '<prefix>_<yyyymmdd_HHMMSS>' or timestamp-only tag

if nargin < 1 || isempty(prefix)
    prefix = '';
end
if nargin < 2 || isempty(timestamp)
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
end

prefix = char(string(prefix));
timestamp = char(string(timestamp));

if isempty(prefix)
    run_tag = timestamp;
else
    run_tag = sprintf('%s_%s', prefix, timestamp);
end
end
