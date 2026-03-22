function info = compute_mb_plot_window_from_data(x_values, options)
%COMPUTE_MB_PLOT_WINDOW_FROM_DATA Derive a safe plot window from data.

if nargin < 1
    x_values = [];
end
if nargin < 2 || isempty(options)
    options = struct();
end

x_values = x_values(:);
valid_x = x_values(isfinite(x_values));
unique_x = unique(valid_x, 'sorted');

info = struct( ...
    'has_valid_points', ~isempty(unique_x), ...
    'valid_point_count', numel(valid_x), ...
    'unique_x_count', numel(unique_x), ...
    'point_only', false, ...
    'state', "ok", ...
    'plot_domain_source', "data_range", ...
    'diagnostic_text', "", ...
    'xlim', [0, 1], ...
    'min_span', local_default_min_span(unique_x), ...
    'search_domain_bounds', [NaN, NaN]);

if isempty(unique_x)
    info.state = "no_valid_points";
    info.plot_domain_source = "no_valid_points";
    info.diagnostic_text = string(local_getfield_or(options, 'empty_message', 'No valid point found within current search domain'));
    return;
end

preferred_xlim = reshape(local_getfield_or(options, 'preferred_xlim', local_getfield_or(options, 'plot_xlim_ns', [])), 1, []);
bounds = reshape(local_getfield_or(options, 'search_domain_bounds', []), 1, []);
if numel(bounds) == 2 && all(isfinite(bounds))
    info.search_domain_bounds = bounds;
else
    bounds = [min(unique_x) - info.min_span, max(unique_x) + info.min_span];
    info.search_domain_bounds = bounds;
end

data_xlim = [min(unique_x), max(unique_x)];
if numel(preferred_xlim) == 2 && all(isfinite(preferred_xlim))
    preferred_xlim = sort(preferred_xlim);
    in_pref = unique_x(unique_x >= preferred_xlim(1) & unique_x <= preferred_xlim(2));
    if numel(in_pref) >= 2
        info.xlim = preferred_xlim;
        info.plot_domain_source = "preferred_xlim";
        return;
    elseif numel(unique_x) >= 2
        base_xlim = data_xlim;
        info.plot_domain_source = "guardrail_data_fallback";
        info.diagnostic_text = "Preferred plot window was too narrow for the available data; widened to the data-supported range.";
    else
        base_xlim = [unique_x(1), unique_x(1)];
        info.plot_domain_source = "single_point_fallback";
        info.diagnostic_text = "Only a single valid point is visible within the current tuned domain.";
    end
else
    base_xlim = data_xlim;
end

typical_step = local_typical_step(unique_x);
[safe_xlim, span_info] = ensure_mb_min_plot_span(base_xlim, struct( ...
    'center', mean(base_xlim), ...
    'min_span', local_getfield_or(options, 'min_span', info.min_span), ...
    'bounds', bounds, ...
    'round_step', typical_step));

info.xlim = safe_xlim;
info.point_only = numel(unique_x) < 2;
if info.point_only
    info.state = "single_point_visible";
    if strlength(info.diagnostic_text) == 0
        info.diagnostic_text = "Only a single valid point is visible within the current search domain.";
    end
elseif span_info.span_was_expanded && strlength(info.diagnostic_text) == 0
    info.diagnostic_text = "Plot window was expanded by guardrail to preserve a minimum visible span.";
end
end

function min_span = local_default_min_span(unique_x)
step = local_typical_step(unique_x);
if isempty(unique_x)
    min_span = 8;
else
    min_span = max(8, 2 * step);
end
end

function step = local_typical_step(unique_x)
if numel(unique_x) < 2
    step = 8;
    return;
end
diffs = diff(unique_x);
diffs = diffs(isfinite(diffs) & diffs > 0);
if isempty(diffs)
    step = 8;
else
    step = max(1, median(diffs));
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
