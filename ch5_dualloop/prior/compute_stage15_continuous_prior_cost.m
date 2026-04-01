function [prior_cost, detail] = compute_stage15_continuous_prior_cost(prior, Bxy_cand, Ruse, weights)
% 连续先验代价
%
% prior   : Stage15 continuous prior
% Bxy_cand: 当前候选参考盒半宽
% Ruse    : 当前局部使用半径
% weights : struct with wf, wb, wr

arguments
    prior struct
    Bxy_cand double
    Ruse double
    weights struct
end

Bxy_ref = prior.Bxy_nominal_est;
Rref = prior.R_geo_est;

Jf = prior.fragility_score;
Jb = ((Bxy_cand - Bxy_ref) / max(Bxy_ref, eps))^2;
Jr = max(0, (Ruse - Rref) / max(Rref, eps))^2;

prior_cost = weights.wf * Jf + weights.wb * Jb + weights.wr * Jr;

detail = struct();
detail.Jf = Jf;
detail.Jb = Jb;
detail.Jr = Jr;
detail.Bxy_ref = Bxy_ref;
detail.Rref = Rref;
detail.prior_cost = prior_cost;
end
