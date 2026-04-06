function out = run_ch5r_phase9_r9_closedloop(overrides)
%RUN_CH5R_PHASE9_R9_CLOSEDLOOP
% Minimal R9 closed-loop:
% - inner loop: local affine Koopman-DMD prediction + IEKF-like bearing update
% - outer loop: pipe-gap-driven bubble suppression scheduling
% - switch count is recorded only, not optimized
% - explicit tail mode after the last valid full-window center
%
% Optional overrides fields:
%   alpha_tau
%   save_outputs
%   log_enable
%   log_every

if nargin < 1 || isempty(overrides)
    overrides = struct();
end

cfg = default_ch5r_r9_params();
cfg = local_apply_overrides(cfg, overrides);

addpath(fullfile(pwd, 'ch5_rebuild', 'r9_inner'));
addpath(fullfile(pwd, 'ch5_rebuild', 'r9_sched'));

ch5case = build_ch5r_case(cfg);
ch5case.cfg = cfg;

Nt = numel(ch5case.t_s);
dt = ch5case.dt;
last_valid_center = Nt - ch5case.window.right_steps;

selection_trace = cell(Nt,1);
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

    pair_list = ch5case.candidates.pair_bank{k};

    if isempty(pair_list)
        sel = struct('k',k,'time_s',ch5case.t_s(k),'pair',[],'score',-inf, ...
                     'name','r9_empty','eval',[],'n_pairs',0, ...
                     'prev_pair',[],'switch_flag',false,'J_pair',zeros(3,3));
        xhat = x_pred;
        P = P_pred;

    elseif k > last_valid_center
        prev_pair = [];
        if k > 1 && isstruct(selection_trace{k-1}) && isfield(selection_trace{k-1}, 'pair')
            prev_pair = selection_trace{k-1}.pair;
        end

        if ~isempty(prev_pair) && ismember(prev_pair, pair_list, 'rows')
            pair = prev_pair;
            name_str = 'r9_tail_hold';
        else
            pair = local_pick_best_trace_pair(ch5case, k, pair_list, x_pred(1:3), cfg);
            name_str = 'r9_tail_trace';
        end

        sel = struct();
        sel.k = k;
        sel.time_s = ch5case.t_s(k);
        sel.pair = pair;
        sel.score = NaN;
        sel.name = name_str;
        sel.eval = struct('tail_mode', true);
        sel.n_pairs = size(pair_list,1);

        z_true = local_bearing_measurement_pair(local_get_truth_state(ch5case,k), ch5case, k, sel.pair);
        [xhat, P] = local_iekf_update_pair(x_pred, P_pred, z_true, ch5case, k, sel.pair, cfg);

        x_true_k = local_get_truth_state(ch5case, k);
        r_tgt = x_true_k(1:3).';
        r_sat_pair = [
            squeeze(ch5case.satbank.r_eci_km(k, :, sel.pair(1)));
            squeeze(ch5case.satbank.r_eci_km(k, :, sel.pair(2)))
        ];
        sel.J_pair = compute_bearing_fim_pair(r_tgt, r_sat_pair, cfg.ch5r.sensor_profile.sigma_angle_rad);

        if k > 1 && isstruct(selection_trace{k-1}) && isfield(selection_trace{k-1}, 'pair') ...
                && ~isempty(selection_trace{k-1}.pair)
            sel.prev_pair = selection_trace{k-1}.pair;
            sel.switch_flag = ~isequal(sel.pair, selection_trace{k-1}.pair);
        else
            sel.prev_pair = [];
            sel.switch_flag = false;
        end

    else
        sel = select_satellite_set_r9_pipe_feedback(cfg, ch5case, selection_trace, k, x_pred, P_pred, model);

        z_true = local_bearing_measurement_pair(local_get_truth_state(ch5case,k), ch5case, k, sel.pair);
        [xhat, P] = local_iekf_update_pair(x_pred, P_pred, z_true, ch5case, k, sel.pair, cfg);

        x_true_k = local_get_truth_state(ch5case, k);
        r_tgt = x_true_k(1:3).';
        r_sat_pair = [
            squeeze(ch5case.satbank.r_eci_km(k, :, sel.pair(1)));
            squeeze(ch5case.satbank.r_eci_km(k, :, sel.pair(2)))
        ];
        sel.J_pair = compute_bearing_fim_pair(r_tgt, r_sat_pair, cfg.ch5r.sensor_profile.sigma_angle_rad);

        if k > 1 && isstruct(selection_trace{k-1}) && isfield(selection_trace{k-1}, 'pair') ...
                && ~isempty(selection_trace{k-1}.pair)
            sel.prev_pair = selection_trace{k-1}.pair;
            sel.switch_flag = ~isequal(sel.pair, selection_trace{k-1}.pair);
        else
            sel.prev_pair = [];
            sel.switch_flag = false;
        end
    end

    selection_trace{k} = sel;
    xpred_hist(:,k) = x_pred;
    xhat_hist(:,k) = xhat;
    P_hist(:,:,k) = P;

    x_true_k = local_get_truth_state(ch5case, k);
    rmse_pos_km(k) = norm(xhat(1:3) - x_true_k(1:3), 2);

    state_buffer(:,end+1) = xhat; %#ok<AGROW>

    if cfg.ch5r.r9.log.enable
        do_log = (k == 1) || (k == Nt) || (mod(k, cfg.ch5r.r9.log.log_every) == 0);
        if do_log
            msg = sprintf('[R9][k=%d/%d] nPairs=%d rmsePos=%.6g', k, Nt, sel.n_pairs, rmse_pos_km(k));
            if ~isempty(sel.pair)
                if isnan(sel.score)
                    msg = sprintf('%s pair=[%d %d] score=tail', msg, sel.pair(1), sel.pair(2));
                else
                    msg = sprintf('%s pair=[%d %d] score=%.6g', msg, sel.pair(1), sel.pair(2), sel.score);
                end
            else
                msg = sprintf('%s pair=[]', msg);
            end
            if cfg.ch5r.r9.log.show_step_timing
                msg = sprintf('%s stepTime=%.3fs elapsed=%.3fs', msg, toc(t_step), toc(t_total));
            end
            disp(msg)
        end
    end
