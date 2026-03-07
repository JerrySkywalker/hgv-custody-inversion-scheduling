function cases_head = generate_heading_family(disk, entry, heading_offsets_deg)
    %GENERATE_HEADING_FAMILY Generate finite heading-family entry cases.
    
        arguments
            disk struct
            entry struct
            heading_offsets_deg (1,:) double
        end
    
        num_points = entry.num_points;
        num_offsets = numel(heading_offsets_deg);
    
        cases_head = repmat(local_empty_case(), num_points * num_offsets, 1);
    
        idx = 0;
        for k = 1:num_points
            p0 = entry.points_xy_km(k, :);
            v_to_center = disk.center_xy_km - p0;
            nominal_heading_deg = atan2d(v_to_center(2), v_to_center(1));
    
            for j = 1:num_offsets
                idx = idx + 1;
                offset = heading_offsets_deg(j);
    
                c = local_empty_case();
                c.case_id = sprintf('H%02d_%+03d', k, round(offset));
                c.family = 'heading';
                c.subfamily = 'finite_heading_family';
                c.entry_point_xy_km = p0;
                c.entry_theta_deg = entry.theta_deg(k);
                c.heading_deg = nominal_heading_deg + offset;
                c.heading_offset_deg = offset;
                c.notes = 'Heading-family case relative to center-seeking direction.';
                cases_head(idx) = c;
            end
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