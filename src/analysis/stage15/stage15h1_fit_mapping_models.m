function out = stage15h1_fit_mapping_models()
% Stage15-H1:
% 在 H0 coupled calibration dataset 上拟合并比较 cross-scale mapping 模型。
%
% 比较三类模型：
%   A: MG ~ 1 + log10(lambda_geom + eps0)
%   B: MG ~ 1 + log10(lambda_geom + eps0) + baseline_n + interaction
%   C: MG ~ 1 + log10(lambda_geom + eps0) + crossing_angle_n + interaction

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'crossscale_mapping');
fig_dir = fullfile(out_root, 'figs');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

dataset_mat = fullfile(pwd, 'outputs', 'stage', 'stage15', 'crossscale_dataset', 'stage15h0_coupled_calibration_dataset.mat');
assert(exist(dataset_mat, 'file') == 2, 'Missing coupled calibration dataset: %s', dataset_mat);

S = load(dataset_mat);
assert(isfield(S, 'dataset'), 'Dataset mat missing variable "dataset".');
dataset = S.dataset;
n = numel(dataset);

lambda_geom = zeros(n,1);
MG = zeros(n,1);
baseline_km = zeros(n,1);
crossing_angle_deg = zeros(n,1);
region = strings(n,1);

for i = 1:n
    lambda_geom(i) = dataset(i).kappa2.lambda_min_geom;
    MG(i) = dataset(i).MG_cpt3;
    baseline_km(i) = dataset(i).baseline_km;
    crossing_angle_deg(i) = dataset(i).kappa2.crossing_angle_deg;
    region(i) = dataset(i).MG_region;
end

eps0 = 1e-6;
log_lambda = log10(lambda_geom + eps0);
baseline_n = baseline_km / 1000;
crossing_n = crossing_angle_deg / 180;

% --------------------------
% 固定随机种子，做分层划分
% --------------------------
rng(20260402);

idx_train = false(n,1);
region_names = unique(region);

for k = 1:numel(region_names)
    rk = region_names(k);
    idx = find(region == rk);
    m = numel(idx);
    order = idx(randperm(m));
    mtrain = max(1, round(0.8 * m));
    idx_train(order(1:mtrain)) = true;
end
idx_test = ~idx_train;

% --------------------------
% 设计矩阵
% --------------------------
XA = [ones(n,1), log_lambda];
XB = [ones(n,1), log_lambda, baseline_n, log_lambda .* baseline_n];
XC = [ones(n,1), log_lambda, crossing_n, log_lambda .* crossing_n];

modelA = local_fit_and_eval('A_log1d', XA, MG, idx_train, idx_test);
modelB = local_fit_and_eval('B_log_baseline', XB, MG, idx_train, idx_test);
modelC = local_fit_and_eval('C_log_crossing', XC, MG, idx_train, idx_test);

models = struct('A', modelA, 'B', modelB, 'C', modelC);

% 选择推荐模型：test RMSE 最小；若接近则优先低复杂度
rmse_test = [modelA.rmse_test, modelB.rmse_test, modelC.rmse_test];
[best_rmse, ibest] = min(rmse_test);
model_names = {'A','B','C'};
best_name = model_names{ibest};

% 若 A 与最优差距 < 3%，优先简单模型 A
if (modelA.rmse_test - best_rmse) / max(best_rmse, eps) < 0.03
    best_name = 'A';
end

recommended_model = best_name;

% --------------------------
% 反推第三章阈值在各模型输入下的“典型 lambda_geom”
% 用全样本中位 baseline / crossing 计算
% --------------------------
MG_thr_12 = 115.411378;
MG_thr_23 = 198.489832;

med_baseline_n = median(baseline_n);
med_crossing_n = median(crossing_n);

thr = struct();
thr.A.lambda_geom_thr_12 = local_inv_lambda_modelA(MG_thr_12, modelA.beta, eps0);
thr.A.lambda_geom_thr_23 = local_inv_lambda_modelA(MG_thr_23, modelA.beta, eps0);

