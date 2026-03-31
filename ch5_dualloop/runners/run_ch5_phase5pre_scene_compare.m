function out = run_ch5_phase5pre_scene_compare(verbose)
%RUN_CH5_PHASE5PRE_SCENE_COMPARE  Build dual-scene reference layer for chapter 5.
%
% Scenes:
%   - stress96
%   - ref128

if nargin < 1
    verbose = true;
end

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase5pre');
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
mat_dir = fullfile(out_root, 'mats');
log_dir = fullfile(out_root, 'logs');

if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end

scene_list = {'stress96', 'ref128'};
sceneSummary = struct([]);

for i = 1:numel(scene_list)
    scene_name = scene_list{i};
    cfg = default_ch5_params(scene_name);

    caseData = build_ch5_case(cfg);

    resultT = policy_tracking_dynamic(caseData, cfg);
    resultS = policy_static_hold(caseData, cfg);
    resultC = policy_custody_singleloop(caseData, cfg);

    trackingT = eval_tracking_metrics(resultT);
    trackingS = eval_tracking_metrics(resultS);
    trackingC = eval_tracking_metrics(resultC);

    sceneSummary(i).scene = scene_name;
    sceneSummary(i).num_sats = caseData.summary.num_sats;
    sceneSummary(i).cand_min = caseData.summary.min_candidate_count;
    sceneSummary(i).cand_max = caseData.summary.max_candidate_count;
    sceneSummary(i).cand_mean = caseData.summary.mean_candidate_count;
    sceneSummary(i).T_mean_rmse = trackingT.mean_rmse;
    sceneSummary(i).S_mean_rmse = trackingS.mean_rmse;
    sceneSummary(i).C_mean_rmse = trackingC.mean_rmse;
    sceneSummary(i).T_cov_ge2 = trackingT.coverage_ratio_ge2;
    sceneSummary(i).S_cov_ge2 = trackingS.coverage_ratio_ge2;
    sceneSummary(i).C_cov_ge2 = trackingC.coverage_ratio_ge2;
end

fig_path = fullfile(fig_dir, 'phase5pre_scene_compare.png');
f = plot_phase5pre_scene_compare(sceneSummary, fig_path); %#ok<NASGU>
close all

txt_path = fullfile(tbl_dir, 'phase5pre_scene_compare.txt');
txt_lines = {'=== Chapter 5 Phase 5-pre Scene Compare ==='};
for i = 1:numel(sceneSummary)
    txt_lines{end+1} = ['scene = ', sceneSummary(i).scene]; %#ok<AGROW>
    txt_lines{end+1} = ['  num_sats    = ', num2str(sceneSummary(i).num_sats)]; %#ok<AGROW>
    txt_lines{end+1} = ['  cand_min    = ', num2str(sceneSummary(i).cand_min)]; %#ok<AGROW>
    txt_lines{end+1} = ['  cand_max    = ', num2str(sceneSummary(i).cand_max)]; %#ok<AGROW>
    txt_lines{end+1} = ['  cand_mean   = ', num2str(sceneSummary(i).cand_mean, '%.6f')]; %#ok<AGROW>
    txt_lines{end+1} = ['  T_mean_rmse = ', num2str(sceneSummary(i).T_mean_rmse, '%.6f')]; %#ok<AGROW>
    txt_lines{end+1} = ['  S_mean_rmse = ', num2str(sceneSummary(i).S_mean_rmse, '%.6f')]; %#ok<AGROW>
    txt_lines{end+1} = ['  C_mean_rmse = ', num2str(sceneSummary(i).C_mean_rmse, '%.6f')]; %#ok<AGROW>
    txt_lines{end+1} = ['  T_cov_ge2   = ', num2str(sceneSummary(i).T_cov_ge2, '%.6f')]; %#ok<AGROW>
    txt_lines{end+1} = ['  S_cov_ge2   = ', num2str(sceneSummary(i).S_cov_ge2, '%.6f')]; %#ok<AGROW>
    txt_lines{end+1} = ['  C_cov_ge2   = ', num2str(sceneSummary(i).C_cov_ge2, '%.6f')]; %#ok<AGROW>
end
SetTxt(txt_path, txt_lines);

log_path = fullfile(log_dir, 'phase5pre_scene_compare_log.txt');
log_lines = {
    '[INFO] run_ch5_phase5pre_scene_compare started'
    ['[INFO] output_root = ', out_root]
    ['[INFO] scene_count = ', num2str(numel(sceneSummary))]
    '[INFO] run_ch5_phase5pre_scene_compare finished'
    };
SetTxt(log_path, log_lines);

mat_path = fullfile(mat_dir, 'phase5pre_scene_compare.mat');
save(mat_path, 'sceneSummary');

if verbose
    disp('=== Chapter 5 Phase 5-pre Scene Compare ===')
    disp(sceneSummary)
    disp(['[phase5pre] fig  : ', fig_path]);
    disp(['[phase5pre] text : ', txt_path]);
    disp(['[phase5pre] log  : ', log_path]);
    disp(['[phase5pre] mat  : ', mat_path]);
end

out = struct();
out.output_root = out_root;
out.fig_file = fig_path;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
out.sceneSummary = sceneSummary;
end

function SetTxt(pathStr, lines)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
