function out = run_ch5_phase4_static_hold(cfg, verbose)
%RUN_CH5_PHASE4_STATIC_HOLD  Phase 4 runner for S vs T comparison.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end
if nargin < 2
    verbose = true;
end

cfg.phase_name = 'phase4';

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase4');
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end

caseData = build_ch5_case(cfg);

resultS = policy_static_hold(caseData, cfg);
resultT = policy_tracking_dynamic(caseData, cfg);

trackingS = eval_tracking_metrics(resultS);
trackingT = eval_tracking_metrics(resultT);

fig_cmp = fullfile(fig_dir, 'phase4_static_vs_tracking_summary.png');
f = plot_static_vs_tracking_summary(resultS, resultT, fig_cmp); %#ok<NASGU>
close all

txt_path = fullfile(tbl_dir, 'phase4_static_vs_tracking_summary.txt');
txt_lines = {
    '=== Chapter 5 Phase 4 Static-hold vs Tracking-dynamic ==='
    ['S_coverage_ratio_ge1 = ', num2str(trackingS.coverage_ratio_ge1, '%.6f')]
    ['S_coverage_ratio_ge2 = ', num2str(trackingS.coverage_ratio_ge2, '%.6f')]
    ['S_mean_rmse          = ', num2str(trackingS.mean_rmse, '%.6f')]
    ['S_max_rmse           = ', num2str(trackingS.max_rmse, '%.6f')]
    ['T_coverage_ratio_ge1 = ', num2str(trackingT.coverage_ratio_ge1, '%.6f')]
    ['T_coverage_ratio_ge2 = ', num2str(trackingT.coverage_ratio_ge2, '%.6f')]
    ['T_mean_rmse          = ', num2str(trackingT.mean_rmse, '%.6f')]
    ['T_max_rmse           = ', num2str(trackingT.max_rmse, '%.6f')]
    };
SetTxt(txt_path, txt_lines);

log_path = fullfile(log_dir, 'phase4_static_hold_log.txt');
log_lines = {
    '[INFO] run_ch5_phase4_static_hold started'
    ['[INFO] output_root = ', out_root]
    ['[INFO] S_cov_ge1 = ', num2str(trackingS.coverage_ratio_ge1, '%.6f')]
    ['[INFO] S_cov_ge2 = ', num2str(trackingS.coverage_ratio_ge2, '%.6f')]
    ['[INFO] S_mean_rmse = ', num2str(trackingS.mean_rmse, '%.6f')]
    ['[INFO] T_cov_ge1 = ', num2str(trackingT.coverage_ratio_ge1, '%.6f')]
    ['[INFO] T_cov_ge2 = ', num2str(trackingT.coverage_ratio_ge2, '%.6f')]
    ['[INFO] T_mean_rmse = ', num2str(trackingT.mean_rmse, '%.6f')]
    '[INFO] run_ch5_phase4_static_hold finished'
    };
SetTxt(log_path, log_lines);

mat_path = fullfile(mat_dir, 'phase4_static_hold.mat');
save(mat_path, 'cfg', 'caseData', 'resultS', 'resultT', 'trackingS', 'trackingT');

if verbose
    disp('=== Chapter 5 Phase 4 Static-hold vs Tracking-dynamic ===')
    disp('--- S metrics ---')
    disp(trackingS)
    disp('--- T metrics ---')
    disp(trackingT)
    disp(['[phase4] compare fig : ', fig_cmp]);
    disp(['[phase4] text        : ', txt_path]);
    disp(['[phase4] log         : ', log_path]);
    disp(['[phase4] mat         : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.compare_fig = fig_cmp;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
out.trackingS = trackingS;
out.trackingT = trackingT;
end

function SetTxt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
