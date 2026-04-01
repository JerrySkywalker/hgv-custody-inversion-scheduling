function out = run_ch5_phase7A_dualloop_ck(cfg, verbose)
%RUN_CH5_PHASE7A_DUALLOOP_CK  Minimal CK closed-loop comparison runner.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params('stress96');
end
if nargin < 2
    verbose = true;
end

cfg.phase_name = 'phase7a';

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase7a');
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end

caseData = build_ch5_case(cfg);

trackingT  = policy_tracking_dynamic(caseData, cfg);
trackingC  = policy_custody_singleloop(caseData, cfg);
trackingCK = policy_custody_dualloop_koopman(caseData, cfg);

% Phase-1 style shell interfaces: single-input evaluators
custodyT   = eval_custody_metrics(trackingT);
custodyC   = eval_custody_metrics(trackingC);
custodyCK  = eval_custody_metrics(trackingCK);

trackingStatsT  = eval_tracking_metrics(trackingT);
trackingStatsC  = eval_tracking_metrics(trackingC);
trackingStatsCK = eval_tracking_metrics(trackingCK);

fig_cmp = fullfile(fig_dir, ['phase7a_ck_vs_c_', cfg.ch5.scene_preset, '.png']);
f1 = plot_ck_vs_c_summary(caseData.time.t(:), trackingC, trackingCK, fig_cmp); %#ok<NASGU>
close all

txt_path = fullfile(tbl_dir, ['phase7a_summary_', cfg.ch5.scene_preset, '.txt']);
txt_lines = {
    '=== Chapter 5 Phase 7A CK Summary ==='
    ['scene_preset                    = ', cfg.ch5.scene_preset]
    '--- T tracking ---'
    ['mean_rmse                       = ', num2str(trackingStatsT.mean_rmse, '%.6f')]
    ['coverage_ratio_ge2              = ', num2str(trackingStatsT.coverage_ratio_ge2, '%.6f')]
    '--- C tracking ---'
    ['mean_rmse                       = ', num2str(trackingStatsC.mean_rmse, '%.6f')]
    ['coverage_ratio_ge2              = ', num2str(trackingStatsC.coverage_ratio_ge2, '%.6f')]
    '--- CK tracking ---'
    ['mean_rmse                       = ', num2str(trackingStatsCK.mean_rmse, '%.6f')]
    ['coverage_ratio_ge2              = ', num2str(trackingStatsCK.coverage_ratio_ge2, '%.6f')]
    '--- T custody ---'
    ['q_worst                         = ', num2str(custodyT.q_worst, '%.6f')]
    ['outage_ratio                    = ', num2str(custodyT.outage_ratio, '%.6f')]
    ['longest_outage_steps            = ', num2str(custodyT.longest_outage_steps)]
    '--- C custody ---'
    ['q_worst                         = ', num2str(custodyC.q_worst, '%.6f')]
    ['outage_ratio                    = ', num2str(custodyC.outage_ratio, '%.6f')]
    ['longest_outage_steps            = ', num2str(custodyC.longest_outage_steps)]
    '--- CK custody ---'
    ['q_worst                         = ', num2str(custodyCK.q_worst, '%.6f')]
    ['outage_ratio                    = ', num2str(custodyCK.outage_ratio, '%.6f')]
    ['longest_outage_steps            = ', num2str(custodyCK.longest_outage_steps)]
    };
SetTxt(txt_path, txt_lines);

log_path = fullfile(log_dir, ['phase7a_log_', cfg.ch5.scene_preset, '.txt']);
log_lines = {
    '[INFO] run_ch5_phase7A_dualloop_ck started'
    ['[INFO] output_root = ', out_root]
    ['[INFO] scene_preset = ', cfg.ch5.scene_preset]
    ['[INFO] C q_worst = ', num2str(custodyC.q_worst, '%.6f')]
    ['[INFO] CK q_worst = ', num2str(custodyCK.q_worst, '%.6f')]
    ['[INFO] C outage_ratio = ', num2str(custodyC.outage_ratio, '%.6f')]
    ['[INFO] CK outage_ratio = ', num2str(custodyCK.outage_ratio, '%.6f')]
    '[INFO] run_ch5_phase7A_dualloop_ck finished'
    };
SetTxt(log_path, log_lines);

mat_path = fullfile(mat_dir, ['phase7a_', cfg.ch5.scene_preset, '.mat']);
save(mat_path, 'cfg', 'caseData', ...
    'trackingT', 'trackingC', 'trackingCK', ...
    'trackingStatsT', 'trackingStatsC', 'trackingStatsCK', ...
    'custodyT', 'custodyC', 'custodyCK');

if verbose
    disp('=== Chapter 5 Phase 7A CK Summary ===')
    disp(['scene_preset = ', cfg.ch5.scene_preset])
    disp('--- custody C ---'); disp(custodyC)
    disp('--- custody CK ---'); disp(custodyCK)
    disp(['[phase7a] fig  : ', fig_cmp]);
    disp(['[phase7a] text : ', txt_path]);
    disp(['[phase7a] log  : ', log_path]);
    disp(['[phase7a] mat  : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.fig_file = fig_cmp;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
end

function SetTxt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
