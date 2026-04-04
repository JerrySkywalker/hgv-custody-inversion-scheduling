function out = compute_outerA_upper_bound_tildeMR(MR_raw, s_k, meas_dim, MG_k, PR_k, cfgA)
%COMPUTE_OUTERA_UPPER_BOUND_TILDEMR Compute outerA conservative upper bound \tilde{M}_R.
%
% Inputs:
%   MR_raw   : raw M_R scalar
%   s_k      : NIS scalar
%   meas_dim : measurement dimension
%   MG_k     : structural metric M_G scalar
%   PR_k     : demand-subspace covariance P_R
%   cfgA     : config struct with fields:
%       .tau_s
%       .tau_g
%       .tau_p
%       .alpha_s
%       .alpha_g
%       .alpha_p
%       .eps_warn
%       .Gamma_req
%
% Outputs:
%   out.tildeMR
%   out.GammaA
%   out.gs
%   out.gg
%   out.gp
%   out.lambda_max_PR

assert(isnumeric(MR_raw) && isscalar(MR_raw) && isfinite(MR_raw), 'MR_raw must be a scalar.');
assert(isnumeric(s_k) && isscalar(s_k) && isfinite(s_k) && s_k >= 0, 's_k invalid.');
assert(isnumeric(meas_dim) && isscalar(meas_dim) && meas_dim >= 1, 'meas_dim invalid.');
assert(isnumeric(MG_k) && isscalar(MG_k) && isfinite(MG_k), 'MG_k invalid.');
assert(isnumeric(PR_k) && ismatrix(PR_k), 'PR_k must be a matrix.');
assert(isstruct(cfgA), 'cfgA must be a struct.');

required_fields = {'tau_s','tau_g','tau_p','alpha_s','alpha_g','alpha_p','eps_warn','Gamma_req'};
for i = 1:numel(required_fields)
    assert(isfield(cfgA, required_fields{i}), 'cfgA missing field: %s', required_fields{i});
end

PR_k = 0.5 * (PR_k + PR_k.');
lambda_max_PR = max(real(eig(PR_k)));

% standardized NIS deviation
ds = abs(s_k - meas_dim) / sqrt(2 * meas_dim);

% logistic helpers
sigmoid = @(x) 1 ./ (1 + exp(-x));

gs = sigmoid(ds / cfgA.tau_s);
gg = sigmoid((cfgA.eps_warn - MG_k) / cfgA.tau_g);
gp = sigmoid((lambda_max_PR - cfgA.Gamma_req) / cfgA.tau_p);

GammaA = 1 + cfgA.alpha_s * gs + cfgA.alpha_g * gg + cfgA.alpha_p * gp;
tildeMR = MR_raw * GammaA;

out = struct();
out.tildeMR = tildeMR;
out.GammaA = GammaA;
out.gs = gs;
out.gg = gg;
out.gp = gp;
out.lambda_max_PR = lambda_max_PR;
out.ds = ds;
end
