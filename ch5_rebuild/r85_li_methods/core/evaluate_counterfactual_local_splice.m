function out = evaluate_counterfactual_local_splice(ch5case, trace_base, trace_patch, k1, k2, base_tag, patch_tag, new_tag)
%EVALUATE_COUNTERFACTUAL_LOCAL_SPLICE
% R8.6c:
%   Evaluate counterfactual by replacing local pair trace segment.

assert(isstruct(ch5case), 'ch5case must be struct.');

trace_cf = splice_selection_trace_local(trace_base, trace_patch, k1, k2, new_tag);

m_base = compute_worst_window_metrics_from_selection_trace(ch5case, trace_base, base_tag);
m_patch = compute_worst_window_metrics_from_selection_trace(ch5case, trace_patch, patch_tag);
m_cf = compute_worst_window_metrics_from_selection_trace(ch5case, trace_cf, new_tag);

delta = struct();
delta.bubble_steps = m_cf.summary.bubble_steps - m_base.summary.bubble_steps;
delta.bubble_time_s = m_cf.summary.bubble_time_s - m_base.summary.bubble_time_s;
delta.max_bubble_depth = m_cf.summary.max_bubble_depth - m_base.summary.max_bubble_depth;
delta.mean_lambda_min_window = m_cf.summary.mean_lambda_min_window - m_base.summary.mean_lambda_min_window;
delta.min_lambda_min_window = m_cf.summary.min_lambda_min_window - m_base.summary.min_lambda_min_window;
delta.longest_bubble_span = m_cf.summary.longest_bubble_span - m_base.summary.longest_bubble_span;
delta.switch_count = m_cf.summary.switch_count - m_base.summary.switch_count;

out = struct();
out.k1 = k1;
out.k2 = k2;
out.trace_cf = trace_cf;
out.base_tag = string(base_tag);
out.patch_tag = string(patch_tag);
out.new_tag = string(new_tag);
out.m_base = m_base;
out.m_patch = m_patch;
out.m_cf = m_cf;
out.delta = delta;
end
