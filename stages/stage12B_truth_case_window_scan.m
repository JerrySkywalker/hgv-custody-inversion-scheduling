function out = stage12B_truth_case_window_scan(cfg, overrides)
%STAGE12B_TRUTH_CASE_WINDOW_SCAN Placeholder kernel for truth window scan.

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
out.case_selection = struct();
out.theta_baseline = struct();
out.window_table = table();
out.summary_table = table();
out.files = struct();
end
