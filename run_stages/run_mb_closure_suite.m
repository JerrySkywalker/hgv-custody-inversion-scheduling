function out = run_mb_closure_suite(options)
%RUN_MB_CLOSURE_SUITE Run fresh-root MB closure checks and cache A/B validation.

mb_safe_startup();

if nargin < 1 || isempty(options)
    options = struct();
end

tag = char(string(local_getfield_or(options, 'tag', datestr(now, 'yyyymmdd_HHMMSS'))));
strict_id = char(string(local_getfield_or(options, 'strict_id', "MB_" + tag + "_fresh_strict")));
fresh_id = char(string(local_getfield_or(options, 'fresh_id', "MB_" + tag + "_freshroot")));
cache_id = char(string(local_getfield_or(options, 'cache_id', "MB_" + tag + "_cacheAB")));
do_clean = logical(local_getfield_or(options, 'clean_roots', true));

cfg0 = milestone_common_defaults();
root_dir = fullfile(cfg0.paths.outputs, 'milestones');
strict_root = fullfile(root_dir, strict_id);
fresh_root = fullfile(root_dir, fresh_id);
cache_root = fullfile(root_dir, cache_id);

if do_clean
    local_reset_dir(strict_root);
    local_reset_dir(fresh_root);
    local_reset_dir(cache_root);
end

out = struct();
out.tag = string(tag);
out.strict_id = string(strict_id);
out.fresh_id = string(fresh_id);
out.cache_id = string(cache_id);
out.strict_root = string(strict_root);
out.fresh_root = string(fresh_root);
out.cache_root = string(cache_root);

strict_cfg = milestone_common_defaults();
[strict_cfg, ~, ~] = mb_cli_configure_search_profile(strict_cfg, false, struct( ...
    'run_mode', 'strict_stage05_validation_only', ...
    'profile_name', 'strict_stage05_replica', ...
    'profile_mode', 'strict_replica'));
strict_cfg.milestones.MB_semantic_compare.milestone_id = strict_id;
strict_cfg.milestones.MB_semantic_compare.title = 'semantic_compare';
strict_cfg.milestones.MB_semantic_compare.heights_to_run = 1000;
strict_cfg.milestones.MB_semantic_compare.family_set = {'nominal'};
strict_cfg.runtime.plotting.mode = 'headless';
out.strict_result = run_milestone_B_semantic_compare(strict_cfg, false);

fresh_cfg = milestone_common_defaults();
[fresh_cfg, ~] = apply_mb_search_profile_to_cfg(fresh_cfg, 'mb_default');
fresh_cfg.milestones.MB_semantic_compare.milestone_id = fresh_id;
fresh_cfg.milestones.MB_semantic_compare.title = 'semantic_compare';
fresh_cfg.milestones.MB_semantic_compare.mode = 'comparison';
fresh_cfg.milestones.MB_semantic_compare.sensor_groups = {'baseline', 'optimistic', 'robust'};
fresh_cfg.milestones.MB_semantic_compare.heights_to_run = 1000;
fresh_cfg.milestones.MB_semantic_compare.family_set = {'nominal'};
fresh_cfg.milestones.MB_semantic_compare.run_dense_local = false;
fresh_cfg.runtime.plotting.mode = 'headless';
out.fresh_result = milestone_B_semantic_compare(fresh_cfg);

cache_base_cfg = milestone_common_defaults();
[cache_base_cfg, ~] = apply_mb_search_profile_to_cfg(cache_base_cfg, 'mb_default');
cache_base_cfg.milestones.MB_semantic_compare.milestone_id = cache_id;
cache_base_cfg.milestones.MB_semantic_compare.title = 'semantic_compare';
cache_base_cfg.milestones.MB_semantic_compare.mode = 'comparison';
cache_base_cfg.milestones.MB_semantic_compare.sensor_groups = {'baseline'};
cache_base_cfg.milestones.MB_semantic_compare.heights_to_run = 1000;
cache_base_cfg.milestones.MB_semantic_compare.family_set = {'nominal'};
cache_base_cfg.milestones.MB_semantic_compare.run_dense_local = false;
cache_base_cfg.runtime.plotting.mode = 'headless';

