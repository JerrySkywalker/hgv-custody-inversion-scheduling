function entry = build_entry_boundary(center_xy_km, R_in_km, num_points)
    %BUILD_ENTRY_BOUNDARY Build evenly sampled entry boundary points.
    
        arguments
            center_xy_km (1,2) double
            R_in_km (1,1) double {mustBePositive}
            num_points (1,1) double {mustBeInteger,mustBePositive}
        end
    
        theta_deg = linspace(0, 360, num_points + 1);
        theta_deg(end) = [];
        theta_rad = deg2rad(theta_deg);
    
        x = center_xy_km(1) + R_in_km * cos(theta_rad);
        y = center_xy_km(2) + R_in_km * sin(theta_rad);
    
        entry = struct();
        entry.center_xy_km = center_xy_km(:).';
        entry.R_in_km = R_in_km;
        entry.num_points = num_points;
        entry.theta_deg = theta_deg(:);
        entry.points_xy_km = [x(:), y(:)];
    end