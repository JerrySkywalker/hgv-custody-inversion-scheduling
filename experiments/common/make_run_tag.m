function tag = make_run_tag(prefix)
if nargin < 1 || isempty(prefix)
    prefix = 'run';
end
tag = sprintf('%s_%s', prefix, datestr(now, 'yyyymmdd_HHMMSS'));
end
