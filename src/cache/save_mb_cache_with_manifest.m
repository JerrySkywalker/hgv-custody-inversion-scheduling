function artifacts = save_mb_cache_with_manifest(cache_file, payload, manifest)
%SAVE_MB_CACHE_WITH_MANIFEST Save an MB cache payload together with its manifest.

if nargin < 1 || strlength(string(cache_file)) == 0
    error('save_mb_cache_with_manifest requires cache_file.');
end
if nargin < 2
    payload = struct();
end
if nargin < 3 || ~isstruct(manifest)
    error('save_mb_cache_with_manifest requires a manifest struct.');
end

cache_dir = fileparts(char(string(cache_file)));
if ~isempty(cache_dir) && exist(cache_dir, 'dir') ~= 7
    mkdir(cache_dir);
end

cache_payload = payload;
cache_manifest = manifest;
save(cache_file, 'cache_payload', 'cache_manifest', '-v7.3');

csv_file = replace(string(cache_file), ".mat", ".csv");
export_mb_cache_manifest_csv(cache_manifest, csv_file);

artifacts = struct();
artifacts.cache_file = string(cache_file);
artifacts.manifest_csv = string(csv_file);
artifacts.manifest = cache_manifest;
end
