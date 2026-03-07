function traj = propagate_hgv_case_stage02(case_i, cfg)
    %PROPAGATE_HGV_CASE_STAGE02
    % Propagate one HGV case using reused VTC dynamics from old project.
    
        hgv_cfg = build_hgv_cfg_from_case_stage02(case_i, cfg);
    
        % Parameter set consistent with old stage11c generator
        p = struct();
        p.Re = 6378137;
        p.mu = 3.986e14;
        p.g0 = 9.80665;
        p.m = 907.2;
        p.S = 0.4839;
        p.coef_L = [0.0301, 2.2992, 1.2287, -1.3001e-4, 0.2047, -6.1460e-2];
        p.coef_D = [0.0100, -0.1748, 2.7247, 4.5781e-4, 0.3591, -6.9440e-2];
    
        X0 = [ ...
            hgv_cfg.v0, ...
            hgv_cfg.theta0, ...
            hgv_cfg.sigma0, ...
            hgv_cfg.phi0, ...
            hgv_cfg.lambda0, ...
            p.Re + hgv_cfg.h0 ]';
    
        % old dynamics expects ctrl.alpha(t), ctrl.gamma(t)
        ctrl = struct();
        ctrl.alpha = @(t) hgv_cfg.ctrl_profile.alpha_deg;
        ctrl.gamma = @(t) hgv_cfg.ctrl_profile.bank_deg;
    
        t0 = cfg.stage02.t0_s;
        tf = cfg.stage02.Tmax_s;
    
        opts = odeset('RelTol',1e-6, 'AbsTol',1e-6, ...
            'Events', @(t,X) events_hgv_stage02(t, X, cfg, p));
    
        [T, X] = ode45(@(t,X) hgv_vtc_dynamics(t, X, ctrl, p), [t0 tf], X0, opts);
    
        % Uniform resampling
        t_uniform = (t0 : cfg.stage02.Ts_s : T(end))';
        X_uniform = interp1(T, X, t_uniform, 'linear');
    
        % Convert geodetic states back to local abstract xy frame
        N = size(X_uniform,1);
        xy_km = zeros(N,2);
        for k = 1:N
            [xy_km(k,1), xy_km(k,2)] = geodetic_to_local_xy_stage02(X_uniform(k,4), X_uniform(k,5), cfg);
        end
    
        traj = struct();
        traj.case_id = case_i.case_id;
        traj.family = case_i.family;
        traj.subfamily = case_i.subfamily;
        traj.t_s = t_uniform;
        traj.X = X_uniform;         % [v theta sigma phi lambda r]
        traj.xy_km = xy_km;         % local abstract regional frame
        traj.h_km = (X_uniform(:,6) - p.Re) / 1000;
        traj.v_mps = X_uniform(:,1);
        traj.meta = struct('hgv_cfg', hgv_cfg, 'p', p);
    end
