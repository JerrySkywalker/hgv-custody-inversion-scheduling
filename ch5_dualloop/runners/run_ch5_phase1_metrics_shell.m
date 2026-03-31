function out = run_ch5_phase1_metrics_shell(cfg, verbose)
%RUN_CH5_PHASE1_METRICS_SHELL  Phase 1 shell runner for unified metrics.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end
if nargin < 2
    verbose = true;
end

cfg.phase_name = 'phase1';

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase1');
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end

caseData = build_ch5_case(cfg);
t = caseData.time.t;
n = numel(t);

% Shell-stage pseudo result, only for metric plumbing verification.
result = struct();
result.time = t;
result.tracking_sat_count = caseData.candidates.count;
result.rmse_pos = linspace(300, 120, n).';
result.phi_series = 1.1 + 0.15 * sin((1:n)'/40) - 0.25 * exp(-((t - 340)/40).^2);

tracking = eval_tracking_metrics(result);
custody = eval_custody_metrics(result);
outPack = package_ch5_result(caseData, result, tracking, custody);

txt_path = fullfile(tbl_dir, 'phase1_summary.txt');
txt_lines = {
    '=== Chapter 5 Phase 1 Summary ==='
    ['coverage_ratio_ge1 = ', num2str(tracking.coverage_ratio_ge1, '%.4f')]
    ['coverage_ratio_ge2 = ', num2str(tracking.coverage_ratio_ge2, '%.4f')]
    ['mean_rmse          = ', num2str(tracking.mean_rmse, '%.4f')]
    ['max_rmse           = ', num2str(tracking.max_rmse, '%.4f')]
    ['q_worst            = ', num2str(custody.q_worst, '%.4f')]
    ['phi_mean           = ', num2str(custody.phi_mean, '%.4f')]
    ['outage_ratio       = ', num2str(custody.outage_ratio, '%.4f')]
    ['longest_outage     = ', num2str(custody.longest_outage_steps)]
    ['sc_ratio           = ', num2str(custody.sc_ratio, '%.4f')]
    ['dc_ratio           = ', num2str(custody.dc_ratio, '%.4f')]
    ['loc_ratio          = ', num2str(custody.loc_ratio, '%.4f')]
    };
SetTxt(txt_path, txt_lines);

log_path = fullfile(log_dir, 'phase1_metrics_shell_log.txt');
log_lines = {
    '[INFO] run_ch5_phase1_metrics_shell started'
    ['[INFO] output_root = ', out_root]
    ['[INFO] num_steps = ', num2str(caseData.summary.num_steps)]
    ['[INFO] q_worst = ', num2str(custody.q_worst, '%.4f')]
    ['[INFO] outage_ratio = ', num2str(custody.outage_ratio, '%.4f')]
    '[INFO] run_ch5_phase1_metrics_shell finished'
    };
SetTxt(log_path, log_lines);

fig_path = fullfile(fig_dir, 'phase1_metrics_shell.png');
fig = plot_phase1_metrics_shell(result, fig_path); %#ok<NASGU>
close all

mat_path = fullfile(mat_dir, 'phase1_metrics_shell.mat');
save(mat_path, 'cfg', 'caseData', 'result', 'tracking', 'custody', 'outPack');

if verbose
    disp('=== Chapter 5 Phase 1 Summary ===')
    disp(tracking)
    disp(custody)
    disp(['[phase1] fig  : ', fig_path]);
    disp(['[phase1] text : ', txt_path]);
    disp(['[phase1] log  : ', log_path]);
    disp(['[phase1] mat  : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.fig_file = fig_path;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
out.tracking = tracking;
out.custody = custody;
end

function SetTxt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
