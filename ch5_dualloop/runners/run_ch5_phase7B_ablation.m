function out = run_ch5_phase7B_ablation(cfg, verbose)
%RUN_CH5_PHASE7B_ABLATION
% WS-1-R1 (revised):
% Minimal ablation:
%   1) C baseline
%   2) CK full
%   3) CK without geometry
%
% Diagnostics in this round:
%   - selected-set compare
%   - candidate score dumps on key differing steps
%
% NOTE:
% outerB diagnose is deferred to WS-1-R2 due config-field mismatch.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params('stress96');
end
if nargin < 2
    verbose = true;
end

phase_name = 'phase7b';
out_root = fullfile(pwd, 'outputs', 'cpt5', phase_name);
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');
diag_dir = fullfile(out_root, 'diagnostics');

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end
if ~exist(diag_dir, 'dir'); mkdir(diag_dir); end

caseData = build_ch5_case(cfg);

% --- C baseline
trackingC = policy_custody_singleloop(caseData, cfg);
resultC = local_attach_custody_fields(trackingC, caseData, cfg);
custodyC = eval_custody_metrics(resultC);
trackingStatsC = eval_tracking_metrics(trackingC);

% --- CK full
trackingCK = policy_custody_dualloop_koopman(caseData, cfg);
resultCK = local_attach_custody_fields(trackingCK, caseData, cfg);
custodyCK = eval_custody_metrics(resultCK);
trackingStatsCK = eval_tracking_metrics(trackingCK);

% --- CK without geometry
cfg_no_geom = cfg;
cfg_no_geom.ch5.ck_warn_geom_lambda_weight = 0.0;
cfg_no_geom.ch5.ck_warn_geom_angle_weight = 0.0;
cfg_no_geom.ch5.ck_trigger_geom_lambda_weight = 0.0;
cfg_no_geom.ch5.ck_trigger_geom_angle_weight = 0.0;

trackingCK_noGeom = policy_custody_dualloop_koopman(caseData, cfg_no_geom);
resultCK_noGeom = local_attach_custody_fields(trackingCK_noGeom, caseData, cfg_no_geom);
custodyCK_noGeom = eval_custody_metrics(resultCK_noGeom);
trackingStatsCK_noGeom = eval_tracking_metrics(trackingCK_noGeom);

methods = struct([]);
methods(1).name = 'C';
methods(1).q_worst_window = custodyC.q_worst_window;
methods(1).phi_mean = custodyC.phi_mean;
methods(1).outage_ratio = custodyC.outage_ratio;
methods(1).longest_outage_steps = custodyC.longest_outage_steps;
methods(1).mean_rmse = trackingStatsC.mean_rmse;

methods(2).name = 'CK-full';
methods(2).q_worst_window = custodyCK.q_worst_window;
methods(2).phi_mean = custodyCK.phi_mean;
methods(2).outage_ratio = custodyCK.outage_ratio;
methods(2).longest_outage_steps = custodyCK.longest_outage_steps;
methods(2).mean_rmse = trackingStatsCK.mean_rmse;

methods(3).name = 'CK-noGeom';
methods(3).q_worst_window = custodyCK_noGeom.q_worst_window;
methods(3).phi_mean = custodyCK_noGeom.phi_mean;
methods(3).outage_ratio = custodyCK_noGeom.outage_ratio;
methods(3).longest_outage_steps = custodyCK_noGeom.longest_outage_steps;
methods(3).mean_rmse = trackingStatsCK_noGeom.mean_rmse;

fig_path = fullfile(fig_dir, ['phase7b_ablation_', cfg.ch5.scene_preset, '.png']);
fig = plot_ck_ablation_summary(cfg.ch5.scene_preset, methods, fig_path); %#ok<NASGU>
close all

