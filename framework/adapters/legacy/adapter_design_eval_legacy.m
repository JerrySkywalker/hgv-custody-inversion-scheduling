function design_eval = adapter_design_eval_legacy(design_point, task_family, profile)
% Minimal adapter for legacy static design-point evaluation.

if nargin < 3
    profile = struct();
end

repo_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
legacy_root = fullfile(repo_root, 'legacy');

addpath(genpath(fullfile(legacy_root, 'src')));
addpath(genpath(fullfile(legacy_root, 'params')));

cfg = default_params();

% Build Stage09 row
row = struct();
row.design_id = design_point.design_id;
row.P = design_point.P;
row.T = design_point.T;
row.h_km = design_point.h_km;
row.i_deg = design_point.i_deg;
row.F = design_point.F;
row.Ns = design_point.Ns;

trajs_in = task_family.trajs_in;
gamma_eff_scalar = 1.0;
eval_ctx = [];

legacy_out = evaluate_single_layer_walker_stage09(row, trajs_in, gamma_eff_scalar, cfg, eval_ctx);

design_eval = struct();
design_eval.design_id = design_point.design_id;
design_eval.legacy_out = legacy_out;
design_eval.meta = struct('source', 'legacy');
end
