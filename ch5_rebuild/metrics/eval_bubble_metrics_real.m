function bubble_metrics = eval_bubble_metrics_real(bubble, dt)
%EVAL_BUBBLE_METRICS_REAL
% Unified bubble metrics on the real R1.5/R3/R4 line.
%
% Important:
% Metrics are computed ONLY on valid_for_bubble == true samples.

if nargin < 1 || isempty(bubble)
    error('bubble is required.');
end
if nargin < 2 || isempty(dt)
    error('dt is required.');
end

is_bubble = logical(bubble.is_bubble(:));
bubble_depth = bubble.bubble_depth(:);

if isfield(bubble, 'valid_for_bubble') && ~isempty(bubble.valid_for_bubble)
    valid_for_bubble = logical(bubble.valid_for_bubble(:));
else
    valid_for_bubble = true(size(is_bubble));
end

assert(numel(is_bubble) == numel(valid_for_bubble), ...
    'bubble.is_bubble and bubble.valid_for_bubble size mismatch.');

masked_is_bubble = is_bubble & valid_for_bubble;
valid_depth = bubble_depth(valid_for_bubble);

total_steps = numel(is_bubble);
total_valid_steps = nnz(valid_for_bubble);
bubble_steps = nnz(masked_is_bubble);

if total_valid_steps > 0
    bubble_fraction = bubble_steps / total_valid_steps;
else
    bubble_fraction = NaN;
end

bubble_time_s = bubble_steps * dt;
total_valid_time_s = total_valid_steps * dt;

segments = local_find_segments(masked_is_bubble, dt);
if isempty(segments)
    longest_bubble_time_s = 0;
    mean_bubble_time_s = 0;
else
    longest_bubble_time_s = max([segments.duration_s]);
    mean_bubble_time_s = mean([segments.duration_s]);
end

bubble_metrics = struct();
bubble_metrics.total_steps = total_steps;
bubble_metrics.total_valid_steps = total_valid_steps;
bubble_metrics.total_valid_time_s = total_valid_time_s;
bubble_metrics.bubble_steps = bubble_steps;
bubble_metrics.bubble_fraction = bubble_fraction;
bubble_metrics.bubble_time_s = bubble_time_s;
bubble_metrics.longest_bubble_time_s = longest_bubble_time_s;
bubble_metrics.mean_bubble_time_s = mean_bubble_time_s;

if isempty(valid_depth)
    bubble_metrics.max_bubble_depth = NaN;
    bubble_metrics.mean_bubble_depth = NaN;
else
    bubble_metrics.max_bubble_depth = max(valid_depth, [], 'omitnan');
    bubble_metrics.mean_bubble_depth = mean(valid_depth, 'omitnan');
end

bubble_metrics.valid_for_bubble = valid_for_bubble;
bubble_metrics.masked_is_bubble = masked_is_bubble;
bubble_metrics.segments = segments;
end

function segments = local_find_segments(mask, dt)
segments = struct('start_idx', {}, 'end_idx', {}, 'length_steps', {}, 'duration_s', {});

if isempty(mask)
    return;
end

mask = logical(mask(:));
d = diff([false; mask; false]);
start_idx = find(d == 1);
end_idx = find(d == -1) - 1;

for i = 1:numel(start_idx)
    seg = struct();
    seg.start_idx = start_idx(i);
    seg.end_idx = end_idx(i);
    seg.length_steps = end_idx(i) - start_idx(i) + 1;
    seg.duration_s = seg.length_steps * dt;
    segments(end+1) = seg; %#ok<AGROW>
end
end
