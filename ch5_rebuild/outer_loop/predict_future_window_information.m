function pred = predict_future_window_information(ch5case, selection_trace_prefix, future_pair, k_now, horizon_steps)
%PREDICT_FUTURE_WINDOW_INFORMATION
% Local-horizon prediction of centered full-window lambda_min for one candidate pair.
%
% Semantics:
% - aligned with centered_full_only
% - evaluate only future centers in [k_now, k_now+H-1]
% - use fixed prefix before k_now
% - use repeated candidate pair from k_now onward when visible

if nargin < 5
    error('ch5case, selection_trace_prefix, future_pair, k_now, horizon_steps are required.');
end

Nt = numel(ch5case.t_s);
H = min(horizon_steps, Nt - k_now + 1);
sigma_angle_rad = ch5case.cfg.ch5r.sensor_profile.sigma_angle_rad;

mode_name = ch5case.window.mode;
if ~strcmpi(mode_name, 'centered_full_only')
    error('predict_future_window_information currently supports centered_full_only only.');
end

left_steps = ch5case.window.left_steps;
right_steps = ch5case.window.right_steps;

idx_start = max(1, k_now - left_steps);
idx_end = min(Nt, k_now + H - 1 + right_steps);
nLocal = idx_end - idx_start + 1;

J_local = zeros(3,3,nLocal);

for kk = idx_start:idx_end
    loc = kk - idx_start + 1;

    if kk < k_now
        if kk <= numel(selection_trace_prefix) && isstruct(selection_trace_prefix{kk}) ...
                && isfield(selection_trace_prefix{kk}, 'J_pair') && ~isempty(selection_trace_prefix{kk}.J_pair)
            J_local(:,:,loc) = selection_trace_prefix{kk}.J_pair;
        else
            J_local(:,:,loc) = zeros(3,3);
        end
    else
        pair_list = ch5case.candidates.pair_bank{kk};

        if isempty(pair_list) || isempty(future_pair) || ~ismember(future_pair, pair_list, 'rows')
            J_local(:,:,loc) = zeros(3,3);
        else
            r_tgt = ch5case.truth.r_eci_km(kk, :);
            r_sat_pair = [
                squeeze(ch5case.satbank.r_eci_km(kk, :, future_pair(1)));
                squeeze(ch5case.satbank.r_eci_km(kk, :, future_pair(2)))
            ];
            J_local(:,:,loc) = compute_bearing_fim_pair(r_tgt, r_sat_pair, sigma_angle_rad);
        end
    end
end

J_cum = zeros(3,3,nLocal+1);
for i = 1:nLocal
    J_cum(:,:,i+1) = J_cum(:,:,i) + J_local(:,:,i);
end

lambda_min_future = nan(H,1);
valid_future_mask = false(H,1);
window_start_idx = nan(H,1);
window_end_idx = nan(H,1);

for kk = k_now:(k_now + H - 1)
    s0 = kk - left_steps;
    s1 = kk + right_steps;

    ii = kk - k_now + 1;
    window_start_idx(ii) = s0;
    window_end_idx(ii) = s1;

    if s0 < 1 || s1 > Nt
        lambda_min_future(ii) = NaN;
        valid_future_mask(ii) = false;
        continue;
    end

    valid_future_mask(ii) = true;

    loc_start = s0 - idx_start + 1;
    loc_end = s1 - idx_start + 1;

    Jw = J_cum(:,:,loc_end+1) - J_cum(:,:,loc_start);
    Jw = 0.5 * (Jw + Jw.');
    lambda_min_future(ii) = min(real(eig(Jw)));
end

if any(valid_future_mask)
    min_future_lambda = min(lambda_min_future(valid_future_mask), [], 'omitnan');
else
    min_future_lambda = -inf;
end

pred = struct();
pred.k_now = k_now;
pred.horizon_steps = H;
pred.window_mode = mode_name;
pred.lambda_min_future = lambda_min_future;
pred.valid_future_mask = valid_future_mask;
pred.window_start_idx = window_start_idx;
pred.window_end_idx = window_end_idx;
pred.min_future_lambda = min_future_lambda;
end
