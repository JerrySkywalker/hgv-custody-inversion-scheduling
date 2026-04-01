function out = score_candidate_with_continuous_prior(score_ck, cand, cfg)
% 对单个 candidate 在 CK 分数基础上接入连续几何先验
%
% 模式:
%   ck_only
%   ck_plus_fragility
%   ck_plus_full_prior
%
% 注意:
%   当前真实主链下，Bxy_cand / Ruse 可能不可用(NaN)。
%   在这种情况下，ck_plus_full_prior 自动退化为 fragility-only。

arguments
    score_ck double
    cand struct
    cfg struct
end

required_fields = {'lambda_geom','baseline_km','crossing_angle_deg'};
for i = 1:numel(required_fields)
    f = required_fields{i};
    assert(isfield(cand, f), 'Candidate missing field: %s', f);
end

assert(isfield(cfg, 'mode'), 'cfg.mode is required.');
assert(isfield(cfg, 'w_prior'), 'cfg.w_prior is required.');
assert(isfield(cfg, 'weights'), 'cfg.weights is required.');

prior = build_stage15_continuous_prior(cand.lambda_geom, cand.baseline_km, cand.crossing_angle_deg);

has_full_geom = isfield(cand, 'Bxy_cand') && isfield(cand, 'Ruse') && ...
    isfinite(cand.Bxy_cand) && isfinite(cand.Ruse);

if has_full_geom
    [prior_cost_full, detail] = compute_stage15_continuous_prior_cost(prior, cand.Bxy_cand, cand.Ruse, cfg.weights);
else
    detail = struct();
    detail.Jf = prior.fragility_score;
    detail.Jb = NaN;
    detail.Jr = NaN;
    detail.Bxy_ref = prior.Bxy_nominal_est;
    detail.Rref = prior.R_geo_est;
    detail.prior_cost = cfg.weights.wf * detail.Jf;
    prior_cost_full = detail.prior_cost;
end

switch cfg.mode
    case 'ck_only'
        prior_cost_used = 0.0;
        mode_effective = "ck_only";

    case 'ck_plus_fragility'
        prior_cost_used = cfg.weights.wf * detail.Jf;
        mode_effective = "ck_plus_fragility";

    case 'ck_plus_full_prior'
        if has_full_geom
            prior_cost_used = prior_cost_full;
            mode_effective = "ck_plus_full_prior";
        else
            prior_cost_used = cfg.weights.wf * detail.Jf;
            mode_effective = "ck_plus_fragility_fallback";
        end

    otherwise
        error('Unknown cfg.mode: %s', cfg.mode);
end

score_total = score_ck - cfg.w_prior * prior_cost_used;

out = struct();
out.mode = cfg.mode;
out.mode_effective = mode_effective;
out.score_ck = score_ck;
out.score_total = score_total;
out.prior_cost_used = prior_cost_used;
out.prior = prior;
out.detail = detail;
end
