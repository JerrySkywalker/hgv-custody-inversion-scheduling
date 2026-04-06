function eval_out = evaluate_candidate_r9_score(cfg, ch5case, selection_trace_prefix, k_now, pair, x_pred, P_pred, model)
%EVALUATE_CANDIDATE_R9_SCORE
% Score one candidate pair for R9:
%   score = Psi - alpha*tau
% where
%   Psi = minimum directional window supply along current pipe direction
%   tau = future violation fraction over valid full-window centers

Nt = numel(ch5case.t_s);
left_steps = ch5case.window.left_steps;
right_steps = ch5case.window.right_steps;
H = cfg.ch5r.r9.horizon_steps;
alpha = cfg.ch5r.r9.alpha_tau;

last_valid_center = Nt - right_steps;
centers = k_now : min(k_now + H - 1, last_valid_center);

gap = compute_r9_pipe_gap_state(P_pred);
u = gap.u_pos;

if isempty(centers)
    eval_out = struct();
    eval_out.pair = pair;
    eval_out.psi = NaN;
    eval_out.tau = 0;
    eval_out.score = -inf;
    eval_out.gap = gap;
    return;
end

t_start = max(1, k_now - left_steps);
t_end = min(Nt, max(centers) + right_steps);
nLocal = t_end - t_start + 1;

J_local = zeros(3,3,nLocal);

% fill past realized J
for t = t_start:min(k_now-1, t_end)
    idx = t - t_start + 1;
    if t <= numel(selection_trace_prefix) && isstruct(selection_trace_prefix{t}) ...
            && isfield(selection_trace_prefix{t}, 'J_pair') && ~isempty(selection_trace_prefix{t}.J_pair)
        J_local(:,:,idx) = selection_trace_prefix{t}.J_pair;
    end
end

% fill current/future predicted J under repeated candidate pair
x_tmp = x_pred;
for t = k_now:t_end
    idx = t - t_start + 1;
    pair_list = ch5case.candidates.pair_bank{t};
    if ~isempty(pair_list) && ismember(pair, pair_list, 'rows')
        r_tgt = x_tmp(1:3).';
        r_sat_pair = [
            squeeze(ch5case.satbank.r_eci_km(t, :, pair(1)));
            squeeze(ch5case.satbank.r_eci_km(t, :, pair(2)))
        ];
        J_local(:,:,idx) = compute_bearing_fim_pair(r_tgt, r_sat_pair, cfg.ch5r.sensor_profile.sigma_angle_rad);
    else
        J_local(:,:,idx) = zeros(3,3);
    end
    if t < t_end
        x_tmp = model.A * x_tmp + model.b;
    end
end

% prefix sums
J_cum = zeros(3,3,nLocal+1);
for i = 1:nLocal
    J_cum(:,:,i+1) = J_cum(:,:,i) + J_local(:,:,i);
end

psi_list = nan(numel(centers),1);
violate_list = false(numel(centers),1);

for ic = 1:numel(centers)
    kc = centers(ic);
    s0 = kc - left_steps;
    s1 = kc + right_steps;

    if s0 < 1 || s1 > Nt
        continue;
    end

    i0 = s0 - t_start + 1;
    i1 = s1 - t_start + 1;

    Yw = J_cum(:,:,i1+1) - J_cum(:,:,i0);
    Yw = 0.5 * (Yw + Yw');

    psi_list(ic) = u' * Yw * u;
    violate_list(ic) = min(real(eig(Yw))) < ch5case.gamma_req;
end

psi = min(psi_list, [], 'omitnan');
tau = mean(double(violate_list), 'omitnan');

if isnan(psi)
    score = -inf;
else
    score = psi - alpha * tau * ch5case.gamma_req;
end

eval_out = struct();
eval_out.pair = pair;
eval_out.psi = psi;
eval_out.tau = tau;
eval_out.score = score;
eval_out.gap = gap;
eval_out.centers = centers;
end
