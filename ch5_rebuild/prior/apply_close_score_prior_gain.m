function [total_scores, meta] = apply_close_score_prior_gain(cfg, prior_scores, base_scores)
%APPLY_CLOSE_SCORE_PRIOR_GAIN
% Amplify prior only when top candidates are close in base score.

if nargin < 3
    error('cfg, prior_scores, base_scores are required.');
end

n = numel(base_scores);
assert(numel(prior_scores) == n, 'prior_scores and base_scores must have same length.');

eps_base = cfg.ch5r.r8.eps_prior_base;
eps_close = cfg.ch5r.r8.eps_prior_close;
close_gap = cfg.ch5r.r8.close_gap;

if ~isfield(cfg.ch5r.r8, 'enable_close_score_prior') || ~cfg.ch5r.r8.enable_close_score_prior
    eps_use = eps_base;
else
    if n >= 2
        sorted_scores = sort(base_scores, 'descend');
        gap12 = sorted_scores(1) - sorted_scores(2);
    else
        gap12 = inf;
    end

    if gap12 <= close_gap
        eps_use = eps_close;
    else
        eps_use = eps_base;
    end
end

total_scores = base_scores + eps_use * prior_scores;

meta = struct();
meta.eps_used = eps_use;
if n >= 2
    sorted_scores = sort(base_scores, 'descend');
    meta.top_gap = sorted_scores(1) - sorted_scores(2);
else
    meta.top_gap = inf;
end
end
