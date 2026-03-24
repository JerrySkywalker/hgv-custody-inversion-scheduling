function vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg)
    %COMPUTE_VISIBILITY_MATRIX_STAGE03 Compute target-satellite visibility mask.
    %
    % Stage04G.5:
    %   - use Stage02 traj.r_eci_km directly as true target inertial trajectory
    %   - align target and satellite time histories on the common prefix length
    
        t_s = traj_case.traj.t_s;
        Nt_traj = numel(t_s);
        Ns = satbank.Ns;
    
        Nt_sat = size(satbank.r_eci_km, 1);
        assert(Nt_sat >= Nt_traj, ...
            'satbank time dimension (%d) is shorter than trajectory time dimension (%d).', ...
            Nt_sat, Nt_traj);
    
        % ------------------------------------------------------------
        % Use true Stage02 inertial trajectory directly
        % ------------------------------------------------------------
        r_tgt_eci_km = eci_from_stage02_target_stage03(traj_case, cfg);
        assert(size(r_tgt_eci_km,1) == Nt_traj, ...
            'Target ECI trajectory length mismatch.');
    
        r_sat_eci_km = permute(satbank.r_eci_km(1:Nt_traj,:,:), [1, 3, 2]);
        r_tgt_batch_km = reshape(r_tgt_eci_km, [Nt_traj, 1, 3]);

        los_km = r_tgt_batch_km - r_sat_eci_km;
        range_km = sqrt(sum(los_km.^2, 3));
        safe_range_km = max(range_km, eps);

        visible_mask = range_km <= cfg.stage03.max_range_km;

        if cfg.stage03.require_earth_occlusion_check
            Re_km = 6378.137;
            los_dir = los_km ./ safe_range_km;
            t_ca = -sum(r_sat_eci_km .* los_dir, 3);
            t_ca = min(max(t_ca, 0), range_km);
            p_ca = r_sat_eci_km + los_dir .* t_ca;
            visible_mask = visible_mask & (sqrt(sum(p_ca.^2, 3)) >= Re_km);
        end

        if isfield(cfg.stage03, 'enable_offnadir_constraint') && cfg.stage03.enable_offnadir_constraint
            sat_norm_km = max(sqrt(sum(r_sat_eci_km.^2, 3)), eps);
            nadir_dir = -r_sat_eci_km ./ sat_norm_km;
            los_dir = los_km ./ safe_range_km;
            cval = sum(nadir_dir .* los_dir, 3);
            cval = min(max(cval, -1), 1);
            offnadir_deg = acosd(cval);
            visible_mask = visible_mask & (offnadir_deg <= cfg.stage03.max_offnadir_deg);
        end

        if isfield(cfg.stage03, 'enable_min_elevation_constraint') && cfg.stage03.enable_min_elevation_constraint
            tgt_norm_km = max(sqrt(sum(r_tgt_batch_km.^2, 3)), eps);
            zenith_dir = r_tgt_batch_km ./ tgt_norm_km;
            sat_dir_from_tgt = (r_sat_eci_km - r_tgt_batch_km) ./ safe_range_km;
            cval = sum(zenith_dir .* sat_dir_from_tgt, 3);
            cval = min(max(cval, -1), 1);
            elev_deg = 90 - acosd(cval);
            visible_mask = visible_mask & (elev_deg >= cfg.stage03.min_elevation_deg);
        end

        num_visible = sum(visible_mask, 2);
        dual_coverage_mask = num_visible >= 2;
    
        vis_case = struct();
        vis_case.case_id = traj_case.case.case_id;
        vis_case.family = traj_case.case.family;
        vis_case.subfamily = traj_case.case.subfamily;
        vis_case.t_s = t_s;
        vis_case.visible_mask = visible_mask;
        vis_case.num_visible = num_visible;
        vis_case.dual_coverage_mask = dual_coverage_mask;
        vis_case.r_tgt_eci_km = r_tgt_eci_km;
    end
