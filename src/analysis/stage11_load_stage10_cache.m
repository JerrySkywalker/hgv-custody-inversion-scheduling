function stage10_meta = stage11_load_stage10_cache(cfg)
%STAGE11_LOAD_STAGE10_CACHE Load latest Stage10 cache metadata for Stage11.

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    entry_token = upper(char(string(cfg.stage11.source_stage10_entry)));
    switch entry_token
        case 'E'
            pattern = 'stage10E_screen_*.mat';
        case 'E1'
            pattern = 'stage10E1_screen_*.mat';
        case 'F'
            pattern = 'stage10F_final_pack_*.mat';
        otherwise
            error('Unsupported stage11.source_stage10_entry: %s', entry_token);
    end

    listing = dir(fullfile(cfg.paths.cache, pattern));
    if isempty(listing)
        error('No Stage10 cache file matching %s was found under %s.', pattern, cfg.paths.cache);
    end

    [~, idx] = max([listing.datenum]);
    cache_file = fullfile(listing(idx).folder, listing(idx).name);
    loaded = load(cache_file, 'out');

    stage10_meta = struct();
    stage10_meta.entry = entry_token;
    stage10_meta.cache_file = cache_file;
    stage10_meta.loaded_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    if isfield(loaded, 'out')
        stage10_meta.out = loaded.out;
    else
        error('Stage10 cache %s does not contain variable ''out''.', cache_file);
    end
end
