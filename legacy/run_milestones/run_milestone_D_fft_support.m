function out = run_milestone_D_fft_support(cfg_override)
%RUN_MILESTONE_D_FFT_SUPPORT Fast entry for Milestone D.

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root)
    addpath(proj_root);
end
startup();

cfg = milestone_common_defaults();
if nargin >= 1 && ~isempty(cfg_override)
    cfg = milestone_common_merge_structs(cfg, cfg_override);
end

out = milestone_D_fft_support(cfg);
fprintf('[run_milestones] MD completed: %s\n', char(string(out.artifacts.summary_report)));
end
