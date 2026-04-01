function out = run_stage15d_template_validation_smoke()
%RUN_STAGE15D_TEMPLATE_VALIDATION_SMOKE
% Validate Stage15-C template family on Stage15-B dataset.

dataset_mat = fullfile(pwd, 'outputs', 'stage', 'stage15', 'dataset', 'stage15b_pair_kernel_dataset.mat');
template_mat = fullfile(pwd, 'outputs', 'stage', 'stage15', 'templates', 'stage15c_template_family.mat');

assert(exist(dataset_mat, 'file') == 2, 'Missing dataset mat: %s', dataset_mat);
assert(exist(template_mat, 'file') == 2, 'Missing template mat: %s', template_mat);

S1 = load(dataset_mat);
S2 = load(template_mat);

dataset = S1.dataset;
template_library = S2.template_library;

result = stage15_eval_template_library(dataset, template_library);

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'validation');
if ~exist(out_root, 'dir'); mkdir(out_root); end

txt_path = fullfile(out_root, 'stage15d_validation_summary.txt');
mat_path = fullfile(out_root, 'stage15d_validation_result.mat');

stage15_write_validation_summary(txt_path, result);
save(mat_path, 'result');

disp('=== Stage15-D Template Validation Smoke ===')
disp(['num_samples = ', num2str(result.num_samples)])
disp(['num_correct = ', num2str(result.num_correct)])
disp(['accuracy = ', num2str(result.accuracy, '%.6f')])

for i = 1:numel(result.matches)
    m = result.matches(i);
    disp([m.sample_id, ' | ', m.true_label, ' -> ', m.matched_label, ...
        ' | d = ', num2str(m.distance, '%.6f'), ...
        ' | correct = ', num2str(m.is_correct)])
end

disp(['[stage15d] text : ', txt_path]);
disp(['[stage15d] mat  : ', mat_path]);

out = struct();
out.output_root = out_root;
out.text_file = txt_path;
out.mat_file = mat_path;
end
