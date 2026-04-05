function score = li_score_pta(candidate)
%LI_SCORE_PTA
% Li-style PTA criterion:
%   maximize predicted tracking arc length.
%
% Input candidate fields:
%   .pta_len_s

assert(isstruct(candidate), 'candidate must be a struct.');
assert(isfield(candidate, 'pta_len_s'), 'candidate.pta_len_s is required.');

score = candidate.pta_len_s;
end
