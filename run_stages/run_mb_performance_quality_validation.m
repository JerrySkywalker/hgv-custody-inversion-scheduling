function out = run_mb_performance_quality_validation(cfg)
%RUN_MB_PERFORMANCE_QUALITY_VALIDATION Run a lightweight validation bundle for startup/cache/search/plot plumbing.

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end

cfg.runtime.figure_visibility_mode = 'headless';
cfg.milestones.MB_semantic_compare.dry_run = true;
cfg.milestones.MB_semantic_compare.sensor_groups = {'baseline'};
cfg.milestones.MB_semantic_compare.heights_to_run = 1000;
cfg.milestones.MB_semantic_compare.family_set = {'nominal'};

paths = mb_output_paths(cfg, 'MB_validation_perf', 'performance_quality_validation');
ensure_dir(paths.tables);

t_init = tic;
startup(true);
startup_first_s = toc(t_init);
t_repeat = tic;
startup();
startup_repeat_s = toc(t_repeat);

path_audit = project_path_manager('audit');
figure_audit = project_figure_manager('audit');
dry_run_out = milestone_B_semantic_compare(cfg);

summary = table( ...
    startup_first_s, ...
    startup_repeat_s, ...
    logical(startup_repeat_s <= startup_first_s), ...
    string(local_getfield_or(path_audit, 'audit_csv', "")), ...
    string(local_getfield_or(path_audit, 'performance_csv', "")), ...
    string(local_getfield_or(figure_audit, 'audit_csv', "")), ...
    string(local_getfield_or(local_getfield_or(dry_run_out, 'tables', struct()), 'cache_key_audit_summary', "")), ...
    string(local_getfield_or(local_getfield_or(dry_run_out, 'tables', struct()), 'search_domain_audit', "")), ...
    'VariableNames', {'startup_first_s', 'startup_repeat_s', 'repeat_is_faster', 'path_audit_csv', 'startup_perf_audit_csv', 'figure_audit_csv', 'cache_key_audit_csv', 'search_domain_audit_csv'});

summary_csv = fullfile(paths.tables, 'MB_validation_summary_startup_cache_search.csv');
milestone_common_save_table(summary, summary_csv);

out = struct();
out.paths = paths;
out.summary = summary;
out.summary_csv = string(summary_csv);
out.path_audit = path_audit;
out.figure_audit = figure_audit;
out.dry_run = dry_run_out;
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
