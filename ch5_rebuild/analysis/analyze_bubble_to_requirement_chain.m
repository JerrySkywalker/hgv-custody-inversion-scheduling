function req_chain = analyze_bubble_to_requirement_chain(outX)
%ANALYZE_BUBBLE_TO_REQUIREMENT_CHAIN
% Minimal real R6 chain analysis on the current Fisher-based line.
%
% Current interpretation:
% - use lambda_min(J_W) as information-floor indicator
% - define requirement-risk proxy by inverse information
% - compare against requirement threshold gamma_req
%
% This is NOT yet a full covariance-projection proof chain.
% It is the minimal real-line bridge from bubble to requirement-risk.

if nargin < 1 || isempty(outX)
    error('outX is required.');
end

lambda_min = outX.wininfo.lambda_min(:);
gamma_req = outX.bubble.gamma_req;
t_s = outX.case.t_s(:);

safe_lambda = max(lambda_min, 1e-12);

% Requirement-risk proxy:
% larger means worse requirement-side uncertainty
req_risk_proxy = 1 ./ safe_lambda;

% Define a requirement proxy threshold consistent with current gamma_req:
% lambda_min < gamma_req  <=> 1/lambda_min > 1/gamma_req
req_threshold_proxy = 1 / gamma_req;

req_violation = req_risk_proxy > req_threshold_proxy;
req_margin_proxy = req_threshold_proxy - req_risk_proxy;

req_chain = struct();
req_chain.t_s = t_s;
req_chain.lambda_min = lambda_min;
req_chain.gamma_req = gamma_req;
req_chain.req_risk_proxy = req_risk_proxy;
req_chain.req_threshold_proxy = req_threshold_proxy;
req_chain.req_violation = req_violation;
req_chain.req_margin_proxy = req_margin_proxy;

req_chain.total_violation_steps = nnz(req_violation);
req_chain.total_violation_time_s = nnz(req_violation) * outX.case.dt;
req_chain.violation_fraction = nnz(req_violation) / max(numel(req_violation), 1);
req_chain.min_margin_proxy = min(req_margin_proxy, [], 'omitnan');
req_chain.mean_margin_proxy = mean(req_margin_proxy, 'omitnan');

% coincidence with bubble
bubble_flag = logical(outX.bubble.is_bubble(:));
req_chain.coincidence_ratio = nnz(bubble_flag & req_violation) / max(nnz(bubble_flag), 1);
req_chain.note = ['Minimal R6 real-line bridge: requirement-risk proxy is ' ...
                  'defined from inverse rolling-window information, not from full filter covariance projection.'];
end
