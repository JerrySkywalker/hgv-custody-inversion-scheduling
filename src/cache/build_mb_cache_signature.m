function signature = build_mb_cache_signature(spec)
%BUILD_MB_CACHE_SIGNATURE Build a readable, version-aware cache signature for MB runs.

if nargin < 1 || isempty(spec)
    spec = struct();
end

payload = struct( ...
    'semantic_name', string(local_getfield_or(spec, 'semantic_name', "")), ...
    'sensor_group', string(local_getfield_or(spec, 'sensor_group', "")), ...
    'search_profile_name', string(local_getfield_or(spec, 'search_profile_name', "")), ...
    'search_profile_mode', string(local_getfield_or(spec, 'search_profile_mode', "")), ...
    'height_km', local_flatten_value(local_getfield_or(spec, 'height_km', NaN)), ...
    'family_name', string(local_getfield_or(spec, 'family_name', "")), ...
    'Ns_grid', local_flatten_value(local_getfield_or(spec, 'Ns_grid', [])), ...
    'P_grid', local_flatten_value(local_getfield_or(spec, 'P_grid', [])), ...
    'T_grid', local_flatten_value(local_getfield_or(spec, 'T_grid', [])), ...
    'expand_blocks', local_flatten_value(local_getfield_or(spec, 'expand_blocks', [])), ...
    'Ns_hard_max', local_getfield_or(spec, 'Ns_hard_max', NaN), ...
    'evaluator_version', string(local_getfield_or(spec, 'evaluator_version', "stage_eval_current")), ...
    'sensor_propagation_version', string(local_getfield_or(spec, 'sensor_propagation_version', "sensor_group_v2")));

payload_json = jsonencode(payload);
md = java.security.MessageDigest.getInstance('MD5');
md.update(uint8(payload_json));
hash_bytes = typecast(md.digest(), 'uint8');
signature = string(lower(reshape(dec2hex(hash_bytes, 2).', 1, [])));
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function value = local_flatten_value(value_in)
if isstruct(value_in)
    try
        value = string(jsonencode(value_in));
    catch
        value = string("<struct>");
    end
elseif iscell(value_in)
    value = string(jsonencode(value_in));
elseif isstring(value_in)
    value = value_in(:).';
elseif ischar(value_in)
    value = string(value_in);
elseif isnumeric(value_in) || islogical(value_in)
    value = reshape(value_in, 1, []);
else
    value = string(value_in);
end
end
