function out = compute_worst_window_metrics_fullwindow(ch5case, selection_trace, tag)
%COMPUTE_WORST_WINDOW_METRICS_FULLWINDOW
% Fast full-window wrapper for R8.6a ~ R8.7b quick migration.
%
% Main semantics:
%   use forward_full_only as the default primary evaluation mode.

met = compute_window_metrics_with_mode(ch5case, selection_trace, tag, 'forward_full_only');

out = struct();
out.summary = met.summary;
out.lambda_series = met.lambda_series;
out.bubble_mask = met.bubble_mask;
out.bubble_depth = met.bubble_depth;
out.valid_mask = met.valid_mask;
out.mode = "forward_full_only";
end
