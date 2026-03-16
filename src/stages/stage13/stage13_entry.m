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
evaluations = repmat(struct('candidate', struct(), 'scan_out', struct(), 'signature', struct()), height(plan.candidate_table), 1);
signature_rows = table('Size', [0 13], ...
    'VariableTypes', {'string', 'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'logical', 'string', 'string'}, ...
    'VariableNames', {'case_tag', 'case_id', 'family', 'D_G_worst', 'D_A_worst', 'D_T_worst', 'D_T_bar_worst', ...
    't0G_star', 't0A_star', 't0T_star', 'feasible_truth', 'active_constraint', 'summary_tag'});

for k = 1:height(plan.candidate_table)
    evaluations(k) = stage13_evaluate_candidate(cfg, plan.candidate_table(k, :), paths);
    sig = evaluations(k).signature;
    signature_rows = [signature_rows; {sig.case_tag, sig.case_id, sig.family, sig.D_G_worst, sig.D_A_worst, ... %#ok<AGROW>
        sig.D_T_worst, sig.D_T_bar_worst, sig.t0G_star, sig.t0A_star, sig.t0T_star, ...
        sig.feasible_truth, sig.active_constraint, sig.summary_tag}];
end

if cfg.stage13.save_tables
    writetable(plan.candidate_table, paths.plan_csv);
    writetable(signature_rows, paths.signature_csv);
end

summary = struct();
summary.mode = plan.mode;
summary.baseline_case_id = string(cfg.stage13.baseline.case_id);
summary.num_families = numel(plan.families);
summary.num_candidates = height(plan.candidate_table);
summary.num_evaluated = height(signature_rows);

out = struct();
out.cfg = cfg;
out.paths = paths;
out.plan = plan;
out.evaluations = evaluations;
out.signature_table = signature_rows;
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
paths.signature_csv = fullfile(paths.tables, 'stage13_candidate_signatures.csv');
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
fprintf(fid, '- candidates evaluated: `%d`\n', out.summary.num_evaluated);
fprintf(fid, '\n## Notes\n\n');
fprintf(fid, 'This increment evaluates each planned candidate with the MA-aligned truth window kernel and stores a unified candidate signature table.\n');
end
