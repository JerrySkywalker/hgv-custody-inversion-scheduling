function satbank = build_satbank_stage03(walker, t_s, cfg)
    %BUILD_SATBANK_STAGE03
    % Wrapper for Stage03 Walker build + propagation.
    %
    % Inputs:
    %   walker : struct with h_km, i_deg, P, T, F
    %   t_s    : time vector from Stage02 trajectory
    %   cfg    : config (reserved for future use)
    %
    % Output:
    %   satbank.r_eci_km : [Nt x 3 x Ns]
    
        %#ok<INUSD>
        walker_cfg = struct();
        walker_cfg.stage03 = walker;
    
        % Reuse existing builder
        walker_full = build_single_layer_walker_stage03(walker_cfg);
    
        % Reuse existing propagator
        satbank = propagate_constellation_stage03(walker_full, t_s(:));
    
        satbank.meta = struct();
        satbank.meta.geometry_mode = 'ECI';
    end