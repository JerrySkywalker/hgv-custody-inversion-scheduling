function out = run_milestone_B_semantic_compare(cfg, interactive)
%RUN_MILESTONE_B_SEMANTIC_COMPARE CLI entry for MB semantic comparison.
%
% Usage:
%   out = run_milestone_B_semantic_compare()
%   out = run_milestone_B_semantic_compare(cfg, false)
%
% Interactive mode supports:
%   - mode: legacyDG / closedD / comparison / all
%   - sensor groups: baseline / optimistic / robust / all / comma list
%   - baseline validation shortcut (default yes, uses h = 1000 km)
%   - heights: validation / default / custom
%   - family set: nominal / heading / critical / all / comma list
%   - dense local refinement, fast mode, resume checkpoint

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = milestone_common_defaults();
    else
        cfg = milestone_common_defaults(cfg);
    end
    if nargin < 2 || isempty(interactive)
        interactive = (nargin == 0);
    end

    [cfg, selection] = mb_cli_configure_search_profile(cfg, interactive);
    if interactive
        cfg = local_configure_runtime(cfg, selection);
    end
    cfg = local_apply_auto_tune_if_requested(cfg, interactive);

    sensor_groups = resolve_sensor_param_groups(cfg.milestones.MB_semantic_compare.sensor_groups);
    sensor_labels = cellfun(@(name) char(format_mb_sensor_group_label(name, "short")), sensor_groups, 'UniformOutput', false);
    profile_label = char(format_mb_search_profile_label(local_build_effective_profile_from_cfg(cfg), cfg, "detailed"));

    fprintf('[run_stages] === MB semantic compare ===\n');
    fprintf('[run_stages] profile=%s | mode=%s | sensor_groups=%s | heights=%s | families=%s | dense_local=%s | fast_mode=%s\n', ...
        char(string(cfg.milestones.MB_semantic_compare.search_profile)), ...
        char(string(cfg.milestones.MB_semantic_compare.mode)), ...
        strjoin(sensor_groups, ','), ...
        mat2str(cfg.milestones.MB_semantic_compare.heights_to_run), ...
        strjoin(cellstr(string(cfg.milestones.MB_semantic_compare.family_set)), ','), ...
        char(string(logical(cfg.milestones.MB_semantic_compare.run_dense_local))), ...
        char(string(logical(cfg.milestones.MB_semantic_compare.fast_mode))));
    fprintf('[run_stages] profile detail: %s\n', profile_label);
    fprintf('[run_stages] sensor detail: %s\n', strjoin(sensor_labels, ' | '));

    out = milestone_B_semantic_compare(cfg);
    fprintf('[run_stages] MB semantic compare complete: status=%s\n', char(string(out.summary.execution_status)));
end

