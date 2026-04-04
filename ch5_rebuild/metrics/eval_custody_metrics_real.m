function custody_metrics = eval_custody_metrics_real(bubble, dt)
%EVAL_CUSTODY_METRICS_REAL
% Treat bubble occurrence as custody loss on the real R3/R4 line.

if nargin < 1 || isempty(bubble)
    error('bubble is required.');
end
if nargin < 2 || isempty(dt)
    error('dt is required.');
end

is_custody_lost = logical(bubble.is_bubble(:));
total_steps = numel(is_custody_lost);
loc_total_steps = nnz(is_custody_lost);
loc_total_time_s = loc_total_steps * dt;
custody_ratio = 1 - loc_total_steps / max(total_steps, 1);

segments = local_find_segments(is_custody_lost, dt);
if isempty(segments)
    longest_loc_time_s = 0;
    mean_loc_time_s = 0;
else
    longest_loc_time_s = max([segments.duration_s]);
    mean_loc_time_s = mean([segments.duration_s]);
end

custody_metrics = struct();
custody_metrics.total_steps = total_steps;
custody_metrics.loc_total_steps = loc_total_steps;
custody_metrics.loc_total_time_s = loc_total_time_s;
custody_metrics.longest_loc_time_s = longest_loc_time_s;
custody_metrics.mean_loc_time_s = mean_loc_time_s;
custody_metrics.custody_ratio = custody_ratio;
custody_metrics.is_custody_lost = is_custody_lost;
custody_metrics.segments = segments;
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
