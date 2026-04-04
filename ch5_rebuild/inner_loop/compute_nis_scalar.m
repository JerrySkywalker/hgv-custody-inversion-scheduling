function nis = compute_nis_scalar(nu, S)
%COMPUTE_NIS_SCALAR Compute scalar NIS value.
%
% Inputs:
%   nu : innovation vector
%   S  : innovation covariance
%
% Output:
%   nis = nu' * inv(S) * nu

assert(isnumeric(nu) && isvector(nu), 'nu must be a numeric vector.');
nu = nu(:);

assert(isnumeric(S) && ismatrix(S), 'S must be a numeric matrix.');
assert(all(size(S) == [numel(nu), numel(nu)]), 'S dimension mismatch.');

nis = nu' * (S \ nu);
nis = real(nis);
end
