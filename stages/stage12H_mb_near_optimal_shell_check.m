function out = stage12H_mb_near_optimal_shell_check(cfg, pool, minimum_design_table, near_optimal_design_table, overrides)
%STAGE12H_MB_NEAR_OPTIMAL_SHELL_CHECK Diagnose whether near-optimal shells exist beyond the current minimum shell.

startup();

if nargin < 1 || isempty(cfg)
    cfg = milestone_common_defaults();
else
    cfg = milestone_common_defaults(cfg);
end
if nargin < 2 || isempty(pool) || ~isstruct(pool)
    error('stage12H_mb_near_optimal_shell_check requires cfg and a populated pool struct.');
end
if nargin < 3 || isempty(minimum_design_table)
    minimum_design_table = table();
end
if nargin < 4 || isempty(near_optimal_design_table)
    near_optimal_design_table = table();
end
if nargin < 5 || isempty(overrides)
    overrides = struct();
end

meta = cfg.milestones.MB;
if isstruct(overrides)
    meta = milestone_common_merge_structs(meta, overrides);
end

minimum_unique = unique_design_rows(minimum_design_table);
near_optimal_unique = unique_design_rows(near_optimal_design_table);
paths = milestone_common_output_paths(cfg, meta.milestone_id, meta.title);
style = milestone_common_plot_style();

summary_table = table();
candidate_table = table();
candidate_eval = struct();
figure_path = "";
summary = local_empty_summary();

if isempty(minimum_unique)
    out = local_build_output(summary_table, candidate_table, candidate_eval, figure_path, summary);
    return;
end

Ns_min = minimum_unique.Ns(1);
shell_ns_values = local_pick_shell_ns_values(pool.design_pool_table, Ns_min);
candidate_design_table = local_build_shell_candidate_design_table(pool, minimum_unique, shell_ns_values);
[candidate_design_table, candidate_group_info] = unique_design_rows(candidate_design_table);

if ~isempty(candidate_design_table)
    candidate_eval = evaluate_design_pool_with_stage09(cfg, candidate_design_table, 'joint', local_shell_eval_overrides(cfg, meta));
    candidate_table = unique_design_rows(candidate_eval.full_theta_table);
    candidate_table = local_annotate_shell_candidate_table(candidate_table, minimum_unique, shell_ns_values, Ns_min);
else
    candidate_eval = struct('full_theta_table', table(), 'feasible_theta_table', table(), 'timing', struct());
end

summary_table = build_ns_shell_summary(candidate_table, minimum_unique, near_optimal_unique);
summary = local_build_summary(summary_table, candidate_table, minimum_unique, near_optimal_unique, Ns_min, shell_ns_values);

if ~(isfield(meta, 'preflight_mode') && logical(meta.preflight_mode))
    fig = local_plot_shell_phasecurve(summary_table, candidate_table, minimum_unique, style);
    figure_path = fullfile(paths.figures, 'MB_near_optimal_shell_phasecurve.png');
    milestone_common_save_figure(fig, figure_path);
    close(fig);
end

out = local_build_output(summary_table, candidate_table, candidate_eval, figure_path, summary);
out.candidate_group_info = candidate_group_info;
end

function out = local_build_output(summary_table, candidate_table, candidate_eval, figure_path, summary)
out = struct();
out.summary_table = summary_table;
out.candidate_table = candidate_table;
out.candidate_eval = candidate_eval;
out.figure_path = string(figure_path);
out.summary = summary;
end

function overrides = local_shell_eval_overrides(cfg, meta)
overrides = struct();
overrides.use_parallel = true;
overrides.save_case_window_bank = false;
overrides.enable_checkpoint = false;
overrides.resume_from_checkpoint = false;
if isfield(meta, 'fast_mode')
    overrides.fast_mode = logical(meta.fast_mode);
end
if isfield(cfg.milestones.MB.slice_settings, 'heading_subset_max')
    overrides.heading_subset_max = cfg.milestones.MB.slice_settings.heading_subset_max;
end
end

function shell_ns_values = local_pick_shell_ns_values(design_pool_table, Ns_min)
if isempty(design_pool_table) || ~ismember('Ns', design_pool_table.Properties.VariableNames)
    shell_ns_values = [];
    return;
