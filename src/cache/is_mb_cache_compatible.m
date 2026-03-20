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

if isfield(existing_manifest, 'generator_function') && isfield(expected_manifest, 'generator_function') && ...
        string(existing_manifest.generator_function) ~= string(expected_manifest.generator_function)
    reason = "generator_function_mismatch";
    return;
end

tf = true;
reason = "compatible";
end
