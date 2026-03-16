function out = stage13_entry(cfg, overrides)
%STAGE13_ENTRY Stage13 baseline neighborhood-search skeleton.

if nargin < 1 || isempty(cfg)
    cfg = stage13_default_config();
else
    cfg = stage13_default_config(cfg);
end
if nargin < 2 || isempty(overrides)
    overrides = struct();
end

cfg = milestone_common_merge_structs(cfg, overrides);
cfg = stage13_default_config(cfg);

paths = local_build_paths(cfg);
plan = stage13_build_search_plan(cfg, cfg.stage13.mode);

if cfg.stage13.save_tables
    writetable(plan.candidate_table, paths.plan_csv);
end

summary = struct();
summary.mode = plan.mode;
summary.baseline_case_id = string(cfg.stage13.baseline.case_id);
summary.num_families = numel(plan.families);
summary.num_candidates = height(plan.candidate_table);

out = struct();
out.cfg = cfg;
out.paths = paths;
out.plan = plan;
out.summary = summary;

save(paths.summary_mat, 'out', '-v7.3');
if cfg.stage13.save_reports
    local_write_report(paths.report_md, out);
end
end

function paths = local_build_paths(cfg)
root_dir = cfg.stage13.output_root;
paths = struct();
paths.root = root_dir;
paths.tables = fullfile(root_dir, 'tables');
paths.figures = fullfile(root_dir, 'figures');
paths.reports = fullfile(root_dir, 'reports');
paths.cache = fullfile(root_dir, 'cache');
paths.plan_csv = fullfile(paths.tables, 'stage13_search_plan.csv');
paths.summary_mat = fullfile(paths.reports, 'stage13_summary.mat');
paths.report_md = fullfile(paths.reports, 'stage13_summary.md');

ensure_dir(cfg.paths.output);
ensure_dir(paths.root);
ensure_dir(paths.tables);
ensure_dir(paths.figures);
ensure_dir(paths.reports);
ensure_dir(paths.cache);
end

function local_write_report(file_path, out)
fid = fopen(file_path, 'w');
if fid < 0
    error('Failed to open Stage13 report: %s', file_path);
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '# Stage13 baseline neighborhood search\n\n');
fprintf(fid, '## Summary\n\n');
fprintf(fid, '- mode: `%s`\n', out.summary.mode);
fprintf(fid, '- baseline case: `%s`\n', out.summary.baseline_case_id);
fprintf(fid, '- families: `%d`\n', out.summary.num_families);
fprintf(fid, '- candidates planned: `%d`\n', out.summary.num_candidates);
fprintf(fid, '\n## Notes\n\n');
fprintf(fid, 'This skeleton only builds the local search plan. Candidate truth evaluation will be added in the next increment.\n');
end
