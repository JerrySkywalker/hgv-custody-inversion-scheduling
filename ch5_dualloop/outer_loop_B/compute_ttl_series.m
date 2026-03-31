function ttl = compute_ttl_series(result, caseData, cfg)
%COMPUTE_TTL_SERIES  Compute a minimal time-to-loss style continuity proxy.
%
% For each time k, ttl(k) is the minimum consecutive future visibility length
% among the currently selected satellites. Empty set => 0.

if nargin < 3 || isempty(cfg)
    cfg = default_ch5_params();
end

N = numel(result.time);
ttl = zeros(N, 1);

for k = 1:N
    ids = result.selected_sets{k};
    if isempty(ids)
        ttl(k) = 0;
        continue;
    end

    min_run = inf;
    for i = 1:numel(ids)
        sid = ids(i);
        run_len = 0;
        tau = k;
        while tau <= N && caseData.candidates.visible_mask(tau, sid)
            run_len = run_len + 1;
            tau = tau + 1;
        end
        min_run = min(min_run, run_len);
    end

    ttl(k) = min_run;
end
end
