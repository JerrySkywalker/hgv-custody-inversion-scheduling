function trace_out = resample_selection_trace_adaptive_interval(trace_in, refresh_mask, new_tag)
%RESAMPLE_SELECTION_TRACE_ADAPTIVE_INTERVAL
% R8.7b:
%   Apply adaptive refresh schedule to stepwise selection trace.

assert(iscell(trace_in), 'trace_in must be cell.');
assert(islogical(refresh_mask) && isvector(refresh_mask), 'refresh_mask must be logical vector.');
assert(numel(trace_in) == numel(refresh_mask), 'trace length mismatch.');

n_steps = numel(trace_in);
trace_out = trace_in;

anchor_rec = [];
for k = 1:n_steps
    if refresh_mask(k) || isempty(anchor_rec)
        anchor_rec = trace_in{k};
        trace_out{k} = anchor_rec;
        if isstruct(trace_out{k})
            trace_out{k}.mode = "refresh_adaptive_interval";
        end
    else
        rec = trace_in{k};
        if ~isempty(anchor_rec) && isstruct(anchor_rec)
            rec.best_pair = anchor_rec.best_pair;
            if isfield(anchor_rec, 'J_pair')
                rec.J_pair = anchor_rec.J_pair;
            end
            rec.mode = "hold_adaptive_interval";
        end
        trace_out{k} = rec;
    end

    if nargin >= 3 && ~isempty(new_tag) && isstruct(trace_out{k})
        trace_out{k}.policy = string(new_tag);
    end
end
end
