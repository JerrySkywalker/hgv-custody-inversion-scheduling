function windows = resolve_mb_passratio_plot_windows(curve_table, search_domain, options)
%RESOLVE_MB_PASSRATIO_PLOT_WINDOWS Build global/zoom x-limits for pass-ratio plots.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

ns_values = local_get_column(curve_table, 'Ns');
ns_values = unique(ns_values(isfinite(ns_values)));

global_min = local_getfield_or(search_domain, 'ns_search_min', NaN);
global_max = local_getfield_or(search_domain, 'ns_search_max', NaN);
if ~isfinite(global_min) && ~isempty(ns_values)
    global_min = min(ns_values);
end
if ~isfinite(global_max) && ~isempty(ns_values)
    global_max = max(ns_values);
end

windows = struct();
windows.global_trend = [global_min, global_max];
windows.frontier_zoom = windows.global_trend;
windows.status_tag = "global_only";

if isempty(ns_values) || ~all(isfinite(windows.global_trend))
    return;
end

y_fields = local_resolve_y_fields(curve_table, options);
transition_ns = [];
plateau_ns = [];
for idx = 1:numel(y_fields)
    y_values = local_get_column(curve_table, y_fields(idx));
    if isempty(y_values)
        continue;
    end
    valid = isfinite(ns_values_for_field(curve_table, y_fields(idx))) & isfinite(y_values);
    ns_field = ns_values_for_field(curve_table, y_fields(idx));
    ns_field = ns_field(valid);
    y_values = y_values(valid);
    transition_ns = [transition_ns; ns_field(y_values >= 0.05 & y_values <= 0.98)]; %#ok<AGROW>
    plateau_ns = [plateau_ns; ns_field(y_values >= 0.98)]; %#ok<AGROW>
end

if isempty(transition_ns) && isempty(plateau_ns)
    if numel(ns_values) >= 4
        tail_count = min(ceil(0.35 * numel(ns_values)), numel(ns_values));
        zoom_ns = ns_values(max(1, numel(ns_values) - tail_count + 1):end);
        windows.frontier_zoom = local_expand_window(zoom_ns, windows.global_trend);
        windows.status_tag = "tail_focus";
    end
    return;
end

anchor_ns = unique([transition_ns; plateau_ns]);
windows.frontier_zoom = local_expand_window(anchor_ns, windows.global_trend);
windows.status_tag = "frontier_zoom";
end

function fields = local_resolve_y_fields(curve_table, options)
fields = string(local_getfield_or(options, 'y_fields', strings(0, 1)));
if ~isempty(fields)
    return;
end
candidate_fields = ["max_pass_ratio", "max_pass_ratio_legacyDG", "max_pass_ratio_closedD"];
available = strings(0, 1);
for idx = 1:numel(candidate_fields)
    if istable(curve_table) && ismember(candidate_fields(idx), curve_table.Properties.VariableNames)
        available(end + 1, 1) = candidate_fields(idx); %#ok<AGROW>
    end
end
fields = available;
end

function ns_field = ns_values_for_field(curve_table, ~)
ns_field = local_get_column(curve_table, 'Ns');
end

function window = local_expand_window(anchor_ns, global_window)
anchor_ns = unique(anchor_ns(isfinite(anchor_ns)));
if isempty(anchor_ns)
    window = global_window;
    return;
end

min_ns = min(anchor_ns);
max_ns = max(anchor_ns);
span = max(8, max_ns - min_ns);
pad = max(8, ceil(0.2 * span / 4) * 4);
window = [min_ns - pad, max_ns + pad];

if all(isfinite(global_window))
    window(1) = max(global_window(1), window(1));
    window(2) = min(global_window(2), window(2));
end

if window(2) - window(1) < 24
    center = mean(window);
    half_span = 12;
    window = [center - half_span, center + half_span];
    if all(isfinite(global_window))
        window(1) = max(global_window(1), window(1));
        window(2) = min(global_window(2), window(2));
    end
end

window = round(window / 4) * 4;
if window(1) == window(2)
    window(2) = window(1) + 4;
end
end

function values = local_get_column(T, field_name)
if istable(T) && ismember(field_name, T.Properties.VariableNames)
    values = T.(field_name);
else
    values = [];
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name) && ~isempty(S.(field_name))
    value = S.(field_name);
else
    value = fallback;
end
end
