function profile = resolve_mb_search_profile(user_input, cfg)
%RESOLVE_MB_SEARCH_PROFILE Resolve user input into a normalized MB search profile.

if nargin < 1 || isempty(user_input)
    profile = get_mb_search_profile('mb_default', cfg);
    return;
end

if isstruct(user_input)
    profile = get_mb_search_profile(user_input, cfg);
elseif ischar(user_input) || isstring(user_input)
    profile = get_mb_search_profile(user_input, cfg);
else
    error('Unsupported MB search profile input type.');
end
end
