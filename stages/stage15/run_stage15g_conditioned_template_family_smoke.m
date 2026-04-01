function out = run_stage15g_conditioned_template_family_smoke()
%RUN_STAGE15G_CONDITIONED_TEMPLATE_FAMILY_SMOKE
% Build conditioned template family and validate it on staticworld dataset.

dataset_mat = fullfile(pwd, 'outputs', 'stage', 'stage15', 'staticworld_dataset3d', 'stage15f3_staticworld_pair_kernel_dataset_3d.mat');
assert(exist(dataset_mat, 'file') == 2, 'Missing staticworld dataset mat: %s', dataset_mat);

S = load(dataset_mat);
dataset = S.dataset;

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'staticworld_templates3d');
if ~exist(out_root, 'dir'); mkdir(out_root); end

template_library = stage15_build_conditioned_template_family_from_staticworld_dataset(dataset);
result = stage15_eval_template_library_3d(dataset, template_library);

txt_tpl = fullfile(out_root, 'stage15g_conditioned_template_family_summary.txt');
txt_val = fullfile(out_root, 'stage15g_template_validation_summary.txt');
mat_tpl = fullfile(out_root, 'stage15g_conditioned_template_family.mat');
mat_val = fullfile(out_root, 'stage15g_template_validation_result.mat');

stage15_write_conditioned_template_family_summary_3d(txt_tpl, template_library);
stage15_write_validation_summary_3d(txt_val, result);
save(mat_tpl, 'template_library');
save(mat_val, 'result');

disp('=== Stage15-G Staticworld Atlas Smoke ===')
disp(['num_templates = ', num2str(numel(template_library))])
disp(['num_samples = ', num2str(result.num_samples)])
disp(['num_correct = ', num2str(result.num_correct)])
disp(['accuracy = ', num2str(result.accuracy, '%.6f')])

disp(['[stage15g] tpl text : ', txt_tpl]);
disp(['[stage15g] val text : ', txt_val]);
disp(['[stage15g] tpl mat  : ', mat_tpl]);
disp(['[stage15g] val mat  : ', mat_val]);

out = struct();
out.output_root = out_root;
out.template_text_file = txt_tpl;
out.validation_text_file = txt_val;
out.template_mat_file = mat_tpl;
out.validation_mat_file = mat_val;
end
