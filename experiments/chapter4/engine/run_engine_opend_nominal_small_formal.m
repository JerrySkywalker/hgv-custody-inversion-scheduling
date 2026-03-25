function result = run_engine_opend_nominal_small_formal()
startup;

task_profile = make_ch4_task_profile();
grid_profile = make_ch4_design_grid_profile();
rows = expand_ch4_design_grid_profile(grid_profile.small_formal, 'EN');
gamma_info = load_stage04_nominal_gamma_req();

cfg = default_params();
cfg.stage04.Tw_s = gamma_info.Tw_s;
cfg.stage04.gamma_req = gamma_info.gamma_req;

task_family = build_task_family(task_profile.nominal, cfg);

search_spec = struct();
search_spec.gamma_eff_scalar = gamma_info.gamma_req;
search_spec.run_tag = 'engine_opend_nominal_small_formal';
search_spec.source_profile = struct( ...
    'task_profile', task_profile.nominal, ...
    'grid_profile', grid_profile.small_formal);
search_spec.source_kind = 'design_grid_search';

search_result = run_design_grid_search_opend(rows, task_family, cfg, search_spec);
truth_table = local_normalize_truth_table(search_result.grid_table, gamma_info);

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
result.task_family = task_family;
result.search_result = search_result;
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
truth_table.raw_DG_rob = grid_table.DG_rob;
truth_table.raw_DA_rob = nan(height(grid_table), 1);
truth_table.raw_DT_bar_rob = nan(height(grid_table), 1);
truth_table.raw_DT_rob = nan(height(grid_table), 1);
truth_table.raw_joint_margin = grid_table.joint_margin;
truth_table.raw_feasible_flag = grid_table.feasible_flag;
end
