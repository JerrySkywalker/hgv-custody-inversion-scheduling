function vis_case = compute_visibility_matrix_stage03_eci(traj_case, satbank, cfg)
    %COMPUTE_VISIBILITY_MATRIX_STAGE03_ECI
    % Compute target-satellite visibility using true ECI geometry.
    %
    % Inputs:
    %   traj_case.traj.r_eci_km : [Nt x 3]
    %   satbank.r_eci_km        : [Nt_sat x 3 x Ns]
    %
    % Outputs:
    %   vis_case.t_s
    %   vis_case.vis_mask
    %   vis_case.visible_ids
    %   vis_case.num_visible
    %   vis_case.dual_visible_mask
    %   vis_case.dual_ratio
    %   vis_case.mean_vis
    %   vis_case.best_crossing_deg
    %   vis_case.min_crossing_deg
    
        traj = traj_case.traj;
        case_i = traj_case.case;
    
        r_tgt_eci_km = traj.r_eci_km;
        Nt = size(r_tgt_eci_km, 1);
    
        r_sat_eci_km = satbank.r_eci_km;
        Nt_sat = size(r_sat_eci_km, 1);
        Ns = size(r_sat_eci_km, 3);
    
        Nuse = min(Nt, Nt_sat);
    
        r_tgt_eci_km = r_tgt_eci_km(1:Nuse, :);
        t_s = traj.t_s(1:Nuse);
    
        vis_mask = false(Nuse, Ns);
        num_visible = zeros(Nuse, 1);
        dual_visible_mask = false(Nuse, 1);
        best_crossing_deg = nan(Nuse, 1);
        visible_ids = cell(Nuse, 1);
    
        Re_km = cfg.geo.a_m / 1000.0;
    
        for k = 1:Nuse
            rt = r_tgt_eci_km(k, :).';
            vis_ids_k = [];
    
            for s = 1:Ns
                rs = squeeze(r_sat_eci_km(k, :, s)).';
    
                if local_is_visible_eci(rt, rs, cfg, Re_km)
                    vis_mask(k, s) = true;
                    vis_ids_k(end+1) = s; %#ok<AGROW>
                end
            end
    
            visible_ids{k} = vis_ids_k;
            num_visible(k) = numel(vis_ids_k);
            dual_visible_mask(k) = num_visible(k) >= 2;
    
            if num_visible(k) >= 2
                best_crossing_deg(k) = local_best_crossing_angle_deg(rt, r_sat_eci_km, k, vis_ids_k);
            end
        end
    
        dual_ratio = mean(dual_visible_mask);
        mean_vis = mean(num_visible);
    
        if any(dual_visible_mask)
            min_crossing_deg = min(best_crossing_deg(dual_visible_mask), [], 'omitnan');
        else
            min_crossing_deg = NaN;
        end
    
        vis_case = struct();
        vis_case.case_id = case_i.case_id;
        vis_case.family = case_i.family;
        vis_case.subfamily = case_i.subfamily;
    
        vis_case.t_s = t_s;
        vis_case.vis_mask = vis_mask;
        vis_case.visible_ids = visible_ids;
        vis_case.num_visible = num_visible;
        vis_case.dual_visible_mask = dual_visible_mask;
        vis_case.dual_ratio = dual_ratio;
        vis_case.mean_vis = mean_vis;
    
        vis_case.best_crossing_deg = best_crossing_deg;
        vis_case.min_crossing_deg = min_crossing_deg;
    
        vis_case.r_tgt_eci_km = r_tgt_eci_km;
    
        vis_case.meta = struct();
        vis_case.meta.geometry_mode = 'ECI';
        vis_case.meta.Re_km = Re_km;
        vis_case.meta.Ns = Ns;
        vis_case.meta.Nt = Nuse;
    end
    
    %% ========================================================================
    % local helpers
    % ========================================================================
    
    function tf = local_is_visible_eci(rt, rs, cfg, Re_km)
    % Visibility conditions in ECI:
    %   1) range gate
    %   2) Earth occultation
    %   3) optional off-nadir
    %   4) optional min elevation
    
        los = rs - rt;
        range_km = norm(los);
    
        % 1) range gate
        if range_km > cfg.stage03.max_range_km
            tf = false;
            return;
        end
    
        % 2) Earth occultation
        if cfg.stage03.require_earth_occlusion_check
            d = los / norm(los);
            t_ca = -dot(rt, d);
            t_ca = max(t_ca, 0);
            t_ca = min(t_ca, norm(los)); % clamp to segment
            p_ca = rt + t_ca * d;
    
            if norm(p_ca) < Re_km
                tf = false;
                return;
            end
        end
    
        % 3) off-nadir
        if isfield(cfg.stage03, 'enable_offnadir_constraint') && cfg.stage03.enable_offnadir_constraint
            nadir_dir = -rs / norm(rs);
            los_dir = (rt - rs) / norm(rt - rs);
    
            cval = dot(nadir_dir, los_dir);
            cval = max(min(cval, 1), -1);
            offnadir_deg = acosd(cval);
    
            if offnadir_deg > cfg.stage03.max_offnadir_deg
                tf = false;
                return;
            end
        end
    
        % 4) min elevation
        if isfield(cfg.stage03, 'enable_min_elevation_constraint') && cfg.stage03.enable_min_elevation_constraint
            zenith_dir = rt / norm(rt);
            sat_dir_from_tgt = (rs - rt) / norm(rs - rt);
    
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
    
    function ang_best = local_best_crossing_angle_deg(rt, r_sat_eci_km, k, vis_ids_k)
    
        nv = numel(vis_ids_k);
        U = zeros(3, nv);
    
        for i = 1:nv
            s = vis_ids_k(i);
            rs = squeeze(r_sat_eci_km(k, :, s)).';
            u = rs - rt;
            u = u / norm(u);
            U(:, i) = u;
        end
    
        ang_best = 0;
        for i = 1:nv-1
            for j = i+1:nv
                cij = dot(U(:, i), U(:, j));
                cij = max(-1, min(1, cij));
                ang = acosd(cij);
                ang_best = max(ang_best, ang);
            end
        end
    end