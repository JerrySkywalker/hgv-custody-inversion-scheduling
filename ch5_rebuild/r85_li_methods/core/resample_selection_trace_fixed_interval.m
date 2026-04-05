function trace_out = resample_selection_trace_fixed_interval(trace_in, interval_steps, new_tag)
%RESAMPLE_SELECTION_TRACE_FIXED_INTERVAL
% R8.7a:
%   Convert stepwise selection_trace into fixed-interval hold trace.
%
% At k = 1, 1+interval, 1+2*interval, ...:
%   keep original selected pair;
% In between:
%   hold the latest selected pair.

assert(iscell(trace_in), 'trace_in must be cell.');
assert(isnumeric(interval_steps) && isscalar(interval_steps) && interval_steps >= 1, 'interval_steps invalid.');

n_steps = numel(trace_in);
trace_out = trace_in;

anchor_rec = [];
for k = 1:n_steps
    if k == 1 || mod(k-1, interval_steps) == 0
        anchor_rec = trace_in{k};
        trace_out{k} = anchor_rec;
    else
        rec = trace_in{k};
        if ~isempty(anchor_rec) && isstruct(anchor_rec)
            rec.best_pair = anchor_rec.best_pair;
            if isfield(anchor_rec, 'J_pair')
                rec.J_pair = anchor_rec.J_pair;
            end
            rec.mode = "hold_fixed_interval";
        end
        trace_out{k} = rec;
    end

    if nargin >= 3 && ~isempty(new_tag) && isstruct(trace_out{k})
        trace_out{k}.policy = string(new_tag);
    end
end
end
