function tf = is_visible_stage03(r_sat_km, r_tgt_km, cfg)
    %IS_VISIBLE_STAGE03 Simple visibility check:
    %   1) max range
    %   2) Earth occlusion
    
        los_km = r_tgt_km - r_sat_km;
        range_km = norm(los_km);
    
        if range_km > cfg.stage03.max_range_km
            tf = false;
            return;
        end
    
        if cfg.stage03.require_earth_occlusion_check
            Re_km = 6378.137;
    
            d = los_km / norm(los_km);
            t_ca = -dot(r_sat_km, d);
            t_ca = max(t_ca, 0);
            p_ca = r_sat_km + t_ca * d;
    
            if norm(p_ca) < Re_km
                tf = false;
                return;
            end
        end
    
        tf = true;
    end