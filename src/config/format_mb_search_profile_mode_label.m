function label = format_mb_search_profile_mode_label(mode_in, detail_level)
%FORMAT_MB_SEARCH_PROFILE_MODE_LABEL Human-readable MB profile-mode label.

if nargin < 1 || isempty(mode_in)
    mode_in = "debug";
end
if nargin < 2 || strlength(string(detail_level)) == 0
    detail_level = "short";
end

mode_name = lower(strtrim(char(string(mode_in))));
switch mode_name
    case 'paper'
        summary = "prefer 0->1 saturation and centered transition";
        detail = "wider search budget with stricter auto-tune success criteria";
    case {'strict_replica', 'strict'}
        mode_name = 'strict_replica';
        summary = "locked Stage05 reference domain";
        detail = "uses original Stage05 sensor defaults, search domain, and plot semantics";
    otherwise
        mode_name = 'debug';
        summary = "fast validation with smaller budget";
        detail = "smaller search budget for quick iteration and local debugging";
end

if strcmpi(char(string(detail_level)), 'detailed')
    label = string(sprintf('%s: %s', mode_name, detail));
else
    label = string(sprintf('%s: %s', mode_name, summary));
end
end
