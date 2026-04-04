function pred = predict_future_window_information(ch5case, selection_trace_prefix, future_pair, k_now, horizon_steps)
%PREDICT_FUTURE_WINDOW_INFORMATION
% Predict rolling-window lambda_min over a finite horizon if future_pair is chosen at k_now.
%
% Current minimal R5 assumption:
% - use already fixed past selections up to k_now-1
% - evaluate one-step candidate future_pair at k_now
% - future steps beyond k_now keep the same future_pair if visible, otherwise zero info

if nargin < 5
    error('ch5case, selection_trace_prefix, future_pair, k_now, horizon_steps are required.');
end

Nt = numel(ch5case.t_s);
H = min(horizon_steps, Nt - k_now + 1);
sigma_angle_rad = ch5case.cfg.ch5r.sensor_profile.sigma_angle_rad;

% Build a temporary selection trace
sel_tmp = selection_trace_prefix;

for kk = k_now:Nt
    if kk > k_now + H - 1
        break;
    end

    pair_list = ch5case.candidates.pair_bank{kk};
    if isempty(pair_list) || isempty(future_pair) || ~ismember(future_pair, pair_list, 'rows')
        sel_tmp{kk} = struct( ...
            'k', kk, ...
            'time_s', ch5case.t_s(kk), ...
            'pair', [], ...
            'J_pair', zeros(3,3), ...
            'score', -inf, ...
            'prev_pair', [], ...
            'switch_flag', false, ...
            'name', 'bubble_predictive_empty');
    else
        r_tgt = ch5case.truth.r_eci_km(kk, :);
        r_sat_pair = [
            squeeze(ch5case.satbank.r_eci_km(kk, :, future_pair(1)));
            squeeze(ch5case.satbank.r_eci_km(kk, :, future_pair(2)))
        ];
        J = compute_bearing_fim_pair(r_tgt, r_sat_pair, sigma_angle_rad);

        sel_tmp{kk} = struct( ...
            'k', kk, ...
            'time_s', ch5case.t_s(kk), ...
            'pair', future_pair, ...
            'J_pair', J, ...
            'score', trace(J), ...
            'prev_pair', [], ...
            'switch_flag', false, ...
            'name', 'bubble_predictive_preview');
    end
end

wininfo_pred = eval_window_information(ch5case, sel_tmp);
idx_end = min(k_now + H - 1, Nt);

pred = struct();
pred.k_now = k_now;
pred.horizon_steps = H;
pred.lambda_min_future = wininfo_pred.lambda_min(k_now:idx_end);
pred.min_future_lambda = min(pred.lambda_min_future, [], 'omitnan');
pred.wininfo_pred = wininfo_pred;
end
