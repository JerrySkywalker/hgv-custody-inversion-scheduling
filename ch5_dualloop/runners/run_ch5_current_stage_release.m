function out = run_ch5_current_stage_release(verbose)
%RUN_CH5_CURRENT_STAGE_RELEASE
% Stage closure exporter for current Chapter 5 status.

if nargin < 1
    verbose = true;
end

out_root = fullfile(pwd, 'outputs', 'cpt5', 'current_stage_release');
doc_dir = fullfile(out_root, 'docs');
fig_dir = fullfile(out_root, 'figs');
if ~exist(doc_dir, 'dir'); mkdir(doc_dir); end
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end

src_doc_1 = fullfile(pwd, 'ch5_dualloop', 'doc', 'ch5_current_stage_summary.md');
src_doc_2 = fullfile(pwd, 'ch5_dualloop', 'doc', 'ch5_mainline_freeze.md');

dst_doc_1 = fullfile(doc_dir, 'ch5_current_stage_summary.md');
dst_doc_2 = fullfile(doc_dir, 'ch5_mainline_freeze.md');

copyfile(src_doc_1, dst_doc_1);
copyfile(src_doc_2, dst_doc_2);

local_try_copy(fullfile(pwd, 'outputs', 'cpt5', 'phase4', 'figs', 'phase4_static_vs_tracking_summary.png'), ...
               fullfile(fig_dir, 'phase4_static_vs_tracking_summary.png'));

local_try_copy(fullfile(pwd, 'outputs', 'cpt5', 'phase7a', 'figs', 'phase7a_ck_vs_c_ref128.png'), ...
               fullfile(fig_dir, 'phase7a_ck_vs_c_ref128.png'));

local_try_copy(fullfile(pwd, 'outputs', 'cpt5', 'phase7a', 'figs', 'phase7a_ck_vs_c_stress96.png'), ...
               fullfile(fig_dir, 'phase7a_ck_vs_c_stress96.png'));

out = struct();
out.doc_dir = doc_dir;
out.fig_dir = fig_dir;
out.docs = {dst_doc_1, dst_doc_2};

if verbose
    disp('=== ch5 current stage release ===')
    disp(out)
end
end

function local_try_copy(src, dst)
if exist(src, 'file')
    copyfile(src, dst);
end
end