function cfg = local_apply_auto_tune_if_requested(cfg, interactive)
    meta = cfg.milestones.MB_semantic_compare;
    auto_tune_mode = local_resolve_auto_tune_mode(meta);
    if strcmpi(auto_tune_mode, 'off') || ~isfield(meta, 'auto_tune') || ~logical(local_getfield_or(meta.auto_tune, 'enabled', false))
        return;
    end

    resolved_groups = resolve_sensor_param_groups(local_getfield_or(meta, 'sensor_groups', {'baseline'}));
    if isempty(resolved_groups)
        return;
    end
    sensor_group = resolved_groups{1};
    heights = reshape(local_getfield_or(meta, 'heights_to_run', 1000), 1, []);
    families = cellstr(string(local_getfield_or(meta, 'family_set', {'nominal'})));
    paths = mb_output_paths(cfg, meta.milestone_id, meta.title);
    semantic_modes = local_resolve_autotune_semantic_modes(local_getfield_or(meta, 'mode', 'legacyDG'));
    tune_results = repmat(struct('semantic_mode', "", 'result', struct(), 'probe', struct()), numel(semantic_modes), 1);
    for idx_mode = 1:numel(semantic_modes)
        probe = struct();
        probe.sensor_group = sensor_group;
        probe.height_km = heights(1);
        probe.family_name = families{1};
        probe.semantic_mode = semantic_modes{idx_mode};

        fprintf('[run_stages][AUTO-TUNE] probing %s | sensor=%s | h=%.0f km | family=%s\n', ...
            probe.semantic_mode, probe.sensor_group, probe.height_km, probe.family_name);

        profile = struct( ...
            'name', string(local_getfield_or(meta, 'search_profile', 'mb_auto_plot_tune')), ...
            'semantic_mode', string(probe.semantic_mode), ...
            'sensor_group_names', {{probe.sensor_group}}, ...
            'height_grid_km', probe.height_km, ...
            'inclination_grid_deg', reshape(local_getfield_or(meta, 'i_grid_deg', []), 1, []), ...
            'P_grid', reshape(local_getfield_or(meta, 'P_grid', []), 1, []), ...
            'T_grid', reshape(local_getfield_or(meta, 'T_grid', []), 1, []), ...
            'P_values', reshape(local_getfield_or(meta, 'P_grid', []), 1, []), ...
            'T_values', reshape(local_getfield_or(meta, 'T_grid', []), 1, []), ...
            'plot_xlim_ns', local_getfield_or(meta, 'plot_xlim_ns', []), ...
            'Ns_xlim_plot', local_getfield_or(meta, 'plot_xlim_ns', []), ...
            'auto_tune', meta.auto_tune, ...
            'cache', meta.cache_profile);

        probe_phasecurve = local_build_autotune_probe_phasecurve(cfg, meta, probe, profile.P_values, profile.T_values);
        evaluator_fn = @(candidate) local_build_autotune_probe_phasecurve(cfg, meta, probe, candidate.P_values, candidate.T_values);
        tune_result = autotune_mb_passratio_plot_window(profile, probe_phasecurve, struct( ...
            'semantic_mode', probe.semantic_mode, ...
            'sensor_group', probe.sensor_group, ...
            'height_km', probe.height_km, ...
            'auto_tune', milestone_common_merge_structs(meta.auto_tune, struct('mode', string(auto_tune_mode))), ...
            'cache', meta.cache_profile, ...
            'cache_dir', paths.cache, ...
            'tables_dir', paths.tables, ...
            'evaluator_fn', evaluator_fn));

        fprintf('[run_stages][AUTO-TUNE] %s state=%s | best=%s | xlim=%s | P=%s | T=%s | score=%.2f\n', ...
            probe.semantic_mode, ...
            char(string(tune_result.state)), ...
            char(string(tune_result.best_candidate_name)), ...
            mat2str(tune_result.recommended_plot_xlim_ns), ...
            mat2str(tune_result.recommended_P_grid), ...
            mat2str(tune_result.recommended_T_grid), ...
            tune_result.best_score);

        tune_results(idx_mode, 1).semantic_mode = string(probe.semantic_mode);
        tune_results(idx_mode, 1).result = tune_result;
        tune_results(idx_mode, 1).probe = probe;
    end

    tune_result = local_combine_autotune_results(tune_results);

    apply_recommendation = strcmpi(auto_tune_mode, 'iterative_recommend_and_apply') || logical(local_getfield_or(meta, 'auto_tune_apply', false));
    if interactive && ~strcmpi(auto_tune_mode, 'iterative_recommend_and_apply') && ~strcmpi(auto_tune_mode, 'evaluate_only')
        apply_recommendation = local_ask_yesno('apply auto-tune recommendation', apply_recommendation);
    end

    meta.auto_tune_probe = {tune_results.probe};
    meta.auto_tune_result = local_compact_tune_result(tune_result);
    meta.auto_tune.mode = string(auto_tune_mode);
    meta.auto_tune_apply = apply_recommendation;
    meta.auto_tuned_flag = false;
    if apply_recommendation
        meta.P_grid = tune_result.recommended_P_grid;
        meta.T_grid = tune_result.recommended_T_grid;
        meta.plot_xlim_ns = tune_result.recommended_plot_xlim_ns;
        meta.auto_tuned_flag = true;
    end
    cfg.milestones.MB_semantic_compare = meta;
end

