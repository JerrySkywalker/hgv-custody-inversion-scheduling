function validation_result = run_validate_against_stage05_06()
startup;

% ------------------------------------------------------------
% Stage05 nominal validation (required)
% ------------------------------------------------------------
nominal_result = run_MB_nominal_validation_stage05();
tbl_new_nominal = nominal_result.truth_result.table;

repo_root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
stage05_cache_dir = fullfile(repo_root, 'legacy', 'outputs', 'stage', 'stage05', 'cache');

assert(exist(stage05_cache_dir, 'dir') == 7, ...
    'Stage05 cache directory not found: %s', stage05_cache_dir);

d5 = dir(fullfile(stage05_cache_dir, 'stage05_nominal_walker_search*.mat'));
assert(~isempty(d5), 'No Stage05 nominal cache found in %s', stage05_cache_dir);
[~, idx5] = max([d5.datenum]);
stage05_file = fullfile(d5(idx5).folder, d5(idx5).name);

S5 = load(stage05_file);
assert(isfield(S5, 'out') && isfield(S5.out, 'grid'), ...
    'Invalid Stage05 cache: missing out.grid');
grid05 = S5.out.grid;

new_nominal = tbl_new_nominal(:, {'design_id','h_km','P','T','i_deg','Ns','pass_ratio','is_feasible','joint_margin'});
new_nominal = renamevars(new_nominal, ...
    {'pass_ratio','is_feasible','joint_margin'}, ...
    {'new_pass_ratio','new_is_feasible','new_joint_margin'});

legacy05 = grid05(:, {'h_km','P','T','i_deg','Ns','pass_ratio','feasible_flag','D_G_min'});
legacy05 = renamevars(legacy05, ...
    {'pass_ratio','feasible_flag','D_G_min'}, ...
    {'legacy_pass_ratio','legacy_is_feasible','legacy_DG_min'});

key_vars = {'h_km','P','T','i_deg','Ns'};
nominal_compare = innerjoin(new_nominal, legacy05, 'Keys', key_vars);
nominal_compare.abs_diff_pass_ratio = abs(nominal_compare.new_pass_ratio - nominal_compare.legacy_pass_ratio);
nominal_compare.feasible_match = (nominal_compare.new_is_feasible == logical(nominal_compare.legacy_is_feasible));

% ------------------------------------------------------------
% Stage06 heading minimal validation (optional but preferred)
% Reuse the already-verified minimal comparison entrypoint.
% ------------------------------------------------------------
heading_compare = table();
stage06_file = '';
artifact_heading = struct();

try
    heading_validation = run_validate_stage06_heading_minimal();
    heading_compare = heading_validation.compare_table;
    stage06_file = heading_validation.stage06_file;
catch ME
    warning('run_validate_against_stage05_06:Stage06Unavailable', ...
        'Stage06 minimal heading validation unavailable: %s', ME.message);
end

% ------------------------------------------------------------
% Export artifacts
% ------------------------------------------------------------
output_dir = fullfile('outputs', 'experiments', 'chapter4', 'validation');

artifact_nominal = artifact_service(nominal_compare, output_dir, 'validate_stage05_nominal');

artifacts = {artifact_nominal};
if ~isempty(heading_compare)
    artifact_heading = artifact_service(heading_compare, output_dir, 'validate_stage06_heading');
    artifacts{end+1} = artifact_heading;
end

manifest = make_artifact_manifest( ...
    'validate_against_stage05_06', ...
    artifacts);

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
disp(nominal_compare(:, {'design_id','h_km','P','T','i_deg','Ns','new_pass_ratio','legacy_pass_ratio','abs_diff_pass_ratio','feasible_match'}));

if ~isempty(heading_compare)
    disp('[validation] Heading comparison:');
    disp(heading_compare(:, {'design_id','h_km','P','T','i_deg','Ns','new_pass_ratio','legacy_pass_ratio','abs_diff_pass_ratio','feasible_match'}));
else
    disp('[validation] Heading comparison skipped: Stage06 minimal validation unavailable.');
end
end