thr.B.lambda_geom_thr_12 = local_inv_lambda_modelB(MG_thr_12, modelB.beta, eps0, med_baseline_n);
thr.B.lambda_geom_thr_23 = local_inv_lambda_modelB(MG_thr_23, modelB.beta, eps0, med_baseline_n);

thr.C.lambda_geom_thr_12 = local_inv_lambda_modelC(MG_thr_12, modelC.beta, eps0, med_crossing_n);
thr.C.lambda_geom_thr_23 = local_inv_lambda_modelC(MG_thr_23, modelC.beta, eps0, med_crossing_n);

% --------------------------
% 可视化 1：true vs predicted
% --------------------------
f1 = figure('Name','stage15h1_true_vs_pred');
tiledlayout(1,3,'Padding','compact','TileSpacing','compact');

nexttile;
scatter(MG(idx_test), modelA.yhat_test, 12, 'filled'); grid on;
xlabel('true MG');
ylabel('pred MG');
title(sprintf('A: test RMSE=%.3f, R2=%.3f', modelA.rmse_test, modelA.r2_test));

nexttile;
scatter(MG(idx_test), modelB.yhat_test, 12, 'filled'); grid on;
xlabel('true MG');
ylabel('pred MG');
title(sprintf('B: test RMSE=%.3f, R2=%.3f', modelB.rmse_test, modelB.r2_test));

nexttile;
scatter(MG(idx_test), modelC.yhat_test, 12, 'filled'); grid on;
xlabel('true MG');
ylabel('pred MG');
title(sprintf('C: test RMSE=%.3f, R2=%.3f', modelC.rmse_test, modelC.r2_test));

saveas(f1, fullfile(fig_dir, 'stage15h1_true_vs_pred.png'));
close(f1);

% --------------------------
% 可视化 2：残差 vs baseline
% --------------------------
f2 = figure('Name','stage15h1_residual_vs_baseline');
tiledlayout(1,3,'Padding','compact','TileSpacing','compact');

nexttile;
scatter(baseline_km(idx_test), MG(idx_test) - modelA.yhat_test, 12, 'filled'); grid on;
xlabel('baseline (km)');
ylabel('residual');
title('A residual vs baseline');

nexttile;
scatter(baseline_km(idx_test), MG(idx_test) - modelB.yhat_test, 12, 'filled'); grid on;
xlabel('baseline (km)');
ylabel('residual');
title('B residual vs baseline');

nexttile;
scatter(baseline_km(idx_test), MG(idx_test) - modelC.yhat_test, 12, 'filled'); grid on;
xlabel('baseline (km)');
ylabel('residual');
title('C residual vs baseline');

saveas(f2, fullfile(fig_dir, 'stage15h1_residual_vs_baseline.png'));
close(f2);

% --------------------------
% 可视化 3：lambda -> MG 拟合曲线（A 模型）
% --------------------------
xfit = linspace(min(log_lambda), max(log_lambda), 200).';
yfit = modelA.beta(1) + modelA.beta(2) * xfit;

f3 = figure('Name','stage15h1_modelA_fit_curve');
scatter(log_lambda, MG, 8, baseline_km, 'filled'); hold on; grid on;
plot(xfit, yfit, 'LineWidth', 2);
xlabel('log10(lambda_geom + eps0)');
ylabel('MG (cpt3 scale)');
title('Stage15-H1 model A fit');
cb = colorbar;
cb.Label.String = 'baseline (km)';
saveas(f3, fullfile(fig_dir, 'stage15h1_modelA_fit_curve.png'));
close(f3);

% --------------------------
% summary
% --------------------------
summary_file = fullfile(out_root, 'stage15h1_mapping_fit_summary.txt');
fid = fopen(summary_file, 'w');
assert(fid >= 0, 'Failed to open summary file.');

fprintf(fid, '=== Stage15-H1 Mapping Fit Summary ===\n');
fprintf(fid, 'num_samples = %d\n', n);
fprintf(fid, 'num_train = %d\n', sum(idx_train));
fprintf(fid, 'num_test = %d\n', sum(idx_test));
fprintf(fid, '\n');

