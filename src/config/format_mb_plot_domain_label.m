function label = format_mb_plot_domain_label(plot_domain_in, detail_level)
%FORMAT_MB_PLOT_DOMAIN_LABEL Human-readable MB plot-domain label.

if nargin < 1 || isempty(plot_domain_in)
    plot_domain_in = struct();
end
if nargin < 2 || strlength(string(detail_level)) == 0
    detail_level = "short";
end

if ~isstruct(plot_domain_in)
    error('format_mb_plot_domain_label expects a plot-domain struct.');
end
plot_domain = plot_domain_in;

parts = strings(0, 1);
mode_name = string(local_getfield_or(plot_domain, 'plot_xlim_mode', "data_range"));
parts(end + 1, 1) = "mode=" + mode_name; %#ok<AGROW>

xlim_ns = reshape(local_getfield_or(plot_domain, 'plot_xlim_ns', []), 1, []);
if numel(xlim_ns) == 2 && all(isfinite(xlim_ns))
    parts(end + 1, 1) = string(sprintf('xlim=[%g,%g]', xlim_ns(1), xlim_ns(2))); %#ok<AGROW>
end

if strcmpi(char(string(detail_level)), 'detailed')
    ylim_pass = reshape(local_getfield_or(plot_domain, 'plot_ylim_passratio', []), 1, []);
    if numel(ylim_pass) == 2 && all(isfinite(ylim_pass))
        parts(end + 1, 1) = string(sprintf('ypass=[%g,%g]', ylim_pass(1), ylim_pass(2))); %#ok<AGROW>
    end
    guardrail_mode = string(local_getfield_or(plot_domain, 'plot_domain_guardrail_mode', ""));
    if strlength(guardrail_mode) > 0
        parts(end + 1, 1) = "guardrail=" + guardrail_mode; %#ok<AGROW>
    end
    if logical(local_getfield_or(plot_domain, 'strict_stage05_reference', false))
        parts(end + 1, 1) = "strict_stage05_reference"; %#ok<AGROW>
    end
end

label = strjoin(cellstr(parts), ', ');
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
