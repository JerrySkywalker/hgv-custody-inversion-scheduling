function out = run_stage12C_inverse_slice_packager(cfg, interactive, slice_type, overrides)
%RUN_STAGE12C_INVERSE_SLICE_PACKAGER Fast entry for Stage12C.

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
if nargin < 3 || isempty(slice_type)
    slice_type = 'hi';
end
if nargin < 4 || isempty(overrides)
    overrides = struct();
end

out = stage12C_inverse_slice_packager(cfg, slice_type, overrides);
fprintf('[run_stages] Stage12C complete.\n');
end
