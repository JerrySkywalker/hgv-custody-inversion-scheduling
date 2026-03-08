function summary = summarize_stage05_grid(grid, cfg)
    %SUMMARIZE_STAGE05_GRID
    % Summarize Stage05.1 search-domain configuration.
    
        summary = struct();
    
        summary.family_scope = cfg.stage05.family_scope;
        summary.gamma_source = cfg.stage05.gamma_source;
    
        summary.h_fixed_km = cfg.stage05.h_fixed_km;
        summary.i_grid_deg = cfg.stage05.i_grid_deg(:).';
        summary.P_grid = cfg.stage05.P_grid(:).';
        summary.T_grid = cfg.stage05.T_grid(:).';
    
        summary.num_i = numel(summary.i_grid_deg);
        summary.num_P = numel(summary.P_grid);
        summary.num_T = numel(summary.T_grid);
        summary.num_total = height(grid);
    
        summary.Ns_min = min(grid.Ns);
        summary.Ns_max = max(grid.Ns);
    end