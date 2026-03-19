function info = apply_mb_plot_domain_guardrail(ax, x_values, y_values, options)
%APPLY_MB_PLOT_DOMAIN_GUARDRAIL Apply unified plot-domain diagnostics.

if nargin < 2
    x_values = [];
end
if nargin < 3
    y_values = [];
end
if nargin < 4 || isempty(options)
    options = struct();
end

info = compute_mb_plot_window_from_data(x_values, options);

if ~ishandle(ax)
    return;
end

if ~info.has_valid_points
    axis(ax, 'off');
    text(ax, 0.5, 0.56, char(local_getfield_or(options, 'empty_message', info.diagnostic_text)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 14);
    domain_summary = char(local_getfield_or(options, 'domain_summary', ""));
    if ~isempty(strtrim(domain_summary))
        text(ax, 0.5, 0.42, domain_summary, ...
            'HorizontalAlignment', 'center', 'FontSize', 11, 'Color', [0.30 0.30 0.30]);
    end
    return;
end

xlim(ax, info.xlim);

if isfield(options, 'ylim') && numel(options.ylim) == 2 && all(isfinite(options.ylim))
    ylim(ax, reshape(options.ylim, 1, []));
elseif logical(local_getfield_or(options, 'auto_ylim', false))
    finite_y = y_values(isfinite(y_values));
    if ~isempty(finite_y)
        y_span = [min(finite_y), max(finite_y)];
        pad = max(0.05 * max(1, diff(y_span)), 0.02);
        y_span = [y_span(1) - pad, y_span(2) + pad];
        ylim(ax, y_span);
    end
end

note_lines = strings(0, 1);
if strlength(info.diagnostic_text) > 0
    note_lines(end + 1, 1) = string(info.diagnostic_text); %#ok<AGROW>
end
plot_domain_source = char(string(local_getfield_or(options, 'plot_domain_source', info.plot_domain_source)));
stop_reason = char(string(local_getfield_or(options, 'stop_reason', "")));
if ~isempty(strtrim(plot_domain_source))
    note_lines(end + 1, 1) = string(sprintf('plot-domain: %s', plot_domain_source)); %#ok<AGROW>
end
if ~isempty(strtrim(stop_reason))
    note_lines(end + 1, 1) = string(sprintf('stop-reason: %s', stop_reason)); %#ok<AGROW>
end

if ~isempty(note_lines)
    text(ax, 0.02, 0.96, strjoin(cellstr(note_lines), newline), ...
        'Units', 'normalized', 'FontSize', 9.5, 'Color', [0.30 0.30 0.30], ...
        'VerticalAlignment', 'top');
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
