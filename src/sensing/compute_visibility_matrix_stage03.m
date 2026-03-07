function vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg)
    %COMPUTE_VISIBILITY_MATRIX_STAGE03 Compute target-satellite visibility mask.
    
        t_s = traj_case.traj.t_s;
        Nt = numel(t_s);
        Ns = satbank.Ns;

        assert(size(satbank.r_eci_km,1) >= Nt, ...
            'satbank time dimension (%d) is shorter than trajectory time dimension (%d).', ...
            size(satbank.r_eci_km,1), Nt);
    
        % Build target inertial-like position directly from Stage02 spherical state
        r_tgt_eci_km = eci_from_stage02_target_stage03(traj_case, cfg);
    
        visible_mask = false(Nt, Ns);
    
        for k = 1:Nt
            r_tgt_km = r_tgt_eci_km(k,:);
            for s = 1:Ns
                r_sat_km = satbank.r_eci_km(k,:,s);
                visible_mask(k,s) = is_visible_stage03(r_sat_km, r_tgt_km, cfg);
            end
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