end

wininfo = eval_window_information(ch5case, selection_trace);
bubble = eval_bubble_state(ch5case, wininfo);
state_trace = package_state_trace(ch5case, wininfo, bubble);

resource_score = 2;
result = package_ch5r_result_real(ch5case, selection_trace, wininfo, bubble, resource_score);

result.r9_tracking = struct();
result.r9_tracking.rmse_pos_km_series = rmse_pos_km;
result.r9_tracking.mean_rmse_pos_km = sqrt(mean(rmse_pos_km.^2, 'omitnan'));
result.r9_tracking.final_rmse_pos_km = rmse_pos_km(end);
result.r9_tracking.xhat_hist = xhat_hist;
result.r9_tracking.xpred_hist = xpred_hist;

out_dir = fullfile(cfg.ch5r.output_root, 'phaseR9_closedloop_real');
if cfg.ch5r.r9.save_outputs
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
    mat_file = fullfile(out_dir, ['phaseR9_closedloop_real_' stamp '.mat']);
    save(mat_file, 'cfg', 'ch5case', 'selection_trace', 'xhat_hist', 'xpred_hist', 'P_hist', ...
        'rmse_pos_km', 'wininfo', 'bubble', 'state_trace', 'result');
else
    mat_file = '';
end

disp(' ')
disp('=== [ch5r:R9-real] minimal closed-loop summary ===')
disp(['case id              : ' ch5case.target_case.case_id])
disp(['window mode          : ' ch5case.window.mode])
disp(['valid steps          : ' num2str(result.bubble_metrics.total_valid_steps)])
disp(['bubble steps         : ' num2str(result.bubble_metrics.bubble_steps)])
disp(['bubble time (s)      : ' num2str(result.bubble_metrics.bubble_time_s, '%.6f')])
disp(['longest bubble (s)   : ' num2str(result.bubble_metrics.longest_bubble_time_s, '%.6f')])
disp(['max bubble depth     : ' num2str(result.bubble_metrics.max_bubble_depth, '%.12g')])
disp(['switch count         : ' num2str(result.cost_metrics.switch_count)])
disp(['mean RMSE pos (km)   : ' num2str(result.r9_tracking.mean_rmse_pos_km, '%.12g')])
disp(['final RMSE pos (km)  : ' num2str(result.r9_tracking.final_rmse_pos_km, '%.12g')])
disp(['mat file             : ' mat_file])

assert(strcmp(ch5case.target_case.case_id, 'N01'));
assert(strcmp(ch5case.window.mode, 'centered_full_only'));
assert(result.cost_metrics.resource_score == 2);
assert(result.bubble_metrics.total_valid_steps > 0);

out = struct();
out.cfg = cfg;
out.case = ch5case;
out.selection_trace = selection_trace;
out.wininfo = wininfo;
out.bubble = bubble;
out.state_trace = state_trace;
out.result = result;
out.paths = struct('mat_file', mat_file, 'output_dir', out_dir);
out.ok = true;
end

function cfg = local_apply_overrides(cfg, overrides)
if ~isstruct(overrides)
    error('overrides must be a struct.');
end
if isfield(overrides, 'alpha_tau')
    cfg.ch5r.r9.alpha_tau = overrides.alpha_tau;
end
if isfield(overrides, 'save_outputs')
    cfg.ch5r.r9.save_outputs = logical(overrides.save_outputs);
end
if isfield(overrides, 'log_enable')
    cfg.ch5r.r9.log.enable = logical(overrides.log_enable);
end
if isfield(overrides, 'log_every')
    cfg.ch5r.r9.log.log_every = overrides.log_every;
end
end

function pair = local_pick_best_trace_pair(ch5case, k, pair_list, r_tgt, cfg)
best_score = -inf;
pair = pair_list(1,:);
for idx = 1:size(pair_list,1)
    cand = pair_list(idx,:);
    r_sat_pair = [
        squeeze(ch5case.satbank.r_eci_km(k, :, cand(1)));
        squeeze(ch5case.satbank.r_eci_km(k, :, cand(2)))
    ];
    J_try = compute_bearing_fim_pair(r_tgt.', r_sat_pair, cfg.ch5r.sensor_profile.sigma_angle_rad);
    s_try = trace(J_try);
    if s_try > best_score
        best_score = s_try;
        pair = cand;
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
if Nt < 2
    error('Truth velocity field not found, and not enough samples to infer velocity.');
end

if k == 1
    r0 = local_get_truth_position(ch5case, 1);
    r1 = local_get_truth_position(ch5case, 2);
    v = (r1 - r0) / dt;
elseif k == Nt
    r0 = local_get_truth_position(ch5case, Nt-1);
    r1 = local_get_truth_position(ch5case, Nt);
    v = (r1 - r0) / dt;
else
    rm = local_get_truth_position(ch5case, k-1);
    rp = local_get_truth_position(ch5case, k+1);
    v = (rp - rm) / (2*dt);
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
