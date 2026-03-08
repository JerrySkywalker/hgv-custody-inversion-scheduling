function summary = summarize_stage06_grid(grid, cfg)
    %SUMMARIZE_STAGE06_GRID
    % Summarize Stage06 search-domain configuration and evaluation status.
    
        summary = struct();
    
        summary.family_scope = cfg.stage06.family_scope;
        summary.gamma_source = cfg.stage06.gamma_source;
    
        summary.h_fixed_km = cfg.stage06.h_fixed_km;
        summary.F_fixed = cfg.stage06.F_fixed;
        summary.i_grid_deg = cfg.stage06.i_grid_deg(:).';
        summary.P_grid = cfg.stage06.P_grid(:).';
        summary.T_grid = cfg.stage06.T_grid(:).';
        summary.heading_offsets_deg = cfg.stage06.active_heading_offsets_deg(:).';
    
        summary.num_i = numel(summary.i_grid_deg);
        summary.num_P = numel(summary.P_grid);
        summary.num_T = numel(summary.T_grid);
        summary.num_total = height(grid);
    
        summary.Ns_min = min(grid.Ns);
        summary.Ns_max = max(grid.Ns);
    
        if ismember('is_evaluated', grid.Properties.VariableNames)
            summary.num_evaluated = sum(grid.is_evaluated);
        else
            summary.num_evaluated = 0;
        end
    
        if ismember('feasible_flag', grid.Properties.VariableNames)
            summary.num_feasible = sum(grid.feasible_flag);
        else
            summary.num_feasible = 0;
        end
    
        if ismember('gamma_req', grid.Properties.VariableNames)
            gamma_vals = grid.gamma_req(isfinite(grid.gamma_req));
            if isempty(gamma_vals)
                summary.gamma_req = NaN;
            else
                summary.gamma_req = gamma_vals(1);
            end
        else
            summary.gamma_req = NaN;
        end
    end