function disk = build_disk_region(center_xy_km, R_D_km)
    %BUILD_DISK_REGION Build abstract protected disk description.
    
        arguments
            center_xy_km (1,2) double
            R_D_km (1,1) double {mustBePositive}
        end
    
        disk = struct();
        disk.center_xy_km = center_xy_km(:).';
        disk.R_D_km = R_D_km;
    end