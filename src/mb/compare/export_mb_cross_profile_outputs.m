function artifacts = export_mb_cross_profile_outputs(run_outputs, paths)
%EXPORT_MB_CROSS_PROFILE_OUTPUTS Export cross-profile overlays across sensor groups.

artifacts = struct('tables', struct(), 'figures', struct(), 'summary', struct(), 'summary_table', table(), 'export_grade_table', table());

if nargin < 2 || isempty(paths) || isempty(run_outputs)
    return;
end

summary_chunks = {};
summary_cursor = 0;
grade_chunks = {};
grade_cursor = 0;

[legacy_artifacts, legacy_summary, legacy_grade] = local_export_mode_family(run_outputs, paths, "legacyDG");
artifacts.tables = milestone_common_merge_structs(artifacts.tables, legacy_artifacts.tables);
artifacts.figures = milestone_common_merge_structs(artifacts.figures, legacy_artifacts.figures);
if ~isempty(legacy_summary)
    summary_cursor = summary_cursor + 1;
    summary_chunks{summary_cursor, 1} = legacy_summary; %#ok<AGROW>
end
if ~isempty(legacy_grade)
    grade_cursor = grade_cursor + 1;
    grade_chunks{grade_cursor, 1} = legacy_grade; %#ok<AGROW>
end

[closed_artifacts, closed_summary, closed_grade] = local_export_mode_family(run_outputs, paths, "closedD");
artifacts.tables = milestone_common_merge_structs(artifacts.tables, closed_artifacts.tables);
artifacts.figures = milestone_common_merge_structs(artifacts.figures, closed_artifacts.figures);
if ~isempty(closed_summary)
    summary_cursor = summary_cursor + 1;
    summary_chunks{summary_cursor, 1} = closed_summary; %#ok<AGROW>
end
if ~isempty(closed_grade)
    grade_cursor = grade_cursor + 1;
    grade_chunks{grade_cursor, 1} = closed_grade; %#ok<AGROW>
end

[dg_artifacts, dg_summary, dg_grade] = local_export_legacy_dg_overlays(run_outputs, paths);
artifacts.tables = milestone_common_merge_structs(artifacts.tables, dg_artifacts.tables);
artifacts.figures = milestone_common_merge_structs(artifacts.figures, dg_artifacts.figures);
if ~isempty(dg_summary)
    summary_cursor = summary_cursor + 1;
    summary_chunks{summary_cursor, 1} = dg_summary; %#ok<AGROW>
end
if ~isempty(dg_grade)
    grade_cursor = grade_cursor + 1;
    grade_chunks{grade_cursor, 1} = dg_grade; %#ok<AGROW>
end

if summary_cursor > 0
    artifacts.summary_table = vertcat(summary_chunks{1:summary_cursor});
    summary_csv = fullfile(paths.tables, 'MB_profileCompare_summary.csv');
    milestone_common_save_table(artifacts.summary_table, summary_csv);
    artifacts.tables.summary = string(summary_csv);
end
if grade_cursor > 0
    artifacts.export_grade_table = vertcat(grade_chunks{1:grade_cursor});
    grade_csv = fullfile(paths.tables, 'MB_profileCompare_export_grade.csv');
    milestone_common_save_table(artifacts.export_grade_table, grade_csv);
    artifacts.tables.export_grade = string(grade_csv);
end

artifacts.summary = struct( ...
    'legacyDG_groups', {local_collect_sensor_groups(run_outputs, "legacyDG")}, ...
    'closedD_groups', {local_collect_sensor_groups(run_outputs, "closedD")}, ...
    'has_strict_stage05_reference', any(strcmp(local_collect_sensor_groups(run_outputs, "legacyDG"), 'stage05_strict_reference')));
end

function [artifacts, summary_table, grade_table] = local_export_mode_family(run_outputs, paths, semantic_mode)
artifacts = struct('tables', struct(), 'figures', struct());
summary_table = table();
grade_table = table();

mode_runs = run_outputs(arrayfun(@(r) r.mode == semantic_mode, run_outputs));
if isempty(mode_runs)
    return;
end

