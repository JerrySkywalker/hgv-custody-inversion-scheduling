function paths = shared_scenario_common_output_paths(cfg, scenario_id, scenario_title)
%SHARED_SCENARIO_COMMON_OUTPUT_PATHS Resolve output folders for shared scenarios.

if nargin < 1 || isempty(cfg)
    cfg = shared_scenario_common_defaults();
end

output_root = fullfile(cfg.paths.root, 'outputs', 'shared_scenarios');
paths = struct();
paths.root = output_root;
paths.scenario_root = fullfile(output_root, scenario_id);
paths.data = fullfile(paths.scenario_root, 'data');
paths.cache = paths.data;
paths.figures = fullfile(paths.scenario_root, 'figures');
paths.reports = fullfile(paths.scenario_root, 'reports');
paths.summary_report = fullfile(paths.reports, sprintf('%s_summary.md', scenario_id));
paths.summary_mat = fullfile(paths.data, sprintf('%s_%s_summary.mat', scenario_id, scenario_title));

ensure_dir(fullfile(cfg.paths.root, 'outputs'));
ensure_dir(paths.root);
ensure_dir(paths.scenario_root);
ensure_dir(paths.data);
ensure_dir(paths.figures);
ensure_dir(paths.reports);
end
