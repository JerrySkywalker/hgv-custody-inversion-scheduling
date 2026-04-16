function out = run_ch5r_phase4f_replot_only(opts)
%RUN_CH5R_PHASE4F_REPLOT_ONLY
% Replot-only entry.
% By default, auto-resolves latest Phase4A/4E artifacts and replots.
%
% Usage:
%   out = run_ch5r_phase4f_replot_only();
%   out = run_ch5r_phase4f_replot_only(struct('visible_mode','on'));
%   out = run_ch5r_phase4f_replot_only(struct( ...
%       'suite_source', '...csv', ...
%       'summary_source', '...mat', ...
%       'case_wins_source', '...mat'));

if nargin < 1 || isempty(opts)
    opts = struct();
end

if ~isfield(opts, 'visible_mode') || isempty(opts.visible_mode)
    opts.visible_mode = 'off';
end

if ~isfield(opts, 'project_root') || isempty(opts.project_root)
    opts.project_root = pwd;
end

sources = local_resolve_sources(opts.project_root, opts);

plot_opts = struct();
plot_opts.suite_source = sources.suite_source;
plot_opts.summary_source = sources.summary_source;
plot_opts.case_wins_source = sources.case_wins_source;
plot_opts.visible_mode = opts.visible_mode;

if isfield(opts, 'outdir_override') && ~isempty(opts.outdir_override)
    plot_opts.outdir_override = opts.outdir_override;
end

out = run_ch5r_phase4f_suite_plots(plot_opts);
out.sources = sources;

disp(' ')
disp('=== [ch5r:phase4F-replot-only] used sources ===')
disp(out.sources)
end

function sources = local_resolve_sources(project_root, opts)
sources = struct();

if isfield(opts, 'suite_source') && ~isempty(opts.suite_source)
    sources.suite_source = opts.suite_source;
else
    suite_root = fullfile(project_root, 'outputs', 'ch5_rebuild', 'phase4_suite_summary');
    sources.suite_source = local_latest_file(suite_root, 'multicase_results_*.csv');
end

if isfield(opts, 'summary_source') && ~isempty(opts.summary_source)
    sources.summary_source = opts.summary_source;
else
    summary_root = fullfile(project_root, 'outputs', 'ch5_rebuild', 'phase4_suite_summary');
    sources.summary_source = local_latest_file(summary_root, 'suite_summary_*.mat');
end

if isfield(opts, 'case_wins_source') && ~isempty(opts.case_wins_source)
    sources.case_wins_source = opts.case_wins_source;
else
    wins_root = fullfile(project_root, 'outputs', 'ch5_rebuild', 'phase4_case_wins');
    sources.case_wins_source = local_latest_file(wins_root, 'case_wins_*.mat');
end

assert(~isempty(sources.suite_source) && isfile(sources.suite_source), 'Cannot resolve suite_source');
assert(~isempty(sources.summary_source) && isfile(sources.summary_source), 'Cannot resolve summary_source');
assert(~isempty(sources.case_wins_source) && isfile(sources.case_wins_source), 'Cannot resolve case_wins_source');
end

function f = local_latest_file(root_dir, pattern)
f = '';
if ~exist(root_dir, 'dir')
    return;
end

D = dir(fullfile(root_dir, '**', pattern));
D = D(~[D.isdir]);
if isempty(D)
    return;
end

[~, idx] = max([D.datenum]);
f = fullfile(D(idx).folder, D(idx).name);
end
