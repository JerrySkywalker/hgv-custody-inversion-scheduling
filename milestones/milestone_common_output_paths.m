function paths = milestone_common_output_paths(cfg, milestone_id, milestone_title)
%MILESTONE_COMMON_OUTPUT_PATHS Resolve and create milestone output folders.

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
end

root_dir = cfg.paths.root;
output_root = fullfile(root_dir, 'outputs', 'milestones');
paths = struct();
paths.root = output_root;
paths.milestone_root = fullfile(output_root, milestone_id);
paths.data = fullfile(paths.milestone_root, 'data');
paths.cache = paths.data;
paths.figures = fullfile(paths.milestone_root, 'figures');
paths.tables = fullfile(paths.milestone_root, 'tables');
paths.reports = fullfile(paths.milestone_root, 'reports');
paths.summary_report = fullfile(paths.reports, sprintf('%s_summary.md', milestone_id));
paths.summary_mat = fullfile(paths.data, sprintf('%s_%s_summary.mat', milestone_id, milestone_title));

ensure_dir(cfg.paths.outputs);
ensure_dir(paths.root);
ensure_dir(paths.milestone_root);
ensure_dir(paths.data);
ensure_dir(paths.figures);
ensure_dir(paths.tables);
ensure_dir(paths.reports);
end
