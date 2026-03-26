function paths = build_output_paths(cfg)
%BUILD_OUTPUT_PATHS Build standardized output path struct for a run.
%   This function only computes paths. It does not create directories.

validate_cfg(cfg);

root_dir = char(cfg.output_def.root_dir);
chapter = char(cfg.output_def.chapter);
namespace = char(cfg.output_def.namespace);
run_name = char(cfg.meta.run_name);

run_dir = fullfile(root_dir, chapter, namespace, run_name);

paths = struct();
paths.root_dir = root_dir;
paths.chapter_dir = fullfile(root_dir, chapter);
paths.namespace_dir = fullfile(root_dir, chapter, namespace);
paths.run_dir = run_dir;
paths.cache_dir = fullfile(run_dir, 'cache');
paths.log_dir = fullfile(run_dir, 'logs');
paths.artifact_dir = fullfile(run_dir, 'artifacts');
end
