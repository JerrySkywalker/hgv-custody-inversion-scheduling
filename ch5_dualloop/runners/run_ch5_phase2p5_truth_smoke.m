function out = run_ch5_phase2p5_truth_smoke(cfg, verbose)
%RUN_CH5_PHASE2P5_TRUTH_SMOKE  Smoke test for chapter 5 truth integration via Stage02 engine.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end
if nargin < 2
    verbose = true;
end

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase2p5');
fig_dir = fullfile(out_root, 'figs');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');
tbl_dir = fullfile(out_root, 'tables');

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end

profile = build_ch5_target_profile(cfg);
truth = build_ch5_truth_from_stage02_engine(profile, cfg);

fig_path = fullfile(fig_dir, 'phase2p5_truth_summary.png');
fig = plot_phase2p5_truth_summary(truth, fig_path); %#ok<NASGU>
close all

txt_path = fullfile(tbl_dir, 'phase2p5_truth_summary.txt');
txt_lines = {
    '=== Chapter 5 Phase 2.5A Truth Summary ==='
    ['source      = ', truth.source]
    ['profile     = ', truth.profile.name]
    ['num_steps   = ', num2str(numel(truth.t))]
    ['t_start     = ', num2str(truth.t(1))]
    ['t_end       = ', num2str(truth.t(end))]
    ['h_mean_km   = ', num2str(mean(truth.h_km), '%.6f')]
    ['h_min_km    = ', num2str(min(truth.h_km), '%.6f')]
    ['h_max_km    = ', num2str(max(truth.h_km), '%.6f')]
    };
SetTxt(txt_path, txt_lines);

log_path = fullfile(log_dir, 'phase2p5_truth_smoke_log.txt');
log_lines = {
    '[INFO] run_ch5_phase2p5_truth_smoke started'
    ['[INFO] output_root = ', out_root]
    ['[INFO] profile = ', profile.name]
    ['[INFO] num_steps = ', num2str(numel(truth.t))]
    '[INFO] run_ch5_phase2p5_truth_smoke finished'
    };
SetTxt(log_path, log_lines);

mat_path = fullfile(mat_dir, 'phase2p5_truth_smoke.mat');
save(mat_path, 'cfg', 'profile', 'truth');

if verbose
    disp('=== Chapter 5 Phase 2.5A Truth Summary ===')
    disp(['source   = ', truth.source])
    disp(['profile  = ', truth.profile.name])
    disp(['num_steps= ', num2str(numel(truth.t))])
    disp(['[phase2p5] fig  : ', fig_path])
    disp(['[phase2p5] text : ', txt_path])
    disp(['[phase2p5] log  : ', log_path])
    disp(['[phase2p5] mat  : ', mat_path])
end

out = struct();
out.output_root = out_root;
out.fig_file = fig_path;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
out.truth = truth;
end

function SetTxt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
