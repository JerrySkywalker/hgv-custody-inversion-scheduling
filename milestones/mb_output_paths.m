function paths = mb_output_paths(cfg, milestone_id, milestone_title)
%MB_OUTPUT_PATHS Resolve MB milestone output folders using figures/tables/cache layout.

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
end
if nargin < 2 || strlength(string(milestone_id)) == 0
    milestone_id = 'MB';
end
if nargin < 3 || strlength(string(milestone_title)) == 0
    milestone_title = string(milestone_id);
end

root_dir = cfg.paths.root;
output_root = fullfile(root_dir, 'outputs', 'milestones');

paths = struct();
paths.root = output_root;
paths.milestone_root = fullfile(output_root, char(string(milestone_id)));
paths.figures = fullfile(paths.milestone_root, 'figures');
paths.tables = fullfile(paths.milestone_root, 'tables');
paths.cache = fullfile(paths.milestone_root, 'cache');
paths.summary_report = fullfile(paths.tables, sprintf('%s_summary.md', milestone_id));
paths.summary_mat = fullfile(paths.tables, sprintf('%s_%s_summary.mat', milestone_id, milestone_title));

ensure_dir(cfg.paths.outputs);
ensure_dir(paths.root);
ensure_dir(paths.milestone_root);
ensure_dir(paths.figures);
ensure_dir(paths.tables);
ensure_dir(paths.cache);
end
