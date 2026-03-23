function plan = resolve_mb_export_plot_plan(cfg_or_meta)
%RESOLVE_MB_EXPORT_PLOT_PLAN Resolve export modes, primary aliases, and heatmap scopes.

profile = resolve_mb_plot_mode_profile(cfg_or_meta);
plotting_cfg = local_extract_plotting_cfg(cfg_or_meta);

plan = struct();
plan.manager_name = "MB_export_plot_plan";
plan.manager_version = "mb-export-plan-v1";
plan.passratio_modes = reshape(string(local_resolve_modes( ...
    ["historyFull", "effectiveFullRange", "globalFullReplay", "frontierZoom"], ...
    profile.passratio_primary_mode, ...
    logical(local_getfield_or(plotting_cfg, 'export_all_passratio_views', profile.export_all_passratio_modes)), ...
    struct( ...
        'historyFull', logical(local_getfield_or(plotting_cfg, 'export_history_full', true)), ...
        'effectiveFullRange', logical(local_getfield_or(plotting_cfg, 'export_effective_full_range', true)), ...
        'globalFullReplay', logical(local_getfield_or(plotting_cfg, 'export_global_full_replay', true)), ...
        'frontierZoom', logical(local_getfield_or(plotting_cfg, 'export_frontier_zoom', true))))), 1, []);
plan.comparison_modes = reshape(string(local_resolve_modes( ...
    ["historyFull", "effectiveFullRange", "globalFullReplay", "frontierZoom"], ...
    profile.comparison_primary_mode, ...
    logical(local_getfield_or(plotting_cfg, 'export_all_passratio_views', profile.export_all_passratio_modes)), ...
    struct( ...
        'historyFull', logical(local_getfield_or(plotting_cfg, 'export_history_full', true)), ...
        'effectiveFullRange', logical(local_getfield_or(plotting_cfg, 'export_effective_full_range', true)), ...
        'globalFullReplay', logical(local_getfield_or(plotting_cfg, 'export_global_full_replay', true)), ...
        'frontierZoom', logical(local_getfield_or(plotting_cfg, 'export_frontier_zoom', true))))), 1, []);
plan.cross_profile_modes = reshape(string(local_resolve_modes( ...
    ["historyFull", "effectiveFullRange", "globalFullReplay", "frontierZoom"], ...
    profile.cross_profile_primary_mode, ...
    logical(local_getfield_or(plotting_cfg, 'export_all_passratio_views', profile.export_all_passratio_modes)), ...
    struct( ...
        'historyFull', logical(local_getfield_or(plotting_cfg, 'export_history_full', true)), ...
        'effectiveFullRange', logical(local_getfield_or(plotting_cfg, 'export_effective_full_range', true)), ...
        'globalFullReplay', logical(local_getfield_or(plotting_cfg, 'export_global_full_replay', true)), ...
        'frontierZoom', logical(local_getfield_or(plotting_cfg, 'export_frontier_zoom', true))))), 1, []);
plan.primary_passratio_view = string(local_getfield_or(plotting_cfg, 'primary_passratio_view', profile.passratio_primary_mode));
plan.primary_comparison_view = profile.comparison_primary_mode;
plan.primary_cross_profile_view = profile.cross_profile_primary_mode;
plan.primary_heatmap_scope = string(local_getfield_or(plotting_cfg, 'primary_heatmap_scope', profile.heatmap_primary_domain_mode));
plan.primary_heatmap_value_mode = profile.heatmap_primary_value_mode;
plan.heatmap_scopes = reshape(string(local_resolve_heatmap_scopes(plotting_cfg, profile)), 1, []);
plan.export_all_passratio_views = logical(local_getfield_or(plotting_cfg, 'export_all_passratio_views', profile.export_all_passratio_modes));
plan.export_all_heatmap_scopes = logical(local_getfield_or(plotting_cfg, 'export_all_heatmap_scopes', profile.export_all_heatmap_modes));
end

function modes = local_resolve_modes(all_modes, primary_mode, export_all_modes, mode_flags)
if export_all_modes
    mask = false(size(all_modes));
    for idx = 1:numel(all_modes)
        key = char(all_modes(idx));
        if isfield(mode_flags, key)
            mask(idx) = logical(mode_flags.(key));
        end
    end
    modes = all_modes(mask);
else
    modes = string(primary_mode);
end
if isempty(modes)
    modes = string(primary_mode);
end
if ~any(modes == string(primary_mode))
    modes = [string(primary_mode), reshape(string(modes), 1, [])];
end
modes = unique(modes, 'stable');
end

function scopes = local_resolve_heatmap_scopes(plotting_cfg, profile)
if logical(local_getfield_or(plotting_cfg, 'export_all_heatmap_scopes', profile.export_all_heatmap_modes))
    scopes = ["local", "globalReplay"];
else
    scopes = string(local_getfield_or(plotting_cfg, 'primary_heatmap_scope', profile.heatmap_primary_domain_mode));
end
scopes = unique(scopes, 'stable');
end

function plotting_cfg = local_extract_plotting_cfg(cfg_or_meta)
plotting_cfg = struct();
if ~isstruct(cfg_or_meta)
    return;
end
if isfield(cfg_or_meta, 'milestones') && isstruct(cfg_or_meta.milestones) && ...
        isfield(cfg_or_meta.milestones, 'MB_plotting') && isstruct(cfg_or_meta.milestones.MB_plotting)
    plotting_cfg = cfg_or_meta.milestones.MB_plotting;
elseif isfield(cfg_or_meta, 'MB_plotting') && isstruct(cfg_or_meta.MB_plotting)
    plotting_cfg = cfg_or_meta.MB_plotting;
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