contexts = local_collect_contexts(mode_runs);
summary_chunks = {};
summary_cursor = 0;
grade_chunks = {};
grade_cursor = 0;
for idx_ctx = 1:size(contexts, 1)
    h_km = contexts{idx_ctx, 1};
    family_name = contexts{idx_ctx, 2};
    context_runs = local_pick_runs(mode_runs, h_km, family_name);
    if isempty(context_runs)
        continue;
    end

    [pass_table, pass_summary] = local_build_passratio_overlay_table(context_runs, semantic_mode, h_km, family_name);
    context_tag = local_context_tag(h_km, family_name, contexts);
    if ~isempty(pass_table)
        pass_csv = fullfile(paths.tables, sprintf('MB_profileCompare_%s_passratio_%s.csv', char(semantic_mode), context_tag));
        pass_summary_csv = fullfile(paths.tables, sprintf('MB_profileCompare_%s_passratioSummary_%s.csv', char(semantic_mode), context_tag));
        milestone_common_save_table(pass_table, pass_csv);
        milestone_common_save_table(pass_summary, pass_summary_csv);
        fig_pass = plot_mb_cross_profile_passratio_overlay(pass_table, pass_summary, h_km, semantic_mode, family_name);
        pass_png = fullfile(paths.figures, sprintf('MB_profileCompare_%s_passratio_%s.png', char(semantic_mode), context_tag));
        milestone_common_save_figure(fig_pass, pass_png);
        close(fig_pass);

        artifacts.tables.(matlab.lang.makeValidName(sprintf('%s_passratio_%s', char(semantic_mode), context_tag))) = string(pass_csv);
        artifacts.tables.(matlab.lang.makeValidName(sprintf('%s_passratioSummary_%s', char(semantic_mode), context_tag))) = string(pass_summary_csv);
        artifacts.figures.(matlab.lang.makeValidName(sprintf('%s_passratio_%s', char(semantic_mode), context_tag))) = string(pass_png);
        summary_cursor = summary_cursor + 1;
        summary_chunks{summary_cursor, 1} = local_normalize_summary(pass_summary, "passratio_overlay"); %#ok<AGROW>
        grade_cursor = grade_cursor + 1;
        grade_chunks{grade_cursor, 1} = local_build_cross_profile_grade(pass_summary, "passratio_overlay", semantic_mode, h_km, family_name); %#ok<AGROW>
    end

    [frontier_table, frontier_summary] = local_build_frontier_overlay_table(context_runs, semantic_mode, h_km, family_name);
    if ~isempty(frontier_table)
        frontier_csv = fullfile(paths.tables, sprintf('MB_profileCompare_%s_frontier_%s.csv', char(semantic_mode), context_tag));
        frontier_summary_csv = fullfile(paths.tables, sprintf('MB_profileCompare_%s_frontierSummary_%s.csv', char(semantic_mode), context_tag));
        milestone_common_save_table(frontier_table, frontier_csv);
        milestone_common_save_table(frontier_summary, frontier_summary_csv);
        fig_frontier = plot_mb_cross_profile_frontier_overlay(frontier_table, frontier_summary, h_km, semantic_mode, family_name);
        frontier_png = fullfile(paths.figures, sprintf('MB_profileCompare_%s_frontier_%s.png', char(semantic_mode), context_tag));
        milestone_common_save_figure(fig_frontier, frontier_png);
        close(fig_frontier);

        artifacts.tables.(matlab.lang.makeValidName(sprintf('%s_frontier_%s', char(semantic_mode), context_tag))) = string(frontier_csv);
        artifacts.tables.(matlab.lang.makeValidName(sprintf('%s_frontierSummary_%s', char(semantic_mode), context_tag))) = string(frontier_summary_csv);
        artifacts.figures.(matlab.lang.makeValidName(sprintf('%s_frontier_%s', char(semantic_mode), context_tag))) = string(frontier_png);
        summary_cursor = summary_cursor + 1;
        summary_chunks{summary_cursor, 1} = local_normalize_summary(frontier_summary, "frontier_summary"); %#ok<AGROW>
        grade_cursor = grade_cursor + 1;
        grade_chunks{grade_cursor, 1} = local_build_cross_profile_grade(frontier_summary, "frontier_summary", semantic_mode, h_km, family_name); %#ok<AGROW>
    end
