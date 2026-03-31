function prior_map = compute_outer_prior_map(caseData, k_anchor, cfg)
%COMPUTE_OUTER_PRIOR_MAP  Compute a simple future-risk-aware prior for all satellites.
%
% The prior prefers satellites that:
%   1) remain visible longer over the future horizon
%   2) stay closer to the target on average over the same horizon
%
% Output:
%   prior_map : [Ns x 1], normalized roughly to [0,1]

if nargin < 3 || isempty(cfg)
    cfg = default_ch5_params();
end

Ns = caseData.summary.num_sats;
N = size(caseData.candidates.visible_mask, 1);

H = cfg.ch5.outer_horizon_steps;
k2 = min(N, k_anchor + H - 1);
R0 = cfg.ch5.outer_range_scale_km;

prior_map = zeros(Ns, 1);

for sid = 1:Ns
    vis_seq = caseData.candidates.visible_mask(k_anchor:k2, sid);
    vis_frac = mean(vis_seq);

    avg_range = 0;
    count = 0;
    for tau = k_anchor:k2
        if caseData.candidates.visible_mask(tau, sid)
            r_tgt = caseData.truth.r_eci_km(tau, :);
            r_sat = squeeze(caseData.satbank.r_eci_km(tau, :, sid));
            avg_range = avg_range + norm(r_sat(:).' - r_tgt);
            count = count + 1;
        end
    end

    if count > 0
        avg_range = avg_range / count;
        range_score = 1 / (1 + avg_range / R0);
    else
        range_score = 0;
    end

    prior_map(sid) = 0.7 * vis_frac + 0.3 * range_score;
end
end
