function out = package_outerA_bubble_prediction_result(MG_part, req_part, bubble_part, tau_part, area_part)
%PACKAGE_OUTERA_BUBBLE_PREDICTION_RESULT Package outerA bubble prediction result.
%
% outerA now directly outputs:
%   Xi_B, R_B, tau_B, A_B
% instead of abstract tilde-M_R style variables.

assert(isstruct(MG_part), 'MG_part must be struct.');
assert(isstruct(req_part), 'req_part must be struct.');
assert(isstruct(bubble_part), 'bubble_part must be struct.');
assert(isstruct(tau_part), 'tau_part must be struct.');
assert(isstruct(area_part), 'area_part must be struct.');

out = struct();
out.M_G = MG_part.M_G;
out.trace_Wr = MG_part.trace_Wr;
out.minEigWr = MG_part.M_G;

out.margin_series = req_part.margin_series;
out.lambda_max_PR_series = req_part.lambda_max_PR_series;

out.Xi_B = bubble_part.Xi_B;
out.R_B = bubble_part.R_B;
out.idx_min = bubble_part.idx_min;
out.is_bubble = bubble_part.is_bubble;

out.tau_B_idx = tau_part.tau_B_idx;
out.tau_B_time_s = tau_part.tau_B_time_s;
out.has_failure = tau_part.has_failure;

out.A_B = area_part.A_B;
out.excess_series = area_part.excess_series;
end
