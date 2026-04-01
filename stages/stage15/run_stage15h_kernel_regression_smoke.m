function out = run_stage15h_kernel_regression_smoke()
% Stage15-H2 smoke:
% 使用 H1 推荐模型 B 映射到 cpt3 M_G 数轴，再生成连续 prior。

map_mat = fullfile(pwd, 'outputs', 'stage', 'stage15', 'crossscale_mapping', 'stage15h1_mapping_fit.mat');
assert(exist(map_mat, 'file') == 2, 'Missing H1 mapping fit mat: %s', map_mat);

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'kernel_regression');
fig_dir = fullfile(out_root, 'figs');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

dataset_mat = fullfile(pwd, 'outputs', 'stage', 'stage15', 'crossscale_dataset', 'stage15h0_coupled_calibration_dataset.mat');
assert(exist(dataset_mat, 'file') == 2, 'Missing coupled calibration dataset mat: %s', dataset_mat);

S = load(dataset_mat);
assert(isfield(S, 'dataset'), 'Dataset mat does not contain variable "dataset".');

R = stage15h_apply_to_dataset(S.dataset);
prior_dataset = R.prior_dataset;

txt_path = stage15h_write_summary(out_root, prior_dataset);

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
scatter(MG, Rgeo, 18, frag, 'filled');
grid on;
xlabel('Mapped MG center');
ylabel('Rgeo estimate (km)');
title('Stage15-H2: mapped MG vs Rgeo');
cb = colorbar;
cb.Label.String = 'fragility score';
saveas(f1, fullfile(fig_dir, 'stage15h_MG_vs_Rgeo.png'));
close(f1);

[frag_sorted, ~] = sort(frag, 'descend');
f2 = figure('Name','stage15h_fragility_sorted');
plot(frag_sorted, 'LineWidth', 1.5);
grid on;
xlabel('sorted sample index');
ylabel('fragility score');
title('Stage15-H2: fragility score (sorted)');
saveas(f2, fullfile(fig_dir, 'stage15h_fragility_sorted.png'));
close(f2);

region_list = arrayfun(@(s) string(s.prior.region_id), prior_dataset);
cats = categorical(region_list);

f3 = figure('Name','stage15h_region_hist');
histogram(cats);
grid on;
xlabel('region id');
ylabel('count');
title('Stage15-H2: region histogram');
saveas(f3, fullfile(fig_dir, 'stage15h_region_hist.png'));
close(f3);

mat_path = fullfile(out_root, 'stage15h_kernel_regression.mat');
save(mat_path, 'prior_dataset');

disp('=== Stage15-H2 Kernel Regression Smoke ===');
fprintf('num_samples = %d\n', n);
disp(['[stage15h2] text : ', txt_path]);
disp(['[stage15h2] mat  : ', mat_path]);

out = struct();
out.output_root = out_root;
out.summary_file = txt_path;
out.mat_file = mat_path;
end
