function req_chain = analyze_bubble_to_requirement_chain(outX)
%ANALYZE_BUBBLE_TO_REQUIREMENT_CHAIN
% Minimal real R6 chain analysis on the current Fisher-based line.
%
% Current interpretation:
% - use lambda_min(J_W) as information-floor indicator
% - define requirement-risk proxy by inverse information
% - compare against requirement threshold gamma_req
%
% Important:
% - statistics are computed ONLY on valid_for_bubble samples
% - current requirement-risk proxy is a monotone transform of lambda_min
%   so it should be interpreted as a minimal proxy bridge, not an
%   independent covariance-projection proof chain.

if nargin < 1 || isempty(outX)
    error('outX is required.');
end

lambda_min = outX.wininfo.lambda_min(:);
gamma_req = outX.bubble.gamma_req;
t_s = outX.case.t_s(:);

if isfield(outX.bubble, 'valid_for_bubble') && ~isempty(outX.bubble.valid_for_bubble)
    valid_for_bubble = logical(outX.bubble.valid_for_bubble(:));
else
    valid_for_bubble = true(size(lambda_min));
end

assert(numel(lambda_min) == numel(valid_for_bubble), ...
    'lambda_min and valid_for_bubble size mismatch.');

safe_lambda = max(lambda_min, 1e-12);

req_risk_proxy = nan(size(lambda_min));
req_risk_proxy(valid_for_bubble) = 1 ./ safe_lambda(valid_for_bubble);

req_threshold_proxy = 1 / gamma_req;

req_violation = false(size(lambda_min));
req_violation(valid_for_bubble) = req_risk_proxy(valid_for_bubble) > req_threshold_proxy;

req_margin_proxy = nan(size(lambda_min));
req_margin_proxy(valid_for_bubble) = req_threshold_proxy - req_risk_proxy(valid_for_bubble);

bubble_flag = false(size(lambda_min));
bubble_flag(valid_for_bubble) = logical(outX.bubble.is_bubble(valid_for_bubble));

valid_violation = req_violation(valid_for_bubble);
valid_margin = req_margin_proxy(valid_for_bubble);

req_chain = struct();
req_chain.t_s = t_s;
req_chain.lambda_min = lambda_min;
req_chain.gamma_req = gamma_req;
req_chain.valid_for_bubble = valid_for_bubble;
req_chain.req_risk_proxy = req_risk_proxy;
req_chain.req_threshold_proxy = req_threshold_proxy;
req_chain.req_violation = req_violation;
req_chain.req_margin_proxy = req_margin_proxy;

req_chain.total_steps = numel(t_s);
req_chain.total_valid_steps = nnz(valid_for_bubble);
req_chain.total_valid_time_s = req_chain.total_valid_steps * outX.case.dt;

req_chain.total_violation_steps = nnz(valid_violation);
req_chain.total_violation_time_s = req_chain.total_violation_steps * outX.case.dt;

if req_chain.total_valid_steps > 0
    req_chain.violation_fraction = req_chain.total_violation_steps / req_chain.total_valid_steps;
else
    req_chain.violation_fraction = NaN;
end

if isempty(valid_margin)
    req_chain.min_margin_proxy = NaN;
    req_chain.mean_margin_proxy = NaN;
else
    req_chain.min_margin_proxy = min(valid_margin, [], 'omitnan');
    req_chain.mean_margin_proxy = mean(valid_margin, 'omitnan');
end

% This overlap is still useful for sanity checking, but is NOT an
% independent empirical finding because the current proxy is monotone-equivalent
% to the bubble threshold.
if nnz(bubble_flag) > 0
    req_chain.coincidence_ratio = nnz(bubble_flag & req_violation) / nnz(bubble_flag);
else
    req_chain.coincidence_ratio = NaN;
end

if isfield(outX.wininfo, 'has_nonzero_input') && ~isempty(outX.wininfo.has_nonzero_input)
    req_chain.observable_steps = nnz(outX.wininfo.has_nonzero_input);
else
    req_chain.observable_steps = NaN;
end

req_chain.proxy_mode = 'inverse_lambda_monotone';
req_chain.note = ['Minimal R6 real-line bridge: requirement-risk proxy is ' ...
                  'defined from inverse rolling-window information, computed only on valid full windows. ' ...
                  'This is a monotone proxy bridge, not a full covariance-projection proof chain.'];
end
