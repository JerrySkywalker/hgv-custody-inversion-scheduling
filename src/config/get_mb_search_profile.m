function profile = get_mb_search_profile(profile_name, cfg)
%GET_MB_SEARCH_PROFILE Return a named MB search profile.

if nargin < 1 || isempty(profile_name)
    profile_name = 'mb_default';
end
if nargin < 2
    cfg = [];
end

if isstruct(profile_name)
    profile = milestone_common_merge_structs(mb_search_profile_defaults(cfg), profile_name);
    if ~isfield(profile, 'name') || strlength(string(profile.name)) == 0
        profile.name = "custom_profile";
    end
    return;
end

token = local_normalize_profile_name(profile_name);
catalog = mb_search_profile_catalog(cfg);
names = cellstr(string({catalog.name}));
hit = find(strcmp(names, token), 1);
if isempty(hit)
    error('Unknown MB search profile: %s', string(profile_name));
end
profile = catalog(hit);
end

function token = local_normalize_profile_name(profile_name)
token = lower(strtrim(char(string(profile_name))));
switch token
    case {'default', 'mb_default'}
        token = 'mb_default';
    case {'dense', 'mb_dense_local'}
        token = 'mb_dense_local';
    case {'heavy', 'mb_heavy'}
        token = 'mb_heavy';
    case {'strict', 'stage05_strict_replica', 'strict_stage05_replica', 'mb_stage05_strict_replica'}
        token = 'strict_stage05_replica';
    case {'auto_plot_tune', 'auto_tune', 'mb_auto_plot_tune'}
        token = 'mb_auto_plot_tune';
    case {'fullnight', 'final_repair_fullnight', 'mb_final_repair_fullnight'}
        token = 'mb_final_repair_fullnight';
end
end
