function design_eval = adapter_design_eval_legacy(design_point, task_family, profile)
% Minimal adapter for legacy static design-point evaluation.
% Convert legacy Stage09 output into a first-pass framework truth row.

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
gamma_source = 'default_unit_threshold';
Tw_s = NaN;

if isfield(profile, 'gamma_eff_scalar') && ~isempty(profile.gamma_eff_scalar)
    gamma_eff_scalar = profile.gamma_eff_scalar;
end
if isfield(profile, 'gamma_source') && ~isempty(profile.gamma_source)
    gamma_source = char(profile.gamma_source);
end
if isfield(profile, 'Tw_s') && ~isempty(profile.Tw_s)
    Tw_s = profile.Tw_s;
end

eval_ctx = [];

legacy_out = evaluate_single_layer_walker_stage09(row, trajs_in, gamma_eff_scalar, cfg, eval_ctx);

design_eval = struct();
design_eval.design_id = design_point.design_id;
design_eval.P = design_point.P;
design_eval.T = design_point.T;
design_eval.h_km = design_point.h_km;
design_eval.i_deg = design_point.i_deg;
design_eval.F = design_point.F;
design_eval.Ns = design_point.Ns;

% First-pass normalized truth-row fields
design_eval.geometry_margin = legacy_out.DG_rob;
design_eval.accuracy_margin = legacy_out.DA_rob;
design_eval.temporal_margin_bar = legacy_out.DT_bar_rob;
design_eval.temporal_margin = legacy_out.DT_rob;
design_eval.joint_margin = legacy_out.joint_margin;

design_eval.is_feasible = logical(legacy_out.feasible_flag);
design_eval.fail_reason = char(legacy_out.dominant_fail_tag);

design_eval.pass_ratio = legacy_out.pass_ratio;
design_eval.rank_score = legacy_out.rank_score;

design_eval.worst_case_id_DG = char(legacy_out.worst_case_id_DG);
design_eval.worst_case_id_DA = char(legacy_out.worst_case_id_DA);
design_eval.worst_case_id_DT = char(legacy_out.worst_case_id_DT);

design_eval.n_case_total = legacy_out.n_case_total;
design_eval.n_case_evaluated = legacy_out.n_case_evaluated;
design_eval.failed_early = logical(legacy_out.failed_early);

% Raw diagnostic fields for threshold / margin alignment
design_eval.gamma_eff_scalar = gamma_eff_scalar;
design_eval.gamma_source = gamma_source;
design_eval.Tw_s = Tw_s;
design_eval.raw_DG_rob = legacy_out.DG_rob;
design_eval.raw_DA_rob = legacy_out.DA_rob;
design_eval.raw_DT_bar_rob = legacy_out.DT_bar_rob;
design_eval.raw_DT_rob = legacy_out.DT_rob;
design_eval.raw_joint_margin = legacy_out.joint_margin;
design_eval.raw_feasible_flag = legacy_out.feasible_flag;

% Keep raw legacy payload for traceability during migration
design_eval.legacy_out = legacy_out;

design_eval.meta = struct();
design_eval.meta.source = 'legacy';
design_eval.meta.adapter = 'adapter_design_eval_legacy';
end
