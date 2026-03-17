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
signature_rows = table('Size', [0 14], ...
    'VariableTypes', {'string', 'string', 'string', 'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double', 'logical', 'string', 'string'}, ...
    'VariableNames', {'case_tag', 'case_id', 'family', 'case_family', 'D_G_worst', 'D_A_worst', 'D_T_worst', 'D_T_bar_worst', ...
    't0G_star', 't0A_star', 't0T_star', 'feasible_truth', 'active_constraint', 'summary_tag'});

for k = 1:height(plan.candidate_table)
    evaluations(k) = stage13_evaluate_candidate(cfg, plan.candidate_table(k, :), paths);
    sig = evaluations(k).signature;
    signature_rows = [signature_rows; {sig.case_tag, sig.case_id, sig.family, sig.case_family, sig.D_G_worst, sig.D_A_worst, ... %#ok<AGROW>
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
summary.representatives = struct();
for k = 1:numel(plan.families)
    family_name = char(plan.families(k));
    summary.representatives.(family_name) = stage13_filter_representatives(signature_rows, family_name);
end

out = struct();
out.cfg = cfg;
out.paths = paths;
out.plan = plan;
out.evaluations = evaluations;
out.signature_table = signature_rows;
out.figures = struct();
out.summary = summary;

baseline_tags = local_identify_baseline_tags(signature_rows);
out.summary_table = stage13_write_summary_table(signature_rows, baseline_tags, paths.summary_csv);
family_names = fieldnames(baseline_tags);
for k = 1:numel(family_names)
    family_name = family_names{k};
    out.figures.(['family_overview_' family_name]) = stage13_plot_family_overview(signature_rows, family_name, paths);
    reps = summary.representatives.(family_name);
    compare_tags = unique(string(struct2cell(reps)));
    compare_tags = compare_tags(strlength(compare_tags) > 0 & compare_tags ~= string(baseline_tags.(family_name)));
    for j = 1:numel(compare_tags)
        baseline_eval = local_find_eval_by_tag(evaluations, string(baseline_tags.(family_name)));
        candidate_eval = local_find_eval_by_tag(evaluations, compare_tags(j));
        files = stage13_plot_case_vs_baseline(baseline_eval, candidate_eval, family_name, paths);
        out.figures.(sprintf('%s_%s_curve', family_name, char(compare_tags(j)))) = files.curve_compare;
        out.figures.(sprintf('%s_%s_worst', family_name, char(compare_tags(j)))) = files.worst_window_compare;
    end
end
out.dissertation_export = stage13_export_for_dissertation(out);
out.dg_refine = stage13_refine_dg_first_probe(cfg, out);

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
paths.summary_csv = fullfile(paths.tables, 'stage13_candidate_summary.csv');
paths.summary_mat = fullfile(paths.reports, 'stage13_summary.mat');
paths.report_md = fullfile(paths.reports, 'stage13_summary.md');
paths.export_mat = fullfile(paths.reports, 'stage13_dissertation_export.mat');
paths.export_md = fullfile(paths.reports, 'stage13_dissertation_export.md');
paths.dg_refined_plan_csv = fullfile(paths.tables, 'stage13_dg_refined_search_plan.csv');

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
fprintf(fid, '- summary table: `%s`\n', out.paths.summary_csv);
fprintf(fid, '- dissertation export: `%s`\n', out.paths.export_md);
fprintf(fid, '- dg refine enabled: `%s`\n', string(out.cfg.stage13.dg_refine.enable));
fprintf(fid, '\n## Notes\n\n');
fprintf(fid, 'This increment evaluates each planned candidate with the MA-aligned truth window kernel and stores a unified candidate signature table.\n');
end

function baseline_tags = local_identify_baseline_tags(signature_rows)
families = unique(string(signature_rows.family), 'stable');
baseline_tags = struct();
for k = 1:numel(families)
    family_name = char(families(k));
    rows = signature_rows(strcmp(string(signature_rows.family), families(k)), :);
    baseline_row = rows(strcmp(string(rows.case_id), "N01"), :);
    if isempty(baseline_row)
        baseline_row = rows(1, :);
    end
    baseline_tags.(family_name) = string(baseline_row.case_tag(1));
end
end

function out_eval = local_find_eval_by_tag(evaluations, case_tag)
out_eval = struct();
for k = 1:numel(evaluations)
    if strcmp(string(evaluations(k).signature.case_tag), string(case_tag))
        out_eval = evaluations(k);
        return;
    end
end
error('Stage13 evaluation not found for candidate tag: %s', case_tag);
end
