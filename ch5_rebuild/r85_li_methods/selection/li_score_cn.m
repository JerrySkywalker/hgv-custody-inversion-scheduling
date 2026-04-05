function score = li_score_cn(candidate)
%LI_SCORE_CN
% Li-style CN criterion:
%   minimize condition number of observability matrix.
%
% For unified selector, return a score to maximize:
%   score = -CN

assert(isstruct(candidate), 'candidate must be a struct.');
assert(isfield(candidate, 'cn_value'), 'candidate.cn_value is required.');

score = -candidate.cn_value;
end
