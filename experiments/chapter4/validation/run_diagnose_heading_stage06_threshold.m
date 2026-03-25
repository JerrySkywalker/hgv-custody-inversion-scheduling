function diagnose_result = run_diagnose_heading_stage06_threshold()
startup;

% ------------------------------------------------------------
% Run aligned heading validation profile
% ------------------------------------------------------------
result_h = run_MB_heading_validation_stage06();
tbl_new = result_h.truth_result.table;

row_new = tbl_new(strcmp(tbl_new.design_id, 'H0603'), :);
assert(height(row_new) == 1, 'Expected exactly one H0603 row in new framework result.');

% ------------------------------------------------------------
% Load legacy Stage06 cache
% ------------------------------------------------------------
repo_root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
stage06_cache_dir = fullfile(repo_root, 'legacy', 'outputs', 'stage', 'stage06', 'cache');

d6 = dir(fullfile(stage06_cache_dir, 'stage06_heading_walker_search*.mat'));
assert(~isempty(d6), 'No Stage06 heading walker-search cache found in %s', stage06_cache_dir);
[~, idx6] = max([d6.datenum]);
stage06_file = fullfile(d6(idx6).folder, d6(idx6).name);

S6 = load(stage06_file);
assert(isfield(S6, 'out') && isfield(S6.out, 'grid'), ...
    'Invalid Stage06 cache: missing out.grid');
grid06 = S6.out.grid;

row_legacy = grid06(grid06.h_km == 1000 & grid06.i_deg == 60 & grid06.P == 10 & grid06.T == 8, :);
assert(height(row_legacy) == 1, 'Expected exactly one aligned legacy Stage06 row.');

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
diagnose_table.new_gamma_source = row_new.gamma_source;
diagnose_table.new_Tw_s = row_new.Tw_s;
diagnose_table.new_DG_rob = row_new.raw_DG_rob;
diagnose_table.new_DA_rob = row_new.raw_DA_rob;
diagnose_table.new_DT_rob = row_new.raw_DT_rob;
diagnose_table.new_joint_margin = row_new.raw_joint_margin;
diagnose_table.new_pass_ratio = row_new.pass_ratio;
diagnose_table.new_feasible_flag = row_new.raw_feasible_flag;
diagnose_table.new_rank_score = row_new.rank_score;
diagnose_table.new_n_case_total = row_new.n_case_total;
diagnose_table.new_n_case_evaluated = row_new.n_case_evaluated;
diagnose_table.new_worst_case_id_DG = row_new.worst_case_id_DG;
diagnose_table.new_worst_case_id_DA = row_new.worst_case_id_DA;
diagnose_table.new_worst_case_id_DT = row_new.worst_case_id_DT;

diagnose_table.legacy_family_scope = row_legacy.family_scope;
diagnose_table.legacy_gamma_source = row_legacy.gamma_source;
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

artifact = artifact_service(diagnose_table, output_dir, 'diagnose_stage06_heading_threshold');
manifest = make_artifact_manifest('diagnose_heading_stage06_threshold', artifact);
manifest_paths = save_artifact_manifest(manifest, output_dir, 'diagnose_stage06_heading_threshold');

diagnose_result = struct();
diagnose_result.diagnose_table = diagnose_table;
diagnose_result.stage06_file = stage06_file;
diagnose_result.artifact = artifact;
diagnose_result.manifest = manifest;
diagnose_result.manifest_paths = manifest_paths;

disp('[diagnose] Heading Stage06 threshold diagnosis completed.');
disp(diagnose_table);
end
