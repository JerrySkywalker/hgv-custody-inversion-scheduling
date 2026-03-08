function r_tgt_eci_km = eci_from_stage02_target_stage03(traj_case, cfg)
    %ECI_FROM_STAGE02_TARGET_STAGE03
    % Return true inertial trajectory from Stage02 output.
    %
    % Stage04G.5:
    %   Stage02 already provides traj.r_eci_km, so Stage03 should use it
    %   directly instead of rebuilding a pseudo-ECI trajectory from spherical
    %   states.
    
        %#ok<INUSD>
        assert(isfield(traj_case, 'traj') && isfield(traj_case.traj, 'r_eci_km'), ...
            'Stage02 trajectory does not contain traj.r_eci_km.');
    
        r_tgt_eci_km = traj_case.traj.r_eci_km;
    
        assert(size(r_tgt_eci_km,2) == 3, ...
            'traj.r_eci_km must be Nt x 3.');
    end