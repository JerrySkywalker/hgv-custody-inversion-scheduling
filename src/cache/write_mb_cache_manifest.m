function artifacts = write_mb_cache_manifest(cache_file, payload, manifest)
%WRITE_MB_CACHE_MANIFEST Write an MB cache payload together with its manifest.

artifacts = save_mb_cache_with_manifest(cache_file, payload, manifest);
end
