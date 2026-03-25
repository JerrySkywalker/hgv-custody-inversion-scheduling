function validation_result = run_validate_stage06_heading_minimal()
startup;

result_h = run_MB_heading_validation_stage06();
tbl_new = result_h.truth_result.table;

repo_root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
stage06_cache_dir = fullfile(repo_root, 'legacy', 'outputs', 'stage', 'stage06', 'cache');

assert(exist(stage06_cache_dir, 'dir') == 7, ...
    'Stage06 cache directory not found: %s', stage06_cache_dir);

d6 = dir(fullfile(stage06_cache_dir, 'stage06_heading_walker_search*.mat'));
assert(~isempty(d6), 'No Stage06 heading walker-search cache found in %s', stage06_cache_dir);

[~, idx6] = max([d6.datenum]);
stage06_file = fullfile(d6(idx6).folder, d6(idx6).name);

S6 = load(stage06_file);
assert(isfield(S6, 'out') && isfield(S6.out, 'grid'), ...
    'Invalid Stage06 cache: missing out.grid');
grid06 = S6.out.grid;

new_heading = tbl_new(:, {'design_id','h_km','P','T','i_deg','Ns','pass_ratio','is_feasible','joint_margin'});
new_heading = renamevars(new_heading, ...
    {'pass_ratio','is_feasible','joint_margin'}, ...
    {'new_pass_ratio','new_is_feasible','new_joint_margin'});

legacy06 = grid06(:, {'h_km','P','T','i_deg','Ns','pass_ratio','feasible_flag','D_G_min','family_scope','n_case_evaluated'});
legacy06 = renamevars(legacy06, ...
    {'pass_ratio','feasible_flag','D_G_min'}, ...
    {'legacy_pass_ratio','legacy_is_feasible','legacy_DG_min'});

key_vars = {'h_km','P','T','i_deg','Ns'};
compare_tbl = innerjoin(new_heading, legacy06, 'Keys', key_vars);
compare_tbl.abs_diff_pass_ratio = abs(compare_tbl.new_pass_ratio - compare_tbl.legacy_pass_ratio);
compare_tbl.feasible_match = logical(compare_tbl.new_is_feasible) == logical(compare_tbl.legacy_is_feasible);

validation_result = struct();
validation_result.stage06_file = stage06_file;
validation_result.compare_table = compare_tbl;

disp('[validation] Minimal Stage06 heading comparison completed.');
disp(compare_tbl(:, {'design_id','h_km','P','T','i_deg','Ns','new_pass_ratio','legacy_pass_ratio','abs_diff_pass_ratio','feasible_match','family_scope','n_case_evaluated'}));
end
