function out = run_ch5_phase3_tracking_baseline(cfg, verbose)
%RUN_CH5_PHASE3_TRACKING_BASELINE  Phase 3 runner for tracking-oriented dynamic baseline.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end
if nargin < 2
    verbose = true;
end

cfg.phase_name = 'phase3';

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase3');
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end

caseData = build_ch5_case(cfg);
result = policy_tracking_dynamic(caseData, cfg);

tracking = eval_tracking_metrics(result);

txt_path = fullfile(tbl_dir, 'phase3_tracking_summary.txt');
txt_lines = {
    '=== Chapter 5 Phase 3 Tracking Baseline Summary ==='
    ['coverage_ratio_ge1 = ', num2str(tracking.coverage_ratio_ge1, '%.6f')]
    ['coverage_ratio_ge2 = ', num2str(tracking.coverage_ratio_ge2, '%.6f')]
    ['mean_rmse          = ', num2str(tracking.mean_rmse, '%.6f')]
    ['max_rmse           = ', num2str(tracking.max_rmse, '%.6f')]
    };
SetTxt(txt_path, txt_lines);

fig_cov = fullfile(fig_dir, 'phase3_tracking_coverage_timeline.png');
fig_rmse = fullfile(fig_dir, 'phase3_tracking_rmse_timeline.png');

f1 = plot_tracking_coverage_timeline(result, fig_cov); %#ok<NASGU>
f2 = plot_tracking_rmse_timeline(result, fig_rmse); %#ok<NASGU>
close all

log_path = fullfile(log_dir, 'phase3_tracking_baseline_log.txt');
log_lines = {
    '[INFO] run_ch5_phase3_tracking_baseline started'
    ['[INFO] output_root = ', out_root]
    ['[INFO] num_steps = ', num2str(caseData.summary.num_steps)]
    ['[INFO] num_sats = ', num2str(caseData.summary.num_sats)]
    ['[INFO] candidate_mean = ', num2str(caseData.summary.mean_candidate_count, '%.6f')]
    ['[INFO] coverage_ratio_ge1 = ', num2str(tracking.coverage_ratio_ge1, '%.6f')]
    ['[INFO] coverage_ratio_ge2 = ', num2str(tracking.coverage_ratio_ge2, '%.6f')]
    ['[INFO] mean_rmse = ', num2str(tracking.mean_rmse, '%.6f')]
    ['[INFO] max_rmse = ', num2str(tracking.max_rmse, '%.6f')]
    '[INFO] run_ch5_phase3_tracking_baseline finished'
    };
SetTxt(log_path, log_lines);

mat_path = fullfile(mat_dir, 'phase3_tracking_baseline.mat');
save(mat_path, 'cfg', 'caseData', 'result', 'tracking');

if verbose
    disp('=== Chapter 5 Phase 3 Tracking Baseline Summary ===')
    disp(tracking)
    disp(['[phase3] coverage fig : ', fig_cov]);
    disp(['[phase3] rmse fig     : ', fig_rmse]);
    disp(['[phase3] text         : ', txt_path]);
    disp(['[phase3] log          : ', log_path]);
    disp(['[phase3] mat          : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.coverage_fig = fig_cov;
out.rmse_fig = fig_rmse;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
out.tracking = tracking;
out.result = result;
end

function SetTxt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
