function out = run_milestone_B_inverse_slices(cfg_override)
%RUN_MILESTONE_B_INVERSE_SLICES Fast entry for Milestone B.

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root)
    addpath(proj_root);
end
startup();

cfg = milestone_common_defaults();
if nargin >= 1 && ~isempty(cfg_override)
    cfg = milestone_common_merge_structs(cfg, cfg_override);
end

out = milestone_B_inverse_slices(cfg);
fprintf('[run_milestones] MB completed: %s\n', char(string(out.artifacts.summary_report)));
end
