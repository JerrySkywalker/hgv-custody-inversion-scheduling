function traj = propagate_single_track(case_i, cfg, hgv_cfg)
    %propagate_single_track
    % Propagate one HGV case using reused VTC dynamics.
    %
    % Stage04G.4a:
    %   - heading family truly enters dynamics via sigma0
    %   - control profile comes from build_control_profile()
    %   - output remains compatible with Stage04G geodetic pipeline
    
        if nargin < 3 || isempty(hgv_cfg)
            hgv_cfg = build_dynamics_init_from_case(case_i, cfg);
        end
    
        % ------------------------------------------------------------
        % Parameter set
        % ------------------------------------------------------------
        p = local_hgv_params();
    
        % ------------------------------------------------------------
        % Initial state
        % X = [v, theta, sigma, phi, lambda, r]^T
        % ------------------------------------------------------------
        X0 = [ ...
            hgv_cfg.v0, ...
            hgv_cfg.theta0, ...
            hgv_cfg.sigma0, ...
            hgv_cfg.phi0, ...
            hgv_cfg.lambda0, ...
            p.Re + hgv_cfg.h0 ]';
    
        % ------------------------------------------------------------
        % Control profile
        % ------------------------------------------------------------
        ctrl = struct();
        ctrl.alpha_rad = deg2rad(hgv_cfg.ctrl_profile.alpha_deg);
        ctrl.gamma_rad = deg2rad(hgv_cfg.ctrl_profile.bank_deg);
    
        t0 = cfg.stage02.t0_s;
        tf = cfg.stage02.Tmax_s;
    
        event_params = local_make_event_params(cfg, p.Re);
        opts = odeset('RelTol',1e-6, 'AbsTol',1e-6, ...
            'Events', @(t,X) local_hgv_events_fast(X, event_params));

        [T, X] = ode45(@(t,X) local_hgv_vtc_dynamics_const(X, ctrl.alpha_rad, ctrl.gamma_rad, p), [t0 tf], X0, opts);
    
        % ------------------------------------------------------------
        % Uniform resampling
        % ------------------------------------------------------------
        t_uniform = (t0 : cfg.stage02.Ts_s : T(end))';
        X_uniform = interp1(T, X, t_uniform, 'linear');
    
        % ------------------------------------------------------------
        % Geodetic states
        % ------------------------------------------------------------
        v_mps   = X_uniform(:,1);
        phi_rad = X_uniform(:,4);
        lam_rad = X_uniform(:,5);
        r_m     = X_uniform(:,6);
    
        lat_deg = rad2deg(phi_rad);
        lon_deg = rad2deg(lam_rad);
        h_m     = r_m - p.Re;
        h_km    = h_m / 1000;
    
        N = size(X_uniform,1);
    
        % ------------------------------------------------------------
        % ECEF
        % ------------------------------------------------------------
        r_ecef_m = geodetic_to_ecef(lat_deg, lon_deg, h_m, cfg).';
        r_ecef_km = r_ecef_m / 1000;
    
        % ------------------------------------------------------------
        % Anchor-local ENU
        % ------------------------------------------------------------
        r_enu_m = ecef_to_local_enu( ...
            r_ecef_m, ...
            cfg.geo.lat0_deg, cfg.geo.lon0_deg, cfg.geo.h0_m, cfg);
        r_enu_km = r_enu_m / 1000;
        xy_km = r_enu_km(:,1:2);
    
        % ------------------------------------------------------------
        % ECI
        % ------------------------------------------------------------
        r_eci_m = ecef_to_eci(r_ecef_m, cfg.time.epoch_utc, t_uniform);
        if size(r_eci_m,1) == 3 && size(r_eci_m,2) == N
            r_eci_m = r_eci_m.';
        end
        r_eci_km = r_eci_m / 1000;
    
        % ------------------------------------------------------------
        % Pack
        % ------------------------------------------------------------
        traj = struct();
        traj.case_id = case_i.case_id;
        traj.family = case_i.family;
        traj.subfamily = case_i.subfamily;
    
        traj.t_s = t_uniform;
        traj.X = X_uniform;
    
        traj.lat_deg = lat_deg;
        traj.lon_deg = lon_deg;
        traj.h_m = h_m;
        traj.h_km = h_km;
    
        traj.r_enu_m  = r_enu_m;
        traj.r_enu_km = r_enu_km;
    
        traj.r_ecef_m  = r_ecef_m;
        traj.r_ecef_km = r_ecef_km;
    
        traj.r_eci_m  = r_eci_m;
        traj.r_eci_km = r_eci_km;
    
        % backward-compatible fields
        traj.xy_km = xy_km;
        traj.v_mps = v_mps;
    
        traj.scene_mode = local_get_scene_mode(cfg);
        traj.anchor_lat_deg = cfg.geo.lat0_deg;
        traj.anchor_lon_deg = cfg.geo.lon0_deg;
        traj.anchor_h_m = cfg.geo.h0_m;
        traj.epoch_utc = cfg.time.epoch_utc;
    
        traj.meta = struct();
        traj.meta.hgv_cfg = hgv_cfg;
        traj.meta.p = p;
        traj.meta.heading_deg = local_get_case_heading(case_i);
        traj.meta.heading_offset_deg = local_get_case_heading_offset(case_i);
        traj.meta.sigma0_deg = rad2deg(hgv_cfg.sigma0);
        traj.meta.bank_cmd_deg = hgv_cfg.ctrl_profile.bank_deg;
        traj.meta.alpha_cmd_deg = hgv_cfg.ctrl_profile.alpha_deg;
    end
    
    function scene_mode = local_get_scene_mode(cfg)
        if isfield(cfg, 'meta') && isfield(cfg.meta, 'scene_mode')
            scene_mode = cfg.meta.scene_mode;
        elseif isfield(cfg, 'geo') && isfield(cfg.geo, 'enable_geodetic_anchor') && cfg.geo.enable_geodetic_anchor
            scene_mode = 'geodetic';
        else
            scene_mode = 'abstract';
        end
    end
    
    function v = local_get_case_heading(case_i)
        if isfield(case_i, 'heading_deg')
            v = case_i.heading_deg;
        else
            v = NaN;
        end
    end
    
    function v = local_get_case_heading_offset(case_i)
        if isfield(case_i, 'heading_offset_deg')
            v = case_i.heading_offset_deg;
        else
            v = NaN;
        end
    end

    function p = local_hgv_params()
        persistent params_cached
        if isempty(params_cached)
            params_cached = struct();
            params_cached.Re = 6378137;
            params_cached.mu = 3.986e14;
            params_cached.g0 = 9.80665;
            params_cached.m = 907.2;
            params_cached.S = 0.4839;
            params_cached.coef_L = [0.0301, 2.2992, 1.2287, -1.3001e-4, 0.2047, -6.1460e-2];
            params_cached.coef_D = [0.0100, -0.1748, 2.7247, 4.5781e-4, 0.3591, -6.9440e-2];
        end
        p = params_cached;
    end

    function event_params = local_make_event_params(cfg, re_m)
        event_params = struct();
        event_params.Re = re_m;
        event_params.phi_ref_rad = deg2rad(cfg.stage02.phi_ref_deg);
        event_params.lambda_ref_rad = deg2rad(cfg.stage02.lambda_ref_deg);
        event_params.cos_phi_ref = cos(event_params.phi_ref_rad);
        event_params.re_km = cfg.stage02.Re_m / 1000;
        event_params.center_x_km = cfg.stage01.disk_center_xy_km(1);
        event_params.center_y_km = cfg.stage01.disk_center_xy_km(2);
        event_params.h_min_m = cfg.stage02.h_min_m;
        event_params.h_max_m = cfg.stage02.h_max_m;
        event_params.v_min_mps = cfg.stage02.v_min_mps;
        event_params.v_max_mps = cfg.stage02.v_max_mps;
        event_params.enable_task_capture_event = cfg.stage02.enable_task_capture_event;
        event_params.capture_radius_km = cfg.stage02.capture_radius_km;
        event_params.enable_landing_event = cfg.stage02.enable_landing_event;
    end

    function dX = local_hgv_vtc_dynamics_const(X, alpha_rad, gamma_rad, p)
        v = X(1);
        th = X(2);
        si = X(3);
        ph = X(4);
        r = X(6);

        h = r - p.Re;
        if h <= 0
            dX = zeros(6,1);
            return;
        end

        [rho, a_s] = atmosphere_us76(h);
        Ma = v / a_s;

        CL = p.coef_L(1) + p.coef_L(2) * alpha_rad + p.coef_L(3) * alpha_rad^2 + ...
            p.coef_L(4) * Ma + p.coef_L(5) * exp(p.coef_L(6) * Ma);
        CD = p.coef_D(1) + p.coef_D(2) * alpha_rad + p.coef_D(3) * alpha_rad^2 + ...
            p.coef_D(4) * Ma + p.coef_D(5) * exp(p.coef_D(6) * Ma);

        Q = 0.5 * rho * v^2 * p.S;
        L = Q * CL;
        D = Q * CD;

        cos_th = cos(th);
        sin_th = sin(th);

        dv = -D / p.m - p.mu / r^2 * sin_th;
        dth = (L * cos(gamma_rad) - p.m * p.g0 * cos_th + p.m * v^2 / r * cos_th) / (p.m * v);
        dsi = -(L * sin(gamma_rad)) / (p.m * v * cos_th) + (v / r) * cos_th * sin(si) * tan(ph);
        dph = v * cos_th * cos(si) / r;
        dla = -v * cos_th * sin(si) / (r * cos(ph));
        dr = v * sin_th;

        dX = [dv; dth; dsi; dph; dla; dr];
    end

    function [value, isterminal, direction] = local_hgv_events_fast(X, event_params)
        v = X(1);
        phi = X(4);
        lambda = X(5);
        r = X(6);

        h_m = r - event_params.Re;

        value = zeros(6, 1);
        isterminal = ones(6, 1);
        direction = -ones(6, 1);

        value(1) = h_m - event_params.h_min_m;
        value(2) = event_params.h_max_m - h_m;
        value(3) = v - event_params.v_min_mps;
        value(4) = event_params.v_max_mps - v;

        next_idx = 5;
        if event_params.enable_task_capture_event
            y_km = (phi - event_params.phi_ref_rad) * event_params.re_km;
            x_km = (lambda - event_params.lambda_ref_rad) * event_params.re_km * event_params.cos_phi_ref;
            dist_to_center_km = hypot(x_km - event_params.center_x_km, y_km - event_params.center_y_km);
            value(next_idx) = dist_to_center_km - event_params.capture_radius_km;
            next_idx = next_idx + 1;
        end

        if event_params.enable_landing_event
            value(next_idx) = h_m;
            next_idx = next_idx + 1;
        end

        value = value(1:next_idx - 1);
        isterminal = isterminal(1:next_idx - 1);
        direction = direction(1:next_idx - 1);
    end

