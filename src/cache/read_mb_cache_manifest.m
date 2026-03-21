function manifest_info = read_mb_cache_manifest(cache_file)
%READ_MB_CACHE_MANIFEST Read an MB cache manifest without enforcing compatibility.

manifest_info = struct( ...
    'found', false, ...
    'manifest', struct(), ...
    'manifest_csv', "");

if nargin < 1 || strlength(string(cache_file)) == 0 || exist(cache_file, 'file') ~= 2
    return;
end

data = load(cache_file);
if isfield(data, 'cache_manifest')
    manifest_info.manifest = data.cache_manifest;
    manifest_info.found = true;
elseif isfield(data, 'manifest')
    manifest_info.manifest = data.manifest;
    manifest_info.found = true;
end

csv_file = replace(string(cache_file), ".mat", ".csv");
if isfile(csv_file)
    manifest_info.manifest_csv = csv_file;
end
end