end

if summary_cursor > 0
    summary_table = vertcat(summary_chunks{1:summary_cursor});
end
if grade_cursor > 0
    grade_table = vertcat(grade_chunks{1:grade_cursor});
end
end

function [artifacts, summary_table, grade_table] = local_export_legacy_dg_overlays(run_outputs, paths)
artifacts = struct('tables', struct(), 'figures', struct());
summary_table = table();
grade_table = table();

mode_runs = run_outputs(arrayfun(@(r) r.mode == "legacyDG", run_outputs));
if isempty(mode_runs)
    return;
end

contexts = local_collect_contexts(mode_runs);
summary_chunks = {};
summary_cursor = 0;
grade_chunks = {};
grade_cursor = 0;
for idx_ctx = 1:size(contexts, 1)
    h_km = contexts{idx_ctx, 1};
    family_name = contexts{idx_ctx, 2};
    context_runs = local_pick_runs(mode_runs, h_km, family_name);
    if isempty(context_runs)
        continue;
    end

    [dg_table, dg_summary] = local_build_dg_overlay_table(context_runs, h_km, family_name);
    if isempty(dg_table)
        continue;
    end

    context_tag = local_context_tag(h_km, family_name, contexts);
    dg_csv = fullfile(paths.tables, sprintf('MB_profileCompare_legacyDG_DG_envelope_%s.csv', context_tag));
    dg_summary_csv = fullfile(paths.tables, sprintf('MB_profileCompare_legacyDG_DG_summary_%s.csv', context_tag));
    milestone_common_save_table(dg_table, dg_csv);
    milestone_common_save_table(dg_summary, dg_summary_csv);
    fig_dg = plot_mb_cross_profile_dg_overlay(dg_table, dg_summary, h_km, family_name);
    dg_png = fullfile(paths.figures, sprintf('MB_profileCompare_legacyDG_DG_envelope_%s.png', context_tag));
    milestone_common_save_figure(fig_dg, dg_png);
    close(fig_dg);

    artifacts.tables.(matlab.lang.makeValidName(sprintf('legacyDG_DG_envelope_%s', context_tag))) = string(dg_csv);
    artifacts.tables.(matlab.lang.makeValidName(sprintf('legacyDG_DG_summary_%s', context_tag))) = string(dg_summary_csv);
    artifacts.figures.(matlab.lang.makeValidName(sprintf('legacyDG_DG_envelope_%s', context_tag))) = string(dg_png);
    summary_cursor = summary_cursor + 1;
    summary_chunks{summary_cursor, 1} = local_normalize_summary(dg_summary, "DG_envelope"); %#ok<AGROW>
    grade_cursor = grade_cursor + 1;
    grade_chunks{grade_cursor, 1} = local_build_cross_profile_grade(dg_summary, "DG_envelope", "legacyDG", h_km, family_name); %#ok<AGROW>
end

if summary_cursor > 0
    summary_table = vertcat(summary_chunks{1:summary_cursor});
end
if grade_cursor > 0
    grade_table = vertcat(grade_chunks{1:grade_cursor});
end
end

function [overlay_table, summary_table] = local_build_passratio_overlay_table(context_runs, semantic_mode, h_km, family_name)
rows = {};
summary_rows = {};
cursor = 0;
summary_cursor = 0;

