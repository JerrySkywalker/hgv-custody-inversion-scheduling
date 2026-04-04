function summary = summarize_ch5r_real_results(outX, policy_name)
%SUMMARIZE_CH5R_REAL_RESULTS  Build one-row real-result summary struct.

if nargin < 2 || isempty(policy_name)
    policy_name = 'unknown';
end

summary = struct();
summary.policy = string(policy_name);
summary.bubble_steps = outX.result.bubble_steps;
summary.bubble_time_s = outX.result.bubble_time_s;
summary.max_bubble_depth = outX.result.max_bubble_depth;
summary.switch_count = outX.result.switch_count;
summary.resource_score = outX.result.resource_score;

if isfield(outX, 'bubble') && isfield(outX.bubble, 'is_bubble')
    summary.bubble_fraction = nnz(outX.bubble.is_bubble) / numel(outX.bubble.is_bubble);
else
    summary.bubble_fraction = NaN;
end

if isfield(outX, 'bubble') && isfield(outX.bubble, 'bubble_depth')
    bd = outX.bubble.bubble_depth(:);
    summary.mean_bubble_depth = mean(bd, 'omitnan');
else
    summary.mean_bubble_depth = NaN;
end

if isfield(outX, 'selection_trace')
    nonempty_count = 0;
    for k = 1:numel(outX.selection_trace)
        if ~isempty(outX.selection_trace{k}.pair)
            nonempty_count = nonempty_count + 1;
        end
    end
    summary.observable_steps = nonempty_count;
else
    summary.observable_steps = NaN;
end
end
