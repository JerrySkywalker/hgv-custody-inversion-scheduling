function score = li_score_detY_rim(candidate)
%LI_SCORE_DETY_RIM
% Li-style RIM determinant criterion:
%   maximize determinant of final information matrix computed by RIM.
%
% Input candidate fields:
%   .detY_rim_value

assert(isstruct(candidate), 'candidate must be a struct.');
assert(isfield(candidate, 'detY_rim_value'), 'candidate.detY_rim_value is required.');

score = candidate.detY_rim_value;
end