% ------------------------------------------------
% Diagnostics kept in WS-1-R1
% ------------------------------------------------
cmp_C_vs_CK = compare_selected_sets_dualloop(trackingC, trackingCK);
cmp_CK_vs_noGeom = compare_selected_sets_dualloop(trackingCK, trackingCK_noGeom);

cmpC_mat = fullfile(diag_dir, ['selected_set_compare_C_vs_CK_', cfg.ch5.scene_preset, '.mat']);
cmpCK_mat = fullfile(diag_dir, ['selected_set_compare_CK_vs_noGeom_', cfg.ch5.scene_preset, '.mat']);

save(cmpC_mat, 'cmp_C_vs_CK');
save(cmpCK_mat, 'cmp_CK_vs_noGeom');

cmpC_txt = fullfile(diag_dir, ['selected_set_compare_C_vs_CK_', cfg.ch5.scene_preset, '.txt']);
cmpCK_txt = fullfile(diag_dir, ['selected_set_compare_CK_vs_noGeom_', cfg.ch5.scene_preset, '.txt']);

local_write_txt(cmpC_txt, {
    '=== WS-1-R1 selected-set compare: C vs CK ==='
    ['scene_preset                    = ', cfg.ch5.scene_preset]
    ['same_ratio                      = ', num2str(cmp_C_vs_CK.same_ratio, '%.6f')]
    ['diff_count                      = ', num2str(cmp_C_vs_CK.diff_count)]
    ['num_steps                       = ', num2str(cmp_C_vs_CK.num_steps)]
    ['first_diff_idx                  = ', local_vec_to_str(cmp_C_vs_CK.diff_idx(1:min(20,end)).')]
    });

local_write_txt(cmpCK_txt, {
    '=== WS-1-R1 selected-set compare: CK vs CK-noGeom ==='
    ['scene_preset                    = ', cfg.ch5.scene_preset]
    ['same_ratio                      = ', num2str(cmp_CK_vs_noGeom.same_ratio, '%.6f')]
    ['diff_count                      = ', num2str(cmp_CK_vs_noGeom.diff_count)]
    ['num_steps                       = ', num2str(cmp_CK_vs_noGeom.num_steps)]
    ['first_diff_idx                  = ', local_vec_to_str(cmp_CK_vs_noGeom.diff_idx(1:min(20,end)).')]
    });

% Candidate score dumps at first few differing steps: CK vs CK-noGeom
dump_indices = cmp_CK_vs_noGeom.diff_idx(1:min(5, numel(cmp_CK_vs_noGeom.diff_idx)));
dump_records = struct([]);
for ii = 1:numel(dump_indices)
    k = dump_indices(ii);

    prev_ids_CK = local_prev_ids(trackingCK, k);
    prev_ids_NG = local_prev_ids(trackingCK_noGeom, k);

    mode_CK = char(trackingCK.mode_series(k));
    mode_NG = char(trackingCK_noGeom.mode_series(k));

    rows_CK = dump_candidate_scores_dualloop(caseData, k, prev_ids_CK, mode_CK, cfg);
    rows_NG = dump_candidate_scores_dualloop(caseData, k, prev_ids_NG, mode_NG, cfg_no_geom);

    dump_records(ii).k = k;
    dump_records(ii).mode_CK = mode_CK;
    dump_records(ii).mode_noGeom = mode_NG;
    dump_records(ii).rows_CK = rows_CK;
    dump_records(ii).rows_noGeom = rows_NG;

    txt_dump = fullfile(diag_dir, sprintf('candidate_scores_%s_k%04d.txt', cfg.ch5.scene_preset, k));
    local_write_candidate_dump(txt_dump, k, mode_CK, mode_NG, rows_CK, rows_NG);
end

dump_mat = fullfile(diag_dir, ['candidate_scores_', cfg.ch5.scene_preset, '.mat']);
save(dump_mat, 'dump_records');

txt_path = fullfile(tbl_dir, ['phase7b_ablation_summary_', cfg.ch5.scene_preset, '.txt']);
txt_lines = {
    '=== Chapter 5 Phase 7B Ablation Summary ==='
    ['scene_preset                    = ', cfg.ch5.scene_preset]

    '--- C baseline ---'
    ['q_worst_window                  = ', num2str(custodyC.q_worst_window, '%.6f')]
    ['phi_mean                        = ', num2str(custodyC.phi_mean, '%.6f')]
    ['outage_ratio                    = ', num2str(custodyC.outage_ratio, '%.6f')]
    ['longest_outage_steps            = ', num2str(custodyC.longest_outage_steps)]
    ['mean_rmse                       = ', num2str(trackingStatsC.mean_rmse, '%.6f')]
    ['max_rmse                        = ', num2str(trackingStatsC.max_rmse, '%.6f')]

    '--- CK full ---'
    ['q_worst_window                  = ', num2str(custodyCK.q_worst_window, '%.6f')]
    ['phi_mean                        = ', num2str(custodyCK.phi_mean, '%.6f')]
    ['outage_ratio                    = ', num2str(custodyCK.outage_ratio, '%.6f')]
    ['longest_outage_steps            = ', num2str(custodyCK.longest_outage_steps)]
    ['mean_rmse                       = ', num2str(trackingStatsCK.mean_rmse, '%.6f')]
    ['max_rmse                        = ', num2str(trackingStatsCK.max_rmse, '%.6f')]

    '--- CK without geometry ---'
    ['q_worst_window                  = ', num2str(custodyCK_noGeom.q_worst_window, '%.6f')]
    ['phi_mean                        = ', num2str(custodyCK_noGeom.phi_mean, '%.6f')]
    ['outage_ratio                    = ', num2str(custodyCK_noGeom.outage_ratio, '%.6f')]
    ['longest_outage_steps            = ', num2str(custodyCK_noGeom.longest_outage_steps)]
    ['mean_rmse                       = ', num2str(trackingStatsCK_noGeom.mean_rmse, '%.6f')]
    ['max_rmse                        = ', num2str(trackingStatsCK_noGeom.max_rmse, '%.6f')]

    '--- diagnostics ---'
    ['cmp_C_vs_CK_same_ratio          = ', num2str(cmp_C_vs_CK.same_ratio, '%.6f')]
    ['cmp_C_vs_CK_diff_count          = ', num2str(cmp_C_vs_CK.diff_count)]
    ['cmp_CK_vs_noGeom_same_ratio     = ', num2str(cmp_CK_vs_noGeom.same_ratio, '%.6f')]
    ['cmp_CK_vs_noGeom_diff_count     = ', num2str(cmp_CK_vs_noGeom.diff_count)]
    ['candidate_dump_steps            = ', local_vec_to_str(dump_indices.')]
    ['diagnostics_dir                 = ', diag_dir]
    ['note                            = outerB diagnose deferred to WS-1-R2 due config-field mismatch']
    };
local_write_txt(txt_path, txt_lines);

log_path = fullfile(log_dir, ['phase7b_ablation_log_', cfg.ch5.scene_preset, '.txt']);
log_lines = {
    '[INFO] run_ch5_phase7B_ablation started'
    ['[INFO] scene_preset = ', cfg.ch5.scene_preset]
    ['[INFO] C q_worst_window = ', num2str(custodyC.q_worst_window, '%.6f')]
    ['[INFO] CK full q_worst_window = ', num2str(custodyCK.q_worst_window, '%.6f')]
    ['[INFO] CK noGeom q_worst_window = ', num2str(custodyCK_noGeom.q_worst_window, '%.6f')]
    ['[INFO] cmp_C_vs_CK same_ratio = ', num2str(cmp_C_vs_CK.same_ratio, '%.6f')]
    ['[INFO] cmp_CK_vs_noGeom same_ratio = ', num2str(cmp_CK_vs_noGeom.same_ratio, '%.6f')]
    ['[INFO] outerB diagnose deferred to WS-1-R2']
    '[INFO] run_ch5_phase7B_ablation finished'
    };
local_write_txt(log_path, log_lines);

mat_path = fullfile(mat_dir, ['phase7b_ablation_', cfg.ch5.scene_preset, '.mat']);
save(mat_path, 'cfg', 'cfg_no_geom', 'caseData', ...
    'trackingC', 'trackingCK', 'trackingCK_noGeom', ...
    'resultC', 'resultCK', 'resultCK_noGeom', ...
    'custodyC', 'custodyCK', 'custodyCK_noGeom', ...
    'trackingStatsC', 'trackingStatsCK', 'trackingStatsCK_noGeom', ...
    'methods', ...
    'cmp_C_vs_CK', 'cmp_CK_vs_noGeom', ...
    'dump_records');

if verbose
    disp('=== Chapter 5 Phase 7B Ablation Summary ===')
    disp(['scene_preset = ', cfg.ch5.scene_preset])
    disp('--- C baseline ---'); disp(custodyC)
    disp('--- CK full ---'); disp(custodyCK)
    disp('--- CK without geometry ---'); disp(custodyCK_noGeom)
    disp('--- diagnostics ---')
    disp(cmp_C_vs_CK)
    disp(cmp_CK_vs_noGeom)
    disp(['[phase7b] fig  : ', fig_path]);
    disp(['[phase7b] text : ', txt_path]);
    disp(['[phase7b] log  : ', log_path]);
    disp(['[phase7b] mat  : ', mat_path]);
    disp(['[phase7b] diag : ', diag_dir]);
end

out = struct();
out.output_root = out_root;
out.fig_file = fig_path;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
out.diag_dir = diag_dir;
out.compare_C_vs_CK = cmpC_mat;
out.compare_CK_vs_noGeom = cmpCK_mat;
out.candidate_dump_mat = dump_mat;
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

function ids = local_prev_ids(tracking, k)
if k <= 1
    ids = [];
else
    ids = tracking.selected_sets{k-1};
end
end

function local_write_candidate_dump(pathStr, k, modeCK, modeNG, rowsCK, rowsNG)
lines = {};
lines{end+1} = '=== WS-1-R1 candidate score dump ==='; %#ok<AGROW>
lines{end+1} = ['k = ', num2str(k)]; %#ok<AGROW>
lines{end+1} = ['mode_CK = ', modeCK]; %#ok<AGROW>
lines{end+1} = ['mode_noGeom = ', modeNG]; %#ok<AGROW>
lines{end+1} = '--- CK full ---'; %#ok<AGROW>

for i = 1:numel(rowsCK)
    lines{end+1} = sprintf('ids=%s | score=%.6f | feas=%d | Lsingle=%g | single=%.6f | zero=%.6f', ... %#ok<AGROW>
        local_vec_to_str(rowsCK(i).ids), rowsCK(i).score, rowsCK(i).is_feasible, ...
        rowsCK(i).longest_single, rowsCK(i).single_ratio, rowsCK(i).zero_ratio);
end

lines{end+1} = '--- CK noGeom ---'; %#ok<AGROW>
for i = 1:numel(rowsNG)
    lines{end+1} = sprintf('ids=%s | score=%.6f | feas=%d | Lsingle=%g | single=%.6f | zero=%.6f', ... %#ok<AGROW>
        local_vec_to_str(rowsNG(i).ids), rowsNG(i).score, rowsNG(i).is_feasible, ...
        rowsNG(i).longest_single, rowsNG(i).single_ratio, rowsNG(i).zero_ratio);
end

local_write_txt(pathStr, lines);
end

function s = local_vec_to_str(v)
if isempty(v)
    s = '[]';
    return
end
v = v(:).';
parts = arrayfun(@num2str, v, 'UniformOutput', false);
s = ['[', strjoin(parts, ' '), ']'];
end

function local_write_txt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
