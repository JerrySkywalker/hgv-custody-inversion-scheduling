function detail = compute_geometry_tiebreak_dualloop(caseData, selected_ids, k, cfg)
%COMPUTE_GEOMETRY_TIEBREAK_DUALLOOP
% Windowed geometric tie-break detail for two-satellite candidate sets.
%
% Reuses Stage-style ideas:
%   - angle-only information increment (Stage04 style)
%   - LOS crossing angle (Stage03 style)

truth = caseData.truth;
satbank = caseData.satbank;

N = numel(caseData.time.t);
k2 = min(N, k + cfg.ch5.window_steps - 1);

if isempty(selected_ids)
    detail = struct();
    detail.lambda_min_geom = 0;
    detail.mean_trace_geom = 0;
    detail.min_crossing_angle_deg = 0;
    return;
end

W = zeros(3,3);
trace_series = zeros(k2-k+1,1);
min_angle_series = nan(k2-k+1,1);

for kk = k:k2
    r_tgt = truth.r_eci_km(kk, :).';

    los_units = zeros(numel(selected_ids), 3);

    for ii = 1:numel(selected_ids)
        s = selected_ids(ii);
        r_sat = squeeze(satbank.r_eci_km(kk, :, s)).';
        Q = info_increment_angle_stage04(r_sat, r_tgt, cfg);
        W = W + Q;

        los = r_sat - r_tgt;
        los = los / max(norm(los), eps);
        los_units(ii, :) = los(:).';
    end

    trace_series(kk-k+1) = trace(W);

    if size(los_units,1) >= 2
        G = los_units * los_units.';
        G = min(max(G, -1), 1);
        pair_mask = triu(true(size(G)), 1);
        ang = acosd(G(pair_mask));
        if ~isempty(ang)
            min_angle_series(kk-k+1) = min(ang);
        end
    end
end

e = eig(0.5*(W+W.'));
e = real(e(:));

detail = struct();
detail.lambda_min_geom = max(0, min(e));
detail.mean_trace_geom = mean(trace_series, 'omitnan');
detail.min_crossing_angle_deg = min(min_angle_series, [], 'omitnan');

if ~isfinite(detail.min_crossing_angle_deg)
    detail.min_crossing_angle_deg = 0;
end
end
