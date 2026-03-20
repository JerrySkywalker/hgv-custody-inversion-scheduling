function label = format_mb_boundary_diagnostics_label(enabled_in, detail_level)
%FORMAT_MB_BOUNDARY_DIAGNOSTICS_LABEL Human-readable MB boundary diagnostics summary.

if nargin < 1 || isempty(enabled_in)
    enabled_in = true;
end
if nargin < 2 || strlength(string(detail_level)) == 0
    detail_level = "short";
end

enabled = logical(enabled_in);
if strcmpi(char(string(detail_level)), 'detailed')
    if enabled
        label = "on (boundary-hit + saturation + frontier truncation diagnostics exported)";
    else
        label = "off (diagnostic export disabled)";
    end
else
    if enabled
        label = "on";
    else
        label = "off";
    end
end
end
