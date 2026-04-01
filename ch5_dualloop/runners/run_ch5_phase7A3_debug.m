function out = run_ch5_phase7A3_debug(cfg, verbose)
%RUN_CH5_PHASE7A3_DEBUG  Diagnose outerA mode usage and outerB gating behavior.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params('stress96');
end
if nargin < 2
    verbose = true;
end

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase7a_dbg');
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end

caseData = build_ch5_case(cfg);

outA = run_ch5_phase6_outerA_rfkoopman(cfg, false);
S = load(outA.mat_file);
outerA = S.outerA;

mode_stats = summarize_outerA_mode_series(outerA.mode_series);
diag = diagnose_outerB_selection_dualloop(caseData, outerA, cfg);

txt_path = fullfile(tbl_dir, ['phase7a_dbg_summary_', cfg.ch5.scene_preset, '.txt']);
lines = {
    '=== Chapter 5 Phase 7A-3-dbg Summary ==='
    ['scene_preset                    = ', cfg.ch5.scene_preset]
    ['safe_ratio                      = ', num2str(mode_stats.safe_ratio, '%.6f')]
    ['warn_ratio                      = ', num2str(mode_stats.warn_ratio, '%.6f')]
    ['trigger_ratio                   = ', num2str(mode_stats.trigger_ratio, '%.6f')]
    ['mean_all_sets                   = ', num2str(diag.summary.mean_all_sets, '%.6f')]
    ['mean_feasible_sets              = ', num2str(diag.summary.mean_feasible_sets, '%.6f')]
    ['ratio_no_feasible               = ', num2str(diag.summary.ratio_no_feasible, '%.6f')]
    ['selected_feasible_ratio         = ', num2str(diag.summary.selected_feasible_ratio, '%.6f')]
    ['selected_two_sat_ratio          = ', num2str(diag.summary.selected_two_sat_ratio, '%.6f')]
    ['gate_warn_zero_ratio            = ', num2str(diag.gate_counts.warn_zero_ratio)]
    ['gate_warn_longest_zero          = ', num2str(diag.gate_counts.warn_longest_zero)]
    ['gate_warn_longest_single        = ', num2str(diag.gate_counts.warn_longest_single)]
    ['gate_trigger_zero_ratio         = ', num2str(diag.gate_counts.trigger_zero_ratio)]
    ['gate_trigger_longest_zero       = ', num2str(diag.gate_counts.trigger_longest_zero)]
    ['gate_trigger_longest_single     = ', num2str(diag.gate_counts.trigger_longest_single)]
    };
local_write_txt(txt_path, lines);

log_path = fullfile(log_dir, ['phase7a_dbg_log_', cfg.ch5.scene_preset, '.txt']);
local_write_txt(log_path, lines);

mat_path = fullfile(mat_dir, ['phase7a_dbg_', cfg.ch5.scene_preset, '.mat']);
save(mat_path, 'cfg', 'caseData', 'outerA', 'mode_stats', 'diag');

if verbose
    disp('=== Chapter 5 Phase 7A-3-dbg Summary ===')
    disp(mode_stats)
    disp(diag.summary)
    disp(diag.gate_counts)
    disp(['[phase7a-dbg] text : ', txt_path])
    disp(['[phase7a-dbg] log  : ', log_path])
    disp(['[phase7a-dbg] mat  : ', mat_path])
end

out = struct();
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
end

function local_write_txt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
