function detail = compute_phi_window_proxy_dualloop(caseData, selected_ids, k, cfg)
%COMPUTE_PHI_WINDOW_PROXY_DUALLOOP
% Predict window-level phi proxy for a candidate tracking set.
%
% detail fields:
%   phi_series_pred
%   phi_min
%   phi_avg
%   outage_ratio
%   longest_outage_steps

if isempty(selected_ids)
    detail = struct();
    detail.phi_series_pred = 0;
    detail.phi_min = 0;
    detail.phi_avg = 0;
    detail.outage_ratio = 1;
    detail.longest_outage_steps = cfg.ch5.window_steps;
    return;
end

mask = caseData.candidates.visible_mask;
N = size(mask, 1);
H = cfg.ch5.window_steps;

k2 = min(N, k + H - 1);
future_mask = mask(k:k2, selected_ids);

% support ratio in [0,1]
phi_pred = mean(future_mask, 2);

bad = (phi_pred < cfg.ch5.ck_support_threshold);

detail = struct();
detail.phi_series_pred = phi_pred(:);
detail.phi_min = min(phi_pred);
detail.phi_avg = mean(phi_pred);
detail.outage_ratio = mean(bad);
detail.longest_outage_steps = local_longest_run(bad);
end

function L = local_longest_run(bad)
if isempty(bad)
    L = 0;
    return;
end

bad = bad(:) > 0;
d = diff([0; bad; 0]);
s = find(d == 1);
e = find(d == -1) - 1;

if isempty(s)
    L = 0;
else
    L = max(e - s + 1);
end
end