out.cache_base_result = milestone_B_semantic_compare(cache_base_cfg);

cache_plot_cfg = cache_base_cfg;
cache_plot_cfg.milestones.MB_semantic_compare.figure_style_mode = 'debug';
cache_plot_cfg.milestones.MB_semantic_compare.export_paper_ready = false;
out.cache_plotonly_result = milestone_B_semantic_compare(cache_plot_cfg);

cache_semantic_cfg = cache_base_cfg;
cache_semantic_cfg.milestones.MB_semantic_compare.Ns_hard_max = 440;
cache_semantic_cfg.milestones.MB_semantic_compare.Ns_expand_blocks = ...
    local_append_expand_block(cache_semantic_cfg.milestones.MB_semantic_compare.Ns_expand_blocks, 404, 4, 440);
out.cache_semantic_result = milestone_B_semantic_compare(cache_semantic_cfg);

out.stage_smoke = run_all_stages(false, false, false, false, 1);

cache_summary = local_build_cache_ab_summary( ...
    out.cache_base_result, out.cache_plotonly_result, out.cache_semantic_result);
cache_summary_csv = fullfile(cache_root, 'tables', 'MB_cache_ab_validation.csv');
milestone_common_save_table(cache_summary, cache_summary_csv);
out.cache_ab_summary_csv = string(cache_summary_csv);

cache_reuse_summary = local_build_cache_reuse_summary( ...
    out.cache_base_result, out.cache_plotonly_result, out.cache_semantic_result);
cache_reuse_csv = fullfile(cache_root, 'tables', 'MB_cache_reuse_summary.csv');
milestone_common_save_table(cache_reuse_summary, cache_reuse_csv);
out.cache_reuse_summary_csv = string(cache_reuse_csv);

cache_signature_manifest = local_build_cache_signature_manifest( ...
    out.cache_base_result, out.cache_plotonly_result, out.cache_semantic_result);
cache_signature_csv = fullfile(cache_root, 'tables', 'MB_cache_signature_manifest.csv');
milestone_common_save_table(cache_signature_manifest, cache_signature_csv);
out.cache_signature_manifest_csv = string(cache_signature_csv);

stage_summary = local_build_stage_smoke_summary(out.stage_smoke);
stage_summary_csv = fullfile(fresh_root, 'tables', 'MB_run_all_stages_headless_smoke.csv');
milestone_common_save_table(stage_summary, stage_summary_csv);
out.stage_smoke_summary_csv = string(stage_summary_csv);
end

function local_reset_dir(path_str)
if isfolder(path_str)
    rmdir(path_str, 's');
end
end

function blocks = local_append_expand_block(blocks_in, ns_min, ns_step, ns_max)
block = struct( ...
    'name', string(sprintf('closure_block_%d_%d', ns_min, ns_max)), ...
    'ns_min', ns_min, ...
    'ns_step', ns_step, ...
    'ns_max', ns_max, ...
    'ns_values', ns_min:ns_step:ns_max);
if isempty(blocks_in)
    blocks = block;
else
    blocks = blocks_in;
    blocks(end + 1) = block; %#ok<AGROW>
end
end

function summary_table = local_build_cache_ab_summary(base_result, plot_result, semantic_result)
rows = cell(0, 7);
rows = local_append_cache_rows(rows, "base", base_result);
rows = local_append_cache_rows(rows, "plot_only_rerun", plot_result);
rows = local_append_cache_rows(rows, "semantic_change_rerun", semantic_result);
summary_table = cell2table(rows, 'VariableNames', ...
    {'scenario', 'semantic_mode', 'sensor_group', 'cache_hits', 'fresh_evaluations', 'total_run_count', 'interpretation_note'});
