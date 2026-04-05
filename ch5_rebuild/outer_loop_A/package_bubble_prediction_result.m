function out = package_bubble_prediction_result(MR_part, MG_part, demand_part, supply_part, bubble_part)
%PACKAGE_BUBBLE_PREDICTION_RESULT Package R8-A bubble-variable prediction result.

assert(isstruct(MR_part), 'MR_part must be a struct.');
assert(isstruct(MG_part), 'MG_part must be a struct.');
assert(isstruct(demand_part), 'demand_part must be a struct.');
assert(isstruct(supply_part), 'supply_part must be a struct.');
assert(isstruct(bubble_part), 'bubble_part must be a struct.');

out = struct();

out.M_R = MR_part.M_R;
out.trace_PR_plus = MR_part.trace_PR_plus;
out.trace_PR_minus = MR_part.trace_PR_minus;
out.delta_trace = MR_part.delta_trace;

out.M_G = MG_part.M_G;
out.trace_Wr = MG_part.trace_Wr;
out.minEigWr = MG_part.M_G;

out.D_r = demand_part.D_r;
out.S_r = supply_part.S_r;
out.idx_min = supply_part.idx_min;

out.Xi_B = bubble_part.Xi_B;
out.R_B = bubble_part.R_B;
out.is_bubble = bubble_part.is_bubble;
end
