function out = run_stage15f3_staticworld_dataset_smoke()
%RUN_STAGE15F3_STATICWORLD_DATASET_SMOKE
% Build staticworld 3D pair-kernel dataset.

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'staticworld_dataset3d');
if ~exist(out_root, 'dir'); mkdir(out_root); end

box = stage15_default_local_box_3d();
dataset = stage15_build_staticworld_pair_kernel_dataset_3d(box);

txt_path = fullfile(out_root, 'stage15f3_staticworld_dataset_summary.txt');
mat_path = fullfile(out_root, 'stage15f3_staticworld_pair_kernel_dataset_3d.mat');

stage15_write_staticworld_dataset_summary(txt_path, dataset);
save(mat_path, 'box', 'dataset');

disp('=== Stage15-F3 Staticworld Dataset Smoke ===')
disp(['num_samples = ', num2str(numel(dataset))])

labels = string({dataset.risk_label});
u = unique(labels, 'stable');
for i = 1:numel(u)
    disp([char(u(i)), ' : ', num2str(sum(labels == u(i)))])
end

gcls = string({dataset.geometry_class});
ug = unique(gcls, 'stable');
for i = 1:numel(ug)
    disp(['geometry/', char(ug(i)), ' : ', num2str(sum(gcls == ug(i)))])
end

lcls = string({dataset.layout_class});
ul = unique(lcls, 'stable');
for i = 1:numel(ul)
    disp(['layout/', char(ul(i)), ' : ', num2str(sum(lcls == ul(i)))])
end

disp(['[stage15f3] text : ', txt_path]);
disp(['[stage15f3] mat  : ', mat_path]);

out = struct();
out.output_root = out_root;
out.text_file = txt_path;
out.mat_file = mat_path;
end