summary_table.scenario = string(summary_table.scenario);
summary_table.semantic_mode = string(summary_table.semantic_mode);
summary_table.sensor_group = string(summary_table.sensor_group);
summary_table.cache_hits = double(summary_table.cache_hits);
summary_table.fresh_evaluations = double(summary_table.fresh_evaluations);
summary_table.total_run_count = double(summary_table.total_run_count);
summary_table.interpretation_note = string(summary_table.interpretation_note);
end

function rows = local_append_cache_rows(rows, scenario_name, result)
run_outputs = local_getfield_or(local_getfield_or(result, 'artifacts', struct()), 'run_outputs', struct([]));
for idx = 1:numel(run_outputs)
    run_output = run_outputs(idx).run_output;
    summary = local_getfield_or(run_output, 'summary', struct());
    rows(end + 1, :) = { ... %#ok<AGROW>
        char(string(scenario_name)), ...
        char(string(local_getfield_or(summary, 'mode', run_outputs(idx).mode))), ...
        char(string(local_getfield_or(summary, 'sensor_group', run_outputs(idx).sensor_group))), ...
        local_getfield_or(summary, 'cache_hits', 0), ...
        local_getfield_or(summary, 'fresh_evaluations', 0), ...
        local_getfield_or(summary, 'total_run_count', numel(local_getfield_or(run_output, 'runs', struct([])))), ...
        char(string(local_getfield_or(summary, 'interpretation_note', "")))};
    end
end

function summary_table = local_build_cache_reuse_summary(base_result, plot_result, semantic_result)
rows = {};
rows = local_append_reuse_rows(rows, "base", base_result, false, "fresh baseline run");
rows = local_append_reuse_rows(rows, "plot_only_rerun", plot_result, true, "plot-only rerun should reuse semantic cache");
rows = local_append_reuse_rows(rows, "semantic_change_rerun", semantic_result, false, "semantic-domain change should invalidate semantic cache");
summary_table = cell2table(rows, 'VariableNames', ...
    {'scenario', 'semantic_mode', 'sensor_group', 'expected_reuse', 'actual_reuse', 'cache_hits', 'fresh_evaluations', 'status', 'note'});
summary_table.scenario = string(summary_table.scenario);
summary_table.semantic_mode = string(summary_table.semantic_mode);
summary_table.sensor_group = string(summary_table.sensor_group);
summary_table.expected_reuse = logical(summary_table.expected_reuse);
summary_table.actual_reuse = logical(summary_table.actual_reuse);
summary_table.cache_hits = double(summary_table.cache_hits);
summary_table.fresh_evaluations = double(summary_table.fresh_evaluations);
summary_table.status = string(summary_table.status);
summary_table.note = string(summary_table.note);
end

function rows = local_append_reuse_rows(rows, scenario_name, result, expected_reuse, note)
run_outputs = local_getfield_or(local_getfield_or(result, 'artifacts', struct()), 'run_outputs', struct([]));
for idx = 1:numel(run_outputs)
    summary = local_getfield_or(run_outputs(idx).run_output, 'summary', struct());
    cache_hits = local_getfield_or(summary, 'cache_hits', 0);
    fresh_evaluations = local_getfield_or(summary, 'fresh_evaluations', 0);
    actual_reuse = cache_hits > 0 && fresh_evaluations == 0;
    if expected_reuse == actual_reuse
        status = "PASS";
    else
        status = "WARN";
    end
    rows(end + 1, :) = { ... %#ok<AGROW>
        char(string(scenario_name)), ...
        char(string(local_getfield_or(summary, 'mode', run_outputs(idx).mode))), ...
        char(string(local_getfield_or(summary, 'sensor_group', run_outputs(idx).sensor_group))), ...
        expected_reuse, actual_reuse, cache_hits, fresh_evaluations, char(status), char(string(note))};
end
end

