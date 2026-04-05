function out = li_select_by_criterion(candidates, criterion_name)
%LI_SELECT_BY_CRITERION
% Unified Li-style relay selection interface.
%
% Inputs:
%   candidates      : struct array
%   criterion_name  : 'pta' | 'cn' | 'detY_rim' | 'detY_fast'
%
% Output:
%   out.best_index
%   out.best_candidate
%   out.best_score
%   out.score_vector
%   out.criterion_name

assert(isstruct(candidates) && ~isempty(candidates), 'candidates must be a non-empty struct array.');
assert(ischar(criterion_name) || isstring(criterion_name), 'criterion_name must be char or string.');

criterion_name = char(string(criterion_name));
score_vector = zeros(numel(candidates), 1);

for i = 1:numel(candidates)
    switch criterion_name
        case 'pta'
            score_vector(i) = li_score_pta(candidates(i));
        case 'cn'
            score_vector(i) = li_score_cn(candidates(i));
        case 'detY_rim'
            score_vector(i) = li_score_detY_rim(candidates(i));
        case 'detY_fast'
            score_vector(i) = li_score_detY_fast(candidates(i));
        otherwise
            error('Unsupported criterion_name: %s', criterion_name);
    end
end

[best_score, best_index] = max(score_vector);

out = struct();
out.criterion_name = string(criterion_name);
out.best_index = best_index;
out.best_candidate = candidates(best_index);
out.best_score = best_score;
out.score_vector = score_vector;
end
