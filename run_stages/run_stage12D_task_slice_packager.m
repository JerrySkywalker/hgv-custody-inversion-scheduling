function out = run_stage12D_task_slice_packager(cfg, interactive, task_mode, overrides)
%RUN_STAGE12D_TASK_SLICE_PACKAGER Fast entry for Stage12D.

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
if nargin < 3 || isempty(task_mode)
    task_mode = 'nominal';
end
if nargin < 4 || isempty(overrides)
    overrides = struct();
end

out = stage12D_task_slice_packager(cfg, task_mode, overrides);
fprintf('[run_stages] Stage12D complete.\n');
end
