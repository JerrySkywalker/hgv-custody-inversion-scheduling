function profile = resolve_mb_plot_mode_profile(cfg_or_meta)
%RESOLVE_MB_PLOT_MODE_PROFILE Resolve unified MB plotting semantics profile.

plotting_cfg = local_extract_plotting_cfg(cfg_or_meta);

profile = struct();
profile.passratio_primary_mode = local_normalize_passratio_mode( ...
    local_getfield_or(plotting_cfg, 'passratio_primary_mode', "effectiveFullRange"));
profile.comparison_primary_mode = local_normalize_passratio_mode( ...
    local_getfield_or(plotting_cfg, 'comparison_primary_mode', profile.passratio_primary_mode));
profile.cross_profile_primary_mode = local_normalize_passratio_mode( ...
    local_getfield_or(plotting_cfg, 'cross_profile_primary_mode', profile.passratio_primary_mode));
profile.heatmap_primary_value_mode = local_normalize_heatmap_value_mode( ...
    local_getfield_or(plotting_cfg, 'heatmap_primary_value_mode', "numeric_requirement"));
profile.heatmap_primary_domain_mode = local_normalize_heatmap_domain_mode( ...
    local_getfield_or(plotting_cfg, 'heatmap_primary_domain_mode', "globalSkeleton"));
profile.export_all_passratio_modes = logical(local_getfield_or(plotting_cfg, 'export_all_passratio_modes', true));
profile.export_all_heatmap_modes = logical(local_getfield_or(plotting_cfg, 'export_all_heatmap_modes', true));
profile.canonical_primary_mode = local_normalize_passratio_mode( ...
    local_getfield_or(plotting_cfg, 'canonical_primary_mode', profile.passratio_primary_mode));
profile.diagnostic_export_full_bundle = logical(local_getfield_or(plotting_cfg, 'diagnostic_export_full_bundle', true));

profile.supported_passratio_modes = ["historyFull", "effectiveFullRange", "frontierZoom"];
profile.supported_heatmap_value_modes = ["numeric_requirement", "state_map"];
profile.supported_heatmap_domain_modes = ["local", "globalSkeleton"];
profile.passratio_export_modes = local_resolve_export_modes(profile.supported_passratio_modes, ...
    profile.passratio_primary_mode, profile.export_all_passratio_modes || profile.diagnostic_export_full_bundle);
profile.comparison_export_modes = local_resolve_export_modes(profile.supported_passratio_modes, ...
    profile.comparison_primary_mode, profile.export_all_passratio_modes || profile.diagnostic_export_full_bundle);
profile.cross_profile_export_modes = local_resolve_export_modes(profile.supported_passratio_modes, ...
    profile.cross_profile_primary_mode, profile.export_all_passratio_modes || profile.diagnostic_export_full_bundle);
profile.heatmap_export_value_modes = local_resolve_export_modes(profile.supported_heatmap_value_modes, ...
    profile.heatmap_primary_value_mode, profile.export_all_heatmap_modes || profile.diagnostic_export_full_bundle);
profile.heatmap_export_domain_modes = local_resolve_export_modes(profile.supported_heatmap_domain_modes, ...
    profile.heatmap_primary_domain_mode, profile.export_all_heatmap_modes || profile.diagnostic_export_full_bundle);
profile.heatmap_primary_selection = local_build_heatmap_selection(profile.heatmap_primary_value_mode, profile.heatmap_primary_domain_mode);
profile.canonical_passratio_selection = profile.canonical_primary_mode;
profile.manager_name = "MB_plot_mode_manager";
profile.manager_version = "mb-plot-mode-v1";
profile.passratio_domain_view_map = struct( ...
    'historyFull', "history_full", ...
    'effectiveFullRange', "effective_full_range", ...
    'frontierZoom', "frontier_zoom");
end

function plotting_cfg = local_extract_plotting_cfg(cfg_or_meta)
plotting_cfg = struct();
if ~isstruct(cfg_or_meta)
    return;
end

if isfield(cfg_or_meta, 'milestones') && isstruct(cfg_or_meta.milestones) && ...
        isfield(cfg_or_meta.milestones, 'MB_plotting') && isstruct(cfg_or_meta.milestones.MB_plotting)
    plotting_cfg = cfg_or_meta.milestones.MB_plotting;
    return;
end

if isfield(cfg_or_meta, 'MB_plotting') && isstruct(cfg_or_meta.MB_plotting)
    plotting_cfg = cfg_or_meta.MB_plotting;
end
end

function mode = local_normalize_passratio_mode(mode)
mode = string(mode);
switch lower(strrep(strrep(char(mode), '_', ''), '-', ''))
    case {'historyfull', 'history'}
        mode = "historyFull";
    case {'effectivefullrange', 'effective', 'fullrange'}
        mode = "effectiveFullRange";
    case {'frontierzoom', 'zoom', 'frontier'}
        mode = "frontierZoom";
    otherwise
        error('resolve_mb_plot_mode_profile:InvalidPassratioMode', ...
            'Unsupported MB passratio/comparison mode: %s', char(mode));
end
end

function mode = local_normalize_heatmap_value_mode(mode)
mode = string(mode);
switch lower(strrep(strrep(char(mode), '_', ''), '-', ''))
    case {'numericrequirement', 'numeric', 'requirement'}
        mode = "numeric_requirement";
    case {'statemap', 'state'}
        mode = "state_map";
    otherwise
        error('resolve_mb_plot_mode_profile:InvalidHeatmapValueMode', ...
            'Unsupported MB heatmap value mode: %s', char(mode));
end
end

function mode = local_normalize_heatmap_domain_mode(mode)
mode = string(mode);
switch lower(strrep(strrep(char(mode), '_', ''), '-', ''))
    case {'local'}
        mode = "local";
    case {'globalskeleton', 'global'}
        mode = "globalSkeleton";
    otherwise
        error('resolve_mb_plot_mode_profile:InvalidHeatmapDomainMode', ...
            'Unsupported MB heatmap domain mode: %s', char(mode));
end
end

function modes = local_resolve_export_modes(all_modes, primary_mode, export_all_modes)
if export_all_modes
    modes = reshape(string(all_modes), 1, []);
else
    modes = string(primary_mode);
end
end

function selection = local_build_heatmap_selection(value_mode, domain_mode)
selection = struct();
selection.value_mode = string(value_mode);
selection.domain_mode = string(domain_mode);
selection.selection_key = string(value_mode) + "|" + string(domain_mode);
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
