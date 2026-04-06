function requirement = eval_requirement_margin_real(wininfo, gamma_req)
%EVAL_REQUIREMENT_MARGIN_REAL
% Requirement margin on the real R1.5/R3/R4 line.
%
% margin(k) = lambda_min(k) - gamma_req
%
% Important:
% Statistics are computed ONLY on valid_for_bubble samples.

if nargin < 1 || isempty(wininfo)
    error('wininfo is required.');
end
if nargin < 2 || isempty(gamma_req)
    error('gamma_req is required.');
end

lambda_min = wininfo.lambda_min(:);

if isfield(wininfo, 'valid_for_bubble') && ~isempty(wininfo.valid_for_bubble)
    valid_for_bubble = logical(wininfo.valid_for_bubble(:));
else
    valid_for_bubble = true(size(lambda_min));
end

assert(numel(lambda_min) == numel(valid_for_bubble), ...
    'wininfo.lambda_min and wininfo.valid_for_bubble size mismatch.');

margin = nan(size(lambda_min));
margin(valid_for_bubble) = lambda_min(valid_for_bubble) - gamma_req;

is_violation = false(size(lambda_min));
is_violation(valid_for_bubble) = margin(valid_for_bubble) < 0;

valid_margin = margin(valid_for_bubble);
valid_violation = is_violation(valid_for_bubble);

requirement = struct();
requirement.margin = margin;
requirement.valid_for_bubble = valid_for_bubble;
requirement.is_violation = is_violation;

if isempty(valid_margin)
    requirement.min_margin = NaN;
    requirement.mean_margin = NaN;
else
    requirement.min_margin = min(valid_margin, [], 'omitnan');
    requirement.mean_margin = mean(valid_margin, 'omitnan');
end

requirement.total_valid_steps = nnz(valid_for_bubble);
requirement.total_violation_steps = nnz(valid_violation);
end
