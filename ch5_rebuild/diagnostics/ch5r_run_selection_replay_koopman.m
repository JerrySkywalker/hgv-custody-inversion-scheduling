function replay_out = ch5r_run_selection_replay_koopman(phase_name, out_phase, save_outputs, log_enable)
%CH5R_RUN_SELECTION_REPLAY_KOOPMAN
% Diagnostic replay only.
% Replays a fixed selection trace with Koopman + IEKF-like update
% to obtain xpred_hist / P_hist / rmse_pos_km for diagnostics.

if nargin < 3 || isempty(save_outputs)
    save_outputs = true;
end
if nargin < 4 || isempty(log_enable)
    log_enable = true;
end

addpath(fullfile(pwd, 'ch5_rebuild', 'r9_inner'));
addpath(fullfile(pwd, 'ch5_rebuild', 'params'));

cfg = out_phase.cfg;
cfg = local_attach_r9_replay_params(cfg);

ch5case = out_phase.case;
selection_trace = out_phase.selection_trace;

Nt = numel(ch5case.t_s);
dt = ch5case.dt;

xhat_hist = nan(6,Nt);
xpred_hist = nan(6,Nt);
P_hist = nan(6,6,Nt);
rmse_pos_km = nan(Nt,1);

x_true_1 = local_get_truth_state(ch5case, 1);
xhat = x_true_1 + [cfg.ch5r.r9.init_pos_sigma_km * randn(3,1); ...
                   cfg.ch5r.r9.init_vel_sigma_kmps * randn(3,1)];
P = diag([cfg.ch5r.r9.init_pos_sigma_km^2 * ones(1,3), ...
          cfg.ch5r.r9.init_vel_sigma_kmps^2 * ones(1,3)]);

state_buffer = nan(6,0);
t_total = tic;

disp(['[replay][' phase_name '] start'])
disp(['[replay][' phase_name '] Nt=' num2str(Nt) ', dt=' num2str(dt) ' s'])

for k = 1:Nt
    t_step = tic;

    if size(state_buffer,2) >= 2
        recent_steps = min(cfg.ch5r.r9.dmd_recent_steps, size(state_buffer,2));
        X_hist = state_buffer(:, end-recent_steps+1:end);
        model = fit_local_koopman_dmd(X_hist, dt, cfg);
    else
        model = fit_local_koopman_dmd(nan(6,0), dt, cfg);
    end

    if ~isfield(model, 'Q') || isempty(model.Q)
        qpos = cfg.ch5r.r9.pos_q_km^2;
        qvel = cfg.ch5r.r9.vel_q_kmps^2;
        model.Q = blkdiag(qpos*eye(3), qvel*eye(3));
    end

    [x_pred, P_pred] = propagate_koopman_state(xhat, P, model, cfg);

    pair = [];
    if k <= numel(selection_trace) && isstruct(selection_trace{k}) ...
            && isfield(selection_trace{k}, 'pair') && ~isempty(selection_trace{k}.pair)
        pair = selection_trace{k}.pair;
    end

    if isempty(pair)
        xhat = x_pred;
        P = P_pred;
    else
        z_true = local_bearing_measurement_pair(local_get_truth_state(ch5case,k), ch5case, k, pair);
        [xhat, P] = local_iekf_update_pair(x_pred, P_pred, z_true, ch5case, k, pair, cfg);
    end

    xpred_hist(:,k) = x_pred;
    xhat_hist(:,k) = xhat;
    P_hist(:,:,k) = P;

    x_true_k = local_get_truth_state(ch5case, k);
    rmse_pos_km(k) = norm(xhat(1:3) - x_true_k(1:3), 2);

    state_buffer(:,end+1) = xhat; %#ok<AGROW>

    if log_enable
        do_log = (k == 1) || (k == Nt) || (mod(k,20) == 0);
        if do_log
            if isempty(pair)
                disp(['[replay][' phase_name '][k=' num2str(k) '/' num2str(Nt) '] pair=[] rmsePos=' num2str(rmse_pos_km(k),'%.6g') ...
                    ' stepTime=' num2str(toc(t_step),'%.3f') 's elapsed=' num2str(toc(t_total),'%.3f') 's'])
            else
                disp(['[replay][' phase_name '][k=' num2str(k) '/' num2str(Nt) '] pair=[' num2str(pair(1)) ' ' num2str(pair(2)) '] rmsePos=' num2str(rmse_pos_km(k),'%.6g') ...
                    ' stepTime=' num2str(toc(t_step),'%.3f') 's elapsed=' num2str(toc(t_total),'%.3f') 's'])
            end
        end
    end