for idx = 1:numel(context_runs)
    run = context_runs(idx).run;
    sensor_group = context_runs(idx).sensor_group;
    sensor_label = context_runs(idx).sensor_label;
    phasecurve = local_getfield_or(run.aggregate, 'passratio_phasecurve', table());
    if isempty(phasecurve) || ~all(ismember({'Ns', 'max_pass_ratio'}, phasecurve.Properties.VariableNames))
        continue;
    end

    env = groupsummary(phasecurve(:, {'Ns', 'max_pass_ratio'}), 'Ns', 'max', 'max_pass_ratio');
    env.Properties.VariableNames{'max_max_pass_ratio'} = 'overlay_pass_ratio';
    env = sortrows(env, 'Ns');

    for idx_row = 1:height(env)
        cursor = cursor + 1;
        rows{cursor, 1} = { ...
            string(semantic_mode), string(sensor_group), string(sensor_label), h_km, string(family_name), ...
            env.Ns(idx_row), env.overlay_pass_ratio(idx_row)}; %#ok<AGROW>
    end

    plateau_reached = local_curve_plateau_reached(env.overlay_pass_ratio);
    note = "";
    if ~plateau_reached
        note = "search domain may still be insufficient for full saturation";
    end
    summary_cursor = summary_cursor + 1;
    summary_rows{summary_cursor, 1} = { ...
        string(semantic_mode), string(sensor_group), string(sensor_label), h_km, string(family_name), ...
        env.Ns(1), env.Ns(end), env.overlay_pass_ratio(end), max(env.overlay_pass_ratio), plateau_reached, note}; %#ok<AGROW>
end

overlay_table = local_cell_rows_to_table(rows, ...
    {'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name', 'Ns', 'overlay_pass_ratio'}, ...
    {'string', 'string', 'string', 'double', 'string', 'double', 'double'});
summary_table = local_cell_rows_to_table(summary_rows, ...
    {'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name', 'search_ns_min', 'search_ns_max', 'final_pass_ratio', 'peak_pass_ratio', 'right_plateau_reached', 'note'}, ...
    {'string', 'string', 'string', 'double', 'string', 'double', 'double', 'double', 'double', 'logical', 'string'});
summary_table = local_sort_sensor_groups(summary_table);
overlay_table = local_sort_sensor_groups(overlay_table);
end

function [frontier_table, summary_table] = local_build_frontier_overlay_table(context_runs, semantic_mode, h_km, family_name)
rows = {};
summary_rows = {};
cursor = 0;
summary_cursor = 0;

for idx = 1:numel(context_runs)
    run = context_runs(idx).run;
    sensor_group = context_runs(idx).sensor_group;
    sensor_label = context_runs(idx).sensor_label;
    i_values = unique(run.design_table.i_deg, 'sorted');
    frontier = local_getfield_or(run.aggregate, 'frontier_vs_i', table());

    defined_count = 0;
    for idx_i = 1:numel(i_values)
        i_deg = i_values(idx_i);
        hit = [];
        if ~isempty(frontier) && ismember('i_deg', frontier.Properties.VariableNames)
            hit = frontier(frontier.i_deg == i_deg, :);
        end
        if isempty(hit)
            status = "undefined_no_feasible_point";
            min_ns = NaN;
            note = "No feasible frontier point found within current search domain";
        else
            status = "defined";
            min_ns = hit.minimum_feasible_Ns(1);
            note = "";
            defined_count = defined_count + 1;
        end
        cursor = cursor + 1;
        rows{cursor, 1} = { ...
            string(semantic_mode), string(sensor_group), string(sensor_label), h_km, string(family_name), ...
            i_deg, min_ns, status, note}; %#ok<AGROW>
    end

    summary_note = "";
    if defined_count == 0
        summary_note = "No feasible frontier point found within current search domain";
    elseif defined_count < numel(i_values)
        summary_note = "Frontier is only partially defined within current search domain";
    end
    summary_cursor = summary_cursor + 1;
    summary_rows{summary_cursor, 1} = { ...
        string(semantic_mode), string(sensor_group), string(sensor_label), h_km, string(family_name), ...
        numel(i_values), defined_count, defined_count > 0, summary_note}; %#ok<AGROW>
end

frontier_table = local_cell_rows_to_table(rows, ...
    {'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name', 'i_deg', 'minimum_feasible_Ns', 'frontier_status', 'note'}, ...
    {'string', 'string', 'string', 'double', 'string', 'double', 'double', 'string', 'string'});
summary_table = local_cell_rows_to_table(summary_rows, ...
    {'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name', 'sampled_inclination_count', 'frontier_defined_count', 'frontier_any_defined', 'note'}, ...
    {'string', 'string', 'string', 'double', 'string', 'double', 'double', 'logical', 'string'});
summary_table = local_sort_sensor_groups(summary_table);
frontier_table = local_sort_sensor_groups(frontier_table);
end

