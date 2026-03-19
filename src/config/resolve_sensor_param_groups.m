function groups = resolve_sensor_param_groups(user_input)
%RESOLVE_SENSOR_PARAM_GROUPS Resolve user input into a normalized sensor-group list.

available = list_sensor_param_groups();

if nargin < 1 || isempty(user_input)
    groups = {'baseline'};
    return;
end

if ischar(user_input) || (isstring(user_input) && isscalar(user_input))
    token = lower(strtrim(char(string(user_input))));
    if strcmp(token, 'all')
        groups = available;
        return;
    end
    user_tokens = {token};
elseif iscell(user_input) || isstring(user_input)
    user_tokens = cellstr(string(user_input));
    user_tokens = cellfun(@(s) lower(strtrim(s)), user_tokens, 'UniformOutput', false);
    if any(strcmp(user_tokens, 'all'))
        groups = available;
        return;
    end
else
    error('Unsupported sensor group input type.');
end

groups = {};
for idx = 1:numel(user_tokens)
    token = user_tokens{idx};
    if ~ismember(token, available)
        error('Unknown sensor parameter group: %s', token);
    end
    if ~ismember(token, groups)
        groups{end + 1} = token; %#ok<AGROW>
    end
end

if isempty(groups)
    groups = {'baseline'};
end
end
