function tf = is_visible_stage03(r_sat_km, r_tgt_km, cfg)
    %IS_VISIBLE_STAGE03 Refined visibility check in ECI geometry.
    %
    % Conditions:
    %   1) max range
    %   2) Earth occlusion
    %   3) optional max off-nadir angle
    %   4) optional min elevation angle
    
        los_km = r_tgt_km - r_sat_km;
        range_km = norm(los_km);
    
        % ------------------------------------------------------------
        % 1) Range gate
        % ------------------------------------------------------------
        if range_km > cfg.stage03.max_range_km
            tf = false;
            return;
        end
    
        % ------------------------------------------------------------
        % 2) Earth occlusion
        % ------------------------------------------------------------
        if cfg.stage03.require_earth_occlusion_check
            Re_km = 6378.137;
    
            d = los_km / norm(los_km);
    
            % Closest point to Earth center on the finite segment from sat to tgt
            t_ca = -dot(r_sat_km, d);
            t_ca = max(t_ca, 0);
            t_ca = min(t_ca, range_km);
    
            p_ca = r_sat_km + t_ca * d;
    
            if norm(p_ca) < Re_km
                tf = false;
                return;
            end
        end
    
        % ------------------------------------------------------------
        % 3) Off-nadir constraint
        % ------------------------------------------------------------
        if isfield(cfg.stage03, 'enable_offnadir_constraint') && cfg.stage03.enable_offnadir_constraint
            nadir_dir = -r_sat_km / norm(r_sat_km);
            los_dir = los_km / norm(los_km);
    
            cval = dot(nadir_dir, los_dir);
            cval = max(min(cval, 1), -1);
            offnadir_deg = acosd(cval);
    
            if offnadir_deg > cfg.stage03.max_offnadir_deg
                tf = false;
                return;
            end
        end
    
        % ------------------------------------------------------------
        % 4) Min elevation-like constraint
        % ------------------------------------------------------------
        if isfield(cfg.stage03, 'enable_min_elevation_constraint') && cfg.stage03.enable_min_elevation_constraint
            zenith_dir = r_tgt_km / norm(r_tgt_km);
            sat_dir_from_tgt = (r_sat_km - r_tgt_km) / norm(r_sat_km - r_tgt_km);
    
            cval = dot(zenith_dir, sat_dir_from_tgt);
            cval = max(min(cval, 1), -1);
            zenith_angle_deg = acosd(cval);
            elev_deg = 90 - zenith_angle_deg;
    
            if elev_deg < cfg.stage03.min_elevation_deg
                tf = false;
                return;
            end
        end
    
        tf = true;
    end