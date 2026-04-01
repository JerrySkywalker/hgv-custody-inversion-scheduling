function out = stage15h25_run_sanity_check()
% Stage15-H2.5:
% 比较 H0 真值 MG_region 与 H2 预测 prior.region_id 的一致性。

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'kernel_regression_sanity');
fig_dir = fullfile(out_root, 'figs');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

truth_mat = fullfile(pwd, 'outputs', 'stage', 'stage15', 'crossscale_dataset', 'stage15h0_coupled_calibration_dataset.mat');
pred_mat  = fullfile(pwd, 'outputs', 'stage', 'stage15', 'kernel_regression', 'stage15h_kernel_regression.mat');

assert(exist(truth_mat, 'file') == 2, 'Missing truth mat: %s', truth_mat);
assert(exist(pred_mat,  'file') == 2, 'Missing pred mat: %s', pred_mat);

T = load(truth_mat);
P = load(pred_mat);

assert(isfield(T, 'dataset'), 'Truth mat missing variable dataset.');
assert(isfield(P, 'prior_dataset'), 'Pred mat missing variable prior_dataset.');

truth_dataset = T.dataset;
pred_dataset  = P.prior_dataset;

n_truth = numel(truth_dataset);
n_pred  = numel(pred_dataset);
assert(n_truth == n_pred, 'Truth/pred dataset size mismatch: %d vs %d', n_truth, n_pred);

labels = ["low_M_G","mid_M_G","high_M_G"];
nclass = numel(labels);

truth = strings(n_truth,1);
pred  = strings(n_pred,1);
sample_id_truth = strings(n_truth,1);
sample_id_pred  = strings(n_pred,1);

for i = 1:n_truth
    truth(i) = string(truth_dataset(i).MG_region);
    sample_id_truth(i) = string(truth_dataset(i).sample_id);
end

for i = 1:n_pred
    pred(i) = string(pred_dataset(i).prior.region_id);
    sample_id_pred(i) = string(pred_dataset(i).sample_id);
end

assert(all(sample_id_truth == sample_id_pred), 'Sample ordering mismatch between truth and pred.');

cm = zeros(nclass, nclass);
for i = 1:n_truth
    it = find(labels == truth(i), 1);
    ip = find(labels == pred(i), 1);
    assert(~isempty(it) && ~isempty(ip), 'Unknown class label encountered.');
    cm(it, ip) = cm(it, ip) + 1;
end

accuracy = sum(diag(cm)) / max(sum(cm, 'all'), eps);

precision = zeros(nclass,1);
recall = zeros(nclass,1);
f1 = zeros(nclass,1);

for k = 1:nclass
    tp = cm(k,k);
    fp = sum(cm(:,k)) - tp;
    fn = sum(cm(k,:)) - tp;

    precision(k) = tp / max(tp + fp, eps);
    recall(k) = tp / max(tp + fn, eps);
    f1(k) = 2 * precision(k) * recall(k) / max(precision(k) + recall(k), eps);
end

% 画图1：confusion matrix
f1fig = figure('Name','stage15h25_confusion_matrix');
imagesc(cm);
axis equal tight;
colorbar;
set(gca, 'XTick', 1:nclass, 'XTickLabel', cellstr(labels));
set(gca, 'YTick', 1:nclass, 'YTickLabel', cellstr(labels));
xlabel('predicted region');
ylabel('true region');
title(sprintf('Stage15-H2.5 confusion matrix (acc = %.4f)', accuracy));
for i = 1:nclass
    for j = 1:nclass
        text(j, i, sprintf('%d', cm(i,j)), 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    end
end
saveas(f1fig, fullfile(fig_dir, 'stage15h25_confusion_matrix.png'));
close(f1fig);

% 画图2：每类 precision/recall/F1
f2fig = figure('Name','stage15h25_region_match_bar');
vals = [precision, recall, f1];
bar(vals);
grid on;
ylim([0, 1]);
set(gca, 'XTick', 1:nclass, 'XTickLabel', cellstr(labels));
legend({'precision','recall','F1'}, 'Location', 'southoutside', 'Orientation', 'horizontal');
xlabel('region');
ylabel('score');
title('Stage15-H2.5 per-class metrics');
saveas(f2fig, fullfile(fig_dir, 'stage15h25_region_match_bar.png'));
close(f2fig);

% 额外输出：前20个错分样本
mis_idx = find(truth ~= pred);
m = min(20, numel(mis_idx));

summary_file = fullfile(out_root, 'stage15h25_sanity_summary.txt');
fid = fopen(summary_file, 'w');
assert(fid >= 0, 'Failed to open summary file.');

fprintf(fid, '=== Stage15-H2.5 Sanity Check Summary ===\n');
fprintf(fid, 'num_samples = %d\n', n_truth);
fprintf(fid, 'accuracy = %.12f\n', accuracy);
fprintf(fid, '\n');

fprintf(fid, '--- labels ---\n');
for k = 1:nclass
    fprintf(fid, '%d: %s\n', k, labels(k));
end
fprintf(fid, '\n');

fprintf(fid, '--- confusion matrix (rows=true, cols=pred) ---\n');
for i = 1:nclass
    fprintf(fid, '%s : ', labels(i));
    for j = 1:nclass
        fprintf(fid, '%d ', cm(i,j));
    end
    fprintf(fid, '\n');
end
fprintf(fid, '\n');

fprintf(fid, '--- per-class metrics ---\n');
for k = 1:nclass
    fprintf(fid, '%s : precision=%.12f recall=%.12f F1=%.12f\n', ...
        labels(k), precision(k), recall(k), f1(k));
end
fprintf(fid, '\n');

fprintf(fid, '--- first 20 mismatches ---\n');
fprintf(fid, 'sample_id,true_region,pred_region,MG_truth,MG_pred\n');
for ii = 1:m
    i = mis_idx(ii);
    fprintf(fid, '%s,%s,%s,%.12f,%.12f\n', ...
        sample_id_truth(i), ...
        truth(i), pred(i), ...
        truth_dataset(i).MG_cpt3, ...
        pred_dataset(i).prior.M_G_center);
end

fclose(fid);

result = struct();
result.labels = labels;
result.cm = cm;
result.accuracy = accuracy;
result.precision = precision;
result.recall = recall;
result.f1 = f1;
result.truth = truth;
result.pred = pred;
result.sample_id = sample_id_truth;
result.mis_idx = mis_idx;

mat_file = fullfile(out_root, 'stage15h25_sanity_result.mat');
save(mat_file, 'result');

out = struct();
out.summary_file = summary_file;
out.mat_file = mat_file;
out.output_root = out_root;
end