end

out_dir = fullfile(cfg.ch5r.output_root, ['phase' phase_name '_diag_replay']);
stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
artifact_tag = ch5r_make_artifact_tag(ch5case, stamp, {['diag-replay-' lower(phase_name)]});
if save_outputs
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    mat_file = fullfile(out_dir, ['phase' phase_name '_diag_replay_' artifact_tag '.mat']);
    save(mat_file, 'cfg', 'ch5case', 'selection_trace', 'xhat_hist', 'xpred_hist', 'P_hist', 'rmse_pos_km');
else
    mat_file = '';
end

disp(['[replay][' phase_name '] done'])
disp(['[replay][' phase_name '] mean RMSE pos (km) = ' num2str(sqrt(mean(rmse_pos_km.^2,'omitnan')),'%.12g')])
disp(['[replay][' phase_name '] final RMSE pos (km) = ' num2str(rmse_pos_km(end),'%.12g')])
disp(['[replay][' phase_name '] mat file = ' mat_file])

replay_out = struct();
replay_out.cfg = cfg;
replay_out.case = ch5case;
replay_out.selection_trace = selection_trace;
replay_out.xhat_hist = xhat_hist;
replay_out.xpred_hist = xpred_hist;
replay_out.P_hist = P_hist;
replay_out.rmse_pos_km = rmse_pos_km;
replay_out.paths = struct('mat_file', mat_file, 'output_dir', out_dir, 'artifact_tag', artifact_tag);
replay_out.ok = true;
end

function cfg = local_attach_r9_replay_params(cfg)
% Ensure replay-only R9 inner-loop params are present even for non-R9 phases.

need_attach = true;
if isfield(cfg, 'ch5r') && isfield(cfg.ch5r, 'r9')
    r9 = cfg.ch5r.r9;
    required = {'init_pos_sigma_km','init_vel_sigma_kmps','dmd_recent_steps', ...
                'pos_q_km','vel_q_kmps','max_iekf_iters'};
    has_all = true;
    for i = 1:numel(required)
        if ~isfield(r9, required{i})
            has_all = false;
            break;
        end
    end
    need_attach = ~has_all;
end

if need_attach
    cfg_r9 = default_ch5r_r9_params();
    if ~isfield(cfg, 'ch5r')
        cfg.ch5r = struct();
    end
    cfg.ch5r.r9 = cfg_r9.ch5r.r9;
    disp('[replay] attached replay-only R9 inner-loop defaults into current cfg')
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

function [x_upd, P_upd] = local_iekf_update_pair(x_pred, P_pred, z_true, ch5case, k, pair, cfg)
R = (cfg.ch5r.sensor_profile.sigma_angle_rad^2) * eye(4);
x_it = x_pred;

for it = 1:cfg.ch5r.r9.max_iekf_iters %#ok<NASGU>
    z_hat = local_bearing_measurement_pair(x_it, ch5case, k, pair);
    H = local_numeric_jacobian(@(x) local_bearing_measurement_pair(x, ch5case, k, pair), x_it);

    innov = z_true - z_hat;
    innov(1) = local_wrap_to_pi(innov(1));
    innov(3) = local_wrap_to_pi(innov(3));

    S = H * P_pred * H' + R;
    K = P_pred * H' / S;
    x_it = x_pred + K * innov;
end

H = local_numeric_jacobian(@(x) local_bearing_measurement_pair(x, ch5case, k, pair), x_it);
z_hat = local_bearing_measurement_pair(x_it, ch5case, k, pair);
innov = z_true - z_hat;
innov(1) = local_wrap_to_pi(innov(1));
innov(3) = local_wrap_to_pi(innov(3));

S = H * P_pred * H' + R;
K = P_pred * H' / S;

x_upd = x_pred + K * innov;
P_upd = (eye(size(P_pred)) - K * H) * P_pred;
P_upd = 0.5 * (P_upd + P_upd');
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
