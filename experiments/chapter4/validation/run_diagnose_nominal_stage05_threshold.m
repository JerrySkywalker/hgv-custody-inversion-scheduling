function diagnose_result = run_diagnose_nominal_stage05_threshold()
startup;

% ------------------------------------------------------------
% Run aligned nominal validation profile
% ------------------------------------------------------------
result_v = run_MB_nominal_validation_stage05();
tbl_new = result_v.truth_result.table;

row_new = tbl_new(strcmp(tbl_new.design_id, 'V0501'), :);
assert(height(row_new) == 1, 'Expected exactly one V0501 row in new framework result.');

% ------------------------------------------------------------
% Load legacy Stage05 cache
% ------------------------------------------------------------
repo_root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
stage05_cache_dir = fullfile(repo_root, 'legacy', 'outputs', 'stage', 'stage05', 'cache');

d5 = dir(fullfile(stage05_cache_dir, 'stage05_nominal_walker_search*.mat'));
assert(~isempty(d5), 'No Stage05 nominal cache found in %s', stage05_cache_dir);
[~, idx5] = max([d5.datenum]);
stage05_file = fullfile(d5(idx5).folder, d5(idx5).name);

S5 = load(stage05_file);
assert(isfield(S5, 'out') && isfield(S5.out, 'grid'), ...
    'Invalid Stage05 cache: missing out.grid');
grid05 = S5.out.grid;

row_legacy = grid05(grid05.h_km == 1000 & grid05.i_deg == 60 & grid05.P == 8 & grid05.T == 8, :);
assert(height(row_legacy) == 1, 'Expected exactly one aligned legacy Stage05 row.');

% ------------------------------------------------------------
% Build diagnostic table
% ------------------------------------------------------------
diagnose_table = table();

diagnose_table.design_id = row_new.design_id;
diagnose_table.h_km = row_new.h_km;
diagnose_table.i_deg = row_new.i_deg;
diagnose_table.P = row_new.P;
diagnose_table.T = row_new.T;
diagnose_table.Ns = row_new.Ns;

diagnose_table.new_gamma_eff_scalar = row_new.gamma_eff_scalar;
diagnose_table.new_DG_rob = row_new.raw_DG_rob;
diagnose_table.new_DA_rob = row_new.raw_DA_rob;
diagnose_table.new_DT_rob = row_new.raw_DT_rob;
diagnose_table.new_joint_margin = row_new.raw_joint_margin;
diagnose_table.new_pass_ratio = row_new.pass_ratio;
diagnose_table.new_feasible_flag = row_new.raw_feasible_flag;
diagnose_table.new_rank_score = row_new.rank_score;
diagnose_table.new_n_case_evaluated = row_new.n_case_evaluated;

diagnose_table.legacy_gamma_req = row_legacy.gamma_req;
diagnose_table.legacy_DG_min = row_legacy.D_G_min;
diagnose_table.legacy_pass_ratio = row_legacy.pass_ratio;
diagnose_table.legacy_feasible_flag = row_legacy.feasible_flag;
diagnose_table.legacy_rank_score = row_legacy.rank_score;
diagnose_table.legacy_n_case_evaluated = row_legacy.n_case_evaluated;

diagnose_table.diff_pass_ratio = diagnose_table.new_pass_ratio - diagnose_table.legacy_pass_ratio;
diagnose_table.diff_rank_score = diagnose_table.new_rank_score - diagnose_table.legacy_rank_score;
diagnose_table.feasible_match = logical(diagnose_table.new_feasible_flag) == logical(diagnose_table.legacy_feasible_flag);

% ------------------------------------------------------------
% Export artifacts
% ------------------------------------------------------------
output_dir = fullfile('outputs', 'experiments', 'chapter4', 'validation');

artifact = artifact_service(diagnose_table, output_dir, 'diagnose_stage05_nominal_threshold');
manifest = make_artifact_manifest('diagnose_nominal_stage05_threshold', artifact);
manifest_paths = save_artifact_manifest(manifest, output_dir, 'diagnose_stage05_nominal_threshold');

diagnose_result = struct();
diagnose_result.diagnose_table = diagnose_table;
diagnose_result.stage05_file = stage05_file;
diagnose_result.artifact = artifact;
diagnose_result.manifest = manifest;
diagnose_result.manifest_paths = manifest_paths;

disp('[diagnose] Nominal Stage05 threshold diagnosis completed.');
disp(diagnose_table);
end
