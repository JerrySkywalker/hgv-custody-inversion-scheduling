function out = run_ch5_bundle(opts)
%RUN_CH5_BUNDLE
% One-click Chapter 5 runner:
% - R4 diagnostic bundle
% - R5 diagnostic bundle
% - R9 diagnostic bundle
% - R10 diagnostic bundle
% - four-way SC/DC/LoC occupancy bar
%
% Usage:
%   out = run_ch5_bundle()
%   out = run_ch5_bundle(struct('visible_mode','on'))
%   out = run_ch5_bundle(struct( ...
%       'r9', struct('alpha_tau', 0.4), ...
%       'r10', struct('interval_steps', 20)))
%
% Supported top-level fields:
%   visible_mode  : 'on' | 'off'
%   run_tag       : output subfolder tag under outputs/ch5_rebuild/bundle_runs
%   run_r4        : true/false
%   run_r5        : true/false
%   run_r9        : true/false
%   run_r10       : true/false
%   make_occupancy_full4 : true/false
%   r4 / r5 / r9 / r10   : per-phase override structs

if nargin < 1 || isempty(opts)
    opts = struct();
end

project_root = fileparts(mfilename('fullpath'));
if isempty(project_root)
    project_root = pwd;
end

addpath(project_root);
startup('force', true);
local_add_ch5_paths(project_root);

opts = local_apply_defaults(opts);

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
if isempty(opts.run_tag)
    run_tag = ['bundle_' stamp];
else
    run_tag = char(opts.run_tag);
end

out_root = fullfile(project_root, 'outputs', 'ch5_rebuild', 'bundle_runs', run_tag);
if ~exist(out_root, 'dir')
    mkdir(out_root);
end

disp(' ')
disp('============================================================')
disp('=== [bundle][ch5] start ====================================')
disp(['[bundle][ch5] project_root : ' project_root])
disp(['[bundle][ch5] run_tag      : ' run_tag])
disp(['[bundle][ch5] out_root     : ' out_root])
disp('============================================================')

out = struct();
out.project_root = project_root;
out.run_tag = run_tag;
out.options = opts;
out.paths = struct('out_root', out_root);

if opts.run_r4
    out.r4 = local_run_r4(opts.r4, opts.visible_mode);
end
if opts.run_r5
    out.r5 = local_run_r5(opts.r5, opts.visible_mode);
end
if opts.run_r9
    out.r9 = local_run_r9(opts.r9, opts.visible_mode);
end
if opts.run_r10
    out.r10 = local_run_r10(opts.r10, opts.visible_mode);
end

if opts.make_occupancy_full4 ...
        && isfield(out, 'r4') && isfield(out, 'r5') ...
        && isfield(out, 'r9') && isfield(out, 'r10')
    occ_dir = fullfile(out_root, 'summary_compare');
    if ~exist(occ_dir, 'dir')
        mkdir(occ_dir);
    end

    out.occupancy = plot_ch5r_custody_state_occupancy_bar_fourway( ...
        out.r4, out.r5, out.r9, out.r10, occ_dir, opts.visible_mode);

    occ_csv = fullfile(occ_dir, 'ch5r_custody_state_occupancy_bar_fourway.csv');
    writetable(out.occupancy.table, occ_csv);
    out.paths.occupancy_csv = occ_csv;
else
    out.occupancy = struct();
end

bundle_summary = local_extract_bundle_summary(out);

summary_mat = fullfile(out_root, 'ch5_bundle_summary.mat');
save(summary_mat, 'bundle_summary');

summary_md = fullfile(out_root, 'ch5_bundle_summary.md');
local_write_summary_md(summary_md, bundle_summary);

out.paths.summary_mat = summary_mat;
out.paths.summary_md = summary_md;
out.ok = true;

disp(' ')
disp('=== [bundle][ch5] done =====================================')
disp(['[bundle][ch5] summary mat : ' summary_mat])
disp(['[bundle][ch5] summary md  : ' summary_md])
if isfield(out, 'occupancy') && isfield(out.occupancy, 'fig_file')
    disp(['[bundle][ch5] occupancy   : ' out.occupancy.fig_file])
end
disp('============================================================')
end

function out = local_run_r4(overrides, visible_mode)
disp('[bundle][ch5] R4 start')
phase_out = run_ch5r_phase4_tracking_baseline(overrides);

