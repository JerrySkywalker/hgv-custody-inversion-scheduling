function cases_nom = generate_nominal_entry_family(disk, entry)
    %GENERATE_NOMINAL_ENTRY_FAMILY Generate center-seeking nominal entry cases.
    
        num_points = entry.num_points;
        cases_nom = repmat(local_empty_case(), num_points, 1);
    
        for k = 1:num_points
            p0 = entry.points_xy_km(k, :);
            v_to_center = disk.center_xy_km - p0;
            heading_deg = atan2d(v_to_center(2), v_to_center(1));
    
            c = local_empty_case();
            c.case_id = sprintf('N%02d', k);
            c.family = 'nominal';
            c.subfamily = 'center_seeking';
            c.entry_point_xy_km = p0;
            c.entry_theta_deg = entry.theta_deg(k);
            c.heading_deg = heading_deg;
            c.heading_offset_deg = 0;
            c.notes = 'Nominal entry case: heading directly toward protected center.';
            cases_nom(k) = c;
        end
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