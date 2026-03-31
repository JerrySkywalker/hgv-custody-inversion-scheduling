function out = run_ch5_phase2_innerloop(cfg, verbose)
%RUN_CH5_PHASE2_INNERLOOP  Phase 2 inner-loop rerun on real wrapped case objects.
%
% After Phase 2.5C, this runner is intentionally redirected to outputs/cpt5/phase2p5/
% because the input objects are no longer placeholder ones.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end
if nargin < 2
    verbose = true;
end

cfg.phase_name = 'phase2p5';

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase2p5');
fig_dir = fullfile(out_root, 'figs');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end

caseData = build_ch5_case(cfg);
inner = run_inner_loop_filter(caseData, cfg);

fig_path = fullfile(fig_dir, 'phase2p5_inner_nis_timeline.png');
fig = plot_inner_nis_timeline(inner, fig_path); %#ok<NASGU>
close all

log_path = fullfile(log_dir, 'phase2p5_innerloop_log.txt');
log_lines = {
    '[INFO] run_ch5_phase2_innerloop started'
    ['[INFO] output_root = ', out_root]
    ['[INFO] num_steps = ', num2str(caseData.summary.num_steps)]
    ['[INFO] num_sats = ', num2str(caseData.summary.num_sats)]
    ['[INFO] candidate_min = ', num2str(caseData.summary.min_candidate_count)]
    ['[INFO] candidate_max = ', num2str(caseData.summary.max_candidate_count)]
    ['[INFO] candidate_mean = ', num2str(caseData.summary.mean_candidate_count, '%.6f')]
    ['[INFO] mean_nis = ', num2str(inner.mean_nis, '%.6f')]
    ['[INFO] max_nis = ', num2str(inner.max_nis, '%.6f')]
    ['[INFO] mean_pos_err = ', num2str(inner.mean_pos_err, '%.6f')]
    ['[INFO] max_pos_err = ', num2str(inner.max_pos_err, '%.6f')]
    '[INFO] run_ch5_phase2_innerloop finished'
    };
SetTxt(log_path, log_lines);

mat_path = fullfile(mat_dir, 'phase2p5_innerloop.mat');
save(mat_path, 'cfg', 'caseData', 'inner');

if verbose
    disp('=== Chapter 5 Phase 2.5C Inner Loop Summary ===')
    disp(['num_steps      = ', num2str(caseData.summary.num_steps)])
    disp(['num_sats       = ', num2str(caseData.summary.num_sats)])
    disp(['cand_min       = ', num2str(caseData.summary.min_candidate_count)])
    disp(['cand_max       = ', num2str(caseData.summary.max_candidate_count)])
    disp(['cand_mean      = ', num2str(caseData.summary.mean_candidate_count, '%.6f')])
    disp(['mean_nis       = ', num2str(inner.mean_nis, '%.6f')])
    disp(['max_nis        = ', num2str(inner.max_nis, '%.6f')])
    disp(['mean_pos_err   = ', num2str(inner.mean_pos_err, '%.6f')])
    disp(['max_pos_err    = ', num2str(inner.max_pos_err, '%.6f')])
    disp(['[phase2p5] fig : ', fig_path]);
    disp(['[phase2p5] log : ', log_path]);
    disp(['[phase2p5] mat : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.fig_file = fig_path;
out.log_file = log_path;
out.mat_file = mat_path;
out.caseData = caseData;
out.inner = inner;
end

function SetTxt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
