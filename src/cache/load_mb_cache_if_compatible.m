function loaded = load_mb_cache_if_compatible(cache_file, expected_manifest)
%LOAD_MB_CACHE_IF_COMPATIBLE Load an MB cache payload only when manifests match.

loaded = struct( ...
    'hit', false, ...
    'reason', "cache_missing", ...
    'payload', struct(), ...
    'manifest', struct(), ...
    'manifest_csv', "");

if nargin < 1 || strlength(string(cache_file)) == 0 || exist(cache_file, 'file') ~= 2
    return;
end

data = load(cache_file);
if isfield(data, 'cache_manifest')
    manifest = data.cache_manifest;
elseif isfield(data, 'manifest')
    manifest = data.manifest;
else
    loaded.reason = "manifest_missing";
    return;
end

[is_ok, reason] = is_mb_cache_compatible(manifest, expected_manifest);
loaded.manifest = manifest;
loaded.reason = string(reason);
if ~is_ok
    return;
end

if isfield(data, 'cache_payload')
    payload = data.cache_payload;
elseif isfield(data, 'payload')
    payload = data.payload;
else
    loaded.reason = "payload_missing";
    return;
end

loaded.hit = true;
loaded.payload = payload;
csv_file = replace(string(cache_file), ".mat", ".csv");
if isfile(csv_file)
    loaded.manifest_csv = csv_file;
end
end
