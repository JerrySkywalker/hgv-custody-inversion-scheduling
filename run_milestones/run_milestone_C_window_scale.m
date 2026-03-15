function out = run_milestone_C_window_scale(cfg_override)
%RUN_MILESTONE_C_WINDOW_SCALE Fast entry for Milestone C.

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root)
    addpath(proj_root);
end
startup();

cfg = milestone_common_defaults();
if nargin >= 1 && ~isempty(cfg_override)
    cfg = milestone_common_merge_structs(cfg, cfg_override);
end

out = milestone_C_window_scale(cfg);
fprintf('[run_milestones] MC completed: %s\n', char(string(out.artifacts.summary_report)));
end
