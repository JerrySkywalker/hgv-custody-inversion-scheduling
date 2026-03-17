function out = run_ma_final(cfg, interactive, opts)
%RUN_MA_FINAL Stable final run path for MA baseline and MA extension exports.

proj_root = fileparts(fileparts(mfilename('fullpath')));
if ~isempty(proj_root)
    addpath(proj_root);
    addpath(fullfile(proj_root, 'run_stages'));
    addpath(fullfile(proj_root, 'run_milestones'));
end
startup();

if nargin < 1 || isempty(cfg) || ~isstruct(cfg) || ~isfield(cfg, 'paths')
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end
if nargin < 2 || isempty(interactive)
    interactive = (nargin == 0);
end
if nargin < 3 || isempty(opts)
    opts = struct();
end

[cfg, opts] = rs_cli_configure('ma_final', cfg, interactive, opts); %#ok<ASGLU>
cfg.stage13.dg_refine.enable = true;
cfg.stage13.dg_refine.micro.enable = true;

fprintf('[run_stages] === MA final convergence pipeline ===\n');
fprintf('[run_stages] path A: MA baseline export\n');
out = struct();
out.MA = run_milestone_A_truth_baseline(cfg);

fprintf('[run_stages] path B: Stage13 tiered candidate export\n');
out.stage13 = run_stage13(cfg, false, struct());

fprintf('[run_stages] path C: MA extension export\n');
out.MA_extension = run_milestone_A_extension_baseline_neighbor(cfg);

fprintf('[run_stages] === MA final convergence pipeline completed ===\n');
end
