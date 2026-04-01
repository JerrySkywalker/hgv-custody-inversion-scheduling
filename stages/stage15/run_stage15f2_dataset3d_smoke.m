function out = run_stage15f2_dataset3d_smoke()
%RUN_STAGE15F2_DATASET3D_SMOKE
% Minimal 3D pair-kernel dataset smoke for Stage15-F2.

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'dataset3d');
if ~exist(out_root, 'dir'); mkdir(out_root); end

box = stage15_default_local_box_3d();
dataset = stage15_build_demo_pair_kernel_dataset_3d(box);

txt_path = fullfile(out_root, 'stage15f2_dataset3d_summary.txt');
mat_path = fullfile(out_root, 'stage15f2_pair_kernel_dataset_3d.mat');

stage15_write_dataset3d_summary(txt_path, dataset);
save(mat_path, 'box', 'dataset');

disp('=== Stage15-F2 Dataset3D Smoke ===')
disp(['num_samples = ', num2str(numel(dataset))])

labels = string({dataset.risk_label});
u = unique(labels, 'stable');
for i = 1:numel(u)
    disp([char(u(i)), ' : ', num2str(sum(labels == u(i)))])
end

disp(['[stage15f2] text : ', txt_path]);
disp(['[stage15f2] mat  : ', mat_path]);

out = struct();
out.output_root = out_root;
out.text_file = txt_path;
out.mat_file = mat_path;
end
