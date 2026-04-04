function out = compute_structural_metric_MG(W, Cr)
%COMPUTE_STRUCTURAL_METRIC_MG Compute M_G on a critical subspace.
%
% Inputs:
%   W  : [nx x nx] dynamic local observability Gramian
%   Cr : [nr x nx] critical-subspace projection matrix
%
% Output:
%   out.W
%   out.Wr
%   out.eigvals_W
%   out.eigvals_Wr
%   out.M_G
%   out.trace_W
%   out.trace_Wr
%   out.cond_W
%   out.cond_Wr
%
% Definition:
%   W_r = C_r * W * C_r'
%   M_G = lambda_min(W_r)

assert(isnumeric(W) && ismatrix(W), 'W must be a numeric matrix.');
assert(size(W,1) == size(W,2), 'W must be square.');
assert(isnumeric(Cr) && ismatrix(Cr), 'Cr must be a numeric matrix.');
assert(size(Cr,2) == size(W,1), 'Cr dimension mismatch.');

W = 0.5 * (W + W.');
Wr = Cr * W * Cr.';
Wr = 0.5 * (Wr + Wr.');

eigvals_W = sort(real(eig(W)), 'ascend');
eigvals_Wr = sort(real(eig(Wr)), 'ascend');

out = struct();
out.W = W;
out.Wr = Wr;
out.eigvals_W = eigvals_W;
out.eigvals_Wr = eigvals_Wr;
out.M_G = eigvals_Wr(1);
out.trace_W = trace(W);
out.trace_Wr = trace(Wr);
out.cond_W = cond(W);
out.cond_Wr = cond(Wr);
end
