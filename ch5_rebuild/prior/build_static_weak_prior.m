function prior = build_static_weak_prior(cfg, ch5case)
%BUILD_STATIC_WEAK_PRIOR
% Build a weak prior descriptor from theta_star and current fixed constellation.

if nargin < 2
    error('cfg and ch5case are required.');
end

prior = struct();
prior.theta_star = cfg.ch5r.theta_star;
prior.Ns = ch5case.satbank.Ns;
prior.note = 'Weak prior from static theta_star; used only for tie-break or soft preference.';
end
