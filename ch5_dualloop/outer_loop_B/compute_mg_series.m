function mg = compute_mg_series(result, caseData, cfg)
%COMPUTE_MG_SERIES  Compute geometry-aware custody proxy.
%
% mg combines:
%   1) count adequacy
%   2) average-range quality
%
% Output is normalized to [0,1].

if nargin < 3 || isempty(cfg)
    cfg = default_ch5_params();
end

max_track_sats = cfg.ch5.max_track_sats;
N = numel(result.time);

mg = zeros(N, 1);

for k = 1:N
    ids = result.selected_sets{k};
    if isempty(ids)
        mg(k) = 0;
        continue;
    end

    count_term = numel(ids) / max_track_sats;
    count_term = max(0, min(1, count_term));

    r_tgt = caseData.truth.r_eci_km(k, :);
    ranges = zeros(numel(ids), 1);

    for i = 1:numel(ids)
        sid = ids(i);
        r_sat = squeeze(caseData.satbank.r_eci_km(k, :, sid));
        ranges(i) = norm(r_sat(:).' - r_tgt);
    end

    avg_range_km = mean(ranges);
    range_term = 1 / (1 + avg_range_km / 2000);

    mg(k) = min(count_term, range_term);
end
end
