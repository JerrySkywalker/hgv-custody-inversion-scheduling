function precursor = detect_bubble_precursor(cfg, ch5case, selection_trace_prefix, k_now)
%DETECT_BUBBLE_PRECURSOR
% Detect future bubble precursor using current pair continuation preview.

warn_ratio = cfg.ch5r.r7.warn_ratio;
horizon_steps = cfg.ch5r.r7.horizon_steps;

pair_list = ch5case.candidates.pair_bank{k_now};

if isempty(pair_list)
    precursor = struct();
    precursor.trigger = true;
    precursor.predicted_min_lambda = -inf;
    precursor.warn_threshold = warn_ratio * ch5case.gamma_req;
    precursor.note = 'No visible candidate pair; force trigger.';
    return;
end

% Use previous pair if available; otherwise use the first visible pair as preview.
preview_pair = [];
if k_now > 1 && ~isempty(selection_trace_prefix{k_now-1}.pair)
    prev_pair = selection_trace_prefix{k_now-1}.pair;
    if ismember(prev_pair, pair_list, 'rows')
        preview_pair = prev_pair;
    end
end
if isempty(preview_pair)
    preview_pair = pair_list(1,:);
end

pred = predict_future_window_information(ch5case, selection_trace_prefix, preview_pair, k_now, horizon_steps);

warn_threshold = warn_ratio * ch5case.gamma_req;
trigger = pred.min_future_lambda < warn_threshold;

precursor = struct();
precursor.trigger = trigger;
precursor.predicted_min_lambda = pred.min_future_lambda;
precursor.warn_threshold = warn_threshold;
precursor.preview_pair = preview_pair;
precursor.pred = pred;
end
