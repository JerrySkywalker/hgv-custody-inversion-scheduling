function eval_out = evaluate_candidate_bubble_gain(ch5case, selection_trace_prefix, pair, k_now, horizon_steps, lambda_sw)
%EVALUATE_CANDIDATE_BUBBLE_GAIN
% Score one candidate pair for R5 bubble-predictive scheduling.
%
% Robustness fixes:
% 1) safely handle empty / non-struct prefix cells
% 2) when centered_full_only leaves no valid future full-window centers
%    near the tail, use a tail-safe current-step information score instead
%    of returning -Inf-like behavior.

if nargin < 6
    error('ch5case, selection_trace_prefix, pair, k_now, horizon_steps, lambda_sw are required.');
end

prev_pair = [];
if k_now > 1 && numel(selection_trace_prefix) >= (k_now - 1)
    prev_item = selection_trace_prefix{k_now-1};
    if isstruct(prev_item) && isfield(prev_item, 'pair')
        prev_pair = prev_item.pair;
    end
end

if isempty(prev_pair)
    switch_cost = 0;
else
    switch_cost = lambda_sw * double(~isequal(pair, prev_pair));
end

pred = predict_future_window_information(ch5case, selection_trace_prefix, pair, k_now, horizon_steps);

if any(pred.valid_future_mask)
    score_main = pred.min_future_lambda;
    score_mode = 'future_full_window';
else
    % tail-safe fallback:
    % if no valid future full-window center exists, use current-step
    % instantaneous Fisher trace as a weak but finite tie-break score.
    sigma_angle_rad = ch5case.cfg.ch5r.sensor_profile.sigma_angle_rad;
    r_tgt = ch5case.truth.r_eci_km(k_now, :);
    r_sat_pair = [
        squeeze(ch5case.satbank.r_eci_km(k_now, :, pair(1)));
        squeeze(ch5case.satbank.r_eci_km(k_now, :, pair(2)))
    ];
    J_now = compute_bearing_fim_pair(r_tgt, r_sat_pair, sigma_angle_rad);
    score_main = trace(J_now);
    score_mode = 'tail_current_trace_fallback';
end

score = score_main - switch_cost;

eval_out = struct();
eval_out.pair = pair;
eval_out.pred = pred;
eval_out.min_future_lambda = pred.min_future_lambda;
eval_out.switch_cost = switch_cost;
eval_out.score_main = score_main;
eval_out.score_mode = score_mode;
eval_out.score = score;
end
