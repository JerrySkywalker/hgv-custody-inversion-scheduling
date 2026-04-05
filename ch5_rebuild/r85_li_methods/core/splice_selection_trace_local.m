function trace_out = splice_selection_trace_local(trace_base, trace_patch, k1, k2, new_tag)
%SPLICE_SELECTION_TRACE_LOCAL
% R8.6c:
%   Replace [k1, k2] segment in trace_base with the same segment from trace_patch.

assert(iscell(trace_base), 'trace_base must be cell.');
assert(iscell(trace_patch), 'trace_patch must be cell.');
assert(numel(trace_base) == numel(trace_patch), 'trace lengths must match.');
assert(k1 >= 1 && k2 <= numel(trace_base) && k1 <= k2, 'invalid splice range.');

trace_out = trace_base;
for k = k1:k2
    trace_out{k} = trace_patch{k};
end

if nargin >= 5 && ~isempty(new_tag)
    for k = 1:numel(trace_out)
        if isstruct(trace_out{k})
            trace_out{k}.policy = string(new_tag);
        end
    end
end
end