function [dg_table, summary_table] = local_build_dg_overlay_table(context_runs, h_km, family_name)
rows = {};
summary_rows = {};
cursor = 0;
summary_cursor = 0;

for idx = 1:numel(context_runs)
    run = context_runs(idx).run;
    sensor_group = context_runs(idx).sensor_group;
    sensor_label = context_runs(idx).sensor_label;
    dg_envelope = local_getfield_or(run.aggregate, 'dg_envelope', table());
    if isempty(dg_envelope) || ~all(ismember({'Ns', 'max_D_G_min', 'max_pass_ratio'}, dg_envelope.Properties.VariableNames))
        continue;
    end

    env = groupsummary(dg_envelope(:, {'Ns', 'max_D_G_min', 'max_pass_ratio'}), 'Ns', 'max', {'max_D_G_min', 'max_pass_ratio'});
    env.Properties.VariableNames{'max_max_D_G_min'} = 'overlay_D_G_min';
    env.Properties.VariableNames{'max_max_pass_ratio'} = 'overlay_pass_ratio';
    env = sortrows(env, 'Ns');

    for idx_row = 1:height(env)
        cursor = cursor + 1;
        rows{cursor, 1} = { ...
            "legacyDG", string(sensor_group), string(sensor_label), h_km, string(family_name), ...
            env.Ns(idx_row), env.overlay_D_G_min(idx_row), env.overlay_pass_ratio(idx_row)}; %#ok<AGROW>
    end

    plateau_reached = local_curve_plateau_reached(env.overlay_pass_ratio);
    note = "";
    if ~plateau_reached
        note = "search domain may still be insufficient for full saturation";
    end
    summary_cursor = summary_cursor + 1;
    summary_rows{summary_cursor, 1} = { ...
        "legacyDG", string(sensor_group), string(sensor_label), h_km, string(family_name), ...
        env.Ns(end), env.overlay_D_G_min(end), env.overlay_pass_ratio(end), plateau_reached, note}; %#ok<AGROW>
end

dg_table = local_cell_rows_to_table(rows, ...
    {'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name', 'Ns', 'overlay_D_G_min', 'overlay_pass_ratio'}, ...
    {'string', 'string', 'string', 'double', 'string', 'double', 'double', 'double'});
summary_table = local_cell_rows_to_table(summary_rows, ...
    {'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name', 'search_ns_max', 'final_overlay_D_G_min', 'final_pass_ratio', 'right_plateau_reached', 'note'}, ...
    {'string', 'string', 'string', 'double', 'string', 'double', 'double', 'double', 'logical', 'string'});
summary_table = local_sort_sensor_groups(summary_table);
dg_table = local_sort_sensor_groups(dg_table);
end

function contexts = local_collect_contexts(mode_runs)
contexts = cell(0, 2);
for idx = 1:numel(mode_runs)
    runs = mode_runs(idx).run_output.runs;
    for idx_run = 1:numel(runs)
        entry = {runs(idx_run).h_km, char(string(runs(idx_run).family_name))};
        if isempty(contexts)
            contexts = entry;
        else
            already = cellfun(@(h, f) isequal(h, entry{1}) && strcmp(f, entry{2}), contexts(:, 1), contexts(:, 2));
            if ~any(already)
                contexts(end + 1, :) = entry; %#ok<AGROW>
            end
        end
    end
end
contexts = sortrows(contexts, [1, 2]);
end

function context_runs = local_pick_runs(mode_runs, h_km, family_name)
context_runs = struct('sensor_group', {}, 'sensor_label', {}, 'run', {});
cursor = 0;
for idx = 1:numel(mode_runs)
    wrapper = mode_runs(idx);
    for idx_run = 1:numel(wrapper.run_output.runs)
        run = wrapper.run_output.runs(idx_run);
        if ~isequal(run.h_km, h_km) || ~strcmp(char(string(run.family_name)), char(string(family_name)))
            continue;
        end
        cursor = cursor + 1;
        context_runs(cursor, 1).sensor_group = char(string(wrapper.run_output.sensor_group.name)); %#ok<AGROW>
        context_runs(cursor, 1).sensor_label = char(format_mb_sensor_group_label(wrapper.run_output.sensor_group, "short"));
        context_runs(cursor, 1).run = run;
        break;
    end
