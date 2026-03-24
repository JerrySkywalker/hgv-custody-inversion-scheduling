function design_eval = adapter_design_eval_legacy(design_point, task_case, profile)
% Minimal adapter for legacy static design-point evaluation.

if nargin < 3
    profile = struct();
end

repo_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
legacy_root = fullfile(repo_root, 'legacy');

addpath(genpath(fullfile(legacy_root, 'src')));
addpath(genpath(fullfile(legacy_root, 'params')));

cfg = default_params();

% Apply a minimal design override if fields are present
if isfield(design_point, 'P'),    cfg.search.P_set = design_point.P; end
if isfield(design_point, 'T'),    cfg.search.T_set = design_point.T; end
if isfield(design_point, 'h_km'), cfg.search.h_grid_km = design_point.h_km; end
if isfield(design_point, 'i_deg'), cfg.search.i_grid_deg = design_point.i_deg; end

% Legacy evaluator
legacy_out = evaluate_single_layer_walker_stage09(design_point, task_case, cfg);

design_eval = struct();
design_eval.design_id = design_point.design_id;
design_eval.case_id = '';
if isstruct(task_case) && isfield(task_case, 'case_id')
    design_eval.case_id = task_case.case_id;
end
design_eval.legacy_out = legacy_out;
design_eval.meta = struct('source', 'legacy');
end
