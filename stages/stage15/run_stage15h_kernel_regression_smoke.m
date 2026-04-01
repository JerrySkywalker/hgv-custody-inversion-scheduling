function out = run_stage15h_kernel_regression_smoke()
% Stage15-H smoke:
% 对 Stage15-F3 staticworld dataset 生成连续几何 prior。

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'kernel_regression');
fig_dir = fullfile(out_root, 'figs');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

dataset_mat = fullfile(pwd, 'outputs', 'stage', 'stage15', 'staticworld_dataset3d', 'stage15f3_staticworld_pair_kernel_dataset_3d.mat');
assert(exist(dataset_mat, 'file') == 2, 'Missing dataset mat: %s', dataset_mat);

S = load(dataset_mat);
assert(isfield(S, 'dataset'), 'Dataset mat does not contain variable "dataset".');

R = stage15h_apply_to_dataset(S.dataset);
prior_dataset = R.prior_dataset;

txt_path = stage15h_write_summary(out_root, prior_dataset);

% 可视化 1：M_G vs R_geo
n = numel(prior_dataset);
MG = zeros(1,n);
Rgeo = zeros(1,n);
frag = zeros(1,n);

for i = 1:n
    p = prior_dataset(i).prior;
    MG(i) = p.M_G_center;
    Rgeo(i) = p.R_geo_est;
    frag(i) = p.fragility_score;
end

f1 = figure('Name','stage15h_MG_vs_Rgeo');
scatter(MG, Rgeo, 30, frag, 'filled');
grid on;
xlabel('M_G center');
ylabel('R_{geo} estimate (km)');
title('Stage15-H: M_G vs R_{geo}');
cb = colorbar;
cb.Label.String = 'fragility score';
saveas(f1, fullfile(fig_dir, 'stage15h_MG_vs_Rgeo.png'));
close(f1);

% 可视化 2：fragility score sorted
[frag_sorted, idx] = sort(frag, 'descend');
f2 = figure('Name','stage15h_fragility_sorted');
plot(frag_sorted, 'LineWidth', 1.5);
grid on;
xlabel('sorted sample index');
ylabel('fragility score');
title('Stage15-H: fragility score (sorted)');
saveas(f2, fullfile(fig_dir, 'stage15h_fragility_sorted.png'));
close(f2);

mat_path = fullfile(out_root, 'stage15h_kernel_regression.mat');
save(mat_path, 'prior_dataset');

disp('=== Stage15-H Kernel Regression Smoke ===');
fprintf('num_samples = %d\n', n);
disp(['[stage15h] text : ', txt_path]);
disp(['[stage15h] mat  : ', mat_path]);

out = struct();
out.output_root = out_root;
out.summary_file = txt_path;
out.mat_file = mat_path;
end
