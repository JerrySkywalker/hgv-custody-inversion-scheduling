function model = fit_local_dmd_operator_tsvd_reg(X_prev, X_next, opts)
%FIT_LOCAL_DMD_OPERATOR_TSVD_REG
% Stabilized local DMD with:
%   - per-dimension standardization
%   - truncated SVD
%   - adaptive ridge in reduced coordinates
%
% Inputs:
%   X_prev : [nx x m]
%   X_next : [nx x m]
%   opts fields:
%       tsvd_rel_tol   (default 1e-6)
%       max_rank       (default [])
%       ridge_alpha    (default 1e-6)
%       sigma_floor    (default 1e-9)
%
% Outputs:
%   model.A_std        : standardized-space propagation
%   model.F_orig       : original-space propagation
%   model.mu           : [nx x 1]
%   model.sigma        : [nx x 1]
%   model.rank         : retained rank
%   model.svals        : singular values of standardized X_prev
%   model.lambda_red   : reduced ridge parameter

assert(isnumeric(X_prev) && ismatrix(X_prev) && ~isempty(X_prev), 'X_prev invalid.');
assert(isnumeric(X_next) && ismatrix(X_next) && ~isempty(X_next), 'X_next invalid.');
assert(all(size(X_prev) == size(X_next)), 'X_prev and X_next must have same size.');

if nargin < 3 || isempty(opts)
    opts = struct();
end

tsvd_rel_tol = local_get_opt(opts, 'tsvd_rel_tol', 1e-6);
max_rank     = local_get_opt(opts, 'max_rank', []);
ridge_alpha  = local_get_opt(opts, 'ridge_alpha', 1e-6);
sigma_floor  = local_get_opt(opts, 'sigma_floor', 1e-9);

[nx, m] = size(X_prev);
assert(m >= 2, 'Need at least two snapshot columns.');

mu = mean(X_prev, 2);
sigma = std(X_prev, 0, 2);
sigma = max(sigma, sigma_floor);

Dinv = diag(1 ./ sigma);
D    = diag(sigma);

Xp = Dinv * (X_prev - mu);
Xn = Dinv * (X_next - mu);

[U, S, V] = svd(Xp, 'econ');
s = diag(S);

if isempty(s)
    error('SVD failed: empty singular spectrum.');
end

r = sum(s / s(1) >= tsvd_rel_tol);
r = max(r, 1);
if ~isempty(max_rank)
    r = min(r, max_rank);
end

Ur = U(:,1:r);
Sr = S(1:r,1:r);
Vr = V(:,1:r);
sr = diag(Sr);

lambda_red = ridge_alpha * max(mean(sr.^2), sigma_floor);

G = diag(sr ./ (sr.^2 + lambda_red));
A_std = Xn * Vr * G * Ur.';
F_orig = D * A_std * Dinv;

model = struct();
model.A_std = A_std;
model.F_orig = F_orig;
model.mu = mu;
model.sigma = sigma;
model.rank = r;
model.svals = s;
model.lambda_red = lambda_red;
model.meta = struct( ...
    'nx', nx, ...
    'm', m, ...
    'tsvd_rel_tol', tsvd_rel_tol, ...
    'ridge_alpha', ridge_alpha, ...
    'sigma_floor', sigma_floor);
end

function v = local_get_opt(opts, name, default_v)
if isfield(opts, name)
    v = opts.(name);
else
    v = default_v;
end
end
