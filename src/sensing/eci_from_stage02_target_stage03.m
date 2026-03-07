function r_tgt_eci_km = eci_from_stage02_target_stage03(traj_case, cfg)
    %ECI_FROM_STAGE02_TARGET_STAGE03
    % Build target inertial-like position from Stage02 state X = [v,theta,sigma,phi,lambda,r].
    %
    % For Stage03.1 we use a simplified spherical Earth position mapping:
    %   r = r * [cos(phi)cos(lambda), cos(phi)sin(lambda), sin(phi)]
    %
    % This is far more self-consistent than the previous pseudo-ECI local map.
    % It is sufficient for visibility geometry refinement at this stage.
    
        X = traj_case.traj.X;
    
        phi = X(:,4);
        lambda = X(:,5);
        r_km = X(:,6) / 1000;   % Stage02 stores r in meters
    
        x = r_km .* cos(phi) .* cos(lambda);
        y = r_km .* cos(phi) .* sin(lambda);
        z = r_km .* sin(phi);
    
        r_tgt_eci_km = [x, y, z];
    end