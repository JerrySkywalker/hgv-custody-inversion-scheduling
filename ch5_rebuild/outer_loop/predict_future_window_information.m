function pred = predict_future_window_information(ch5case, selection_trace_prefix, future_pair, k_now, horizon_steps)
%PREDICT_FUTURE_WINDOW_INFORMATION
% Local-horizon prediction of rolling-window lambda_min for one candidate pair.
%
% Key optimization:
% - do NOT rebuild whole-length selection traces
% - do NOT call eval_window_information over all Nt
% - only evaluate the local interval needed by [k_now, k_now+H-1]

if nargin < 5
    error('ch5case, selection_trace_prefix, future_pair, k_now, horizon_steps are required.');
end

Nt = numel(ch5case.t_s);
L = ch5case.window.length_steps;
H = min(horizon_steps, Nt - k_now + 1);
sigma_angle_rad = ch5case.cfg.ch5r.sensor_profile.sigma_angle_rad;

idx_start = max(1, k_now - L + 1);
idx_end = min(Nt, k_now + H - 1);
nLocal = idx_end - idx_start + 1;

J_local = zeros(3,3,nLocal);

% Fill local J series:
% - past part: from already fixed prefix
% - future part: repeated future_pair if visible, otherwise zero
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

% Prefix cumulative sum for fast rolling-window evaluation
J_cum = zeros(3,3,nLocal+1);
for i = 1:nLocal
    J_cum(:,:,i+1) = J_cum(:,:,i) + J_local(:,:,i);
end

lambda_min_future = nan(H,1);

for kk = k_now:(k_now + H - 1)
    loc_end = kk - idx_start + 1;
    w_start = max(idx_start, kk - L + 1);
    loc_start = w_start - idx_start + 1;

    Jw = J_cum(:,:,loc_end+1) - J_cum(:,:,loc_start);
    Jw = 0.5 * (Jw + Jw.');
    lambda_min_future(kk - k_now + 1) = min(eig(Jw));
end

pred = struct();
pred.k_now = k_now;
pred.horizon_steps = H;
pred.lambda_min_future = lambda_min_future;
pred.min_future_lambda = min(lambda_min_future, [], 'omitnan');
end
