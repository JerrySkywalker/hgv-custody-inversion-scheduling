function cases_crit = generate_critical_family(cfg)
    %GENERATE_CRITICAL_FAMILY Generate representative critical-geometry cases.
    %
    % C1: track-plane-aligned entry (horizontal from left to right)
    % C2: small-crossing-angle entry (near-tangent entry from upper boundary)
    
        cases = [];
    
        if cfg.stage01.enable_critical_C1
            c1 = local_empty_case();
            c1.case_id = 'C1_track_plane_aligned';
            c1.family = 'critical';
            c1.subfamily = 'C1_track_plane_aligned';
            c1.entry_point_xy_km = [-cfg.stage01.R_in_km, cfg.stage01.critical_C1_y_offset_km];
            c1.entry_theta_deg = atan2d(c1.entry_point_xy_km(2), c1.entry_point_xy_km(1));
            c1.heading_deg = 0; % due east
            c1.heading_offset_deg = NaN;
            c1.notes = 'Critical C1: representative track-plane-aligned entry.';
            cases = [cases; c1]; %#ok<AGROW>
        end
    
        if cfg.stage01.enable_critical_C2
            theta0_deg = cfg.stage01.critical_C2_start_angle_deg;
            theta0_rad = deg2rad(theta0_deg);
            p0 = cfg.stage01.disk_center_xy_km + ...
                cfg.stage01.R_in_km * [cos(theta0_rad), sin(theta0_rad)];
    
            center_heading_deg = atan2d(-p0(2), -p0(1));
    
            c2 = local_empty_case();
            c2.case_id = 'C2_small_crossing_angle';
            c2.family = 'critical';
            c2.subfamily = 'C2_small_crossing_angle';
            c2.entry_point_xy_km = p0;
            c2.entry_theta_deg = theta0_deg;
            c2.heading_deg = center_heading_deg + cfg.stage01.critical_C2_heading_offset_deg;
            c2.heading_offset_deg = cfg.stage01.critical_C2_heading_offset_deg;
            c2.notes = 'Critical C2: representative small-LOS-crossing-angle entry.';
            cases = [cases; c2]; %#ok<AGROW>
        end
    
        cases_crit = cases;
    end
    
    function c = local_empty_case()
        c = struct( ...
            'case_id', '', ...
            'family', '', ...
            'subfamily', '', ...
            'entry_point_xy_km', [NaN, NaN], ...
            'entry_theta_deg', NaN, ...
            'heading_deg', NaN, ...
            'heading_offset_deg', NaN, ...
            'notes', '' ...
        );
    end