end
if cursor > 0
    [~, order] = sort(local_sensor_rank({context_runs.sensor_group}));
    context_runs = context_runs(order);
end
end

function tag = local_context_tag(h_km, family_name, contexts)
tag = sprintf('h%d', round(h_km));
family_names = string(contexts(:, 2));
if numel(unique(family_names)) > 1
    tag = sprintf('%s_%s', tag, matlab.lang.makeValidName(char(string(family_name))));
end
end

function groups = local_collect_sensor_groups(run_outputs, semantic_mode)
hits = run_outputs(arrayfun(@(r) r.mode == semantic_mode, run_outputs));
if isempty(hits)
    groups = {};
    return;
end
groups = unique(arrayfun(@(r) string(r.sensor_group), hits), 'stable');
groups = cellstr(groups);
end

function plateau_reached = local_curve_plateau_reached(pass_values)
pass_values = pass_values(isfinite(pass_values));
if isempty(pass_values)
    plateau_reached = false;
    return;
end
tail = pass_values(max(1, end - 1):end);
plateau_reached = median(tail) >= 0.98;
end

function order = local_sensor_rank(groups)
preferred = ["stage05_strict_reference", "baseline", "optimistic", "robust"];
order = zeros(1, numel(groups));
for idx = 1:numel(groups)
    hit = find(preferred == string(groups{idx}), 1);
    if isempty(hit)
        order(idx) = numel(preferred) + idx;
    else
        order(idx) = hit;
    end
end
end

function T = local_sort_sensor_groups(T)
if isempty(T) || ~ismember('sensor_group', T.Properties.VariableNames)
    return;
end
rank = local_sensor_rank(cellstr(string(T.sensor_group)));
T.sensor_rank_tmp = rank(:);
sort_keys = {'sensor_rank_tmp'};
if ismember('i_deg', T.Properties.VariableNames)
    sort_keys{end + 1} = 'i_deg'; %#ok<AGROW>
elseif ismember('Ns', T.Properties.VariableNames)
    sort_keys{end + 1} = 'Ns'; %#ok<AGROW>
end
T = sortrows(T, sort_keys);
T.sensor_rank_tmp = [];
end

function T = local_cell_rows_to_table(rows, variable_names, variable_types)
if isempty(rows)
    T = table('Size', [0, numel(variable_names)], ...
        'VariableTypes', variable_types, ...
        'VariableNames', variable_names);
    return;
end
T = cell2table(vertcat(rows{:}), 'VariableNames', variable_names);
for idx = 1:numel(variable_names)
    if strcmp(variable_types{idx}, 'string')
        T.(variable_names{idx}) = string(T.(variable_names{idx}));
    elseif strcmp(variable_types{idx}, 'double')
        T.(variable_names{idx}) = double(T.(variable_names{idx}));
    elseif strcmp(variable_types{idx}, 'logical')
        T.(variable_names{idx}) = logical(T.(variable_names{idx}));
    end
end
end

function summary_table = local_normalize_summary(T, summary_kind)
summary_table = table('Size', [height(T), 10], ...
    'VariableTypes', {'string', 'string', 'string', 'string', 'double', 'string', 'double', 'double', 'logical', 'string'}, ...
    'VariableNames', {'summary_kind', 'semantic_mode', 'sensor_group', 'sensor_label', 'h_km', 'family_name', 'metric_primary', 'metric_secondary', 'status_flag', 'note'});
summary_table.summary_kind = repmat(string(summary_kind), height(T), 1);
summary_table.semantic_mode = string(local_pick_or_repeat(T, 'semantic_mode', "", height(T)));
summary_table.sensor_group = string(local_pick_or_repeat(T, 'sensor_group', "", height(T)));
summary_table.sensor_label = string(local_pick_or_repeat(T, 'sensor_label', "", height(T)));
summary_table.h_km = double(local_pick_or_repeat(T, 'h_km', NaN, height(T)));
summary_table.family_name = string(local_pick_or_repeat(T, 'family_name', "", height(T)));
summary_table.note = string(local_pick_or_repeat(T, 'note', "", height(T)));

