function out = run_ch5_phase6B_outerA_alignment(cfg, verbose)
%RUN_CH5_PHASE6B_OUTERA_ALIGNMENT
% Phase 6B-1:
%   validate outerA alignment against bad phi windows
%   under two alert modes:
%     1) trigger_only
%     2) warn_or_trigger

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params('stress96');
end
if nargin < 2
    verbose = true;
end

cfg.phase_name = 'phase6b';

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase6b');
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end

outA = run_ch5_phase6_outerA_rfkoopman(cfg, false);
S = load(outA.mat_file);

phiT = S.phiT;
outerA = S.outerA;

window_steps = cfg.ch5.window_steps;

alignment = match_outerA_events_to_bad_segments( ...
    phiT, cfg.ch5.custody_phi_threshold, outerA.risk_state, outerA.lead_time_steps, window_steps);

fig_align = fullfile(fig_dir, ['phase6b_alignment_', cfg.ch5.scene_preset, '.png']);
f1 = plot_outerA_vs_phi_alignment(outerA.time, phiT, cfg.ch5.custody_phi_threshold, outerA.risk_state, alignment, fig_align); %#ok<NASGU>
close all

A1 = alignment.trigger_only;
A2 = alignment.warn_or_trigger;

txt_path = fullfile(tbl_dir, ['phase6b_alignment_summary_', cfg.ch5.scene_preset, '.txt']);
txt_lines = {
    '=== Chapter 5 Phase 6B-1 OuterA Alignment Summary ==='
    ['scene_preset                    = ', cfg.ch5.scene_preset]
    ['bad_window_steps                = ', num2str(alignment.bad_window_steps)]
    ['bad_segment_count               = ', num2str(alignment.bad_segment_count)]
    '--- trigger_only ---'
    ['event_count                     = ', num2str(A1.event_count)]
    ['hit_count                       = ', num2str(A1.hit_count)]
    ['miss_count                      = ', num2str(A1.miss_count)]
    ['false_alarm_count               = ', num2str(A1.false_alarm_count)]
    ['hit_rate                        = ', num2str(A1.hit_rate, '%.6f')]
    ['miss_rate                       = ', num2str(A1.miss_rate, '%.6f')]
    ['false_alarm_rate                = ', num2str(A1.false_alarm_rate, '%.6f')]
    ['mean_lead_time_steps            = ', num2str(A1.mean_lead_time_steps, '%.6f')]
    ['max_lead_time_steps             = ', num2str(A1.max_lead_time_steps, '%.6f')]
    '--- warn_or_trigger ---'
    ['event_count                     = ', num2str(A2.event_count)]
    ['hit_count                       = ', num2str(A2.hit_count)]
    ['miss_count                      = ', num2str(A2.miss_count)]
    ['false_alarm_count               = ', num2str(A2.false_alarm_count)]
    ['hit_rate                        = ', num2str(A2.hit_rate, '%.6f')]
    ['miss_rate                       = ', num2str(A2.miss_rate, '%.6f')]
    ['false_alarm_rate                = ', num2str(A2.false_alarm_rate, '%.6f')]
    ['mean_lead_time_steps            = ', num2str(A2.mean_lead_time_steps, '%.6f')]
    ['max_lead_time_steps             = ', num2str(A2.max_lead_time_steps, '%.6f')]
    };
SetTxt(txt_path, txt_lines);

log_path = fullfile(log_dir, ['phase6b_alignment_log_', cfg.ch5.scene_preset, '.txt']);
log_lines = {
    '[INFO] run_ch5_phase6B_outerA_alignment started'
    ['[INFO] output_root = ', out_root]
    ['[INFO] scene_preset = ', cfg.ch5.scene_preset]
    ['[INFO] trigger_only hit_rate = ', num2str(A1.hit_rate, '%.6f')]
    ['[INFO] trigger_only false_alarm_rate = ', num2str(A1.false_alarm_rate, '%.6f')]
    ['[INFO] warn_or_trigger hit_rate = ', num2str(A2.hit_rate, '%.6f')]
    ['[INFO] warn_or_trigger false_alarm_rate = ', num2str(A2.false_alarm_rate, '%.6f')]
    '[INFO] run_ch5_phase6B_outerA_alignment finished'
    };
SetTxt(log_path, log_lines);

mat_path = fullfile(mat_dir, ['phase6b_alignment_', cfg.ch5.scene_preset, '.mat']);
save(mat_path, 'cfg', 'phiT', 'outerA', 'alignment');

if verbose
    disp('=== Chapter 5 Phase 6B-1 OuterA Alignment Summary ===')
    disp(['scene_preset = ', cfg.ch5.scene_preset])
    disp(alignment)
    disp(['[phase6b] align fig : ', fig_align]);
    disp(['[phase6b] text      : ', txt_path]);
    disp(['[phase6b] log       : ', log_path]);
    disp(['[phase6b] mat       : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.align_fig = fig_align;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
out.alignment = alignment;
end

function SetTxt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
