function out = run_ch5_phase6_dualloop_min(cfg, verbose)
%RUN_CH5_PHASE6_DUALLOOP_MIN  Phase 6 minimal dual-loop custody comparison.
%
% Compare:
%   T      : tracking dynamic
%   C      : single-loop custody
%   CK-min : minimal dual-loop custody

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params('stress96');
end
if nargin < 2
    verbose = true;
end

cfg.phase_name = 'phase6';

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase6');
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end

caseData = build_ch5_case(cfg);

resultT = policy_tracking_dynamic(caseData, cfg);
resultC = policy_custody_singleloop(caseData, cfg);
resultCK = policy_custody_dualloop_min(caseData, cfg);

trackingT = eval_tracking_metrics(resultT);
trackingC = eval_tracking_metrics(resultC);
trackingCK = eval_tracking_metrics(resultCK);

mgT = compute_mg_series(resultT, caseData, cfg);
mgC = compute_mg_series(resultC, caseData, cfg);
mgCK = compute_mg_series(resultCK, caseData, cfg);

ttlT = compute_ttl_series(resultT, caseData, cfg);
ttlC = compute_ttl_series(resultC, caseData, cfg);
ttlCK = compute_ttl_series(resultCK, caseData, cfg);

switchT = zeros(size(resultT.time));
for k = 2:numel(resultT.selected_sets)
    switchT(k) = ~isequal(resultT.selected_sets{k-1}, resultT.selected_sets{k});
end

switchC = resultC.switch_indicator(:);
switchCK = resultCK.switch_indicator(:);

phiT = compute_phi_window(mgT, ttlT, switchT, cfg);
phiC = compute_phi_window(mgC, ttlC, switchC, cfg);
phiCK = compute_phi_window(mgCK, ttlCK, switchCK, cfg);

custodyResultT = struct();
custodyResultT.time = resultT.time;
custodyResultT.phi_series = phiT;
custodyResultT.threshold = cfg.ch5.custody_phi_threshold;

custodyResultC = struct();
custodyResultC.time = resultC.time;
custodyResultC.phi_series = phiC;
custodyResultC.threshold = cfg.ch5.custody_phi_threshold;

custodyResultCK = struct();
custodyResultCK.time = resultCK.time;
custodyResultCK.phi_series = phiCK;
custodyResultCK.threshold = cfg.ch5.custody_phi_threshold;

custodyT = eval_custody_metrics(custodyResultT);
custodyC = eval_custody_metrics(custodyResultC);
custodyCK = eval_custody_metrics(custodyResultCK);

fig_phi = fullfile(fig_dir, ['phase6_custody_phi_timeline_', cfg.ch5.scene_preset, '.png']);
fig_bar = fullfile(fig_dir, ['phase6_custody_summary_bars_', cfg.ch5.scene_preset, '.png']);

f1 = plot_custody_phi_timeline_three(resultT.time, phiT, phiC, phiCK, fig_phi); %#ok<NASGU>
f2 = plot_custody_summary_bars_three(custodyT, custodyC, custodyCK, fig_bar); %#ok<NASGU>
close all

txt_path = fullfile(tbl_dir, ['phase6_dualloop_summary_', cfg.ch5.scene_preset, '.txt']);
txt_lines = {
    '=== Chapter 5 Phase 6 T / C / CK-min Summary ==='
    ['scene_preset         = ', cfg.ch5.scene_preset]
    ['outer_update_steps   = ', num2str(cfg.ch5.outer_update_steps)]
    ['outer_horizon_steps  = ', num2str(cfg.ch5.outer_horizon_steps)]
    ['outer_prior_weight   = ', num2str(cfg.ch5.outer_prior_weight, '%.6f')]
    ['T_q_worst            = ', num2str(custodyT.q_worst, '%.6f')]
    ['C_q_worst            = ', num2str(custodyC.q_worst, '%.6f')]
    ['CK_q_worst           = ', num2str(custodyCK.q_worst, '%.6f')]
    ['T_outage_ratio       = ', num2str(custodyT.outage_ratio, '%.6f')]
    ['C_outage_ratio       = ', num2str(custodyC.outage_ratio, '%.6f')]
    ['CK_outage_ratio      = ', num2str(custodyCK.outage_ratio, '%.6f')]
    ['T_longest_outage     = ', num2str(custodyT.longest_outage_steps)]
    ['C_longest_outage     = ', num2str(custodyC.longest_outage_steps)]
    ['CK_longest_outage    = ', num2str(custodyCK.longest_outage_steps)]
    ['T_phi_mean           = ', num2str(custodyT.phi_mean, '%.6f')]
    ['C_phi_mean           = ', num2str(custodyC.phi_mean, '%.6f')]
    ['CK_phi_mean          = ', num2str(custodyCK.phi_mean, '%.6f')]
    };
SetTxt(txt_path, txt_lines);

log_path = fullfile(log_dir, ['phase6_dualloop_log_', cfg.ch5.scene_preset, '.txt']);
log_lines = {
    '[INFO] run_ch5_phase6_dualloop_min started'
    ['[INFO] output_root = ', out_root]
    ['[INFO] scene_preset = ', cfg.ch5.scene_preset]
    ['[INFO] outer_update_steps = ', num2str(cfg.ch5.outer_update_steps)]
    ['[INFO] outer_horizon_steps = ', num2str(cfg.ch5.outer_horizon_steps)]
    ['[INFO] T_q_worst = ', num2str(custodyT.q_worst, '%.6f')]
    ['[INFO] C_q_worst = ', num2str(custodyC.q_worst, '%.6f')]
    ['[INFO] CK_q_worst = ', num2str(custodyCK.q_worst, '%.6f')]
    '[INFO] run_ch5_phase6_dualloop_min finished'
    };
SetTxt(log_path, log_lines);

mat_path = fullfile(mat_dir, ['phase6_dualloop_', cfg.ch5.scene_preset, '.mat']);
save(mat_path, 'cfg', 'caseData', ...
    'resultT', 'resultC', 'resultCK', ...
    'trackingT', 'trackingC', 'trackingCK', ...
    'phiT', 'phiC', 'phiCK', ...
    'custodyT', 'custodyC', 'custodyCK');

if verbose
    disp('=== Chapter 5 Phase 6 T / C / CK-min Summary ===')
    disp(['scene_preset = ', cfg.ch5.scene_preset])
    disp('--- custody T ---'); disp(custodyT)
    disp('--- custody C ---'); disp(custodyC)
    disp('--- custody CK ---'); disp(custodyCK)
    disp(['[phase6] phi fig : ', fig_phi]);
    disp(['[phase6] bar fig : ', fig_bar]);
    disp(['[phase6] text    : ', txt_path]);
    disp(['[phase6] log     : ', log_path]);
    disp(['[phase6] mat     : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.phi_fig = fig_phi;
out.bar_fig = fig_bar;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
out.custodyT = custodyT;
out.custodyC = custodyC;
out.custodyCK = custodyCK;
end

function SetTxt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
