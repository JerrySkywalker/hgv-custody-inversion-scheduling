function PR = compute_requirement_cov_PR(P_plus, Cr)
%COMPUTE_REQUIREMENT_COV_PR Compute demand/critical-subspace covariance P_R.
%
% Definition:
%   P_R = C_r * P_plus * C_r'
%
% Inputs:
%   P_plus : posterior covariance [nx x nx]
%   Cr     : critical-subspace projection [nr x nx]
%
% Output:
%   PR     : demand-subspace covariance [nr x nr]

assert(isnumeric(P_plus) && ismatrix(P_plus), 'P_plus must be a matrix.');
assert(size(P_plus,1) == size(P_plus,2), 'P_plus must be square.');
assert(isnumeric(Cr) && ismatrix(Cr), 'Cr must be a matrix.');
assert(size(Cr,2) == size(P_plus,1), 'Cr dimension mismatch.');

P_plus = 0.5 * (P_plus + P_plus.');
PR = Cr * P_plus * Cr.';
PR = 0.5 * (PR + PR.');
end
