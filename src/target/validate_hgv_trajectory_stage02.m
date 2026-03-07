function val = validate_hgv_trajectory_stage02(traj, cfg)
    %VALIDATE_HGV_TRAJECTORY_STAGE02 Validate one propagated HGV trajectory.
    
        val = struct();
        val.num_steps = numel(traj.t_s);
        val.duration_s = traj.t_s(end) - traj.t_s(1);
        val.h_min_km = min(traj.h_km);
        val.h_max_km = max(traj.h_km);
        val.v_min_mps = min(traj.v_mps);
        val.v_max_mps = max(traj.v_mps);
    
        dist = hypot(traj.xy_km(:,1) - cfg.stage01.disk_center_xy_km(1), ...
                     traj.xy_km(:,2) - cfg.stage01.disk_center_xy_km(2));
        val.r_min_to_center_km = min(dist);
    
        val.pass = true;
        val.fail_reasons = {};
    
        if any(~isfinite(traj.X), 'all')
            val.pass = false;
            val.fail_reasons{end+1} = 'NaN_or_Inf_in_state'; %#ok<AGROW>
        end
    
        if val.num_steps < 20
            val.pass = false;
            val.fail_reasons{end+1} = 'trajectory_too_short'; %#ok<AGROW>
        end
    
        if val.h_min_km < 0
            val.pass = false;
            val.fail_reasons{end+1} = 'negative_altitude'; %#ok<AGROW>
        end
    
        if val.v_min_mps <= 0
            val.pass = false;
            val.fail_reasons{end+1} = 'nonpositive_speed'; %#ok<AGROW>
        end
    end