function cfg = local_configure_runtime(cfg, selection)
    meta = cfg.milestones.MB_semantic_compare;
    fprintf('[run_stages][CLI] 当前 search profile: %s\n', char(string(selection.profile_name)));
    family_token = local_ask_csv_token('family set', strjoin(cellstr(string(meta.family_set)), ','), {'nominal', 'heading', 'critical', 'all'});
    run_dense_local = local_ask_yesno('run dense local refinement', logical(meta.run_dense_local));
    fast_mode = local_ask_yesno('fast mode', logical(meta.fast_mode));
    resume_checkpoint = local_ask_yesno('resume checkpoint', logical(meta.resume_checkpoint));

    cfg.milestones.MB_semantic_compare.family_set = local_parse_csv_cell(family_token);
    cfg.milestones.MB_semantic_compare.run_dense_local = run_dense_local;
    cfg.milestones.MB_semantic_compare.fast_mode = fast_mode;
    cfg.milestones.MB_semantic_compare.resume_checkpoint = resume_checkpoint;
end

function phasecurve_table = local_build_autotune_probe_phasecurve(cfg, meta, probe, P_grid, T_grid)
    common_options = struct( ...
        'sensor_group', probe.sensor_group, ...
        'heights_to_run', probe.height_km, ...
        'family_set', {{probe.family_name}}, ...
        'i_grid_deg', reshape(local_getfield_or(meta, 'i_grid_deg', []), 1, []), ...
        'P_grid', reshape(P_grid, 1, []), ...
        'T_grid', reshape(T_grid, 1, []), ...
        'F_fixed', local_getfield_or(meta, 'F_fixed', 1), ...
        'use_parallel', false);

    switch lower(char(string(probe.semantic_mode)))
        case 'legacydg'
            out = run_mb_legacydg_semantics(cfg, common_options);
        case 'closedd'
            out = run_mb_closedd_semantics(cfg, common_options);
        otherwise
            error('Auto-tune currently supports legacyDG or closedD, got: %s', probe.semantic_mode);
    end

    if isempty(out.runs)
        phasecurve_table = table();
    else
        phasecurve_table = out.runs(1).aggregate.passratio_phasecurve;
    end
end

function modes = local_resolve_autotune_semantic_modes(mode_in)
    mode = lower(char(string(mode_in)));
    switch mode
        case 'legacydg'
            modes = {'legacyDG'};
        case 'closedd'
            modes = {'closedD'};
        otherwise
            modes = {'legacyDG', 'closedD'};
    end
end

function compact = local_compact_tune_result(tune_result)
    compact = struct( ...
        'best_candidate_name', string(local_getfield_or(tune_result, 'best_candidate_name', "")), ...
        'recommended_plot_xlim_ns', reshape(local_getfield_or(tune_result, 'recommended_plot_xlim_ns', []), 1, []), ...
        'recommended_P_grid', reshape(local_getfield_or(tune_result, 'recommended_P_grid', []), 1, []), ...
        'recommended_T_grid', reshape(local_getfield_or(tune_result, 'recommended_T_grid', []), 1, []), ...
        'recommended_reason', string(local_getfield_or(tune_result, 'recommended_reason', "")), ...
        'best_score', local_getfield_or(tune_result, 'best_score', NaN), ...
        'auto_tune_mode', string(local_getfield_or(tune_result, 'auto_tune_mode', "")), ...
        'state', string(local_getfield_or(tune_result, 'state', "")), ...
        'stop_reason', string(local_getfield_or(tune_result, 'stop_reason', "")), ...
        'unresolved_due_to_search_limit', logical(local_getfield_or(tune_result, 'unresolved_due_to_search_limit', false)), ...
        'iteration_history_csv', string(local_getfield_or(tune_result, 'iteration_history_csv', "")), ...
        'summary_csv', string(local_getfield_or(tune_result, 'summary_csv', "")), ...
        'summary_row', local_getfield_or(tune_result, 'summary_row', table()), ...
        'stats', local_getfield_or(tune_result, 'stats', struct()));
    if isfield(tune_result, 'legacyDG_result')
        compact.legacyDG_state = string(local_getfield_or(tune_result.legacyDG_result, 'state', ""));
        compact.legacyDG_iteration_history_csv = string(local_getfield_or(tune_result.legacyDG_result, 'iteration_history_csv', ""));
        compact.legacyDG_summary_csv = string(local_getfield_or(tune_result.legacyDG_result, 'summary_csv', ""));
        compact.legacyDG_best_score = local_getfield_or(tune_result.legacyDG_result, 'best_score', NaN);
    end
    if isfield(tune_result, 'closedD_result')
        compact.closedD_state = string(local_getfield_or(tune_result.closedD_result, 'state', ""));
        compact.closedD_iteration_history_csv = string(local_getfield_or(tune_result.closedD_result, 'iteration_history_csv', ""));
        compact.closedD_summary_csv = string(local_getfield_or(tune_result.closedD_result, 'summary_csv', ""));
        compact.closedD_best_score = local_getfield_or(tune_result.closedD_result, 'best_score', NaN);
    end
