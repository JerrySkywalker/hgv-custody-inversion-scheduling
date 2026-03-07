function dX = hgv_vtc_dynamics(t, X, ctrl, p)
% hgv_vtc_dynamics  CAV-H + US76 的 VTC 质点动力学（复用 Chapter2）
% 状态 X = [v, theta, sigma, phi, lambda, r]^T

v  = X(1);
th = X(2);
si = X(3);
ph = X(4);
la = X(5);
r  = X(6);

h = r - p.Re;
if h <= 0
    dX = zeros(6,1);
    return;
end

[rho, a_s] = atmosphere_us76(h);
Ma = v / a_s;
alpha = deg2rad(ctrl.alpha(t));
gamma = deg2rad(ctrl.gamma(t));

CL = p.coef_L(1) + p.coef_L(2)*alpha + p.coef_L(3)*alpha^2 + p.coef_L(4)*Ma + p.coef_L(5)*exp(p.coef_L(6)*Ma);
CD = p.coef_D(1) + p.coef_D(2)*alpha + p.coef_D(3)*alpha^2 + p.coef_D(4)*Ma + p.coef_D(5)*exp(p.coef_D(6)*Ma);

Q = 0.5 * rho * v^2 * p.S;
L = Q * CL;
D = Q * CD;

dv  = -D/p.m - p.mu/r^2 * sin(th);
dth = (L*cos(gamma) - p.m*p.g0*cos(th) + p.m*v^2/r*cos(th)) / (p.m*v);
dsi = -(L*sin(gamma)) / (p.m*v*cos(th)) + (v/r)*cos(th)*sin(si)*tan(ph);
dph = v*cos(th)*cos(si) / r;
dla = -v*cos(th)*sin(si) / (r*cos(ph));
dr  = v*sin(th);

dX = [dv; dth; dsi; dph; dla; dr];
end