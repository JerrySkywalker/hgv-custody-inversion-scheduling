function out = run_ch5_phase2p5_candidates_smoke(cfg, verbose)
%RUN_CH5_PHASE2P5_CANDIDATES_SMOKE  Smoke test for chapter 5 satbank + candidates integration.

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
satbank = build_ch5_satbank_from_stage03_engine(cfg, truth.t);
candidates = build_ch5_candidates_from_stage03_engine(truth, satbank, cfg);

fig_path = fullfile(fig_dir, 'phase2p5_candidates_summary.png');
fig = plot_phase2p5_candidates_summary(candidates, fig_path); %#ok<NASGU>
close all

txt_path = fullfile(tbl_dir, 'phase2p5_candidates_summary.txt');
txt_lines = {
    '=== Chapter 5 Phase 2.5B Candidate Summary ==='
    ['satbank_source = ', satbank.meta.source]
    ['num_steps      = ', num2str(numel(truth.t))]
    ['num_sats       = ', num2str(satbank.Ns)]
    ['cand_min       = ', num2str(candidates.min_count)]
    ['cand_max       = ', num2str(candidates.max_count)]
    ['cand_mean      = ', num2str(candidates.mean_count, '%.6f')]
    ['dual_ratio     = ', num2str(mean(candidates.dual_coverage_mask), '%.6f')]
    };
SetTxt(txt_path, txt_lines);

log_path = fullfile(log_dir, 'phase2p5_candidates_smoke_log.txt');
log_lines = {
    '[INFO] run_ch5_phase2p5_candidates_smoke started'
    ['[INFO] output_root = ', out_root]
    ['[INFO] num_steps = ', num2str(numel(truth.t))]
    ['[INFO] num_sats = ', num2str(satbank.Ns)]
    ['[INFO] cand_min = ', num2str(candidates.min_count)]
    ['[INFO] cand_max = ', num2str(candidates.max_count)]
    ['[INFO] cand_mean = ', num2str(candidates.mean_count, '%.6f')]
    '[INFO] run_ch5_phase2p5_candidates_smoke finished'
    };
SetTxt(log_path, log_lines);

mat_path = fullfile(mat_dir, 'phase2p5_candidates_smoke.mat');
save(mat_path, 'cfg', 'profile', 'truth', 'satbank', 'candidates');

if verbose
    disp('=== Chapter 5 Phase 2.5B Candidate Summary ===')
    disp(['num_steps = ', num2str(numel(truth.t))])
    disp(['num_sats  = ', num2str(satbank.Ns)])
    disp(['cand_min  = ', num2str(candidates.min_count)])
    disp(['cand_max  = ', num2str(candidates.max_count)])
    disp(['cand_mean = ', num2str(candidates.mean_count, '%.6f')])
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
out.satbank = satbank;
out.candidates = candidates;
end

function SetTxt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
