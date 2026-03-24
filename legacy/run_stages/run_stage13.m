function out = run_stage13(cfg, interactive, opts)
%RUN_STAGE13 Public entry for Stage13 baseline neighborhood search.

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root)
    addpath(proj_root);
    addpath(fullfile(proj_root, 'run_stages'));
    addpath(fullfile(proj_root, 'src', 'stages', 'stage13'));
end
startup();

if nargin < 1 || isempty(cfg)
    cfg = default_params();
end
if nargin < 2 || isempty(interactive)
    interactive = (nargin == 0);
end
if nargin < 3 || isempty(opts)
    opts = struct();
end

[cfg, opts] = rs_cli_configure('stage13', cfg, interactive, opts);
cfg = stage13_default_config(cfg);
cfg.run_stages.parallel_modes.stage13 = 'serial';

fprintf('[run_stages] === Stage13 邻域参数搜索入口 ===\n');
fprintf('[run_stages] mode           : %s\n', cfg.stage13.mode);
fprintf('[run_stages] baseline case  : %s\n', cfg.stage13.baseline.case_id);
fprintf('[run_stages] baseline Tw(s) : %g\n', cfg.stage13.baseline.Tw_s);

out = stage13_entry(cfg);

fprintf('[run_stages] === Stage13 完成 ===\n');
end
