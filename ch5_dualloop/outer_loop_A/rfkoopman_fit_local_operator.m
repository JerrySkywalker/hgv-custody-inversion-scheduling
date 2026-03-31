function A = rfkoopman_fit_local_operator(X, cfg)
%RFKOOPMAN_FIT_LOCAL_OPERATOR  Fit a robust stabilized local Koopman-style operator.
%
% Input:
%   X   : [n x d] local lifted state sequence
%   cfg : optional config
%
% Output:
%   A   : [d x d] local operator such that x_{k+1} ~= A * x_k
%
% Robust strategy:
%   1) inspect numerical rank using SVD
%   2) if full-rank enough: use ridge least squares
%   3) if rank-deficient but usable: fit only in effective low-rank subspace
%   4) if rank too low: fall back to identity
%   5) apply spectral-radius clipping

assert(size(X,1) >= 2, 'Need at least 2 samples to fit local operator.');

X0 = X(1:end-1, :);
X1 = X(2:end,   :);

d = size(X0, 2);

if nargin >= 2 && ~isempty(cfg) && isfield(cfg, 'ch5')
    lambda = cfg.ch5.outerA_ridge_lambda;
    rank_rel_tol = cfg.ch5.outerA_rank_rel_tol;
    rank_fallback_min = cfg.ch5.outerA_rank_fallback_min;
    rho_max = cfg.ch5.outerA_rho_max;
else
    lambda = 1.0e-2;
    rank_rel_tol = 1.0e-6;
    rank_fallback_min = 2;
    rho_max = 0.90;
end

[U,S,V] = svd(X0, 'econ');
s = diag(S);

if isempty(s)
    A = eye(d);
    return;
end

tol = max(size(X0)) * max(s) * rank_rel_tol;
r = sum(s > tol);

% Case 1: enough rank, fit full model with ridge
if r >= d
    B = (X0' * X0 + lambda * eye(d)) \ (X0' * X1);

% Case 2: rank-deficient but still has useful subspace
elseif r >= rank_fallback_min
    Vr = V(:, 1:r);
    Z0 = X0 * Vr;
    Z1 = X1 * Vr;

    Br = (Z0' * Z0 + lambda * eye(r)) \ (Z0' * Z1);

    % lift back to original space and keep only effective subspace dynamics
    P = Vr * Vr';
    B = Vr * Br * Vr';
    B = P * B * P;

% Case 3: rank too low, do not trust fitted dynamics
else
    A = eye(d);
    return;
end

A = B.';

% Spectral-radius clipping
try
    eigA = eig(A);
    rho = max(abs(eigA));
catch
    rho = inf;
end

if isfinite(rho) && rho > rho_max && rho > 0
    A = A * (rho_max / rho);
end
end
