function out = run_ch5r_phase4b_suite_plots(opts)
%RUN_CH5R_PHASE4B_SUITE_PLOTS
% Phase 4B: create stable statistics plots from Phase 4A summary.

if nargin < 1 || isempty(opts)
    opts = struct();
end

if ~isfield(opts, 'summary_source') || isempty(opts.summary_source)
    error('run_ch5r_phase4b_suite_plots:MissingSource', 'opts.summary_source is required.');
end

if ~isfield(opts, 'visible_mode') || isempty(opts.visible_mode)
    opts.visible_mode = 'off';
end

if ~isfield(opts, 'overall_metrics') || isempty(opts.overall_metrics)
    opts.overall_metrics = { ...
        'bubble_fraction', ...
        'bubble_steps', ...
        'max_bubble_depth', ...
        'switch_count', ...
        'mean_rmse_pos_km'};
end

if ~isfield(opts, 'family_metrics') || isempty(opts.family_metrics)
    opts.family_metrics = { ...
        'bubble_fraction', ...
        'switch_count', ...
        'mean_rmse_pos_km'};
end

if isstruct(opts.summary_source) && isfield(opts.summary_source, 'stats')
    stats = opts.summary_source.stats;
else
    error('run_ch5r_phase4b_suite_plots:UnsupportedSource', ...
        'summary_source should be Phase4A output struct.');
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
tag = ['phase4b_suite_plots_' stamp];

out_dir = fullfile(pwd, 'outputs', 'ch5_rebuild', 'phase4_suite_plots', tag);
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

overall_files = struct();
for i = 1:numel(opts.overall_metrics)
    metric = opts.overall_metrics{i};
    overall_files.(metric) = plot_ch5r_suite_metric_stats( ...
        stats.overall, metric, out_dir, opts.visible_mode, tag);
end

family_files = struct();
for i = 1:numel(opts.family_metrics)
    metric = opts.family_metrics{i};
    family_files.(metric) = plot_ch5r_suite_family_mean_bar( ...
        stats.by_family, metric, out_dir, opts.visible_mode, tag);
end

mat_file = fullfile(out_dir, ['suite_plots_' tag '.mat']);
save(mat_file, 'stats', 'overall_files', 'family_files', 'opts');

disp(' ')
disp('=== [ch5r:phase4B] suite plots done ===')
disp(out_dir)

out = struct();
out.ok = true;
out.stats = stats;
out.overall_files = overall_files;
out.family_files = family_files;
out.paths = struct('output_dir', out_dir, 'mat_file', mat_file, 'tag', tag);
end
