function tf = should_log(message_level, threshold_level)
levels = struct('ERROR', 1, 'WARN', 2, 'INFO', 3, 'DEBUG', 4);

ml = upper(string(message_level));
tl = upper(string(threshold_level));

if ~isfield(levels, ml)
    error('should_log:UnknownMessageLevel', 'Unknown message level: %s', ml);
end
if ~isfield(levels, tl)
    error('should_log:UnknownThresholdLevel', 'Unknown threshold level: %s', tl);
end

tf = levels.(ml) <= levels.(tl);
end
