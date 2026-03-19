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

    fprintf('[run_stages] === MB semantic compare ===\n');
    fprintf('[run_stages] profile=%s | mode=%s | sensor_groups=%s | heights=%s | families=%s | dense_local=%s | fast_mode=%s\n', ...
        char(string(cfg.milestones.MB_semantic_compare.search_profile)), ...
        char(string(cfg.milestones.MB_semantic_compare.mode)), ...
        strjoin(resolve_sensor_param_groups(cfg.milestones.MB_semantic_compare.sensor_groups), ','), ...
        mat2str(cfg.milestones.MB_semantic_compare.heights_to_run), ...
        strjoin(cellstr(string(cfg.milestones.MB_semantic_compare.family_set)), ','), ...
        char(string(logical(cfg.milestones.MB_semantic_compare.run_dense_local))), ...
        char(string(logical(cfg.milestones.MB_semantic_compare.fast_mode))));

    out = milestone_B_semantic_compare(cfg);
    fprintf('[run_stages] MB semantic compare complete: status=%s\n', char(string(out.summary.execution_status)));
end

function cfg = local_apply_auto_tune_if_requested(cfg, interactive)
    meta = cfg.milestones.MB_semantic_compare;
    if ~isfield(meta, 'auto_tune') || ~logical(local_getfield_or(meta.auto_tune, 'enabled', false))
        return;
    end

    resolved_groups = resolve_sensor_param_groups(local_getfield_or(meta, 'sensor_groups', {'baseline'}));
    if isempty(resolved_groups)
        return;
    end
    sensor_group = resolved_groups{1};
    heights = reshape(local_getfield_or(meta, 'heights_to_run', 1000), 1, []);
    families = cellstr(string(local_getfield_or(meta, 'family_set', {'nominal'})));
    probe = struct();
    probe.sensor_group = sensor_group;
    probe.height_km = heights(1);
    probe.family_name = families{1};
    probe.semantic_mode = local_resolve_autotune_semantic_mode(local_getfield_or(meta, 'mode', 'legacyDG'));

    fprintf('[run_stages][AUTO-TUNE] probing %s | sensor=%s | h=%.0f km | family=%s\n', ...
        probe.semantic_mode, probe.sensor_group, probe.height_km, probe.family_name);

    paths = mb_output_paths(cfg, meta.milestone_id, meta.title);
    probe_phasecurve = local_build_autotune_probe_phasecurve(cfg, meta, probe, meta.P_grid, meta.T_grid);
    profile = struct( ...
        'name', string(local_getfield_or(meta, 'search_profile', 'mb_auto_plot_tune')), ...
        'semantic_mode', string(probe.semantic_mode), ...
        'sensor_group_names', {{probe.sensor_group}}, ...
        'height_grid_km', probe.height_km, ...
        'inclination_grid_deg', reshape(local_getfield_or(meta, 'i_grid_deg', []), 1, []), ...
        'P_grid', reshape(local_getfield_or(meta, 'P_grid', []), 1, []), ...
        'T_grid', reshape(local_getfield_or(meta, 'T_grid', []), 1, []), ...
        'plot_xlim_ns', local_getfield_or(meta, 'plot_xlim_ns', []), ...
        'auto_tune', meta.auto_tune, ...
        'cache', meta.cache_profile);

    evaluator_fn = @(candidate) local_build_autotune_probe_phasecurve(cfg, meta, probe, candidate.P_grid, candidate.T_grid);
    tune_result = autotune_mb_passratio_plot_window(profile, probe_phasecurve, struct( ...
        'semantic_mode', probe.semantic_mode, ...
        'sensor_group', probe.sensor_group, ...
        'height_km', probe.height_km, ...
        'auto_tune', meta.auto_tune, ...
        'cache', meta.cache_profile, ...
        'cache_dir', paths.cache, ...
        'evaluator_fn', evaluator_fn));

    fprintf('[run_stages][AUTO-TUNE] best=%s | xlim=%s | P=%s | T=%s | score=%.2f\n', ...
        char(string(tune_result.best_candidate_name)), ...
        mat2str(tune_result.recommended_plot_xlim_ns), ...
        mat2str(tune_result.recommended_P_grid), ...
        mat2str(tune_result.recommended_T_grid), ...
        tune_result.best_score);

    apply_recommendation = logical(local_getfield_or(meta, 'auto_tune_apply', false));
    if interactive
        apply_recommendation = local_ask_yesno('apply auto-tune recommendation', apply_recommendation);
    end

    meta.auto_tune_probe = probe;
    meta.auto_tune_result = local_compact_tune_result(tune_result);
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

function mode = local_resolve_autotune_semantic_mode(mode_in)
    mode = lower(char(string(mode_in)));
    if strcmp(mode, 'comparison')
        mode = 'legacyDG';
    end
end

function compact = local_compact_tune_result(tune_result)
    compact = struct( ...
        'best_candidate_name', string(tune_result.best_candidate_name), ...
        'recommended_plot_xlim_ns', reshape(tune_result.recommended_plot_xlim_ns, 1, []), ...
        'recommended_P_grid', reshape(tune_result.recommended_P_grid, 1, []), ...
        'recommended_T_grid', reshape(tune_result.recommended_T_grid, 1, []), ...
        'recommended_reason', string(tune_result.recommended_reason), ...
        'best_score', tune_result.best_score, ...
        'stats', tune_result.stats);
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
