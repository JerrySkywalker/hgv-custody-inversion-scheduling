function out = run_stage00_to05_then_ch5_bundle(opts)
%RUN_STAGE00_TO05_THEN_CH5_BUNDLE
% One-click full Chapter 4 -> Chapter 5 pipeline:
% - run Stage00 ~ Stage05 non-interactively
% - then run Chapter 5 bundle
%
% Usage:
%   out = run_stage00_to05_then_ch5_bundle()
%   out = run_stage00_to05_then_ch5_bundle(struct( ...
%       'stage_cfg', struct('stage05', struct('use_parallel', false)), ...
%       'ch5', struct('visible_mode', 'on')))
%
% Supported top-level fields:
%   stage_cfg         : nested struct merged into default_params() output
%   stage_runner_opts : struct passed as the 3rd arg to run_stageXX runners
%   ch5               : struct passed into run_ch5_bundle(...)

if nargin < 1 || isempty(opts)
    opts = struct();
end

project_root = fileparts(mfilename('fullpath'));
if isempty(project_root)
    project_root = pwd;
end

addpath(project_root);
addpath(fullfile(project_root, 'run_stages'));

startup('force', true);

opts = local_apply_defaults(opts);

cfg = default_params();
cfg = local_merge_recursive(cfg, opts.stage_cfg);

stage_runner_opts = opts.stage_runner_opts;

disp(' ')
disp('============================================================')
disp('=== [bundle][stage00-05+ch5] start ==========================')
disp(['[bundle][stage00-05+ch5] project_root : ' project_root])
disp('============================================================')

out = struct();
out.project_root = project_root;
out.stage_cfg = cfg;
out.stage_runner_opts = stage_runner_opts;

disp('[bundle][stage00-05+ch5] run Stage00')
out.stages.stage00 = run_stage00_bootstrap(cfg, false, stage_runner_opts);

disp('[bundle][stage00-05+ch5] run Stage01')
out.stages.stage01 = run_stage01_scenario_disk(cfg, false, stage_runner_opts);

disp('[bundle][stage00-05+ch5] run Stage02')
out.stages.stage02 = run_stage02_hgv_nominal(cfg, false, stage_runner_opts);

disp('[bundle][stage00-05+ch5] run Stage03')
out.stages.stage03 = run_stage03_visibility_pipeline(cfg, false, stage_runner_opts);

disp('[bundle][stage00-05+ch5] run Stage04')
out.stages.stage04 = run_stage04_window_worstcase(cfg, false, stage_runner_opts);

disp('[bundle][stage00-05+ch5] run Stage05')
out.stages.stage05 = run_stage05_nominal_walker(cfg, false, stage_runner_opts);

if ~isfield(opts.ch5, 'run_tag') || isempty(opts.ch5.run_tag)
    opts.ch5.run_tag = ['after_stage05_' char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'))];
end

disp('[bundle][stage00-05+ch5] run Chapter 5 bundle')
out.ch5 = run_ch5_bundle(opts.ch5);

out.ok = true;

disp(' ')
disp('=== [bundle][stage00-05+ch5] done ===========================')
disp(['[bundle][stage00-05+ch5] ch5 summary md : ' out.ch5.paths.summary_md])
if isfield(out.ch5, 'occupancy') && isfield(out.ch5.occupancy, 'fig_file')
    disp(['[bundle][stage00-05+ch5] occupancy      : ' out.ch5.occupancy.fig_file])
end
disp('============================================================')
end

function opts = local_apply_defaults(opts)
if ~isfield(opts, 'stage_cfg') || isempty(opts.stage_cfg)
    opts.stage_cfg = struct();
end
if ~isfield(opts, 'stage_runner_opts') || isempty(opts.stage_runner_opts)
    opts.stage_runner_opts = struct();
end
if ~isfield(opts, 'ch5') || isempty(opts.ch5)
    opts.ch5 = struct();
end
end

function dst = local_merge_recursive(dst, src)
if ~isstruct(src) || isempty(fieldnames(src))
    return;
end

src_fields = fieldnames(src);
for i = 1:numel(src_fields)
    f = src_fields{i};
    if isfield(dst, f) && isstruct(dst.(f)) && isstruct(src.(f))
        dst.(f) = local_merge_recursive(dst.(f), src.(f));
    else
        dst.(f) = src.(f);
    end
end
end
