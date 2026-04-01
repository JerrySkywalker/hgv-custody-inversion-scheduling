function out = run_stage15c_template_family_smoke()
%RUN_STAGE15C_TEMPLATE_FAMILY_SMOKE
% Minimal conditioned template-family build from Stage15-B dataset.

in_mat = fullfile(pwd, 'outputs', 'stage', 'stage15', 'dataset', 'stage15b_pair_kernel_dataset.mat');
assert(exist(in_mat, 'file') == 2, 'Missing Stage15-B dataset mat: %s', in_mat);

S = load(in_mat);
dataset = S.dataset;

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'templates');
if ~exist(out_root, 'dir'); mkdir(out_root); end

template_library = stage15_build_template_family_from_dataset(dataset);

txt_path = fullfile(out_root, 'stage15c_template_family_summary.txt');
mat_path = fullfile(out_root, 'stage15c_template_family.mat');

stage15_write_template_family_summary(txt_path, template_library);
save(mat_path, 'template_library');

disp('=== Stage15-C Template Family Smoke ===')
disp(['num_templates = ', num2str(numel(template_library))])

for i = 1:numel(template_library)
    t = template_library(i);
    disp([t.template_id, ' | ', t.risk_label, ' | members = ', num2str(t.num_members)])
end

disp(['[stage15c] text : ', txt_path]);
disp(['[stage15c] mat  : ', mat_path]);

out = struct();
out.output_root = out_root;
out.text_file = txt_path;
out.mat_file = mat_path;
end
