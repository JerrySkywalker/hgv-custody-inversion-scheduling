function out = run_ch5_phase7A_dualloop_ck(cfg, verbose)
%RUN_CH5_PHASE7A_DUALOOP_CK
% Minimal patched version for NX-2 entry verification.
%
% This patch forces the CK branch to call:
%   policy_custody_dualloop_koopman(caseData, cfg)
%
% and keeps the original output contract as much as possible.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params('ref128');
end
if nargin < 2
    verbose = true;
end

if ischar(cfg) || isstring(cfg)
    cfg = default_ch5_params(char(cfg));
end

cfg = apply_nx2_state_machine_defaults(cfg);
scene_preset = cfg.ch5.scene_preset;

out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase7a');
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
log_dir = fullfile(out_root, 'logs');
mat_dir = fullfile(out_root, 'mats');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end

caseData = build_ch5_case(cfg);

trackingC = policy_custody_singleloop(caseData, cfg);
trackingCK = policy_custody_dualloop_koopman(caseData, cfg);

custodyC = evaluate_custody_metrics(trackingC, cfg);
custodyCK = evaluate_custody_metrics(trackingCK, cfg);

trackingStatsC = summarize_tracking_metrics(trackingC, cfg);
trackingStatsCK = summarize_tracking_metrics(trackingCK, cfg);

fig_path = fullfile(fig_dir, ['phase7a_ck_vs_c_', scene_preset, '.png']);
plot_ch5_phase7a_ck_vs_c(custodyC, custodyCK, scene_preset, fig_path);

txt_path = fullfile(tbl_dir, ['phase7a_summary_', scene_preset, '.txt']);
local_write_summary(txt_path, scene_preset, custodyC, custodyCK, trackingStatsC, trackingStatsCK, trackingCK);

log_path = fullfile(log_dir, ['phase7a_log_', scene_preset, '.txt']);
local_write_log(log_path, scene_preset, trackingCK);

mat_path = fullfile(mat_dir, ['phase7a_', scene_preset, '.mat']);
save(mat_path, 'scene_preset', 'trackingC', 'trackingCK', 'custodyC', 'custodyCK', 'trackingStatsC', 'trackingStatsCK');

if verbose
    disp('=== Chapter 5 Phase 7A CK Summary ===')
    disp(['scene_preset = ', scene_preset])
    disp('--- custody C ---')
    disp(custodyC)
    disp(' ')
    disp('--- custody CK ---')
    disp(custodyCK)
    disp(' ')
    disp(['[phase7a] fig  : ', fig_path])
    disp(['[phase7a] text : ', txt_path])
    disp(['[phase7a] log  : ', log_path])
    disp(['[phase7a] mat  : ', mat_path])
end

out = struct();
out.fig_file = fig_path;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
end

function local_write_summary(pathStr, scene_preset, custodyC, custodyCK, trackingStatsC, trackingStatsCK, trackingCK)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open summary file.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== Chapter 5 Phase 7A CK Summary ===\n');
fprintf(fid, 'scene_preset = %s\n', scene_preset);

fprintf(fid, '--- custody C ---\n');
local_dump_struct(fid, custodyC);

fprintf(fid, '\n--- custody CK ---\n');
local_dump_struct(fid, custodyCK);

fprintf(fid, '\n--- trackingStatsC ---\n');
local_dump_struct(fid, trackingStatsC);

fprintf(fid, '\n--- trackingStatsCK ---\n');
local_dump_struct(fid, trackingStatsCK);

fprintf(fid, '\n--- trackingCK fields ---\n');
fn = fieldnames(trackingCK);
for i = 1:numel(fn)
    fprintf(fid, '%s\n', fn{i});
end
end

function local_write_log(pathStr, scene_preset, trackingCK)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open log file.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '[INFO] phase7a ck\n');
fprintf(fid, '[INFO] scene_preset = %s\n', scene_preset);
fprintf(fid, '[INFO] trackingCK fields:\n');
fn = fieldnames(trackingCK);
for i = 1:numel(fn)
    fprintf(fid, '[INFO]   %s\n', fn{i});
end
end

function local_dump_struct(fid, S)
fn = fieldnames(S);
for i = 1:numel(fn)
    v = S.(fn{i});
    if isnumeric(v) && isscalar(v)
        fprintf(fid, '%s = %.6f\n', fn{i}, v);
    elseif isstring(v) && isscalar(v)
        fprintf(fid, '%s = %s\n', fn{i}, char(v));
    elseif ischar(v)
        fprintf(fid, '%s = %s\n', fn{i}, v);
    else
        sz = size(v);
        sz_txt = sprintf('%dx', sz);
        sz_txt = sz_txt(1:end-1);
        fprintf(fid, '%s : [%s %s]\n', fn{i}, sz_txt, class(v));
    end
end
end
