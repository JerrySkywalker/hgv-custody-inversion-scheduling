function ch5case = build_ch5r_case(cfg)
%BUILD_CH5R_CASE  Build minimal Chapter 5 R1 case for bubble evaluation.
%
% Phase R1 policy:
% - do not build a full tracker
% - do not depend on old ch5_dualloop
% - build a minimal time-indexed information case
%
% Output fields:
%   ch5case.time_s
%   ch5case.window
%   ch5case.gamma_req
%   ch5case.target_case
%   ch5case.theta
%   ch5case.info_series   [n_state x n_state x N]
%   ch5case.meta

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params();
end

theta = cfg.ch5r.theta_star;
gamma_req = cfg.ch5r.gamma_req;

t0 = 0;
dt = 10;
tf = 200;
time_s = (t0:dt:tf).';
N = numel(time_s);

window_length_s = 60;
window_length_steps = max(1, round(window_length_s / dt));

n_state = 6;
info_series = zeros(n_state, n_state, N);

for k = 1:N
    info_series(:,:,k) = local_make_information_matrix(k, N, theta, gamma_req);
end

ch5case = struct();
ch5case.time_s = time_s;
ch5case.dt = dt;
ch5case.window = struct();
ch5case.window.length_s = window_length_s;
ch5case.window.length_steps = window_length_steps;
ch5case.gamma_req = gamma_req;
ch5case.target_case = cfg.ch5r.target_case;
ch5case.theta = theta;
ch5case.info_series = info_series;

ch5case.meta = struct();
ch5case.meta.phase_name = 'R1';
ch5case.meta.case_type = 'minimal_information_case';
ch5case.meta.source = mfilename;
ch5case.meta.note = ['R1 minimal synthetic information series built from theta_star; ' ...
    'used only for bubble-state pipeline smoke.'];
end

function Yk = local_make_information_matrix(k, N, theta, gamma_req)
% Construct a deterministic SPD information matrix with a strong valley.
% The design target in R1a is explicit:
%   rolling-window lambda_min must cross below gamma_req for a mid-horizon segment.

n = 6;

ns_factor = max(theta.Ns / 100, 0.5);
dg_factor = max(theta.DG, 0.5);

% Lower baseline than previous version, so rolling window does not stay too high.
baseline = gamma_req * (0.42 + 0.04 * ns_factor + 0.02 * dg_factor);

% Strong and wide valley so the rolling sum also shows a bubble interval.
valley_depth = gamma_req * 0.34;
center = 0.62 * N;
width = 0.18 * N;

s = k;
dip = valley_depth * exp(-((s - center)^2) / (2 * width^2));

diag_vals = [ ...
    baseline - 1.00 * dip, ...
    baseline * 1.04 - 0.92 * dip, ...
    baseline * 1.09 - 0.78 * dip, ...
    baseline * 1.18 - 0.42 * dip, ...
    baseline * 1.30 - 0.28 * dip, ...
    baseline * 1.46 - 0.18 * dip];

diag_vals = max(diag_vals, 1e-3);

Yk = diag(diag_vals);

C = [ ...
    0    0.03 0.01 0    0    0; ...
    0.03 0    0.02 0.01 0    0; ...
    0.01 0.02 0    0.02 0.01 0; ...
    0    0.01 0.02 0    0.02 0.01; ...
    0    0    0.01 0.02 0    0.03; ...
    0    0    0    0.01 0.03 0];

scale = 0.008 * baseline;
Yk = Yk + scale * C;

Yk = 0.5 * (Yk + Yk.');

mineig = min(eig(Yk));
if mineig <= 0
    Yk = Yk + (abs(mineig) + 1e-6) * eye(n);
end
end
