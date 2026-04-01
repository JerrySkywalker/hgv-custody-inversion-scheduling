function out = run_stage15e_conditioned_template_family_smoke()
%RUN_STAGE15E_CONDITIONED_TEMPLATE_FAMILY_SMOKE
% Build conditioned template family from Stage15-B dataset.

dataset_mat = fullfile(pwd, 'outputs', 'stage', 'stage15', 'dataset', 'stage15b_pair_kernel_dataset.mat');
assert(exist(dataset_mat, 'file') == 2, 'Missing dataset mat: %s', dataset_mat);

S = load(dataset_mat);
dataset = S.dataset;

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'conditioned_templates');
if ~exist(out_root, 'dir'); mkdir(out_root); end

template_library = stage15_build_conditioned_template_family_from_dataset(dataset);

txt_path = fullfile(out_root, 'stage15e_conditioned_template_family_summary.txt');
mat_path = fullfile(out_root, 'stage15e_conditioned_template_family.mat');

stage15_write_conditioned_template_family_summary(txt_path, template_library);
save(mat_path, 'template_library');

disp('=== Stage15-E Conditioned Template Family Smoke ===')
disp(['num_templates = ', num2str(numel(template_library))])

for i = 1:numel(template_library)
    t = template_library(i);
    disp([t.template_id, ...
        ' | ', t.geometry_class, ...
        ' | ', t.heading_class, ...
        ' | ', t.risk_label, ...
        ' | members = ', num2str(t.num_members)])
end

disp(['[stage15e] text : ', txt_path]);
disp(['[stage15e] mat  : ', mat_path]);

out = struct();
out.output_root = out_root;
out.text_file = txt_path;
out.mat_file = mat_path;
end
