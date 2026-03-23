function contract = resolve_mb_plot_view_contract(cfg_or_meta, request)
%RESOLVE_MB_PLOT_VIEW_CONTRACT Resolve the rendering/data contract for an MB plot view.

if nargin < 1 || isempty(cfg_or_meta)
    cfg_or_meta = struct();
end
if nargin < 2 || isempty(request)
    request = struct();
end

profile = resolve_mb_plot_mode_profile(cfg_or_meta);
policy = resolve_mb_plot_data_policy(cfg_or_meta, request);

passratio_mode = string(local_getfield_or(request, 'passratio_mode', ""));
heatmap_scope = string(local_getfield_or(request, 'heatmap_scope', ""));
heatmap_value_mode = string(local_getfield_or(request, 'heatmap_value_mode', ""));

contract = struct( ...
    'view_name', "", ...
    'x_domain_kind', "", ...
    'y_domain_kind', "", ...
    'allow_gap_bridge', false, ...
    'connect_only_defined', true, ...
    'show_missing_as_break', true, ...
    'is_global_view', false, ...
    'is_effective_view', false, ...
    'requires_dense_grid', false, ...
    'requires_global_grid', false, ...
    'requires_history_points', false, ...
    'title_suffix', "", ...
    'sidecar_plot_domain', "", ...
    'sidecar_view_scope', "", ...
    'passratio_mode', passratio_mode, ...
    'heatmap_scope', heatmap_scope, ...
    'heatmap_value_mode', heatmap_value_mode, ...
    'plot_primary_mode', string(local_getfield_or(profile, 'passratio_primary_mode', "")));

if strlength(passratio_mode) > 0
    switch passratio_mode
        case "historyFull"
            contract.view_name = "historyFull";
            contract.x_domain_kind = "history_points";
            contract.y_domain_kind = "real_eval";
            contract.allow_gap_bridge = false;
            contract.connect_only_defined = true;
            contract.show_missing_as_break = true;
            contract.is_global_view = false;
            contract.is_effective_view = false;
            contract.requires_dense_grid = false;
            contract.requires_global_grid = false;
            contract.requires_history_points = true;
            contract.title_suffix = "History-Full (real computed points)";
            contract.sidecar_plot_domain = "history_full";
            contract.sidecar_view_scope = "history_real_points";
        case "effectiveFullRange"
            contract.view_name = "effectiveFullRange";
            contract.x_domain_kind = "effective_dense";
            contract.y_domain_kind = "dense_rebuild";
            contract.allow_gap_bridge = false;
            contract.connect_only_defined = true;
            contract.show_missing_as_break = true;
            contract.is_global_view = false;
            contract.is_effective_view = true;
            contract.requires_dense_grid = true;
            contract.requires_global_grid = false;
            contract.requires_history_points = false;
            contract.title_suffix = "Effective Full-Range (effective domain only)";
            contract.sidecar_plot_domain = "effective_full_range";
            contract.sidecar_view_scope = "effective_only";
        case "frontierZoom"
            contract.view_name = "frontierZoom";
            contract.x_domain_kind = "frontier_window";
            contract.y_domain_kind = "dense_rebuild";
            contract.allow_gap_bridge = false;
            contract.connect_only_defined = true;
            contract.show_missing_as_break = true;
            contract.is_global_view = false;
            contract.is_effective_view = true;
            contract.requires_dense_grid = true;
            contract.requires_global_grid = false;
            contract.requires_history_points = false;
            contract.title_suffix = "Frontier Zoom";
            contract.sidecar_plot_domain = "frontier_zoom";
            contract.sidecar_view_scope = "frontier_window";
        case "globalFullReplay"
            contract.view_name = "globalFullReplay";
            contract.x_domain_kind = "global_dense";
            contract.y_domain_kind = "global_replay";
            contract.allow_gap_bridge = false;
            contract.connect_only_defined = true;
            contract.show_missing_as_break = true;
            contract.is_global_view = true;
            contract.is_effective_view = false;
            contract.requires_dense_grid = true;
            contract.requires_global_grid = true;
            contract.requires_history_points = false;
            contract.title_suffix = "Global Full Replay";
            contract.sidecar_plot_domain = "global_full_replay";
            contract.sidecar_view_scope = "global_replay";
    end
end

if strlength(heatmap_scope) > 0
    switch heatmap_scope
        case "local"
            contract.sidecar_view_scope = "local";
            contract.is_global_view = false;
            contract.is_effective_view = true;
        case "globalReplay"
            contract.sidecar_view_scope = "global_replay";
            contract.is_global_view = true;
            contract.is_effective_view = false;
            contract.requires_global_grid = true;
    end
end

contract.data_policy = policy;
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