switch char(string(summary_kind))
    case 'passratio_overlay'
        summary_table.metric_primary = double(local_pick_or_repeat(T, 'final_pass_ratio', NaN, height(T)));
        summary_table.metric_secondary = double(local_pick_or_repeat(T, 'peak_pass_ratio', NaN, height(T)));
        summary_table.status_flag = logical(local_pick_or_repeat(T, 'right_plateau_reached', false, height(T)));
    case 'frontier_summary'
        summary_table.metric_primary = double(local_pick_or_repeat(T, 'frontier_defined_count', NaN, height(T)));
        summary_table.metric_secondary = double(local_pick_or_repeat(T, 'sampled_inclination_count', NaN, height(T)));
        summary_table.status_flag = logical(local_pick_or_repeat(T, 'frontier_any_defined', false, height(T)));
    case 'DG_envelope'
        summary_table.metric_primary = double(local_pick_or_repeat(T, 'final_overlay_D_G_min', NaN, height(T)));
        summary_table.metric_secondary = double(local_pick_or_repeat(T, 'final_pass_ratio', NaN, height(T)));
        summary_table.status_flag = logical(local_pick_or_repeat(T, 'right_plateau_reached', false, height(T)));
    otherwise
        summary_table.metric_primary = NaN(height(T), 1);
        summary_table.metric_secondary = NaN(height(T), 1);
        summary_table.status_flag = false(height(T), 1);
end
summary_table = local_sort_sensor_groups(summary_table);
end

function grade_table = local_build_cross_profile_grade(summary_table, summary_kind, semantic_mode, h_km, family_name)
group_count = numel(unique(summary_table.sensor_group));
single_group_only = group_count < 2;
switch char(string(summary_kind))
    case {'passratio_overlay', 'DG_envelope'}
        plateau_ok = all(logical(local_pick_or_repeat(summary_table, 'right_plateau_reached', false, height(summary_table))));
        paper_candidate = (~single_group_only) && plateau_ok;
        note = "";
        if single_group_only
            note = "single-group diagnostic only";
        elseif ~plateau_ok
            note = "search domain may still be insufficient for full saturation";
        end
    case 'frontier_summary'
        defined_counts = double(local_pick_or_repeat(summary_table, 'frontier_defined_count', 0, height(summary_table)));
        sampled_counts = double(local_pick_or_repeat(summary_table, 'sampled_inclination_count', 0, height(summary_table)));
        frontier_ok = all(defined_counts == sampled_counts & defined_counts > 1);
        paper_candidate = (~single_group_only) && frontier_ok;
        note = "";
        if single_group_only
            note = "single-group diagnostic only";
        elseif ~frontier_ok
            note = "frontier remains weakly defined for at least one sensor group";
        end
    otherwise
        paper_candidate = false;
        note = "unsupported summary kind";
end

grade_table = table( ...
    repmat(string(summary_kind), height(summary_table), 1), ...
    repmat(string(semantic_mode), height(summary_table), 1), ...
    repmat(h_km, height(summary_table), 1), ...
    repmat(string(family_name), height(summary_table), 1), ...
    summary_table.sensor_group, ...
    repmat(group_count, height(summary_table), 1), ...
    repmat(single_group_only, height(summary_table), 1), ...
    repmat(string(local_grade_label(paper_candidate)), height(summary_table), 1), ...
    repmat(logical(paper_candidate), height(summary_table), 1), ...
    repmat(string(note), height(summary_table), 1), ...
    'VariableNames', {'summary_kind', 'semantic_mode', 'h_km', 'family_name', 'sensor_group', ...
    'group_count', 'single_group_only', 'export_grade', 'paper_candidate', 'note'});
grade_table = local_sort_sensor_groups(grade_table);
end

function grade = local_grade_label(flag)
if logical(flag)
    grade = "paper_candidate";
else
    grade = "diagnostic_only";
end
end

function values = local_pick_or_repeat(T, var_name, fallback, row_count)
if ismember(var_name, T.Properties.VariableNames)
    values = T.(var_name);
else
    values = repmat(fallback, row_count, 1);
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