end

Ns_all = unique(design_pool_table.Ns);
Ns_all = sort(Ns_all(:).');
Ns_shell = Ns_all(Ns_all > Ns_min);
shell_ns_values = Ns_shell(1:min(5, numel(Ns_shell)));
end

function candidate_design_table = local_build_shell_candidate_design_table(pool, minimum_unique, shell_ns_values)
candidate_design_table = table();
if isempty(minimum_unique) || isempty(shell_ns_values)
    return;
end

allowed_h = unique(pool.design_pool_table.h_km(:));
allowed_i = unique(pool.design_pool_table.i_deg(:));
allowed_pairs = unique(pool.design_pool_table(:, {'P', 'T', 'Ns'}));
allowed_pairs = sortrows(allowed_pairs, {'Ns', 'P', 'T'});
allowed_pairs = allowed_pairs(ismember(allowed_pairs.Ns, shell_ns_values), :);
if isempty(allowed_pairs)
    return;
end

rows = cell(height(minimum_unique), 1);
for idx = 1:height(minimum_unique)
    h_vals = intersect(allowed_h, minimum_unique.h_km(idx) + [-100; 0; 100], 'stable');
    i_vals = intersect(allowed_i, minimum_unique.i_deg(idx) + [-10; 0; 10], 'stable');
    if isempty(h_vals) || isempty(i_vals)
        continue;
    end
    [H, I, pair_idx] = ndgrid(h_vals, i_vals, (1:height(allowed_pairs)).');
    pair_idx = pair_idx(:);
    block = table();
    block.h_km = H(:);
    block.i_deg = I(:);
    block.P = allowed_pairs.P(pair_idx);
    block.T = allowed_pairs.T(pair_idx);
    block.F = repmat(minimum_unique.F(idx), numel(pair_idx), 1);
    block.Ns = allowed_pairs.Ns(pair_idx);
    block.slice_source = repmat("shell_check", height(block), 1);
    rows{idx} = block;
end

rows = rows(~cellfun(@isempty, rows));
if isempty(rows)
    return;
end
candidate_design_table = vertcat(rows{:});
candidate_design_table = sortrows(candidate_design_table, {'Ns', 'h_km', 'i_deg', 'P', 'T'}, ...
    {'ascend', 'ascend', 'ascend', 'ascend', 'ascend'});
end

function T = local_annotate_shell_candidate_table(T, minimum_unique, shell_ns_values, Ns_min)
if isempty(T)
    return;
end

best_margin_min = NaN;
if ~isempty(minimum_unique) && ismember('joint_margin', minimum_unique.Properties.VariableNames)
    best_margin_min = max(minimum_unique.joint_margin);
end
delta_margin = 0.2;
delta_N = 12;
T.is_shell_extension = T.Ns > Ns_min;
T.delta_Ns = T.Ns - Ns_min;
T.shell_rank = nan(height(T), 1);
for idx = 1:numel(shell_ns_values)
    T.shell_rank(T.Ns == shell_ns_values(idx)) = idx;
end
T.near_optimal_by_size = logical(T.joint_feasible) & (T.delta_Ns <= delta_N);
if isfinite(best_margin_min)
    T.near_optimal_by_margin = logical(T.joint_feasible) & (T.joint_margin >= (best_margin_min - delta_margin));
else
    T.near_optimal_by_margin = false(height(T), 1);
end
end

function summary_table = build_ns_shell_summary(candidate_table, minimum_unique, near_optimal_unique)
summary_table = table();

min_rows = local_shell_count_rows(minimum_unique, "minimum");
near_rows = local_shell_count_rows(near_optimal_unique, "reported_near_optimal");
candidate_rows = local_shell_count_rows(candidate_table, "shell_check");
all_rows = [min_rows; near_rows; candidate_rows];
if isempty(all_rows)
    return;
end

Ns_values = unique(all_rows.Ns);
Ns_values = sort(Ns_values);
rows = cell(numel(Ns_values), 1);
for idx = 1:numel(Ns_values)
    Ns = Ns_values(idx);
    rows{idx} = local_build_shell_row(Ns, min_rows, near_rows, candidate_rows);
end
summary_table = struct2table(vertcat(rows{:}));
summary_table = sortrows(summary_table, 'Ns', 'ascend');
end

function rows = local_shell_count_rows(T, source_tag)
rows = table();
if isempty(T) || ~ismember('Ns', T.Properties.VariableNames)
    return;
end

Ns_values = unique(T.Ns);
Ns_values = sort(Ns_values);
row_bank = cell(numel(Ns_values), 1);
for idx = 1:numel(Ns_values)
    sub = T(T.Ns == Ns_values(idx), :);
    row_bank{idx} = table(Ns_values(idx), string(source_tag), height(sub), ...
        sum(local_get_logical_column(sub, 'joint_feasible', true)), ...
        sum(local_get_logical_column(sub, 'near_optimal_by_size', false)), ...
        sum(local_get_logical_column(sub, 'near_optimal_by_margin', false)), ...
        local_safe_max(sub, 'joint_margin'), ...
        'VariableNames', {'Ns', 'source_tag', 'count_total', 'count_feasible', 'count_near_by_size', 'count_near_by_margin', 'best_joint_margin'});
end
rows = vertcat(row_bank{:});
end

function row = local_build_shell_row(Ns, min_rows, near_rows, candidate_rows)
candidate_sub = candidate_rows(candidate_rows.Ns == Ns, :);
minimum_sub = min_rows(min_rows.Ns == Ns, :);
near_sub = near_rows(near_rows.Ns == Ns, :);

row = struct();
row.Ns = Ns;
row.is_minimum_shell = ~isempty(minimum_sub);
row.minimum_shell_count = local_first_or_zero(minimum_sub, 'count_total');
row.reported_near_optimal_count = local_first_or_zero(near_sub, 'count_total');
row.candidate_count = local_first_or_zero(candidate_sub, 'count_total');
row.feasible_candidate_count = local_first_or_zero(candidate_sub, 'count_feasible');
row.near_optimal_by_size_count = local_first_or_zero(candidate_sub, 'count_near_by_size');
row.near_optimal_by_margin_count = local_first_or_zero(candidate_sub, 'count_near_by_margin');
row.best_joint_margin = local_first_or_nan(candidate_sub, 'best_joint_margin');
row.shell_status = local_shell_status(row);
end

function status = local_shell_status(row)
if row.is_minimum_shell
    status = "minimum_shell";
elseif row.near_optimal_by_margin_count > 0
    status = "near_optimal_by_margin";
elseif row.near_optimal_by_size_count > 0
    status = "near_optimal_by_size";
elseif row.feasible_candidate_count > 0
    status = "feasible_shell_only";
else
    status = "no_feasible_extension";
end
end

function summary = local_build_summary(summary_table, candidate_table, minimum_unique, near_optimal_unique, Ns_min, shell_ns_values)
summary = local_empty_summary();
summary.Ns_min = Ns_min;
summary.shell_ns_checked = shell_ns_values;
summary.minimum_shell_count = height(minimum_unique);
summary.reported_near_optimal_count = height(near_optimal_unique);
summary.num_shell_candidates = height(candidate_table);
summary.num_feasible_shell_candidates = sum(local_get_logical_column(candidate_table, 'joint_feasible', false));
summary.num_near_optimal_by_size = sum(local_get_logical_column(candidate_table, 'near_optimal_by_size', false));
summary.num_near_optimal_by_margin = sum(local_get_logical_column(candidate_table, 'near_optimal_by_margin', false));
summary.shells_with_feasible_extension = local_collect_shells(summary_table, 'feasible_candidate_count');
summary.shells_with_margin_near_optimal = local_collect_shells(summary_table, 'near_optimal_by_margin_count');
summary.shells_with_size_near_optimal = local_collect_shells(summary_table, 'near_optimal_by_size_count');
if isempty(summary.shells_with_margin_near_optimal) && isempty(summary.shells_with_size_near_optimal)
    summary.conclusion = "In the current shell-neighborhood check, the near-optimal region still collapses to the minimum shell.";
else
    summary.conclusion = "Current stage12E near-optimal extraction still stops at the minimum shell, but shell-neighborhood diagnostics detect feasible and margin-near-optimal extensions beyond Ns_min.";
end
end

function shells = local_collect_shells(summary_table, field_name)
shells = [];
if isempty(summary_table) || ~ismember(field_name, summary_table.Properties.VariableNames)
    return;
end
mask = summary_table.(field_name) > 0 & ~summary_table.is_minimum_shell;
shells = summary_table.Ns(mask).';
end

function fig = local_plot_shell_phasecurve(summary_table, candidate_table, minimum_unique, style)
fig = figure('Visible', 'off', 'Color', 'w');
tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

ax1 = nexttile;
hold(ax1, 'on');
if isempty(summary_table)
    plot(ax1, 0, 0, 'o', 'Color', style.colors(1, :));
else
    bar(ax1, summary_table.Ns, summary_table.feasible_candidate_count, 'FaceColor', style.colors(1, :), 'FaceAlpha', 0.85);
    xline(ax1, summary_table.Ns(summary_table.is_minimum_shell), '--', 'Color', style.threshold_color, 'LineWidth', 1.1);
end
xlabel(ax1, 'N_s');
ylabel(ax1, 'Feasible candidate count');
title(ax1, 'Near-Optimal Shell Feasible Counts');
grid(ax1, 'on');
hold(ax1, 'off');

ax2 = nexttile;
hold(ax2, 'on');
distribution_table = local_build_margin_distribution_table(candidate_table, minimum_unique);
if isempty(distribution_table)
    plot(ax2, 0, 0, 'o', 'Color', style.colors(2, :));
else
    boxchart(ax2, categorical(string(distribution_table.Ns)), distribution_table.joint_margin, ...
        'BoxFaceColor', style.colors(2, :), ...
        'WhiskerLineColor', style.threshold_color);
end
xlabel(ax2, 'N_s');
ylabel(ax2, 'Joint margin');
title(ax2, 'Shell Margin Distribution');
grid(ax2, 'on');
hold(ax2, 'off');
end

function summary = local_empty_summary()
summary = struct( ...
    'Ns_min', NaN, ...
    'shell_ns_checked', [], ...
    'minimum_shell_count', 0, ...
    'reported_near_optimal_count', 0, ...
    'num_shell_candidates', 0, ...
    'num_feasible_shell_candidates', 0, ...
    'num_near_optimal_by_size', 0, ...
    'num_near_optimal_by_margin', 0, ...
    'shells_with_feasible_extension', [], ...
    'shells_with_margin_near_optimal', [], ...
    'shells_with_size_near_optimal', [], ...
    'conclusion', "");
end

function values = local_get_logical_column(T, name, default_value)
if isempty(T)
    values = false(0, 1);
    return;
end
if ismember(name, T.Properties.VariableNames)
    values = logical(T.(name));
else
    values = repmat(logical(default_value), height(T), 1);
end
end

function value = local_first_or_zero(T, field_name)
value = 0;
if ~isempty(T) && ismember(field_name, T.Properties.VariableNames)
    value = T.(field_name)(1);
end
end

function value = local_first_or_nan(T, field_name)
value = NaN;
if ~isempty(T) && ismember(field_name, T.Properties.VariableNames)
    value = T.(field_name)(1);
end
end

function value = local_safe_max(T, field_name)
value = NaN;
if isempty(T) || ~ismember(field_name, T.Properties.VariableNames)
    return;
end
values = T.(field_name);
values = values(isfinite(values));
if ~isempty(values)
    value = max(values);
end
end

function T = local_build_margin_distribution_table(candidate_table, minimum_unique)
T = table();
rows = {};
if ~isempty(minimum_unique) && ismember('joint_margin', minimum_unique.Properties.VariableNames)
    rows{end + 1, 1} = minimum_unique(:, {'Ns', 'joint_margin'});
end
if ~isempty(candidate_table) && ismember('joint_feasible', candidate_table.Properties.VariableNames) && ismember('joint_margin', candidate_table.Properties.VariableNames)
    sub = candidate_table(logical(candidate_table.joint_feasible), {'Ns', 'joint_margin'});
    if ~isempty(sub)
        rows{end + 1, 1} = sub;
    end
end
if ~isempty(rows)
    T = vertcat(rows{:});
end
end
