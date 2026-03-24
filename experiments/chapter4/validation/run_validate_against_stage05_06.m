function validation_result = run_validate_against_stage05_06()
startup;

% ------------------------------------------------------------
% Run new framework results
% ------------------------------------------------------------
nominal_result = run_MB_nominal();
heading_result = run_MB_heading();

tbl_new_nominal = nominal_result.out.truth_result.table;
tbl_new_heading = heading_result.out.truth_result.table;

% ------------------------------------------------------------
% Locate legacy Stage05 / Stage06 caches directly
% ------------------------------------------------------------
repo_root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));

stage05_cache_dir = fullfile(repo_root, 'legacy', 'outputs', 'stage', 'stage05', 'cache');
stage06_cache_dir = fullfile(repo_root, 'legacy', 'outputs', 'stage', 'stage06', 'cache');

assert(exist(stage05_cache_dir, 'dir') == 7, ...
    'Stage05 cache directory not found: %s', stage05_cache_dir);
assert(exist(stage06_cache_dir, 'dir') == 7, ...
    'Stage06 cache directory not found: %s', stage06_cache_dir);

d5 = dir(fullfile(stage05_cache_dir, 'stage05_nominal_walker_search*.mat'));
assert(~isempty(d5), 'No Stage05 nominal cache found in %s', stage05_cache_dir);
[~, idx5] = max([d5.datenum]);
stage05_file = fullfile(d5(idx5).folder, d5(idx5).name);

d6 = dir(fullfile(stage06_cache_dir, 'stage06_heading_walker_search*.mat'));
assert(~isempty(d6), 'No Stage06 heading cache found in %s', stage06_cache_dir);
[~, idx6] = max([d6.datenum]);
stage06_file = fullfile(d6(idx6).folder, d6(idx6).name);

S5 = load(stage05_file);
assert(isfield(S5, 'out') && isfield(S5.out, 'grid'), ...
    'Invalid Stage05 cache: missing out.grid');
grid05 = S5.out.grid;

S6 = load(stage06_file);
assert(isfield(S6, 'out') && isfield(S6.out, 'grid'), ...
    'Invalid Stage06 cache: missing out.grid');
grid06 = S6.out.grid;

% ------------------------------------------------------------
% Normalize new tables to comparison schema
% ------------------------------------------------------------
new_nominal = tbl_new_nominal(:, {'design_id','P','T','i_deg','Ns','pass_ratio','is_feasible','joint_margin'});
new_heading = tbl_new_heading(:, {'design_id','P','T','i_deg','Ns','pass_ratio','is_feasible','joint_margin'});

new_nominal = renamevars(new_nominal, ...
    {'pass_ratio','is_feasible','joint_margin'}, ...
    {'new_pass_ratio','new_is_feasible','new_joint_margin'});

new_heading = renamevars(new_heading, ...
    {'pass_ratio','is_feasible','joint_margin'}, ...
    {'new_pass_ratio','new_is_feasible','new_joint_margin'});

% ------------------------------------------------------------
% Normalize legacy tables to comparison schema
% ------------------------------------------------------------
legacy05 = grid05(:, {'P','T','i_deg','Ns','pass_ratio','feasible_flag','D_G_min'});
legacy06 = grid06(:, {'P','T','i_deg','Ns','pass_ratio','feasible_flag','D_G_min'});

legacy05 = renamevars(legacy05, ...
    {'pass_ratio','feasible_flag','D_G_min'}, ...
    {'legacy_pass_ratio','legacy_is_feasible','legacy_DG_min'});

legacy06 = renamevars(legacy06, ...
    {'pass_ratio','feasible_flag','D_G_min'}, ...
    {'legacy_pass_ratio','legacy_is_feasible','legacy_DG_min'});

% ------------------------------------------------------------
% Inner join on common design keys
% ------------------------------------------------------------
key_vars = {'P','T','i_deg','Ns'};

nominal_compare = innerjoin(new_nominal, legacy05, 'Keys', key_vars);
heading_compare = innerjoin(new_heading, legacy06, 'Keys', key_vars);

nominal_compare.abs_diff_pass_ratio = abs(nominal_compare.new_pass_ratio - nominal_compare.legacy_pass_ratio);
heading_compare.abs_diff_pass_ratio = abs(heading_compare.new_pass_ratio - heading_compare.legacy_pass_ratio);

nominal_compare.feasible_match = (nominal_compare.new_is_feasible == logical(nominal_compare.legacy_is_feasible));
heading_compare.feasible_match = (heading_compare.new_is_feasible == logical(heading_compare.legacy_is_feasible));

% ------------------------------------------------------------
% Export artifacts
% ------------------------------------------------------------
output_dir = fullfile('outputs', 'experiments', 'chapter4', 'validation');

artifact_nominal = artifact_service(nominal_compare, output_dir, 'validate_stage05_nominal');
artifact_heading = artifact_service(heading_compare, output_dir, 'validate_stage06_heading');

manifest = make_artifact_manifest( ...
    'validate_against_stage05_06', ...
    {artifact_nominal, artifact_heading});

manifest_paths = save_artifact_manifest( ...
    manifest, ...
    output_dir, ...
    'validate_against_stage05_06');

validation_result = struct();
validation_result.nominal_compare = nominal_compare;
validation_result.heading_compare = heading_compare;
validation_result.stage05_file = stage05_file;
validation_result.stage06_file = stage06_file;
validation_result.artifact_nominal = artifact_nominal;
validation_result.artifact_heading = artifact_heading;
validation_result.manifest = manifest;
validation_result.manifest_paths = manifest_paths;

disp('[validation] Stage05/06 comparison completed.');
disp('[validation] Nominal comparison:');
disp(nominal_compare(:, {'design_id','P','T','i_deg','Ns','new_pass_ratio','legacy_pass_ratio','abs_diff_pass_ratio','feasible_match'}));
disp('[validation] Heading comparison:');
disp(heading_compare(:, {'design_id','P','T','i_deg','Ns','new_pass_ratio','legacy_pass_ratio','abs_diff_pass_ratio','feasible_match'}));
end
