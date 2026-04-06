function bubble = eval_bubble_state(ch5case, wininfo)
%EVAL_BUBBLE_STATE  Evaluate bubble state from windowed information.

if nargin < 2 || isempty(wininfo)
    error('wininfo is required. Call eval_window_information(ch5case, selection_trace) first.');
end

gamma_req = ch5case.gamma_req;
lambda_min = wininfo.lambda_min(:);
valid_for_bubble = logical(wininfo.valid_for_bubble(:));

is_bubble = false(size(lambda_min));
bubble_depth = zeros(size(lambda_min));

mask = valid_for_bubble & isfinite(lambda_min);
is_bubble(mask) = lambda_min(mask) < gamma_req;
bubble_depth(mask) = max(0, gamma_req - lambda_min(mask));

segments = local_find_segments(is_bubble, ch5case.dt);

bubble = struct();
bubble.t_s = wininfo.t_s(:);
bubble.time_s = wininfo.t_s(:);
bubble.gamma_req = gamma_req;
bubble.lambda_min = lambda_min;
bubble.valid_for_bubble = valid_for_bubble;
bubble.is_bubble = is_bubble(:);
bubble.bubble_depth = bubble_depth(:);
bubble.segments = segments;

bubble.total_valid_steps = nnz(valid_for_bubble);
bubble.total_valid_time_s = bubble.total_valid_steps * ch5case.dt;

bubble.total_bubble_steps = nnz(is_bubble);
bubble.total_bubble_time_s = nnz(is_bubble) * ch5case.dt;

if isempty(segments)
    bubble.longest_bubble_time_s = 0;
else
    bubble.longest_bubble_time_s = max([segments.duration_s]);
end
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
    seg.duration_s = dt * seg.length_steps;
    segments(end+1) = seg; %#ok<AGROW>
end
end
