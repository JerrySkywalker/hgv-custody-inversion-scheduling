function out = eval_bubble_metrics(MG_series, eps_warn, dt)
%EVAL_BUBBLE_METRICS Evaluate bubble metrics from M_G series.
%
% Inputs:
%   MG_series : [N x 1] structure metric series
%   eps_warn  : warning threshold
%   dt        : time step
%
% Outputs:
%   out.bubble_steps
%   out.bubble_fraction
%   out.bubble_time_s
%   out.longest_bubble_time_s
%   out.max_bubble_depth
%   out.is_bubble

MG_series = MG_series(:);
N = numel(MG_series);

assert(isnumeric(eps_warn) && isscalar(eps_warn), 'eps_warn invalid.');
assert(isnumeric(dt) && isscalar(dt) && dt > 0, 'dt invalid.');

is_bubble = MG_series < eps_warn;
bubble_steps = sum(is_bubble);
bubble_fraction = bubble_steps / max(N,1);
bubble_time_s = bubble_steps * dt;

depth = max(eps_warn - MG_series, 0);
max_bubble_depth = max(depth);

longest_seg = 0;
cur = 0;
for k = 1:N
    if is_bubble(k)
        cur = cur + 1;
        longest_seg = max(longest_seg, cur);
    else
        cur = 0;
    end
end

out = struct();
out.bubble_steps = bubble_steps;
out.bubble_fraction = bubble_fraction;
out.bubble_time_s = bubble_time_s;
out.longest_bubble_time_s = longest_seg * dt;
out.max_bubble_depth = max_bubble_depth;
out.is_bubble = is_bubble;
end
