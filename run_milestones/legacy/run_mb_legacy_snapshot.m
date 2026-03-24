function out = run_mb_legacy_snapshot(varargin)
%RUN_MB_LEGACY_SNAPSHOT Wrapper for the frozen legacy MB entrypoint.

proj_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
if ~isempty(proj_root)
    addpath(proj_root);
end
startup();

fprintf('[run_milestones][legacy] THIS IS LEGACY / FROZEN\n');
fprintf('[run_milestones][legacy] DO NOT ADD NEW FEATURES HERE\n');
fprintf('[run_milestones][legacy] Redirect new development to run_milestones/active and src/mb/v2\n');
fprintf('[run_milestones][legacy] Forwarding to run_milestone_B_semantic_compare\n');

out = run_milestone_B_semantic_compare(varargin{:});
end
