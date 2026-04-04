function out = compute_structural_metric_MG(W)
%COMPUTE_STRUCTURAL_METRIC_MG Compute M_G from predicted window Gramian.
%
% By current convention:
%   M_G = lambda_min(W)

assert(isnumeric(W) && ismatrix(W), 'W must be a numeric matrix.');
assert(size(W,1) == size(W,2), 'W must be square.');

W = 0.5 * (W + W.');
eigvals = eig(W);
eigvals = real(eigvals);

out = struct();
out.W = W;
out.eigvals = sort(eigvals, 'ascend');
out.M_G = out.eigvals(1);
out.trace_W = trace(W);
out.cond_W = cond(W);
end
