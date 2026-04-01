function out = run_stage15g_holdout_validation_stratified_smoke()
%RUN_STAGE15G_HOLDOUT_VALIDATION_STRATIFIED_SMOKE
% Stratified hold-out validation for staticworld atlas:
% one held-out target per geometry_class.

dataset_mat = fullfile(pwd, 'outputs', 'stage', 'stage15', 'staticworld_dataset3d', 'stage15f3_staticworld_pair_kernel_dataset_3d.mat');
assert(exist(dataset_mat, 'file') == 2, 'Missing staticworld dataset mat: %s', dataset_mat);

S = load(dataset_mat);
dataset = S.dataset;

split = stage15_split_staticworld_dataset_holdout_stratified(dataset);

template_library = stage15_build_conditioned_template_family_from_staticworld_dataset(split.train_dataset);
result = stage15_eval_template_library_3d(split.test_dataset, template_library);

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'staticworld_templates3d_holdout_stratified');
if ~exist(out_root, 'dir'); mkdir(out_root); end

txt_tpl = fullfile(out_root, 'stage15g_holdout_stratified_template_family_summary.txt');
txt_val = fullfile(out_root, 'stage15g_holdout_stratified_validation_summary.txt');
mat_tpl = fullfile(out_root, 'stage15g_holdout_stratified_template_family.mat');
mat_val = fullfile(out_root, 'stage15g_holdout_stratified_validation_result.mat');

stage15_write_conditioned_template_family_summary_3d(txt_tpl, template_library);
stage15_write_holdout_split_summary(txt_val, split, result);
save(mat_tpl, 'template_library', 'split');
save(mat_val, 'result', 'split');

disp('=== Stage15-G Stratified Holdout Validation Smoke ===')
disp(['num_train_samples = ', num2str(numel(split.train_dataset))])
disp(['num_test_samples = ', num2str(numel(split.test_dataset))])
disp(['num_templates = ', num2str(numel(template_library))])
disp(['holdout_accuracy = ', num2str(result.accuracy, '%.6f')])

disp(['[stage15g-stratified] tpl text : ', txt_tpl]);
disp(['[stage15g-stratified] val text : ', txt_val]);
disp(['[stage15g-stratified] tpl mat  : ', mat_tpl]);
disp(['[stage15g-stratified] val mat  : ', mat_val]);

out = struct();
out.output_root = out_root;
out.template_text_file = txt_tpl;
out.validation_text_file = txt_val;
out.template_mat_file = mat_tpl;
out.validation_mat_file = mat_val;
end
