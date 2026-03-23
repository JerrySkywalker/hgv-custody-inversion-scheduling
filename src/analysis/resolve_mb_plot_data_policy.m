function policy = resolve_mb_plot_data_policy(cfg_or_meta, request)
%RESOLVE_MB_PLOT_DATA_POLICY Resolve MB plot data-source semantics policy.

if nargin < 1 || isempty(cfg_or_meta)
    cfg_or_meta = struct();
end
if nargin < 2 || isempty(request)
    request = struct();
end

data_cfg = local_extract_data_cfg(cfg_or_meta);
plot_mode_profile = local_getfield_or(request, 'plot_mode_profile', struct());
if isempty(fieldnames(plot_mode_profile))
    plot_mode_profile = resolve_mb_plot_mode_profile(cfg_or_meta);
end

passratio_mode = local_normalize_passratio_mode(local_getfield_or(request, 'passratio_mode', ""));
heatmap_value_mode = local_normalize_heatmap_value_mode(local_getfield_or(request, 'heatmap_value_mode', ""));
heatmap_domain_mode = local_normalize_heatmap_domain_mode(local_getfield_or(request, 'heatmap_domain_mode', ""));

policy = struct();
policy.manager_name = "MB_plot_data_policy_manager";
policy.manager_version = "mb-plot-data-v1";
policy.plot_mode_profile = plot_mode_profile;
policy.remove_global_trend_mode = logical(local_getfield_or(data_cfg, 'remove_global_trend_mode', true));
policy.force_dense_rebuild = logical(local_getfield_or(data_cfg, 'force_dense_rebuild', true));
policy.allow_sparse_projection = logical(local_getfield_or(data_cfg, 'allow_sparse_projection', false));
policy.allow_history_zero_padding = logical(local_getfield_or(data_cfg, 'allow_history_zero_padding', false));
policy.force_global_numeric_heatmap_rebuild = logical(local_getfield_or(data_cfg, 'force_global_numeric_heatmap_rebuild', true));

policy.passratio_mode = passratio_mode;
policy.heatmap_value_mode = heatmap_value_mode;
policy.heatmap_domain_mode = heatmap_domain_mode;

policy.allow_zero_padding = false;
policy.allow_sparse_projection = policy.allow_sparse_projection;
policy.require_dense_rebuild = false;
policy.inherit_effective_dense = false;
policy.use_true_history_points_only = false;
policy.used_global_rebuild_required = false;
policy.used_skeleton_projection_allowed = false;
policy.policy_label = "";
policy.policy_reason = "";

if strlength(passratio_mode) > 0
    switch passratio_mode
        case "historyFull"
            policy.allow_zero_padding = false;
            policy.allow_sparse_projection = true;
            policy.require_dense_rebuild = false;
            policy.inherit_effective_dense = false;
            policy.use_true_history_points_only = true;
            policy.policy_label = "history_true_points_only";
            policy.policy_reason = "Plot true computed history points only; never synthesize zero-padded rows.";
        case "effectiveFullRange"
            policy.allow_zero_padding = false;
            policy.allow_sparse_projection = false;
            policy.require_dense_rebuild = true;
            policy.inherit_effective_dense = false;
            policy.policy_label = "effective_dense_full_range";
            policy.policy_reason = "Rebuild a dense pass-ratio table on the effective search domain; sparse window projection is disallowed.";
        case "frontierZoom"
            policy.allow_zero_padding = false;
            policy.allow_sparse_projection = false;
            policy.require_dense_rebuild = true;
            policy.inherit_effective_dense = true;
            policy.policy_label = "frontier_zoom_from_dense_effective";
            policy.policy_reason = "Reuse or rebuild the dense effective-full-range table, then crop to the frontier zoom window.";
    end
end

if strlength(heatmap_value_mode) > 0 || strlength(heatmap_domain_mode) > 0
    if heatmap_value_mode == "numeric_requirement" && heatmap_domain_mode == "globalSkeleton"
        policy.used_global_rebuild_required = true;
        policy.used_skeleton_projection_allowed = false;
        policy.policy_label = "numeric_global_true_rebuild";
        policy.policy_reason = "A numeric globalSkeleton heatmap must come from a rebuilt full requirement surface, not a sparse skeleton projection.";
    elseif heatmap_value_mode == "numeric_requirement" && heatmap_domain_mode == "local"
        policy.used_global_rebuild_required = false;
        policy.used_skeleton_projection_allowed = false;
        policy.policy_label = "numeric_local_surface";
        policy.policy_reason = "A numeric local heatmap may use the currently defined local requirement surface.";
    elseif heatmap_value_mode == "state_map" && heatmap_domain_mode == "globalSkeleton"
        policy.used_global_rebuild_required = false;
        policy.used_skeleton_projection_allowed = true;
        policy.policy_label = "state_global_coverage";
        policy.policy_reason = "A globalSkeleton state map may use skeleton coverage logic, but it must preserve defined-vs-uncomputed semantics.";
    elseif heatmap_value_mode == "state_map" && heatmap_domain_mode == "local"
        policy.used_global_rebuild_required = false;
        policy.used_skeleton_projection_allowed = false;
        policy.policy_label = "state_local_surface";
        policy.policy_reason = "A local state map may use the currently defined local surface.";
    end
end
end

function data_cfg = local_extract_data_cfg(cfg_or_meta)
data_cfg = struct();
if ~isstruct(cfg_or_meta)
    return;
end
if isfield(cfg_or_meta, 'milestones') && isstruct(cfg_or_meta.milestones) && ...
        isfield(cfg_or_meta.milestones, 'MB_plot_data') && isstruct(cfg_or_meta.milestones.MB_plot_data)
    data_cfg = cfg_or_meta.milestones.MB_plot_data;
    return;
end
if isfield(cfg_or_meta, 'MB_plot_data') && isstruct(cfg_or_meta.MB_plot_data)
    data_cfg = cfg_or_meta.MB_plot_data;
end
end

function mode = local_normalize_passratio_mode(mode)
mode = string(mode);
if strlength(mode) == 0
    return;
end
switch lower(strrep(strrep(char(mode), '_', ''), '-', ''))
    case {'historyfull', 'history'}
        mode = "historyFull";
    case {'effectivefullrange', 'effective', 'fullrange'}
        mode = "effectiveFullRange";
    case {'frontierzoom', 'zoom', 'frontier'}
        mode = "frontierZoom";
    otherwise
        error('resolve_mb_plot_data_policy:InvalidPassratioMode', ...
            'Unsupported MB passratio mode: %s', char(mode));
end
end

function mode = local_normalize_heatmap_value_mode(mode)
mode = string(mode);
if strlength(mode) == 0
    return;
end
switch lower(strrep(strrep(char(mode), '_', ''), '-', ''))
    case {'numericrequirement', 'numeric', 'requirement'}
        mode = "numeric_requirement";
    case {'statemap', 'state'}
        mode = "state_map";
    otherwise
        error('resolve_mb_plot_data_policy:InvalidHeatmapValueMode', ...
            'Unsupported MB heatmap value mode: %s', char(mode));
end
end

function mode = local_normalize_heatmap_domain_mode(mode)
mode = string(mode);
if strlength(mode) == 0
    return;
end
switch lower(strrep(strrep(char(mode), '_', ''), '-', ''))
    case {'local'}
        mode = "local";
    case {'globalskeleton', 'global'}
        mode = "globalSkeleton";
    otherwise
        error('resolve_mb_plot_data_policy:InvalidHeatmapDomainMode', ...
            'Unsupported MB heatmap domain mode: %s', char(mode));
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
