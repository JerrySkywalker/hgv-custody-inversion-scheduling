function metrics = eval_bubble_metrics(state_trace)
%EVAL_BUBBLE_METRICS  Evaluate minimal bubble metrics from state trace.

if nargin < 1 || isempty(state_trace)
    error('state_trace is required.');
end

time_s = state_trace.time_s(:);
is_bubble = logical(state_trace.is_bubble(:));
bubble_depth = state_trace.bubble_depth(:);

if numel(time_s) <= 1
    dt = 0;
else
    dt = median(diff(time_s));
end

total_steps = numel(time_s);
bubble_steps = nnz(is_bubble);
bubble_time_s = bubble_steps * dt;

segments = local_find_segments(is_bubble, dt);

if isempty(segments)
    longest_bubble_time_s = 0;
    mean_bubble_time_s = 0;
else
    durations = [segments.duration_s];
    longest_bubble_time_s = max(durations);
    mean_bubble_time_s = mean(durations);
end

metrics = struct();
metrics.total_steps = total_steps;
metrics.bubble_steps = bubble_steps;
metrics.bubble_fraction = bubble_steps / max(total_steps, 1);
metrics.bubble_time_s = bubble_time_s;
metrics.longest_bubble_time_s = longest_bubble_time_s;
metrics.mean_bubble_time_s = mean_bubble_time_s;
metrics.max_bubble_depth = max(bubble_depth);
metrics.mean_bubble_depth = mean(bubble_depth(is_bubble), 'omitnan');
if isnan(metrics.mean_bubble_depth)
    metrics.mean_bubble_depth = 0;
end
metrics.segments = segments;
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
