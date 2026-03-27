function dX = hgv_vtc_dynamics(t, X, target_cfg)
%HGV_VTC_DYNAMICS HGV VTC point-mass dynamics using target_cfg.
%   State X = [v, theta, sigma, phi, lambda, r]^T

if nargin < 3 || ~isstruct(target_cfg)
    error('hgv_vtc_dynamics:InvalidInput', ...
        'target_cfg must be a struct.');
end

v  = X(1);
th = X(2);
si = X(3);
ph = X(4);
la = X(5); %#ok<NASGU>
r  = X(6);

Re = target_cfg.planet.re_m;
h = r - Re;
if h <= 0
    dX = zeros(6,1);
    return;
end

[rho, a_s] = eval_atmosphere_model(h, target_cfg);
Ma = v / a_s;

alpha = deg2rad(target_cfg.control_profile.alpha_deg);
gamma = deg2rad(target_cfg.control_profile.bank_deg);

coef_L = target_cfg.aero.coef_L;
coef_D = target_cfg.aero.coef_D;

CL = coef_L(1) + coef_L(2)*alpha + coef_L(3)*alpha^2 + coef_L(4)*Ma + coef_L(5)*exp(coef_L(6)*Ma);
CD = coef_D(1) + coef_D(2)*alpha + coef_D(3)*alpha^2 + coef_D(4)*Ma + coef_D(5)*exp(coef_D(6)*Ma);

Q = 0.5 * rho * v^2 * target_cfg.dynamics.s_ref_m2;
L = Q * CL;
D = Q * CD;

m  = target_cfg.dynamics.mass0_kg;
mu = target_cfg.planet.mu_m3_s2;
g0 = target_cfg.planet.g0_mps2;

dv  = -D/m - mu/r^2 * sin(th);
dth = (L*cos(gamma) - m*g0*cos(th) + m*v^2/r*cos(th)) / (m*v);
dsi = -(L*sin(gamma)) / (m*v*cos(th)) + (v/r)*cos(th)*sin(si)*tan(ph);
dph = v*cos(th)*cos(si) / r;
dla = -v*cos(th)*sin(si) / (r*cos(ph));
dr  = v*sin(th);

dX = [dv; dth; dsi; dph; dla; dr];
end