disp('[bundle][ch5] R4 replay start')
replay = ch5r_run_selection_replay_koopman('R4', phase_out, true, true);
if isfield(replay, 'paths') && isfield(replay.paths, 'mat_file') ...
        && ~isempty(replay.paths.mat_file)
    phase_out.paths.mat_file = replay.paths.mat_file;
end

disp('[bundle][ch5] R4 diag build')
diag_out = ch5r_build_custody_diag_bundle('R4', phase_out);
diag_dir = fullfile(phase_out.cfg.ch5r.output_root, 'phaseR4_diag_bundle');
files = plot_ch5r_custody_diag_bundle(diag_out, diag_dir, visible_mode);

out = struct();
out.phase = phase_out;
out.replay = replay;
out.diag = diag_out;
out.files = files;
out.ok = true;
end

function out = local_run_r5(overrides, visible_mode)
disp('[bundle][ch5] R5 start')
phase_out = run_ch5r_phase5_bubble_predictive(overrides);

disp('[bundle][ch5] R5 replay start')
replay = ch5r_run_selection_replay_koopman('R5', phase_out, true, true);
if isfield(replay, 'paths') && isfield(replay.paths, 'mat_file') ...
        && ~isempty(replay.paths.mat_file)
    phase_out.paths.mat_file = replay.paths.mat_file;
end

disp('[bundle][ch5] R5 diag build')
diag_out = ch5r_build_custody_diag_bundle('R5', phase_out);
diag_dir = fullfile(phase_out.cfg.ch5r.output_root, 'phaseR5_diag_bundle');
files = plot_ch5r_custody_diag_bundle(diag_out, diag_dir, visible_mode);

out = struct();
out.phase = phase_out;
out.replay = replay;
out.diag = diag_out;
out.files = files;
out.ok = true;
end

function out = local_run_r9(overrides, visible_mode)
disp('[bundle][ch5] R9 start')
phase_out = run_ch5r_phase9_r9_closedloop(overrides);

disp('[bundle][ch5] R9 diag build')
diag_out = ch5r_build_custody_diag_bundle('R9', phase_out);
diag_dir = fullfile(phase_out.cfg.ch5r.output_root, 'phaseR9_diag_bundle');
files = plot_ch5r_custody_diag_bundle(diag_out, diag_dir, visible_mode);

out = struct();
out.phase = phase_out;
out.diag = diag_out;
out.files = files;
out.ok = true;
end

function out = local_run_r10(overrides, visible_mode)
disp('[bundle][ch5] R10 start')
phase_out = run_ch5r_phase10_li_backend_closedloop(overrides);

disp('[bundle][ch5] R10 diag build')
diag_out = ch5r_build_custody_diag_bundle('R10', phase_out);
diag_dir = fullfile(phase_out.cfg.ch5r.output_root, 'phaseR10_diag_bundle');
files = plot_ch5r_custody_diag_bundle(diag_out, diag_dir, visible_mode);

out = struct();
out.phase = phase_out;
out.diag = diag_out;
out.files = files;
out.ok = true;
end

function opts = local_apply_defaults(opts)
if ~isfield(opts, 'visible_mode') || isempty(opts.visible_mode)
    opts.visible_mode = 'off';
end
if ~isfield(opts, 'run_tag')
    opts.run_tag = '';
end

if ~isfield(opts, 'run_r4') || isempty(opts.run_r4)
    opts.run_r4 = true;
end
if ~isfield(opts, 'run_r5') || isempty(opts.run_r5)
    opts.run_r5 = true;
end
if ~isfield(opts, 'run_r9') || isempty(opts.run_r9)
    opts.run_r9 = true;
end
if ~isfield(opts, 'run_r10') || isempty(opts.run_r10)
    opts.run_r10 = true;
end
if ~isfield(opts, 'make_occupancy_full4') || isempty(opts.make_occupancy_full4)
    opts.make_occupancy_full4 = true;
end

if ~isfield(opts, 'r4') || isempty(opts.r4)
    opts.r4 = struct();
end
if ~isfield(opts, 'r5') || isempty(opts.r5)
    opts.r5 = struct();
