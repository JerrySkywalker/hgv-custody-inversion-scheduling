function out = package_outerA_result(MR_raw_struct, MG_struct, outerA_struct, mode_struct, PR_k)
%PACKAGE_OUTERA_RESULT Package outerA result for logging and downstream use.

assert(isstruct(MR_raw_struct), 'MR_raw_struct must be a struct.');
assert(isstruct(MG_struct), 'MG_struct must be a struct.');
assert(isstruct(outerA_struct), 'outerA_struct must be a struct.');
assert(isstruct(mode_struct), 'mode_struct must be a struct.');
assert(isnumeric(PR_k) && ismatrix(PR_k), 'PR_k must be a matrix.');

out = struct();
out.M_R = MR_raw_struct.M_R;
out.trace_PR_plus = MR_raw_struct.trace_PR_plus;
out.trace_PR_minus = MR_raw_struct.trace_PR_minus;
out.delta_trace = MR_raw_struct.delta_trace;

out.M_G = MG_struct.M_G;
out.trace_Wr = MG_struct.trace_Wr;
out.minEigWr = MG_struct.M_G;

out.P_R = PR_k;
out.lambda_max_PR = outerA_struct.lambda_max_PR;

out.tildeMR = outerA_struct.tildeMR;
out.GammaA = outerA_struct.GammaA;
out.gs = outerA_struct.gs;
out.gg = outerA_struct.gg;
out.gp = outerA_struct.gp;
out.ds = outerA_struct.ds;

out.mode = mode_struct.label;
out.mode_code = mode_struct.code;
end
