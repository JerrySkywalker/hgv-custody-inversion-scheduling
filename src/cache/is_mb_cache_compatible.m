function [tf, reason] = is_mb_cache_compatible(existing_manifest, expected_manifest)
%IS_MB_CACHE_COMPATIBLE Check whether an MB cache manifest can be reused safely.

tf = false;
reason = "missing_manifest";

if ~isstruct(existing_manifest) || ~isstruct(expected_manifest)
    return;
end

required = {'cache_schema_version', 'cache_type', 'cache_namespace', 'input_hash'};
if ~all(isfield(existing_manifest, required)) || ~all(isfield(expected_manifest, required))
    reason = "manifest_fields_missing";
    return;
end

if existing_manifest.cache_schema_version ~= expected_manifest.cache_schema_version
    reason = "schema_version_mismatch";
    return;
end
if string(existing_manifest.cache_type) ~= string(expected_manifest.cache_type)
    reason = "cache_type_mismatch";
    return;
end
if string(existing_manifest.cache_namespace) ~= string(expected_manifest.cache_namespace)
    reason = "cache_namespace_mismatch";
    return;
end
if string(existing_manifest.input_hash) ~= string(expected_manifest.input_hash)
    reason = "input_hash_mismatch";
    return;
end
if isfield(existing_manifest, 'generator_version') && isfield(expected_manifest, 'generator_version') && ...
        string(existing_manifest.generator_version) ~= string(expected_manifest.generator_version)
    reason = "generator_version_mismatch";
    return;
end
if isfield(existing_manifest, 'semantic_mode') && isfield(expected_manifest, 'semantic_mode') && ...
        string(existing_manifest.semantic_mode) ~= string(expected_manifest.semantic_mode)
    reason = "semantic_mode_mismatch";
    return;
end
if isfield(existing_manifest, 'sensor_group_name') && isfield(expected_manifest, 'sensor_group_name') && ...
        string(existing_manifest.sensor_group_name) ~= string(expected_manifest.sensor_group_name)
    reason = "sensor_group_mismatch";
    return;
end
if isfield(existing_manifest, 'sensor_param_digest') && isfield(expected_manifest, 'sensor_param_digest') && ...
        string(existing_manifest.sensor_param_digest) ~= string(expected_manifest.sensor_param_digest)
    reason = "sensor_param_digest_mismatch";
    return;
end
if isfield(existing_manifest, 'search_domain_digest') && isfield(expected_manifest, 'search_domain_digest') && ...
        string(existing_manifest.search_domain_digest) ~= string(expected_manifest.search_domain_digest)
    reason = "search_domain_digest_mismatch";
    return;
end
if isfield(existing_manifest, 'profile_mode') && isfield(expected_manifest, 'profile_mode') && ...
        string(existing_manifest.profile_mode) ~= string(expected_manifest.profile_mode)
    reason = "profile_mode_mismatch";
    return;
end
if isfield(existing_manifest, 'cache_tag') && isfield(expected_manifest, 'cache_tag') && ...
        string(existing_manifest.cache_tag) ~= string(expected_manifest.cache_tag)
    reason = "cache_tag_mismatch";
    return;
end
if isfield(existing_manifest, 'cache_signature') && isfield(expected_manifest, 'cache_signature') && ...
        strlength(string(existing_manifest.cache_signature)) > 0 && ...
        strlength(string(expected_manifest.cache_signature)) > 0 && ...
        string(existing_manifest.cache_signature) ~= string(expected_manifest.cache_signature)
    reason = "cache_signature_mismatch";
    return;
end

if isfield(existing_manifest, 'generator_function') && isfield(expected_manifest, 'generator_function') && ...
        string(existing_manifest.generator_function) ~= string(expected_manifest.generator_function)
    reason = "generator_function_mismatch";
    return;
end

tf = true;
reason = "compatible";
end
