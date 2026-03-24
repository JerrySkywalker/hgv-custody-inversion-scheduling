function out = run_stage12E_minimum_design_packager(inputs, cfg, interactive, overrides)
%RUN_STAGE12E_MINIMUM_DESIGN_PACKAGER Fast entry for Stage12E.

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root)
    addpath(proj_root);
end
startup();

if nargin < 1 || isempty(inputs)
    inputs = struct();
end
if nargin < 2 || isempty(cfg)
    cfg = default_params();
end
if nargin < 3 || isempty(interactive)
    interactive = (nargin == 0); %#ok<NASGU>
end
if nargin < 4 || isempty(overrides)
    overrides = struct();
end

out = stage12E_minimum_design_packager(inputs, cfg, overrides);
fprintf('[run_stages] Stage12E complete.\n');
end
