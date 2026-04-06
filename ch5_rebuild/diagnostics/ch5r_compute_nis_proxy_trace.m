function nis = ch5r_compute_nis_proxy_trace(ch5case, selection_trace, xpred_hist, P_hist, sigma_angle_rad)
%CH5R_COMPUTE_NIS_PROXY_TRACE
% Shell-aligned NIS proxy for R9/R10/R5-replay.
%
% Outputs:
%   nis.value         = nu' * S^{-1} * nu
%   nis.lambda_min_S  = lambda_min(S)
%   nis.innov_norm    = ||nu||_2

nis = struct();
nis.value = [];
nis.valid = [];
nis.lambda_min_S = [];
nis.innov_norm = [];
nis.mode = 'unavailable';

if nargin < 5 || isempty(xpred_hist) || isempty(P_hist)
    return;
end

Nt = size(xpred_hist,2);
nis.value = nan(Nt,1);
nis.valid = false(Nt,1);
nis.lambda_min_S = nan(Nt,1);
nis.innov_norm = nan(Nt,1);
nis.mode = 'innovation_mahalanobis_proxy';

R = (sigma_angle_rad^2) * eye(4);

for k = 1:Nt
    if k > numel(selection_trace) || ~isstruct(selection_trace{k}) ...
            || ~isfield(selection_trace{k}, 'pair') || isempty(selection_trace{k}.pair)
        continue;
    end

    pair = selection_trace{k}.pair;
    xpred = xpred_hist(:,k);
    Pk = P_hist(:,:,k);
    if ~all(isfinite(xpred)) || ~all(isfinite(Pk(:)))
        continue;
    end

    z_true = local_bearing_measurement_pair(local_get_truth_state(ch5case,k), ch5case, k, pair);
    z_hat  = local_bearing_measurement_pair(xpred, ch5case, k, pair);
    innov  = z_true - z_hat;
    innov(1) = local_wrap_to_pi(innov(1));
    innov(3) = local_wrap_to_pi(innov(3));

    H = local_numeric_jacobian(@(x) local_bearing_measurement_pair(x, ch5case, k, pair), xpred);
    S = H * Pk * H' + R;
    S = 0.5 * (S + S');

    nis.innov_norm(k) = norm(innov, 2);
    nis.lambda_min_S(k) = min(real(eig(S)));

    if rcond(S) > 1e-12
        nis.value(k) = innov' * (S \ innov);
        nis.valid(k) = true;
    end
end
end

function x_true = local_get_truth_state(ch5case, k)
r = local_get_truth_position(ch5case, k);
v = local_get_truth_velocity(ch5case, k);
x_true = [r; v];
end

function r = local_get_truth_position(ch5case, k)
truth = ch5case.truth;
if isfield(truth, 'r_eci_km')
    r = squeeze(truth.r_eci_km(k,:)).';
elseif isfield(truth, 'r_eci')
    r = squeeze(truth.r_eci(k,:)).';
elseif isfield(truth, 'position_km')
    r = squeeze(truth.position_km(k,:)).';
elseif isfield(truth, 'position')
    r = squeeze(truth.position(k,:)).';
else
    error('Truth position field not found.');
end
end

function v = local_get_truth_velocity(ch5case, k)
truth = ch5case.truth;
if isfield(truth, 'v_eci_kmps')
    v = squeeze(truth.v_eci_kmps(k,:)).';
    return;
elseif isfield(truth, 'v_eci')
    v = squeeze(truth.v_eci(k,:)).';
    return;
elseif isfield(truth, 'velocity_kmps')
    v = squeeze(truth.velocity_kmps(k,:)).';
    return;
elseif isfield(truth, 'velocity')
    v = squeeze(truth.velocity(k,:)).';
    return;
end

Nt = numel(ch5case.t_s);
dt = ch5case.dt;

if k == 1
    r0 = local_get_truth_position(ch5case,1);
    r1 = local_get_truth_position(ch5case,2);
    v = (r1-r0)/dt;
elseif k == Nt
    r0 = local_get_truth_position(ch5case,Nt-1);
    r1 = local_get_truth_position(ch5case,Nt);
    v = (r1-r0)/dt;
else
    rm = local_get_truth_position(ch5case,k-1);
    rp = local_get_truth_position(ch5case,k+1);
    v = (rp-rm)/(2*dt);
end
end

function z = local_bearing_measurement_pair(x, ch5case, k, pair)
z1 = local_bearing_single(x(1:3), squeeze(ch5case.satbank.r_eci_km(k,:,pair(1))).');
z2 = local_bearing_single(x(1:3), squeeze(ch5case.satbank.r_eci_km(k,:,pair(2))).');
z = [z1; z2];
end

function z = local_bearing_single(r_tgt, r_sat)
los = r_tgt - r_sat;
x = los(1); y = los(2); zc = los(3);
az = atan2(y, x);
el = atan2(zc, sqrt(x^2 + y^2));
z = [az; el];
end

function H = local_numeric_jacobian(fun, x)
z0 = fun(x);
m = numel(z0);
n = numel(x);
H = zeros(m,n);
eps_fd = 1e-6;
for i = 1:n
    dx = zeros(n,1);
    dx(i) = eps_fd;
    zp = fun(x + dx);
    zm = fun(x - dx);
    H(:,i) = (zp - zm) / (2*eps_fd);
end
end

function a = local_wrap_to_pi(a)
a = mod(a + pi, 2*pi) - pi;
end
