function out = run_stage15b_dataset_smoke()
%RUN_STAGE15B_DATASET_SMOKE
% Minimal pair-kernel dataset smoke for Stage15-B.

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'dataset');
if ~exist(out_root, 'dir'); mkdir(out_root); end

box = stage15_default_local_box();
dataset = stage15_build_demo_pair_kernel_dataset(box);

txt_path = fullfile(out_root, 'stage15b_dataset_summary.txt');
mat_path = fullfile(out_root, 'stage15b_pair_kernel_dataset.mat');

stage15_write_dataset_summary(txt_path, dataset);
save(mat_path, 'box', 'dataset');

disp('=== Stage15-B Dataset Smoke ===')
disp(['num_samples = ', num2str(numel(dataset))])

labels = string({dataset.risk_label});
u = unique(labels, 'stable');
for i = 1:numel(u)
    disp([char(u(i)), ' : ', num2str(sum(labels == u(i)))])
end

disp(['[stage15b] text : ', txt_path]);
disp(['[stage15b] mat  : ', mat_path]);

out = struct();
out.output_root = out_root;
out.text_file = txt_path;
out.mat_file = mat_path;
end
