function manifest = build_mb_cache_manifest(cache_type, generator_function, input_spec, metadata)
%BUILD_MB_CACHE_MANIFEST Build a versioned manifest for MB cache artifacts.

if nargin < 1 || strlength(string(cache_type)) == 0
    cache_type = "semantic_eval";
end
if nargin < 2 || strlength(string(generator_function)) == 0
    generator_function = "unknown";
end
if nargin < 3 || isempty(input_spec)
    input_spec = struct();
end
if nargin < 4 || isempty(metadata)
    metadata = struct();
end

manifest = struct();
manifest.cache_schema_version = 1;
manifest.cache_type = string(cache_type);
manifest.cache_namespace = string(local_getfield_or(metadata, 'cache_namespace', "mb_default"));
manifest.git_commit = local_git_commit();
manifest.generator_function = string(generator_function);
manifest.generator_version = string(local_getfield_or(metadata, 'generator_version', local_generator_version(generator_function)));
manifest.created_at = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
manifest.input_hash = string(compute_mb_cache_input_hash(input_spec));
manifest.semantic_mode = string(local_getfield_or(metadata, 'semantic_mode', ""));
manifest.sensor_group_name = string(local_getfield_or(metadata, 'sensor_group_name', ""));
manifest.sensor_param_digest = string(compute_mb_cache_input_hash(local_getfield_or(metadata, 'sensor_params', struct())));
manifest.search_domain_digest = string(compute_mb_cache_input_hash(local_getfield_or(metadata, 'search_domain', struct())));
manifest.plot_domain_digest = string(compute_mb_cache_input_hash(local_getfield_or(metadata, 'plot_domain', struct())));
manifest.profile_mode = string(local_getfield_or(metadata, 'profile_mode', ""));
manifest.height_km = local_getfield_or(metadata, 'height_km', NaN);
manifest.family_name = string(local_getfield_or(metadata, 'family_name', ""));
manifest.compatible_with_plot_only_changes = logical(local_getfield_or(metadata, 'compatible_with_plot_only_changes', true));
manifest.compatible_with_export_only_changes = logical(local_getfield_or(metadata, 'compatible_with_export_only_changes', true));
manifest.cache_tag = string(local_getfield_or(metadata, 'cache_tag', ""));
manifest.notes = string(local_getfield_or(metadata, 'notes', ""));
manifest.input_spec = input_spec;
manifest.metadata = metadata;
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function git_commit = local_git_commit()
persistent cached_commit
if ~isempty(cached_commit)
    git_commit = cached_commit;
    return;
end

[status, txt] = system('git rev-parse --short HEAD');
if status == 0
    cached_commit = string(strtrim(txt));
else
    cached_commit = "unknown";
end
git_commit = cached_commit;
end

function version = local_generator_version(generator_function)
version = "unknown";
try
    file_path = which(char(string(generator_function)));
    if isempty(file_path)
        return;
    end
    info = dir(file_path);
    if isempty(info)
        return;
    end
    version = string(sprintf('%s|%.0f', info.date, info.bytes));
catch
    version = "unknown";
end
end
