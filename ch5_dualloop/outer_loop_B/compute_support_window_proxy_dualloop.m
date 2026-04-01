function detail = compute_support_window_proxy_dualloop(caseData, selected_ids, k, cfg)
%COMPUTE_SUPPORT_WINDOW_PROXY_DUALLOOP
% Evaluate future support structure over a rolling window.
%
% detail fields:
%   support_count_series
%   dual_support_ratio
%   single_support_ratio
%   zero_support_ratio
%   longest_single_support_steps
%   longest_zero_support_steps

mask = caseData.candidates.visible_mask;
N = size(mask, 1);
H = cfg.ch5.window_steps;
k2 = min(N, k + H - 1);

if isempty(selected_ids)
    support_count = zeros(k2-k+1, 1);
else
    future_mask = mask(k:k2, selected_ids);
    support_count = sum(future_mask, 2);
end

dual_seg = (support_count >= 2);
single_seg = (support_count == 1);
zero_seg = (support_count == 0);

detail = struct();
detail.support_count_series = support_count(:);
detail.dual_support_ratio = mean(dual_seg);
detail.single_support_ratio = mean(single_seg);
detail.zero_support_ratio = mean(zero_seg);
detail.longest_single_support_steps = local_longest_run(single_seg);
detail.longest_zero_support_steps = local_longest_run(zero_seg);
end

function L = local_longest_run(flag)
if isempty(flag)
    L = 0;
    return;
end

flag = flag(:) > 0;
d = diff([0; flag; 0]);
s = find(d == 1);
e = find(d == -1) - 1;

if isempty(s)
    L = 0;
else
    L = max(e - s + 1);
end
end
