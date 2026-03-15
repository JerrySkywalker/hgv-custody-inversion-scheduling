function out = run_stage12A_truth_baseline_kernel(cfg, interactive, overrides)
%RUN_STAGE12A_TRUTH_BASELINE_KERNEL Fast entry for Stage12A.

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

out = stage12A_truth_baseline_kernel(cfg, overrides);
fprintf('[run_stages] Stage12A complete.\n');
end
