function w = map_tildeMR_to_scheduler_weights(tildeMR_k, cfgB)
%MAP_TILDEMR_TO_SCHEDULER_WEIGHTS Map \tilde{M}_R(k) to outerB weights.
%
% Inputs:
%   tildeMR_k : scalar \tilde{M}_R(k)
%   cfgB      : struct with fields
%       .alpha0
%       .beta0
%       .eta0
%       .mu0
%       .kappa_alpha
%       .kappa_beta
%       .kappa_eta
%
% Outputs:
%   w.alpha_k
%   w.beta_k
%   w.eta_k
%   w.mu_k

assert(isnumeric(tildeMR_k) && isscalar(tildeMR_k) && isfinite(tildeMR_k), ...
    'tildeMR_k must be a finite scalar.');
assert(isstruct(cfgB), 'cfgB must be a struct.');

required_fields = {'alpha0','beta0','eta0','mu0','kappa_alpha','kappa_beta','kappa_eta'};
for i = 1:numel(required_fields)
    assert(isfield(cfgB, required_fields{i}), 'cfgB missing field: %s', required_fields{i});
end

w = struct();
w.alpha_k = cfgB.alpha0 * (1 + cfgB.kappa_alpha * tildeMR_k);
w.beta_k  = cfgB.beta0  * (1 + cfgB.kappa_beta  * tildeMR_k);
w.eta_k   = cfgB.eta0   / (1 + cfgB.kappa_eta   * tildeMR_k);
w.mu_k    = cfgB.mu0;
end
