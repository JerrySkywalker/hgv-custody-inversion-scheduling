function stage10_meta = stage11_load_stage10_cache(cfg)
%STAGE11_LOAD_STAGE10_CACHE Load latest Stage10.E1/E metadata for Stage11.

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    stage10_meta = struct();
    stage10_meta.entry = upper(char(string(cfg.stage11.source_stage10_entry)));
    stage10_meta.loaded_at = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    stage10_meta.cache_reuse_mode = "metadata_reused_window_truth_recomputed";

    stage10_meta.e1 = local_load_latest_cache(cfg.paths.cache, 'stage10E1_screen_*.mat', true);
    stage10_meta.e = local_load_latest_cache(cfg.paths.cache, 'stage10E_screen_*.mat', false);

    stage10_meta.cache_file = stage10_meta.e1.cache_file;
    if isfield(stage10_meta.e1.out, 'scan_table_e1')
        stage10_meta.scan_table_e1 = stage10_meta.e1.out.scan_table_e1;
    else
        error('Stage10.E1 cache does not contain scan_table_e1.');
    end
    if isfield(stage10_meta.e1.out, 'summary_table')
        stage10_meta.summary_table_e1 = stage10_meta.e1.out.summary_table;
    end
    if isfield(stage10_meta.e1.out, 'label_count_table')
        stage10_meta.label_count_table_e1 = stage10_meta.e1.out.label_count_table;
    end

    if ~isempty(stage10_meta.e.cache_file) && isfield(stage10_meta.e.out, 'detail_list')
        stage10_meta.detail_list_e = stage10_meta.e.out.detail_list;
    else
        stage10_meta.detail_list_e = {};
    end

    stage10_meta.grid = local_extract_grid(stage10_meta, cfg);
    stage10_meta.thresholds = struct( ...
        'truth', cfg.stage11.threshold_truth, ...
        'zero', cfg.stage11.threshold_zero, ...
        'bcirc', cfg.stage11.threshold_bcirc);
    stage10_meta.cache_files = struct( ...
        'stage10E1', string(stage10_meta.e1.cache_file), ...
        'stage10E', string(stage10_meta.e.cache_file));
end


function loaded_pack = local_load_latest_cache(cache_dir, pattern, required)
    listing = find_stage_cache_files(cache_dir, pattern);
    loaded_pack = struct('pattern', pattern, 'cache_file', '', 'out', struct());
    if isempty(listing)
        if required
            error('No Stage10 cache file matching %s was found under %s.', pattern, cache_dir);
        end
        return;
    end

    [~, idx] = max([listing.datenum]);
    cache_file = fullfile(listing(idx).folder, listing(idx).name);
    loaded = load(cache_file, 'out');
    if ~isfield(loaded, 'out')
        error('Stage10 cache %s does not contain variable ''out''.', cache_file);
    end

    loaded_pack.cache_file = cache_file;
    loaded_pack.out = loaded.out;
end


function grid = local_extract_grid(stage10_meta, cfg)
    grid = struct( ...
        'h_km', cfg.stage11.grid_h_km, ...
        'i_deg', cfg.stage11.grid_i_deg, ...
        'P', cfg.stage11.grid_P, ...
        'T', cfg.stage11.grid_T, ...
        'F', cfg.stage11.grid_F);

    T = stage10_meta.scan_table_e1;
    if isempty(T)
        return;
    end

    if ismember('h_km', T.Properties.VariableNames)
        grid.h_km = unique(T.h_km(:).', 'stable');
    end
    if ismember('i_deg', T.Properties.VariableNames)
        grid.i_deg = unique(T.i_deg(:).', 'stable');
    end
    if ismember('P', T.Properties.VariableNames)
        grid.P = unique(T.P(:).', 'stable');
    end
    if ismember('T', T.Properties.VariableNames)
        grid.T = unique(T.T(:).', 'stable');
    end
    if ismember('F', T.Properties.VariableNames)
        grid.F = unique(T.F(:).', 'stable');
        if isscalar(grid.F)
            grid.F = grid.F(1);
        else
            grid.F = grid.F(1);
        end
    end
end
