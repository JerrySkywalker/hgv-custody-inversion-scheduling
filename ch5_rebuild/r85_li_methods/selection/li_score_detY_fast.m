function score = li_score_detY_fast(candidate)
%LI_SCORE_DETY_FAST
% Li-style fast determinant criterion:
%   maximize fast-approximated determinant of final information matrix.
%
% Input candidate fields:
%   .detY_fast_value

assert(isstruct(candidate), 'candidate must be a struct.');
assert(isfield(candidate, 'detY_fast_value'), 'candidate.detY_fast_value is required.');

score = candidate.detY_fast_value;
end