end

function combined = local_combine_autotune_results(tune_results)
if numel(tune_results) == 1
    combined = tune_results(1).result;
    return;
end

P_all = [];
T_all = [];
x_left = [];
x_right = [];
states = strings(numel(tune_results), 1);
reasons = strings(numel(tune_results), 1);
cache_hits = 0;
fresh_evaluations = 0;
total_iterations = 0;
best_scores = nan(numel(tune_results), 1);
history_csvs = strings(numel(tune_results), 1);

combined = struct();
for idx = 1:numel(tune_results)
    semantic_mode = char(string(tune_results(idx).semantic_mode));
    res = tune_results(idx).result;
    P_all = unique([P_all, reshape(local_getfield_or(res, 'recommended_P_grid', []), 1, [])], 'sorted');
    T_all = unique([T_all, reshape(local_getfield_or(res, 'recommended_T_grid', []), 1, [])], 'sorted');
    xlim_ns = reshape(local_getfield_or(res, 'recommended_plot_xlim_ns', []), 1, []);
    if numel(xlim_ns) == 2
        x_left(end + 1) = xlim_ns(1); %#ok<AGROW>
        x_right(end + 1) = xlim_ns(2); %#ok<AGROW>
    end
    states(idx) = string(local_getfield_or(res, 'state', ""));
    reasons(idx) = string(local_getfield_or(res, 'stop_reason', ""));
    stats = local_getfield_or(res, 'stats', struct());
    cache_hits = cache_hits + local_getfield_or(stats, 'cache_hits', 0);
    fresh_evaluations = fresh_evaluations + local_getfield_or(stats, 'fresh_evaluations', 0);
    total_iterations = total_iterations + local_getfield_or(stats, 'total_iterations', 0);
    best_scores(idx) = local_getfield_or(res, 'best_score', NaN);
    history_csvs(idx) = string(local_getfield_or(res, 'iteration_history_csv', ""));
    combined.([semantic_mode '_result']) = res;
end

combined.profile_name = "comparison_shared_autotune";
combined.semantic_mode = "comparison";
combined.sensor_group = tune_results(1).result.sensor_group;
combined.height_km = tune_results(1).result.height_km;
combined.recommended_P_grid = reshape(P_all, 1, []);
combined.recommended_T_grid = reshape(T_all, 1, []);
if ~isempty(x_left) && ~isempty(x_right)
    combined.recommended_plot_xlim_ns = [min(x_left), max(x_right)];
else
    combined.recommended_plot_xlim_ns = [];
end
combined.recommended_reason = "Shared comparison domain assembled from legacyDG and closedD iterative autotune results.";
combined.best_score = min(best_scores, [], 'omitnan');
combined.best_candidate_name = "comparison_shared_domain";
combined.state = local_combine_states(states);
combined.stop_reason = strjoin(unique(reasons(reasons ~= "")), " | ");
combined.unresolved_due_to_search_limit = any(strcmpi(states, 'limit_reached'));
combined.stats = struct( ...
    'cache_hits', cache_hits, ...
    'fresh_evaluations', fresh_evaluations, ...
    'total_iterations', total_iterations);
