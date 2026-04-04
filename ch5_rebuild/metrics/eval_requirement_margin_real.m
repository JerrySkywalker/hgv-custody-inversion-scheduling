function requirement = eval_requirement_margin_real(wininfo, gamma_req)
%EVAL_REQUIREMENT_MARGIN_REAL
% Requirement margin on the real R3/R4 line.

if nargin < 1 || isempty(wininfo)
    error('wininfo is required.');
end
if nargin < 2 || isempty(gamma_req)
    error('gamma_req is required.');
end

margin = wininfo.lambda_min(:) - gamma_req;
is_violation = margin < 0;

requirement = struct();
requirement.margin = margin;
requirement.is_violation = is_violation;
requirement.min_margin = min(margin, [], 'omitnan');
requirement.mean_margin = mean(margin, 'omitnan');
requirement.total_violation_steps = nnz(is_violation);
end
