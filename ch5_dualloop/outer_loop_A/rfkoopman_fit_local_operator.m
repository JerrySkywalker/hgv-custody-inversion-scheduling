function A = rfkoopman_fit_local_operator(X, cfg)
%RFKOOPMAN_FIT_LOCAL_OPERATOR  Fit a stabilized local linear Koopman-style operator.
%
% Input:
%   X   : [n x d] local lifted state sequence
%   cfg : optional config, used for spectral-radius clipping
%
% Output:
%   A   : [d x d] local operator such that x_{k+1} ~= A * x_k

assert(size(X,1) >= 2, 'Need at least 2 samples to fit local operator.');

X0 = X(1:end-1, :);
X1 = X(2:end,   :);

A = X0 \ X1;
A = A.';

if nargin >= 2 && ~isempty(cfg) && isfield(cfg, 'ch5') && isfield(cfg.ch5, 'outerA_rho_max')
    rho_max = cfg.ch5.outerA_rho_max;
else
    rho_max = 0.90;
end

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
