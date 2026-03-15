function out = stage12A_truth_baseline_kernel(cfg, overrides)
%STAGE12A_TRUTH_BASELINE_KERNEL Placeholder kernel for milestone truth baseline.

startup();

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end
if nargin < 2 || isempty(overrides)
    overrides = struct();
end

out = struct();
out.cfg = cfg;
out.overrides = overrides;
out.theta_baseline = struct();
out.case_selection = struct();
out.summary_table = table();
out.case_table = table();
out.window_table = table();
out.files = struct();
end
