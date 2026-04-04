function s = score_tiebreak_with_static_prior(prior, pair)
%SCORE_TIEBREAK_WITH_STATIC_PRIOR
% Minimal weak-prior tie-break score.
%
% Current simple rule:
% - smaller pair index sum gets slightly higher preference
% - only used as a tiny secondary term

if nargin < 2 || isempty(pair)
    s = -inf;
    return;
end

s = -sum(pair);
end
