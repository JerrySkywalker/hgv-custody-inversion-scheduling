function eval_out = evaluate_candidate_bubble_gain(ch5case, selection_trace_prefix, pair, k_now, horizon_steps, lambda_sw)
%EVALUATE_CANDIDATE_BUBBLE_GAIN
% Evaluate one candidate pair by future worst-window lifting gain.

if nargin < 6
    lambda_sw = 0;
end

pred = predict_future_window_information(ch5case, selection_trace_prefix, pair, k_now, horizon_steps);

switch_cost = 0;
if k_now > 1 && ~isempty(selection_trace_prefix{k_now-1}.pair)
    if ~isequal(selection_trace_prefix{k_now-1}.pair, pair)
        switch_cost = 1;
    end
end

score = pred.min_future_lambda - lambda_sw * switch_cost;

eval_out = struct();
eval_out.pair = pair;
eval_out.min_future_lambda = pred.min_future_lambda;
eval_out.switch_cost = switch_cost;
eval_out.score = score;
eval_out.pred = pred;
end
