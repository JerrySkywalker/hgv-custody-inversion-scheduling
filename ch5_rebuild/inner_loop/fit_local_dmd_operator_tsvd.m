function model = fit_local_dmd_operator_tsvd(X_prev, X_next, varargin)
%FIT_LOCAL_DMD_OPERATOR_TSVD Fit a truncated-SVD local affine DMD operator.
%
% Inputs:
%   X_prev: [nx x N]
%   X_next: [nx x N]
%
% Optional name-value:
%   'rank_trunc' : retained rank (default = nx)
%
% Output:
%   model.A
%   model.b
%   model.nx
%   model.n_samples
%   model.rank_trunc
%   model.fit_mode = 'tsvd'

p = inputParser;
addParameter(p, 'rank_trunc', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 1));
parse(p, varargin{:});

assert(isnumeric(X_prev) && isnumeric(X_next), 'X_prev and X_next must be numeric.');
assert(ismatrix(X_prev) && ismatrix(X_next), 'X_prev and X_next must be matrices.');
assert(all(size(X_prev) == size(X_next)), 'X_prev and X_next must have identical size.');

[nx, N] = size(X_prev);
assert(N >= 2, 'At least 2 samples are required.');

Phi = [X_prev; ones(1, N)];

[U, S, V] = svd(Phi, 'econ');
s = diag(S);

if isempty(p.Results.rank_trunc)
    r = min(nx + 1, numel(s));
else
    r = min(p.Results.rank_trunc, numel(s));
end

U_r = U(:, 1:r);
S_r = S(1:r, 1:r);
V_r = V(:, 1:r);

Theta = X_next * V_r / S_r * U_r.';
A = Theta(:, 1:nx);
b = Theta(:, end);

model = struct();
model.A = A;
model.b = b;
model.nx = nx;
model.n_samples = N;
model.rank_trunc = r;
model.fit_mode = 'tsvd';
end
