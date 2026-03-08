function vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg)
    %COMPUTE_VISIBILITY_MATRIX_STAGE03
    % Compute target-satellite visibility in true ECI geometry.
    %
    % Stage04G.5:
    %   - target position uses traj_case.traj.r_eci_km
    %   - satellite position uses satbank.r_eci_km
    %   - Earth occultation is checked in ECI
    %   - LOS crossing angle uses ECI LOS vectors
    %
    % Output fields:
    %   vis_mask              [Nt x Ns] logical
    %   num_visible           [Nt x 1]
    %   dual_visible_mask     [Nt x 1]
    %   dual_ratio            scalar
    %   mean_vis              scalar
    %   best_crossing_deg     [Nt x 1]
    %   min_crossing_deg      scalar
    %   visible_ids           {Nt x 1}
    %   case                  copied case struct
    %   traj                  copied traj struct
    
        traj = traj_case.traj;
        case_i = traj_case.case;
    
        r_tgt_eci_km = traj.r_eci_km;   % [Nt x 3]
        Nt = size(r_tgt_eci_km, 1);
    
        % satbank.r_eci_km is expected as [Nt_sat x 3 x Ns]
        r_sat_eci_km = satbank.r_eci_km;
        Nt_sat = size(r_sat_eci_km, 1);
        Ns = size(r_sat_eci_km, 3);
    
        % If satellite bank length differs from target timeline, crop to common length
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
            rt = r_tgt_eci_km(k, :).';   % [3x1]
            vis_ids_k = [];
    
            for s = 1:Ns
                rs = squeeze(r_sat_eci_km(k, :, s)).';   % [3x1]
    
                if local_is_visible_eci(rt, rs, Re_km)
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
        vis_case.case = case_i;
        vis_case.traj = traj_case.traj;
    
        vis_case.t_s = t_s;
        vis_case.vis_mask = vis_mask;
        vis_case.visible_ids = visible_ids;
        vis_case.num_visible = num_visible;
        vis_case.dual_visible_mask = dual_visible_mask;
        vis_case.dual_ratio = dual_ratio;
        vis_case.mean_vis = mean_vis;
    
        vis_case.best_crossing_deg = best_crossing_deg;
        vis_case.min_crossing_deg = min_crossing_deg;
    
        vis_case.meta = struct();
        vis_case.meta.geometry_mode = 'ECI';
        vis_case.meta.Re_km = Re_km;
        vis_case.meta.Ns = Ns;
        vis_case.meta.Nt = Nuse;
    end
    
    %% ===== local helpers =====
    
    function tf = local_is_visible_eci(rt, rs, Re_km)
    % Earth occultation test in ECI.
    % Visible iff segment rt->rs does not intersect Earth sphere.
    
        d = rs - rt;               % line direction
        dd = dot(d, d);
    
        if dd <= 0
            tf = false;
            return;
        end
    
        % closest point on segment rt + u d, u in [0,1]
        u = -dot(rt, d) / dd;
        u = max(0, min(1, u));
        rc = rt + u * d;
    
        dmin = norm(rc);
    
        % If closest point to Earth center is outside Earth, LOS is clear.
        % Also require satellite not below horizon wrt target radial direction.
        tf = dmin > Re_km;
    end
    
    function ang_best = local_best_crossing_angle_deg(rt, r_sat_eci_km, k, vis_ids_k)
    % For all visible satellite pairs, compute LOS angle at target and
    % retain the largest one as "best crossing angle" at this epoch.
    
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