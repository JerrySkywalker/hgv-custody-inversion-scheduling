function bubble_metrics = eval_bubble_metrics_real(bubble, dt)
%EVAL_BUBBLE_METRICS_REAL  Unified bubble metrics on the real R3/R4 line.

if nargin < 1 || isempty(bubble)
    error('bubble is required.');
end
if nargin < 2 || isempty(dt)
    error('dt is required.');
end

is_bubble = logical(bubble.is_bubble(:));
bubble_depth = bubble.bubble_depth(:);

total_steps = numel(is_bubble);
bubble_steps = nnz(is_bubble);
bubble_fraction = bubble_steps / max(total_steps, 1);
bubble_time_s = bubble_steps * dt;

segments = local_find_segments(is_bubble, dt);
if isempty(segments)
    longest_bubble_time_s = 0;
    mean_bubble_time_s = 0;
else
    longest_bubble_time_s = max([segments.duration_s]);
    mean_bubble_time_s = mean([segments.duration_s]);
end

bubble_metrics = struct();
bubble_metrics.total_steps = total_steps;
bubble_metrics.bubble_steps = bubble_steps;
bubble_metrics.bubble_fraction = bubble_fraction;
bubble_metrics.bubble_time_s = bubble_time_s;
bubble_metrics.longest_bubble_time_s = longest_bubble_time_s;
bubble_metrics.mean_bubble_time_s = mean_bubble_time_s;
bubble_metrics.max_bubble_depth = max(bubble_depth, [], 'omitnan');
bubble_metrics.mean_bubble_depth = mean(bubble_depth, 'omitnan');
bubble_metrics.segments = segments;
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