function manifest_table = local_build_cache_signature_manifest(base_result, plot_result, semantic_result)
rows = {};
rows = local_append_signature_rows(rows, "base", base_result);
rows = local_append_signature_rows(rows, "plot_only_rerun", plot_result);
rows = local_append_signature_rows(rows, "semantic_change_rerun", semantic_result);
manifest_table = cell2table(rows, 'VariableNames', ...
    {'scenario', 'semantic_mode', 'sensor_group', 'family_name', 'height_km', 'cache_file', 'manifest_csv', 'semantic_version', 'figure_version', 'semantic_cache_signature', 'figure_cache_signature', 'cache_hit', 'reason'});
manifest_table.scenario = string(manifest_table.scenario);
manifest_table.semantic_mode = string(manifest_table.semantic_mode);
manifest_table.sensor_group = string(manifest_table.sensor_group);
manifest_table.family_name = string(manifest_table.family_name);
manifest_table.height_km = double(manifest_table.height_km);
manifest_table.cache_file = string(manifest_table.cache_file);
manifest_table.manifest_csv = string(manifest_table.manifest_csv);
manifest_table.semantic_version = string(manifest_table.semantic_version);
manifest_table.figure_version = string(manifest_table.figure_version);
manifest_table.semantic_cache_signature = string(manifest_table.semantic_cache_signature);
manifest_table.figure_cache_signature = string(manifest_table.figure_cache_signature);
manifest_table.cache_hit = logical(manifest_table.cache_hit);
manifest_table.reason = string(manifest_table.reason);
end

function rows = local_append_signature_rows(rows, scenario_name, result)
run_outputs = local_getfield_or(local_getfield_or(result, 'artifacts', struct()), 'run_outputs', struct([]));
for idx = 1:numel(run_outputs)
    run_output = run_outputs(idx).run_output;
    cache_records = local_getfield_or(run_output, 'cache_records', struct([]));
    for idx_record = 1:numel(cache_records)
        record = cache_records(idx_record);
        manifest_info = read_mb_cache_manifest(record.cache_file);
        manifest = local_getfield_or(manifest_info, 'manifest', struct());
        rows(end + 1, :) = { ... %#ok<AGROW>
            char(string(scenario_name)), ...
            char(string(run_outputs(idx).mode)), ...
            char(string(run_outputs(idx).sensor_group)), ...
            char(string(local_getfield_or(record, 'family_name', ""))), ...
            local_getfield_or(record, 'h_km', NaN), ...
            char(string(local_getfield_or(record, 'cache_file', ""))), ...
            char(string(local_getfield_or(record, 'manifest_csv', local_getfield_or(manifest_info, 'manifest_csv', "")))), ...
            char(string(local_getfield_or(manifest, 'semantic_version', ""))), ...
            char(string(local_getfield_or(manifest, 'figure_version', ""))), ...
            char(string(local_getfield_or(manifest, 'semantic_cache_signature', ""))), ...
            char(string(local_getfield_or(manifest, 'figure_cache_signature', ""))), ...
            logical(local_getfield_or(record, 'cache_hit', false)), ...
            char(string(local_getfield_or(record, 'reason', "")))};
    end
end
end

function summary_table = local_build_stage_smoke_summary(stage_out)
rows = {};
stage_names = fieldnames(stage_out);
for idx = 1:numel(stage_names)
    name = stage_names{idx};
    entry = stage_out.(name);
    status = string(local_getfield_or(entry, 'status', local_getfield_or(entry, 'Status', "unknown")));
    fig_path = string(local_getfield_or(entry, 'figure_path', local_getfield_or(entry, 'figure', "")));
    cache_path = string(local_getfield_or(entry, 'cache_file', local_getfield_or(entry, 'cache', "")));
    rows(end + 1, :) = {string(name), status, fig_path, cache_path}; %#ok<AGROW>
end
summary_table = cell2table(rows, 'VariableNames', {'stage_name', 'status', 'figure_path', 'cache_path'});
summary_table.stage_name = string(summary_table.stage_name);
summary_table.status = string(summary_table.status);
summary_table.figure_path = string(summary_table.figure_path);
summary_table.cache_path = string(summary_table.cache_path);
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
