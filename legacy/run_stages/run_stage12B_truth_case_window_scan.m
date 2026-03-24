function out = run_stage12B_truth_case_window_scan(cfg, interactive, overrides)
%RUN_STAGE12B_TRUTH_CASE_WINDOW_SCAN Fast entry for Stage12B.

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root)
    addpath(proj_root);
end
startup();

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end
if nargin < 2 || isempty(interactive)
    interactive = (nargin == 0); %#ok<NASGU>
end
if nargin < 3 || isempty(overrides)
    overrides = struct();
end

out = stage12B_truth_case_window_scan(cfg, overrides);
fprintf('[run_stages] Stage12B complete.\n');
end
