function out = score_candidate_with_continuous_prior(score_ck, cand, cfg)
% 对单个 candidate 在 CK 分数基础上接入连续几何先验
%
% 输入:
%   score_ck : 原始 CK 分数
%   cand     : struct，至少包含
%              lambda_geom
%              baseline_km
%              crossing_angle_deg
%              Bxy_cand
%              Ruse
%   cfg      : default_phase8_continuous_prior_config()
%
% 输出:
%   out.score_ck
%   out.score_total
%   out.prior
%   out.detail
%   out.mode

arguments
    score_ck double
    cand struct
    cfg struct
end

required_fields = {'lambda_geom','baseline_km','crossing_angle_deg','Bxy_cand','Ruse'};
for i = 1:numel(required_fields)
    f = required_fields{i};
    assert(isfield(cand, f), 'Candidate missing field: %s', f);
end

assert(isfield(cfg, 'mode'), 'cfg.mode is required.');
assert(isfield(cfg, 'w_prior'), 'cfg.w_prior is required.');
assert(isfield(cfg, 'weights'), 'cfg.weights is required.');

prior = build_stage15_continuous_prior(cand.lambda_geom, cand.baseline_km, cand.crossing_angle_deg);
[prior_cost_full, detail] = compute_stage15_continuous_prior_cost(prior, cand.Bxy_cand, cand.Ruse, cfg.weights);

switch cfg.mode
    case 'ck_only'
        prior_cost_used = 0.0;
    case 'ck_plus_fragility'
        prior_cost_used = cfg.weights.wf * detail.Jf;
    case 'ck_plus_full_prior'
        prior_cost_used = prior_cost_full;
    otherwise
        error('Unknown cfg.mode: %s', cfg.mode);
end

score_total = score_ck - cfg.w_prior * prior_cost_used;

out = struct();
out.mode = cfg.mode;
out.score_ck = score_ck;
out.score_total = score_total;
out.prior_cost_used = prior_cost_used;
out.prior = prior;
out.detail = detail;
end
