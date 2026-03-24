function cfg = stage08_prepare_cfg(cfg)
    %STAGE08_PREPARE_CFG
    % Normalize / resolve Stage08 configuration fields.
    
        if nargin < 1 || isempty(cfg)
            cfg = default_params();
        end
    
        if ~isfield(cfg, 'stage08') || isempty(cfg.stage08)
            error('cfg.stage08 is missing.');
        end
    
        if ~isfield(cfg.stage08, 'active_tw_grid_name') || isempty(cfg.stage08.active_tw_grid_name)
            cfg.stage08.active_tw_grid_name = 'baseline';
        end
    
        switch lower(string(cfg.stage08.active_tw_grid_name))
            case "baseline"
                cfg.stage08.active_tw_grid_s = cfg.stage08.Tw_grid_baseline_s;
            case "dense"
                cfg.stage08.active_tw_grid_s = cfg.stage08.Tw_grid_dense_s;
            case "custom"
                cfg.stage08.active_tw_grid_s = cfg.stage08.Tw_grid_custom_s;
            otherwise
                error('Unknown cfg.stage08.active_tw_grid_name: %s', cfg.stage08.active_tw_grid_name);
        end
    
        cfg.stage08.active_tw_grid_s = unique(cfg.stage08.active_tw_grid_s(:).', 'stable');
    
        if cfg.stage08.require_include_current_Tw
            if ~any(abs(cfg.stage08.active_tw_grid_s - cfg.stage04.Tw_s) < 1e-9)
                cfg.stage08.active_tw_grid_s = unique([cfg.stage08.active_tw_grid_s, cfg.stage04.Tw_s], 'stable');
                cfg.stage08.active_tw_grid_s = sort(cfg.stage08.active_tw_grid_s, 'ascend');
            end
        end
    
        if ~isfield(cfg.stage08, 'run_tag') || isempty(cfg.stage08.run_tag)
            cfg.stage08.run_tag = char(cfg.stage08.active_tw_grid_name);
        end
    
        if ~isfield(cfg.stage08, 'family_order') || isempty(cfg.stage08.family_order)
            cfg.stage08.family_order = {'nominal','C1','C2'};
        end
    end