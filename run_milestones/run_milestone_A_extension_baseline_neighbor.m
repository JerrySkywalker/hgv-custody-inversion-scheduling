function out = run_milestone_A_extension_baseline_neighbor(cfg_override)
%RUN_MILESTONE_A_EXTENSION_BASELINE_NEIGHBOR Fast entry for MA extension export.

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root)
    addpath(proj_root);
end
startup();

cfg = milestone_common_defaults();
if nargin >= 1 && ~isempty(cfg_override)
    cfg = milestone_common_merge_structs(cfg, cfg_override);
end

out = milestone_A_extension_baseline_neighbor(cfg);
fprintf('[run_milestones] MA extension completed: %s\n', char(string(out.artifacts.summary_report)));
end
