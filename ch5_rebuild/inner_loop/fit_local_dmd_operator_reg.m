function model = fit_local_dmd_operator_reg(X_prev, X_next, varargin)
%FIT_LOCAL_DMD_OPERATOR_REG Fit a regularized local affine DMD operator.
%
% Inputs:
%   X_prev: [nx x N]
%   X_next: [nx x N]
%
% Optional name-value:
%   'lambda_reg' : Tikhonov regularization (default 1e-4)
%
% Output:
%   model.A
%   model.b
%   model.nx
%   model.n_samples
%   model.lambda_reg
%   model.fit_mode = 'reg'

p = inputParser;
addParameter(p, 'lambda_reg', 1e-4, @(x) isnumeric(x) && isscalar(x) && x >= 0);
parse(p, varargin{:});

lambda_reg = p.Results.lambda_reg;

assert(isnumeric(X_prev) && isnumeric(X_next), 'X_prev and X_next must be numeric.');
assert(ismatrix(X_prev) && ismatrix(X_next), 'X_prev and X_next must be matrices.');
assert(all(size(X_prev) == size(X_next)), 'X_prev and X_next must have identical size.');

[nx, N] = size(X_prev);
assert(N >= 2, 'At least 2 samples are required.');

Phi = [X_prev; ones(1, N)];
G = Phi * Phi.';
Theta = (X_next * Phi.') / (G + lambda_reg * eye(nx + 1));

A = Theta(:, 1:nx);
b = Theta(:, end);

model = struct();
model.A = A;
model.b = b;
model.nx = nx;
model.n_samples = N;
model.lambda_reg = lambda_reg;
model.fit_mode = 'reg';
end