combined.iteration_history_csv = strjoin(cellstr(history_csvs(history_csvs ~= "")), ', ');
end

function state = local_combine_states(states)
if all(strcmpi(states, 'success'))
    state = "success";
elseif any(strcmpi(states, 'limit_reached'))
    state = "limit_reached";
elseif any(strcmpi(states, 'stalled'))
    state = "stalled";
else
    state = "mixed";
end
end

function token = local_ask_csv_token(name, default_val, allowed_values)
    prompt = sprintf('%s [%s] options=%s: ', name, default_val, strjoin(allowed_values, '/'));
    s = input(prompt, 's');
    if isempty(strtrim(s))
        token = default_val;
        return;
    end
    parts = local_parse_csv_cell(s);
    if any(strcmpi(parts, 'all'))
        token = 'all';
        return;
    end
    for idx = 1:numel(parts)
        if ~any(strcmpi(parts{idx}, allowed_values))
            warning('%s 输入非法，保留默认值。', name);
            token = default_val;
            return;
        end
    end
    token = strjoin(parts, ',');
end

function value = local_ask_yesno(name, default_val)
    if default_val
        default_token = 'y';
    else
        default_token = 'n';
    end
    s = input(sprintf('%s [y/n, default=%s]: ', name, default_token), 's');
    if isempty(strtrim(s))
        value = logical(default_val);
        return;
    end
    s = lower(strtrim(s));
    if any(strcmp(s, {'y', 'yes', '1'}))
        value = true;
    elseif any(strcmp(s, {'n', 'no', '0'}))
        value = false;
    else
        warning('%s 输入非法，保留默认值。', name);
        value = logical(default_val);
    end
end

function value = local_getfield_or(S, field_name, fallback)
    if isstruct(S) && isfield(S, field_name)
        value = S.(field_name);
    else
        value = fallback;
    end
end

function mode = local_resolve_auto_tune_mode(meta)
mode = char(string(local_getfield_or(local_getfield_or(meta, 'auto_tune', struct()), 'mode', "off")));
if strcmpi(mode, 'off') && logical(local_getfield_or(local_getfield_or(meta, 'auto_tune', struct()), 'enabled', false))
    if logical(local_getfield_or(meta, 'auto_tune_apply', false))
        mode = 'iterative_recommend_and_apply';
    else
        mode = 'iterative_recommend_only';
    end
end
end

function profile = local_build_effective_profile_from_cfg(cfg)
meta = cfg.milestones.MB_semantic_compare;
profile = struct( ...
    'name', string(local_getfield_or(meta, 'search_profile', "mb_default")), ...
    'description', string(local_getfield_or(meta, 'search_profile_description', "")), ...
    'semantic_mode', string(local_getfield_or(meta, 'mode', "")), ...
    'sensor_group_names', {cellstr(string(local_getfield_or(meta, 'sensor_groups', {'baseline'})))}, ...
    'height_grid_km', reshape(local_getfield_or(meta, 'heights_to_run', []), 1, []), ...
    'inclination_grid_deg', reshape(local_getfield_or(meta, 'i_grid_deg', []), 1, []), ...
    'P_grid', reshape(local_getfield_or(meta, 'P_grid', []), 1, []), ...
    'T_grid', reshape(local_getfield_or(meta, 'T_grid', []), 1, []), ...
    'P_values', reshape(local_getfield_or(meta, 'P_grid', []), 1, []), ...
    'T_values', reshape(local_getfield_or(meta, 'T_grid', []), 1, []), ...
    'plot_xlim_ns', reshape(local_getfield_or(meta, 'plot_xlim_ns', []), 1, []), ...
    'Ns_xlim_plot', reshape(local_getfield_or(meta, 'plot_xlim_ns', []), 1, []), ...
    'stage05_replica', local_getfield_or(meta, 'stage05_replica', struct()));
end

function parts = local_parse_csv_cell(token)
    raw = split(string(token), ',');
    raw = strtrim(raw);
    raw = raw(raw ~= "");
    if isempty(raw)
        parts = {'baseline'};
        return;
    end
    parts = cellstr(raw(:).');
end