end
if ~isfield(opts, 'r9') || isempty(opts.r9)
    opts.r9 = struct();
end
if ~isfield(opts, 'r10') || isempty(opts.r10)
    opts.r10 = struct();
end
end

function local_add_ch5_paths(project_root)
ch5_root = fullfile(project_root, 'ch5_rebuild');
addpath(ch5_root);
addpath(genpath(ch5_root));
end

function summary = local_extract_bundle_summary(out)
summary = struct();
summary.run_tag = out.run_tag;
summary.out_root = out.paths.out_root;

if isfield(out, 'r4')
    summary.r4 = local_extract_phase_summary(out.r4);
end
if isfield(out, 'r5')
    summary.r5 = local_extract_phase_summary(out.r5);
end
if isfield(out, 'r9')
    summary.r9 = local_extract_phase_summary(out.r9);
end
if isfield(out, 'r10')
    summary.r10 = local_extract_phase_summary(out.r10);
end

if isfield(out, 'occupancy') && isfield(out.occupancy, 'table')
    summary.occupancy_fig = out.occupancy.fig_file;
    summary.occupancy_table = out.occupancy.table;
else
    summary.occupancy_fig = '';
    summary.occupancy_table = table();
end
end

function ps = local_extract_phase_summary(phase_out)
ps = struct();
ps.ok = phase_out.ok;
ps.fig_rmse_bubble = '';
ps.fig_vr_mg_fsm = '';
ps.fig_nis = '';

if isfield(phase_out, 'files')
    if isfield(phase_out.files, 'fig_rmse_bubble')
        ps.fig_rmse_bubble = phase_out.files.fig_rmse_bubble;
    end
    if isfield(phase_out.files, 'fig_vr_mg_fsm')
        ps.fig_vr_mg_fsm = phase_out.files.fig_vr_mg_fsm;
    end
    if isfield(phase_out.files, 'fig_nis')
        ps.fig_nis = phase_out.files.fig_nis;
    end
end

if isfield(phase_out, 'diag') && isfield(phase_out.diag, 'fsm') && isfield(phase_out.diag.fsm, 'summary')
    ps.fsm_summary = phase_out.diag.fsm.summary;
else
    ps.fsm_summary = struct();
end
end

function local_write_summary_md(md_file, summary)
lines = {};
lines{end+1} = '# Chapter 5 bundle summary';
lines{end+1} = '';
lines{end+1} = ['- run tag: `', summary.run_tag, '`'];
lines{end+1} = ['- output root: `', summary.out_root, '`'];
lines{end+1} = '';

phase_names = {'r4','r5','r9','r10'};
for i = 1:numel(phase_names)
    name = phase_names{i};
    if isfield(summary, name)
        s = summary.(name);
        lines{end+1} = ['## ', upper(name)];
        lines{end+1} = ['- RMSE/bubble figure: `', s.fig_rmse_bubble, '`'];
        lines{end+1} = ['- Vr/MG/FSM figure: `', s.fig_vr_mg_fsm, '`'];
        if isfield(s, 'fsm_summary') && isstruct(s.fsm_summary) ...
                && isfield(s.fsm_summary, 'sc_ratio')
            lines{end+1} = sprintf('- SC/DC/LoC: %.2f%% / %.2f%% / %.2f%%', ...
                100*s.fsm_summary.sc_ratio, ...
                100*s.fsm_summary.dc_ratio, ...
                100*s.fsm_summary.loc_ratio);
        end
        lines{end+1} = '';
    end
end

if isfield(summary, 'occupancy_fig') && ~isempty(summary.occupancy_fig)
    lines{end+1} = '## Four-way occupancy';
    lines{end+1} = ['- figure: `', summary.occupancy_fig, '`'];
    if isfield(summary, 'occupancy_table') && ~isempty(summary.occupancy_table)
        T = summary.occupancy_table;
        for i = 1:height(T)
            lines{end+1} = sprintf('- %s: SC=%.1f%%, DC=%.1f%%, LoC=%.1f%%', ...
                char(T.method_label(i)), ...
                100*T.SC_ratio(i), ...
                100*T.DC_ratio(i), ...
                100*T.LoC_ratio(i));
        end
    end
end

fid = fopen(md_file, 'w');
cleanup = onCleanup(@() fclose(fid));
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
end
