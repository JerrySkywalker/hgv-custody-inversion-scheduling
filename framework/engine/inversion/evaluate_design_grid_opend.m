function grid_table = evaluate_design_grid_opend(design_grid, trajs_in, gamma_eff_scalar, engine_cfg)
%EVALUATE_DESIGN_GRID_OPEND Evaluate a design grid under OpenD (D_G only).
% Inputs:
%   design_grid        : struct array or table of design rows
%   trajs_in           : target-family struct array with fields .case and .traj
%   gamma_eff_scalar   : scalar geometry threshold
%   engine_cfg         : engine configuration tree; defaults to default_params()
%
% Output:
%   grid_table         : table of OpenD design evaluations

if nargin < 4 || isempty(engine_cfg)
    engine_cfg = default_params();
end

rows = legacy_eval_support_common_impl('normalize_design_grid', design_grid);
ctx = legacy_eval_support_common_impl('build_eval_context', trajs_in, engine_cfg, []);

nGrid = numel(rows);
out_rows = repmat(struct(), nGrid, 1);

for k = 1:nGrid
    row = rows(k);
    res = evaluate_design_point_opend(row, trajs_in, gamma_eff_scalar, engine_cfg, ctx);

    out_rows(k).design_id = legacy_eval_support_common_impl('get_design_id', row, k);
    out_rows(k).h_km = row.h_km;
    out_rows(k).i_deg = row.i_deg;
    out_rows(k).P = row.P;
    out_rows(k).T = row.T;
    out_rows(k).F = row.F;
    out_rows(k).Ns = row.Ns;
    out_rows(k).gamma_eff_scalar = gamma_eff_scalar;
    out_rows(k).pass_ratio = res.pass_ratio;
    out_rows(k).feasible_flag = res.feasible_flag;
    out_rows(k).joint_margin = res.joint_margin;
    out_rows(k).DG_rob = res.DG_rob;
    out_rows(k).rank_score = res.rank_score;
    out_rows(k).worst_case_id_DG = res.worst_case_id_DG;
    out_rows(k).n_case_total = res.n_case_total;
    out_rows(k).n_case_evaluated = res.n_case_evaluated;
    out_rows(k).failed_early = res.failed_early;
end

grid_table = struct2table(out_rows);
end
