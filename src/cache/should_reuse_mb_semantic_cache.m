function decision = should_reuse_mb_semantic_cache(cache_file, expected_manifest)
%SHOULD_REUSE_MB_SEMANTIC_CACHE Decide whether an MB semantic cache can be reused.

loaded = load_mb_cache_if_compatible(cache_file, expected_manifest);
decision = struct( ...
    'reuse', logical(local_getfield_or(loaded, 'hit', false)), ...
    'reason', string(local_getfield_or(loaded, 'reason', "cache_missing")), ...
    'manifest', local_getfield_or(loaded, 'manifest', struct()), ...
    'manifest_csv', string(local_getfield_or(loaded, 'manifest_csv', "")), ...
    'payload', local_getfield_or(loaded, 'payload', struct()));
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