local_write_model_summary(fid, modelA);
local_write_model_summary(fid, modelB);
local_write_model_summary(fid, modelC);

fprintf(fid, '--- recommended model ---\n');
fprintf(fid, 'recommended_model = %s\n', recommended_model);
fprintf(fid, '\n');

fprintf(fid, '--- inverse thresholds (typical conditional settings) ---\n');
fprintf(fid, 'A.lambda_geom_thr_12 = %.12f\n', thr.A.lambda_geom_thr_12);
fprintf(fid, 'A.lambda_geom_thr_23 = %.12f\n', thr.A.lambda_geom_thr_23);
fprintf(fid, 'B.lambda_geom_thr_12 = %.12f\n', thr.B.lambda_geom_thr_12);
fprintf(fid, 'B.lambda_geom_thr_23 = %.12f\n', thr.B.lambda_geom_thr_23);
fprintf(fid, 'C.lambda_geom_thr_12 = %.12f\n', thr.C.lambda_geom_thr_12);
fprintf(fid, 'C.lambda_geom_thr_23 = %.12f\n', thr.C.lambda_geom_thr_23);
fprintf(fid, '\n');

fprintf(fid, 'median_baseline_n = %.12f\n', med_baseline_n);
fprintf(fid, 'median_crossing_n = %.12f\n', med_crossing_n);

fclose(fid);

mat_file = fullfile(out_root, 'stage15h1_mapping_fit.mat');
save(mat_file, 'models', 'recommended_model', 'thr', 'idx_train', 'idx_test', 'lambda_geom', 'MG', 'baseline_km', 'crossing_angle_deg');

out = struct();
out.summary_file = summary_file;
out.mat_file = mat_file;
end

function model = local_fit_and_eval(name, X, y, idx_train, idx_test)
Xtr = X(idx_train,:);
ytr = y(idx_train);
Xte = X(idx_test,:);
yte = y(idx_test);

beta = Xtr \ ytr;

yhat_tr = Xtr * beta;
yhat_te = Xte * beta;

rmse_tr = sqrt(mean((ytr - yhat_tr).^2));
rmse_te = sqrt(mean((yte - yhat_te).^2));

r2_tr = 1 - sum((ytr - yhat_tr).^2) / max(sum((ytr - mean(ytr)).^2), eps);
r2_te = 1 - sum((yte - yhat_te).^2) / max(sum((yte - mean(yte)).^2), eps);

model = struct();
model.name = name;
model.beta = beta;
model.rmse_train = rmse_tr;
model.rmse_test = rmse_te;
model.r2_train = r2_tr;
model.r2_test = r2_te;
model.yhat_train = yhat_tr;
model.yhat_test = yhat_te;
end

function lambda = local_inv_lambda_modelA(MG_target, beta, eps0)
x = (MG_target - beta(1)) / beta(2);
lambda = 10.^x - eps0;
lambda = max(lambda, eps);
end

function lambda = local_inv_lambda_modelB(MG_target, beta, eps0, baseline_n)
den = beta(2) + beta(4) * baseline_n;
num = MG_target - beta(1) - beta(3) * baseline_n;
x = num / den;
lambda = 10.^x - eps0;
lambda = max(lambda, eps);
end

function lambda = local_inv_lambda_modelC(MG_target, beta, eps0, crossing_n)
den = beta(2) + beta(4) * crossing_n;
num = MG_target - beta(1) - beta(3) * crossing_n;
x = num / den;
lambda = 10.^x - eps0;
lambda = max(lambda, eps);
end

function local_write_model_summary(fid, model)
fprintf(fid, '--- %s ---\n', model.name);
fprintf(fid, 'beta = ');
fprintf(fid, '%.12f ', model.beta);
fprintf(fid, '\n');
fprintf(fid, 'rmse_train = %.12f\n', model.rmse_train);
fprintf(fid, 'rmse_test = %.12f\n', model.rmse_test);
fprintf(fid, 'r2_train = %.12f\n', model.r2_train);
fprintf(fid, 'r2_test = %.12f\n', model.r2_test);
fprintf(fid, '\n');
end
