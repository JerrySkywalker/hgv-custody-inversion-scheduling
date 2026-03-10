function Tw_grid_s = build_window_grid_stage08(cfg)
    %BUILD_WINDOW_GRID_STAGE08
    % Build standardized Tw scan grid for Stage08.
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
            cfg = stage08_prepare_cfg(cfg);
        end
    
        assert(isfield(cfg, 'stage08') && isfield(cfg.stage08, 'active_tw_grid_s'), ...
            'cfg.stage08.active_tw_grid_s is missing. Please call stage08_prepare_cfg first.');
    
        Tw_grid_s = unique(cfg.stage08.active_tw_grid_s(:).', 'stable');
        Tw_grid_s = sort(Tw_grid_s, 'ascend');
    
        assert(~isempty(Tw_grid_s), 'Stage08 Tw grid is empty.');
        assert(all(isfinite(Tw_grid_s)), 'Stage08 Tw grid contains non-finite values.');
        assert(all(Tw_grid_s > 0), 'Stage08 Tw grid must be positive.');
    end