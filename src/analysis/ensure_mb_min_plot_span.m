function [span_out, info] = ensure_mb_min_plot_span(span_in, options)
%ENSURE_MB_MIN_PLOT_SPAN Enforce a minimum visible plot span.

if nargin < 1 || isempty(span_in) || numel(span_in) ~= 2 || ~all(isfinite(span_in))
    span_in = [0, 1];
end
if nargin < 2 || isempty(options)
    options = struct();
end

span_in = reshape(span_in, 1, []);
center = local_getfield_or(options, 'center', mean(span_in));
min_span = local_getfield_or(options, 'min_span', max(1, abs(diff(span_in))));
bounds = reshape(local_getfield_or(options, 'bounds', [-inf, inf]), 1, []);
round_step = local_getfield_or(options, 'round_step', []);

span_out = sort(span_in);
info = struct('span_was_expanded', false, 'requested_span', span_in, 'applied_span', span_out);

if diff(span_out) < min_span
    half_span = min_span / 2;
    span_out = [center - half_span, center + half_span];
    info.span_was_expanded = true;
end

if numel(bounds) == 2 && all(isfinite(bounds))
    width = diff(span_out);
    if span_out(1) < bounds(1)
        span_out = [bounds(1), bounds(1) + width];
    end
    if span_out(2) > bounds(2)
        span_out = [bounds(2) - width, bounds(2)];
    end
end

if ~isempty(round_step) && isfinite(round_step) && round_step > 0
    span_out = [floor(span_out(1) / round_step) * round_step, ceil(span_out(2) / round_step) * round_step];
end

if diff(span_out) <= 0
    span_out = [span_out(1) - min_span / 2, span_out(2) + min_span / 2];
    info.span_was_expanded = true;
end

info.applied_span = span_out;
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
