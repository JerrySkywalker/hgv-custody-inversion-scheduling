function result = run_engine_opend_nominal_small_formal()
startup;

task_profile = make_ch4_task_profile();
grid_profile = make_ch4_design_grid_profile();
rows = expand_ch4_design_grid_profile(grid_profile.small_formal, 'EN');
gamma_info = load_stage04_nominal_gamma_req();

cfg = default_params();
cfg.stage04.Tw_s = gamma_info.Tw_s;
cfg.stage04.gamma_req = gamma_info.gamma_req;

casebank = build_casebank_nominal(cfg);
n_case = min(task_profile.nominal.max_cases, numel(casebank.nominal));
nominal_cases = casebank.nominal(1:n_case);
first_traj = propagate_target_case(nominal_cases(1), cfg);
nominal_trajs = repmat(first_traj, n_case, 1);
trajs_in = repmat(struct('case', nominal_cases(1), 'traj', first_traj), n_case, 1);

nominal_trajs(1) = first_traj;
trajs_in(1).case = nominal_cases(1);
trajs_in(1).traj = first_traj;

for k = 2:n_case
    nominal_trajs(k) = propagate_target_case(nominal_cases(k), cfg);
    trajs_in(k).case = nominal_cases(k);
    trajs_in(k).traj = nominal_trajs(k);
end

grid_table = evaluate_design_grid_opend(rows, trajs_in, gamma_info.gamma_req, cfg);
truth_table = local_normalize_truth_table(grid_table, gamma_info);

truth_result = struct();
truth_result.rows = table2struct(truth_table);
truth_result.table = truth_table;
truth_result.row_count = height(truth_table);
truth_result.meta = struct('source', 'engine_opend', 'gamma_source', gamma_info.gamma_source);

boundary_result = ch4_small_formal_boundary_summary_service(truth_result);
envelope_result = ch4_best_pass_envelope_service(truth_table, struct('i_deg', 60));
scatter_result = ch4_design_point_scatter_service(truth_table);
fixed_path_result = ch4_fixed_path_curve_service(truth_table, struct('mode', 'P_equals_T'));

output_dir = fullfile('outputs', 'experiments', 'chapter4', 'engine');
artifact_truth = artifact_service(truth_table, output_dir, 'engine_opend_nominal_small_formal_truth');
artifact_env = artifact_service(envelope_result.envelope_table, output_dir, 'engine_opend_nominal_small_formal_best_pass');
artifact_scatter = artifact_service(scatter_result.scatter_table, output_dir, 'engine_opend_nominal_small_formal_scatter');
artifact_fixed = artifact_service(fixed_path_result.curve_table, output_dir, 'engine_opend_nominal_small_formal_fixed_path');
artifact_boundary = artifact_service(boundary_result.summary_table, output_dir, 'engine_opend_nominal_small_formal_boundary');

manifest = make_artifact_manifest('engine_opend_nominal_small_formal', ...
    {artifact_truth, artifact_env, artifact_scatter, artifact_fixed, artifact_boundary});
manifest_paths = save_artifact_manifest(manifest, output_dir, 'engine_opend_nominal_small_formal');

result = struct();
result.gamma_info = gamma_info;
result.truth_result = truth_result;
result.boundary_result = boundary_result;
result.envelope_result = envelope_result;
result.scatter_result = scatter_result;
result.fixed_path_result = fixed_path_result;
result.artifact_truth = artifact_truth;
result.artifact_env = artifact_env;
result.artifact_scatter = artifact_scatter;
result.artifact_fixed = artifact_fixed;
result.artifact_boundary = artifact_boundary;
result.manifest = manifest;
result.manifest_paths = manifest_paths;

disp('[engine] OpenD nominal small-formal run completed.');
disp(truth_table(:, {'design_id', 'P', 'T', 'Ns', 'pass_ratio', 'is_feasible', 'joint_margin'}));
disp(envelope_result.envelope_table);
end

function truth_table = local_normalize_truth_table(grid_table, gamma_info)
truth_table = table();
truth_table.design_id = string(grid_table.design_id);
truth_table.h_km = grid_table.h_km;
truth_table.i_deg = grid_table.i_deg;
truth_table.P = grid_table.P;
truth_table.T = grid_table.T;
truth_table.F = grid_table.F;
truth_table.Ns = grid_table.Ns;
truth_table.gamma_eff_scalar = repmat(gamma_info.gamma_req, height(grid_table), 1);
truth_table.gamma_source = repmat(string(gamma_info.gamma_source), height(grid_table), 1);
truth_table.Tw_s = repmat(gamma_info.Tw_s, height(grid_table), 1);
truth_table.pass_ratio = grid_table.pass_ratio;
truth_table.is_feasible = grid_table.feasible_flag;
truth_table.joint_margin = grid_table.joint_margin;
truth_table.rank_score = grid_table.rank_score;
truth_table.worst_case_id_DG = string(grid_table.worst_case_id_DG);
truth_table.n_case_total = grid_table.n_case_total;
truth_table.n_case_evaluated = grid_table.n_case_evaluated;
truth_table.failed_early = grid_table.failed_early;
truth_table.source = repmat("engine_opend", height(grid_table), 1);
end
