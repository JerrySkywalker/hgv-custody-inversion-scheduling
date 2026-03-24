function out = run_milestone_E_worst_window_diagnosis(cfg_override)
%RUN_MILESTONE_E_WORST_WINDOW_DIAGNOSIS Fast entry for Milestone E.

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root)
    addpath(proj_root);
end
startup();

cfg = milestone_common_defaults();
if nargin >= 1 && ~isempty(cfg_override)
    cfg = milestone_common_merge_structs(cfg, cfg_override);
end

out = milestone_E_worst_window_diagnosis(cfg);
fprintf('[run_milestones] ME completed: %s\n', char(string(out.artifacts.summary_report)));
end
