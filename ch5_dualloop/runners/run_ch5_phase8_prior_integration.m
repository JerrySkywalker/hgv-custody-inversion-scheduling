function out = run_ch5_phase8_prior_integration(cfg, verbose)
%RUN_CH5_PHASE8_PRIOR_INTEGRATION
% Compare CK full vs CK+prior, with C as baseline reference.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params('stress96');
end
if nargin < 2
    verbose = true;
end

phase_name = 'phase8';
out_root = fullfile(pwd, 'outputs', 'cpt5', phase_name);
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end

caseData = build_ch5_case(cfg);

trackingC = policy_custody_singleloop(caseData, cfg);
resultC = local_attach_custody_fields(trackingC, caseData, cfg);
custodyC = eval_custody_metrics(resultC);
trackingStatsC = eval_tracking_metrics(trackingC);

trackingCK = policy_custody_dualloop_koopman(caseData, cfg);
resultCK = local_attach_custody_fields(trackingCK, caseData, cfg);
custodyCK = eval_custody_metrics(resultCK);
trackingStatsCK = eval_tracking_metrics(trackingCK);

cfg_prior = cfg;
cfg_prior.ch5.prior_enable = true;
cfg_prior.ch5.prior_library = build_reference_prior_library(caseData, cfg_prior);

trackingCKP = policy_custody_dualloop_koopman(caseData, cfg_prior);
resultCKP = local_attach_custody_fields(trackingCKP, caseData, cfg_prior);
custodyCKP = eval_custody_metrics(resultCKP);
trackingStatsCKP = eval_tracking_metrics(trackingCKP);

methods = struct([]);
methods(1) = local_make_method('C', custodyC, trackingStatsC, trackingC);
methods(2) = local_make_method('CK', custodyCK, trackingStatsCK, trackingCK);
methods(3) = local_make_method('CK-prior', custodyCKP, trackingStatsCKP, trackingCKP);

scene_name = cfg.ch5.scene_preset;
fig_path = fullfile(fig_dir, ['phase8_prior_summary_', scene_name, '.png']);
fig = plot_prior_match_summary(scene_name, methods, fig_path); %#ok<NASGU>
close all

txt_path = fullfile(tbl_dir, ['phase8_prior_summary_', scene_name, '.txt']);
lines = {
    '=== Chapter 5 Phase 8 Prior Integration Summary ==='
    ['scene_preset                    = ', scene_name]
    ['prior_anchor_count              = ', num2str(cfg_prior.ch5.prior_anchor_count)]
    ['prior_library_size              = ', num2str(numel(cfg_prior.ch5.prior_library))]
    '--- C ---'
    ['q_worst_window                  = ', num2str(custodyC.q_worst_window, '%.6f')]
    ['phi_mean                        = ', num2str(custodyC.phi_mean, '%.6f')]
    ['outage_ratio                    = ', num2str(custodyC.outage_ratio, '%.6f')]
    ['longest_outage_steps            = ', num2str(custodyC.longest_outage_steps)]
    ['mean_rmse                       = ', num2str(trackingStatsC.mean_rmse, '%.6f')]
    ['switch_count                    = ', num2str(local_count_switches(trackingC.selected_sets))]
    '--- CK ---'
    ['q_worst_window                  = ', num2str(custodyCK.q_worst_window, '%.6f')]
    ['phi_mean                        = ', num2str(custodyCK.phi_mean, '%.6f')]
    ['outage_ratio                    = ', num2str(custodyCK.outage_ratio, '%.6f')]
    ['longest_outage_steps            = ', num2str(custodyCK.longest_outage_steps)]
    ['mean_rmse                       = ', num2str(trackingStatsCK.mean_rmse, '%.6f')]
    ['switch_count                    = ', num2str(local_count_switches(trackingCK.selected_sets))]
    '--- CK-prior ---'
    ['q_worst_window                  = ', num2str(custodyCKP.q_worst_window, '%.6f')]
    ['phi_mean                        = ', num2str(custodyCKP.phi_mean, '%.6f')]
    ['outage_ratio                    = ', num2str(custodyCKP.outage_ratio, '%.6f')]
    ['longest_outage_steps            = ', num2str(custodyCKP.longest_outage_steps)]
    ['mean_rmse                       = ', num2str(trackingStatsCKP.mean_rmse, '%.6f')]
    ['switch_count                    = ', num2str(local_count_switches(trackingCKP.selected_sets))]
    };
local_write_txt(txt_path, lines);

mat_path = fullfile(mat_dir, ['phase8_prior_integration_', scene_name, '.mat']);
save(mat_path, 'cfg', 'cfg_prior', 'caseData', ...
    'trackingC', 'trackingCK', 'trackingCKP', ...
    'resultC', 'resultCK', 'resultCKP', ...
    'custodyC', 'custodyCK', 'custodyCKP', ...
    'trackingStatsC', 'trackingStatsCK', 'trackingStatsCKP', ...
    'methods');

log_path = fullfile(log_dir, ['phase8_prior_integration_log_', scene_name, '.txt']);
local_write_txt(log_path, {
    '=== Chapter 5 Phase 8 Prior Integration Log ==='
    ['scene_preset = ', scene_name]
    ['prior_library_size = ', num2str(numel(cfg_prior.ch5.prior_library))]
    ['fig = ', fig_path]
    ['txt = ', txt_path]
    ['mat = ', mat_path]
    });

if verbose
    disp('=== Chapter 5 Phase 8 Prior Integration Summary ===')
    disp(['scene_preset = ', scene_name])
    disp(['prior_library_size = ', num2str(numel(cfg_prior.ch5.prior_library))])
    disp(struct2table(methods))
    disp(['[phase8] fig  : ', fig_path]);
    disp(['[phase8] text : ', txt_path]);
    disp(['[phase8] log  : ', log_path]);
    disp(['[phase8] mat  : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.fig_file = fig_path;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
end

function method = local_make_method(name, custody, tracking, result)
method = struct();
method.name = name;
method.q_worst_window = custody.q_worst_window;
method.phi_mean = custody.phi_mean;
method.outage_ratio = custody.outage_ratio;
method.longest_outage_steps = custody.longest_outage_steps;
method.mean_rmse = tracking.mean_rmse;
method.switch_count = local_count_switches(result.selected_sets);
end

function result = local_attach_custody_fields(tracking, caseData, cfg)
result = tracking;

mg = compute_mg_series(tracking, caseData, cfg);
ttl = compute_ttl_series(tracking, caseData, cfg);

switch_series = zeros(size(tracking.time(:)));
for k = 2:numel(tracking.selected_sets)
    switch_series(k) = ~isequal(tracking.selected_sets{k-1}, tracking.selected_sets{k});
end

phi_series = compute_phi_window(mg, ttl, switch_series, cfg);

result.mg_series = mg(:);
result.ttl_series = ttl(:);
result.switch_series = switch_series(:);
result.phi_series = phi_series(:);
result.threshold = cfg.ch5.custody_phi_threshold;
end

function n = local_count_switches(selected_sets)
n = 0;
for k = 2:numel(selected_sets)
    if ~isequal(selected_sets{k-1}, selected_sets{k})
        n = n + 1;
    end
end
end

function local_write_txt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
