function precursor = detect_bubble_precursor(cfg, ch5case, selection_trace_prefix, k_now)
%DETECT_BUBBLE_PRECURSOR
% Detect future bubble precursor using current pair continuation preview.

warn_ratio = cfg.ch5r.r7.warn_ratio;
horizon_steps = cfg.ch5r.r7.horizon_steps;
pair_list = ch5case.candidates.pair_bank{k_now};
last_valid_center = numel(ch5case.t_s) - ch5case.window.right_steps;

precursor = struct();
precursor.warn_threshold = warn_ratio * ch5case.gamma_req;

if isempty(pair_list)
    precursor.trigger = true;
    precursor.predicted_min_lambda = -inf;
    precursor.note = 'No visible candidate pair; force trigger.';
    precursor.preview_pair = [];
    precursor.pred = [];
    return;
end

if k_now > last_valid_center
    precursor.trigger = false;
    precursor.predicted_min_lambda = NaN;
    precursor.note = 'Tail zone: no future full-window center remains.';
    precursor.preview_pair = [];
    precursor.pred = [];
    return;
end

preview_pair = [];
if k_now > 1 && numel(selection_trace_prefix) >= (k_now-1)
    prev_item = selection_trace_prefix{k_now-1};
    if isstruct(prev_item) && isfield(prev_item, 'pair') && ~isempty(prev_item.pair)
        prev_pair = prev_item.pair;
        if ismember(prev_pair, pair_list, 'rows')
            preview_pair = prev_pair;
        end
    end
end

if isempty(preview_pair)
    preview_pair = pair_list(1,:);
end

pred = predict_future_window_information(ch5case, selection_trace_prefix, preview_pair, k_now, horizon_steps);

trigger = pred.min_future_lambda < precursor.warn_threshold;

precursor.trigger = trigger;
precursor.predicted_min_lambda = pred.min_future_lambda;
precursor.preview_pair = preview_pair;
precursor.pred = pred;
precursor.note = 'Preview current continuation against warning threshold.';
end
