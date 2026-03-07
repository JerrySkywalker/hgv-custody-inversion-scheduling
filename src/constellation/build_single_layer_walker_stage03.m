function walker = build_single_layer_walker_stage03(cfg)
    %BUILD_SINGLE_LAYER_WALKER_STAGE03 Build baseline single-layer Walker constellation.
    
        walker = struct();
        walker.h_km = cfg.stage03.h_km;
        walker.i_deg = cfg.stage03.i_deg;
        walker.P = cfg.stage03.P;
        walker.T = cfg.stage03.T;
        walker.F = cfg.stage03.F;
        walker.Ns = walker.P * walker.T;
    
        % If old walker_gen exists, later replace this simple builder by wrapper.
        sat = repmat(struct('plane_id', [], 'sat_id_in_plane', [], ...
                            'raan_deg', [], 'M0_deg', [], ...
                            'h_km', [], 'i_deg', []), walker.Ns, 1);
    
        idx = 0;
        for p = 1:walker.P
            raan_deg = (p-1) * 360 / walker.P;
            for t = 1:walker.T
                idx = idx + 1;
    
                % Simple Walker-T like phasing
                M0_deg = mod((t-1) * 360 / walker.T + (p-1) * walker.F * 360 / walker.Ns, 360);
    
                sat(idx).plane_id = p;
                sat(idx).sat_id_in_plane = t;
                sat(idx).raan_deg = raan_deg;
                sat(idx).M0_deg = M0_deg;
                sat(idx).h_km = walker.h_km;
                sat(idx).i_deg = walker.i_deg;
            end
        end
    
        walker.sat = sat;
    end