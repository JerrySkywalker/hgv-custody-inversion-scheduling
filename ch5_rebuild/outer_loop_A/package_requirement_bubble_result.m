function out = package_requirement_bubble_result(MG_part, req_part, bubble_part)
%PACKAGE_REQUIREMENT_BUBBLE_RESULT Package requirement-induced bubble result.

assert(isstruct(MG_part), 'MG_part must be struct.');
assert(isstruct(req_part), 'req_part must be struct.');
assert(isstruct(bubble_part), 'bubble_part must be struct.');

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
end
