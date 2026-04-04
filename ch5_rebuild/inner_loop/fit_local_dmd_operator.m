function model = fit_local_dmd_operator(X_prev, X_next, varargin)
%FIT_LOCAL_DMD_OPERATOR Fit a regularized local linear operator for state propagation.
%
% model usage:
%   x_next_pred = model.A * x_now + model.b
%
% Inputs:
%   X_prev: [n x N] previous state samples
%   X_next: [n x N] next state samples
%
% Optional name-value:
%   'lambda_reg' : Tikhonov regularization (default 1e-6)
%
% Output:
%   model.A, model.b, model.nx, model.n_samples, model.lambda_reg

p = inputParser;
addParameter(p, 'lambda_reg', 1e-6, @(x) isnumeric(x) && isscalar(x) && x >= 0);
parse(p, varargin{:});

lambda_reg = p.Results.lambda_reg;

assert(isnumeric(X_prev) && isnumeric(X_next), 'X_prev and X_next must be numeric.');
assert(ismatrix(X_prev) && ismatrix(X_next), 'X_prev and X_next must be matrices.');
assert(all(size(X_prev) == size(X_next)), 'X_prev and X_next must have identical size.');

[nx, N] = size(X_prev);
assert(N >= 2, 'At least 2 samples are required.');

Phi = [X_prev; ones(1, N)];
G = Phi * Phi.';
R = lambda_reg * eye(nx + 1);
Theta = (X_next * Phi.') / (G + R);

A = Theta(:, 1:nx);
b = Theta(:, end);

model = struct();
model.A = A;
model.b = b;
model.nx = nx;
model.n_samples = N;
model.lambda_reg = lambda_reg;
end
