function out = run_ch5_phase5_singleloop_custody(cfg, verbose)
%RUN_CH5_PHASE5_SINGLELOOP_CUSTODY  Phase 5 runner for T vs C comparison.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end
if nargin < 2
    verbose = true;
end

cfg.phase_name = 'phase5';

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase5');
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

trackingT = eval_tracking_metrics(resultT);
trackingC = eval_tracking_metrics(resultC);

mgT = compute_mg_series(resultT, caseData, cfg);
mgC = compute_mg_series(resultC, caseData, cfg);

ttlT = compute_ttl_series(resultT, caseData, cfg);
ttlC = compute_ttl_series(resultC, caseData, cfg);

switchT = zeros(size(resultT.time));
if isfield(resultT, 'selected_sets')
    for k = 2:numel(resultT.selected_sets)
        switchT(k) = ~isequal(resultT.selected_sets{k-1}, resultT.selected_sets{k});
    end
end

switchC = resultC.switch_indicator(:);

phiT = compute_phi_window(mgT, ttlT, switchT, cfg);
phiC = compute_phi_window(mgC, ttlC, switchC, cfg);

custodyResultT = struct();
custodyResultT.time = resultT.time;
custodyResultT.phi_series = phiT;
custodyResultT.threshold = cfg.ch5.custody_phi_threshold;

custodyResultC = struct();
custodyResultC.time = resultC.time;
custodyResultC.phi_series = phiC;
custodyResultC.threshold = cfg.ch5.custody_phi_threshold;

custodyT = eval_custody_metrics(custodyResultT);
custodyC = eval_custody_metrics(custodyResultC);

fig_phi = fullfile(fig_dir, ['phase5_custody_phi_timeline_', cfg.ch5.scene_preset, '.png']);
fig_bar = fullfile(fig_dir, ['phase5_custody_summary_bars_', cfg.ch5.scene_preset, '.png']);

f1 = plot_custody_phi_timeline(resultT.time, phiT, phiC, fig_phi); %#ok<NASGU>
f2 = plot_custody_summary_bars(custodyT, custodyC, fig_bar); %#ok<NASGU>
close all

txt_path = fullfile(tbl_dir, ['phase5_singleloop_custody_summary_', cfg.ch5.scene_preset, '.txt']);
txt_lines = {
    '=== Chapter 5 Phase 5 T vs C Summary ==='
    ['scene_preset         = ', cfg.ch5.scene_preset]
    ['phi_threshold        = ', num2str(cfg.ch5.custody_phi_threshold, '%.6f')]
    ['gap_weight           = ', num2str(cfg.ch5.custody_gap_weight, '%.6f')]
    ['outage_weight        = ', num2str(cfg.ch5.custody_outage_weight, '%.6f')]
    ['T_mean_rmse          = ', num2str(trackingT.mean_rmse, '%.6f')]
    ['C_mean_rmse          = ', num2str(trackingC.mean_rmse, '%.6f')]
    ['T_q_worst            = ', num2str(custodyT.q_worst, '%.6f')]
    ['C_q_worst            = ', num2str(custodyC.q_worst, '%.6f')]
    ['T_outage_ratio       = ', num2str(custodyT.outage_ratio, '%.6f')]
    ['C_outage_ratio       = ', num2str(custodyC.outage_ratio, '%.6f')]
    ['T_longest_outage     = ', num2str(custodyT.longest_outage_steps)]
    ['C_longest_outage     = ', num2str(custodyC.longest_outage_steps)]
    ['T_phi_mean           = ', num2str(custodyT.phi_mean, '%.6f')]
    ['C_phi_mean           = ', num2str(custodyC.phi_mean, '%.6f')]
    };
SetTxt(txt_path, txt_lines);

log_path = fullfile(log_dir, ['phase5_singleloop_custody_log_', cfg.ch5.scene_preset, '.txt']);
log_lines = {
    '[INFO] run_ch5_phase5_singleloop_custody started'
    ['[INFO] output_root = ', out_root]
    ['[INFO] scene_preset = ', cfg.ch5.scene_preset]
    ['[INFO] phi_threshold = ', num2str(cfg.ch5.custody_phi_threshold, '%.6f')]
    ['[INFO] gap_weight = ', num2str(cfg.ch5.custody_gap_weight, '%.6f')]
    ['[INFO] outage_weight = ', num2str(cfg.ch5.custody_outage_weight, '%.6f')]
    ['[INFO] T_mean_rmse = ', num2str(trackingT.mean_rmse, '%.6f')]
    ['[INFO] C_mean_rmse = ', num2str(trackingC.mean_rmse, '%.6f')]
    ['[INFO] T_q_worst = ', num2str(custodyT.q_worst, '%.6f')]
    ['[INFO] C_q_worst = ', num2str(custodyC.q_worst, '%.6f')]
    ['[INFO] T_outage_ratio = ', num2str(custodyT.outage_ratio, '%.6f')]
    ['[INFO] C_outage_ratio = ', num2str(custodyC.outage_ratio, '%.6f')]
    '[INFO] run_ch5_phase5_singleloop_custody finished'
    };
SetTxt(log_path, log_lines);

mat_path = fullfile(mat_dir, ['phase5_singleloop_custody_', cfg.ch5.scene_preset, '.mat']);
save(mat_path, 'cfg', 'caseData', ...
    'resultT', 'resultC', ...
    'trackingT', 'trackingC', ...
    'mgT', 'mgC', 'ttlT', 'ttlC', ...
    'phiT', 'phiC', ...
    'custodyT', 'custodyC');

if verbose
    disp('=== Chapter 5 Phase 5 T vs C Summary ===')
    disp(['scene_preset = ', cfg.ch5.scene_preset])
    disp(['phi_threshold = ', num2str(cfg.ch5.custody_phi_threshold, '%.6f')])
    disp(['gap_weight = ', num2str(cfg.ch5.custody_gap_weight, '%.6f')])
    disp(['outage_weight = ', num2str(cfg.ch5.custody_outage_weight, '%.6f')])
    disp('--- tracking T ---'); disp(trackingT)
    disp('--- tracking C ---'); disp(trackingC)
    disp('--- custody T ---'); disp(custodyT)
    disp('--- custody C ---'); disp(custodyC)
    disp(['[phase5] phi fig : ', fig_phi]);
    disp(['[phase5] bar fig : ', fig_bar]);
    disp(['[phase5] text    : ', txt_path]);
    disp(['[phase5] log     : ', log_path]);
    disp(['[phase5] mat     : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.phi_fig = fig_phi;
out.bar_fig = fig_bar;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
out.trackingT = trackingT;
out.trackingC = trackingC;
out.custodyT = custodyT;
out.custodyC = custodyC;
end

function SetTxt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
