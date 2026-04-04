function custody = eval_custody_metrics(state_trace)
%EVAL_CUSTODY_METRICS  Minimal custody-style metrics from bubble state.

if nargin < 1 || isempty(state_trace)
    error('state_trace is required.');
end

time_s = state_trace.time_s(:);
is_bubble = logical(state_trace.is_bubble(:));

if numel(time_s) <= 1
    dt = 0;
else
    dt = median(diff(time_s));
end

is_custody_lost = is_bubble;
loc_total_steps = nnz(is_custody_lost);
loc_total_time_s = loc_total_steps * dt;

segments = local_find_segments(is_custody_lost, dt);
if isempty(segments)
    longest_loc_time_s = 0;
else
    longest_loc_time_s = max([segments.duration_s]);
end

custody = struct();
custody.is_custody_lost = is_custody_lost;
custody.loc_total_steps = loc_total_steps;
custody.loc_total_time_s = loc_total_time_s;
custody.longest_loc_time_s = longest_loc_time_s;
custody.custody_ratio = 1 - loc_total_steps / max(numel(time_s), 1);
custody.segments = segments;
end

function segments = local_find_segments(mask, dt)
segments = struct('start_idx', {}, 'end_idx', {}, 'length_steps', {}, 'duration_s', {});

if isempty(mask)
    return;
end

mask = mask(:);
d = diff([false; mask; false]);
start_idx = find(d == 1);
end_idx = find(d == -1) - 1;

for i = 1:numel(start_idx)
    seg.start_idx = start_idx(i);
    seg.end_idx = end_idx(i);
    seg.length_steps = end_idx(i) - start_idx(i) + 1;
    seg.duration_s = seg.length_steps * dt;
    segments(end+1) = seg; %#ok<AGROW>
end
end
