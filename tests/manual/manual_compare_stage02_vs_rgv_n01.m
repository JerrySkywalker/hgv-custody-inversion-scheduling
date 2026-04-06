function out = manual_compare_stage02_vs_rgv_n01()
%MANUAL_COMPARE_STAGE02_VS_RGV_N01
% Compare Stage02 N01 trajectory against an RGV-style reference propagator.
%
% Purpose
%   1) Use the same N01 initial condition and same constant control
%   2) Compare Stage02 packed trajectory with a reference integrator copied
%      from RGV_Simulation_All_In_One.m dynamics/process style
%   3) Distinguish:
%        - dynamics / propagation mismatch
%        - resampling mismatch
%        - coordinate / plotting mismatch
%
% Output
%   out.metrics
%   out.files
%   out.case_i
%   out.hgv_cfg
%   out.stage02_traj
%   out.rgv_ref
%
% Recommended usage
%   >> clear functions
%   >> rehash
%   >> startup('force', true)
%   >> out = manual_compare_stage02_vs_rgv_n01();

    clearvars -except out;
    close all;
    clc;

    startup('force', true);

    cfg = default_params();

    % ----------------------------
    % Reduce unrelated variability
    % ----------------------------
    if isfield(cfg, 'parallel'); cfg.parallel.enabled = false; end
    if isfield(cfg, 'benchmark'); cfg.benchmark.enabled = false; end

    if isfield(cfg, 'stage02')
        cfg.stage02.make_plot = false;
        cfg.stage02.make_plot_3d = false;
    end

    out_dir = fullfile(pwd, 'outputs', 'manual', 'stage02_vs_rgv_n01');
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end

    % ----------------------------
    % Ensure Stage01 casebank exists
    % ----------------------------
    stage01_file = local_ensure_stage01_cache(cfg);

    tmp = load(stage01_file);
    assert(isfield(tmp, 'out') && isfield(tmp.out, 'casebank'), ...
        'Invalid Stage01 cache file: missing out.casebank');
    casebank = tmp.out.casebank;

    case_i = local_find_case_by_id(casebank, 'N01');
    assert(~isempty(case_i), 'Cannot find case_id = N01 in Stage01 casebank.');

    % ----------------------------
    % Build Stage02 HGV config from N01
    % ----------------------------
    hgv_cfg = build_hgv_cfg_from_case_stage02(case_i, cfg);

    % ----------------------------
    % Run Stage02 current implementation
    % ----------------------------
    traj_stage02 = propagate_hgv_case_stage02(case_i, cfg, hgv_cfg);

    % ----------------------------
    % Run RGV-style reference with same N01 IC/control
    % ----------------------------
    ref = local_propagate_rgv_reference_on_n01(cfg, hgv_cfg);

    % ----------------------------
    % Compare on Stage02 uniform time grid
    % ----------------------------
    tq = traj_stage02.t_s(:);

    X_ref_q = interp1(ref.T_raw, ref.X_raw, tq, 'linear', 'extrap');
    lat_ref_q = interp1(ref.T_raw, ref.lat_deg_raw, tq, 'linear', 'extrap');
    lon_ref_q = interp1(ref.T_raw, ref.lon_deg_raw, tq, 'linear', 'extrap');
    h_ref_q   = interp1(ref.T_raw, ref.h_km_raw,   tq, 'linear', 'extrap');

    r_ecef_ref_m = geodetic_to_ecef(lat_ref_q, lon_ref_q, h_ref_q * 1000, cfg).';
    r_enu_ref_m = ecef_to_local_enu( ...
        r_ecef_ref_m, ...
        cfg.geo.lat0_deg, cfg.geo.lon0_deg, cfg.geo.h0_m, cfg);
    r_enu_ref_km = r_enu_ref_m / 1000;

    % ----------------------------
    % Metrics
    % ----------------------------
    dX = traj_stage02.X - X_ref_q;
    d_lat_deg = traj_stage02.lat_deg - lat_ref_q;
    d_lon_deg = traj_stage02.lon_deg - lon_ref_q;
    d_h_km    = traj_stage02.h_km - h_ref_q;
    d_enu_km  = traj_stage02.r_enu_km - r_enu_ref_km;

    metrics = struct();
    metrics.max_abs_state = max(abs(dX), [], 1);
    metrics.rms_state = sqrt(mean(dX.^2, 1));

    metrics.max_abs_lat_deg = max(abs(d_lat_deg));
    metrics.max_abs_lon_deg = max(abs(d_lon_deg));
    metrics.max_abs_h_km    = max(abs(d_h_km));

    metrics.rms_lat_deg = sqrt(mean(d_lat_deg.^2));
    metrics.rms_lon_deg = sqrt(mean(d_lon_deg.^2));
    metrics.rms_h_km    = sqrt(mean(d_h_km.^2));

    metrics.max_abs_enu_km = max(abs(d_enu_km), [], 1);
    metrics.rms_enu_km = sqrt(mean(d_enu_km.^2, 1));

    metrics.final_stage02_lat_lon_h = [traj_stage02.lat_deg(end), traj_stage02.lon_deg(end), traj_stage02.h_km(end)];
    metrics.final_ref_lat_lon_h     = [lat_ref_q(end), lon_ref_q(end), h_ref_q(end)];

    % ----------------------------
    % Save metrics text
    % ----------------------------
    metrics_txt = fullfile(out_dir, 'compare_metrics.txt');
    local_write_metrics(metrics_txt, metrics, case_i, hgv_cfg, stage01_file);

    % ----------------------------
    % Plot 1: lon-lat-h overlay
    % ----------------------------
    fig1 = figure('Color', 'w', 'Name', 'N01 compare lon-lat-h');
    plot3(ref.lon_deg_raw, ref.lat_deg_raw, ref.h_km_raw, 'k--', 'LineWidth', 1.2); hold on;
    plot3(traj_stage02.lon_deg, traj_stage02.lat_deg, traj_stage02.h_km, 'b-', 'LineWidth', 1.2);
    grid on; axis square; view(225, 25);
    xlabel('Longitude (deg)');
    ylabel('Latitude (deg)');
    zlabel('Height (km)');
    legend('RGV-style reference', 'Stage02 packed', 'Location', 'best');
    title('N01 comparison in lon-lat-h');
    f1 = fullfile(out_dir, 'compare_lon_lat_h.png');
    exportgraphics(fig1, f1, 'Resolution', 220);
    close(fig1);

    % ----------------------------
    % Plot 2: anchor-local ENU overlay
    % ----------------------------
    fig2 = figure('Color', 'w', 'Name', 'N01 compare ENU');
    plot3(r_enu_ref_km(:,1), r_enu_ref_km(:,2), h_ref_q, 'k--', 'LineWidth', 1.2); hold on;
    plot3(traj_stage02.xy_km(:,1), traj_stage02.xy_km(:,2), traj_stage02.h_km, 'b-', 'LineWidth', 1.2);
    grid on; axis equal; view(225, 25);
    xlabel('East (km)');
    ylabel('North (km)');
    zlabel('Height (km)');
    legend('RGV-style reference projected to ENU', 'Stage02 packed ENU', 'Location', 'best');
    title('N01 comparison in anchor-local ENU');
    f2 = fullfile(out_dir, 'compare_enu_xyz.png');
    exportgraphics(fig2, f2, 'Resolution', 220);
    close(fig2);

    % ----------------------------
    % Plot 3: state differences
    % ----------------------------
    fig3 = figure('Color', 'w', 'Name', 'N01 state diffs');
    tiledlayout(3,2, 'Padding','compact', 'TileSpacing','compact');

    labels = {'v (m/s)', '\theta (rad)', '\sigma (rad)', '\phi (rad)', '\lambda (rad)', 'r (m)'};
    for i = 1:6
        nexttile;
        plot(tq, dX(:,i), 'LineWidth', 1.0);
        grid on;
        xlabel('Time (s)');
        ylabel(['\Delta ' labels{i}]);
    end
    title(tiledlayout(3,2), 'State difference: Stage02 - RGV reference');
    f3 = fullfile(out_dir, 'compare_state_diffs.png');
    exportgraphics(fig3, f3, 'Resolution', 220);
    close(fig3);

    % ----------------------------
    % Plot 4: lat/lon/h and ENU diffs
    % ----------------------------
    fig4 = figure('Color', 'w', 'Name', 'N01 output diffs');
    tiledlayout(3,2, 'Padding','compact', 'TileSpacing','compact');

    nexttile; plot(tq, d_lat_deg, 'LineWidth',1.0); grid on; xlabel('Time (s)'); ylabel('\Delta lat (deg)');
    nexttile; plot(tq, d_lon_deg, 'LineWidth',1.0); grid on; xlabel('Time (s)'); ylabel('\Delta lon (deg)');
    nexttile; plot(tq, d_h_km,    'LineWidth',1.0); grid on; xlabel('Time (s)'); ylabel('\Delta h (km)');
    nexttile; plot(tq, d_enu_km(:,1), 'LineWidth',1.0); grid on; xlabel('Time (s)'); ylabel('\Delta East (km)');
    nexttile; plot(tq, d_enu_km(:,2), 'LineWidth',1.0); grid on; xlabel('Time (s)'); ylabel('\Delta North (km)');
    nexttile; plot(tq, d_enu_km(:,3), 'LineWidth',1.0); grid on; xlabel('Time (s)'); ylabel('\Delta Up (km)');
    title(tiledlayout(3,2), 'Output difference: Stage02 - RGV reference');
    f4 = fullfile(out_dir, 'compare_output_diffs.png');
    exportgraphics(fig4, f4, 'Resolution', 220);
    close(fig4);

    % ----------------------------
    % Plot 5: Stage02 same trajectory, two plotting dialects
    % ----------------------------
    fig5 = figure('Color', 'w', 'Name', 'Stage02 same traj two dialects');
    tiledlayout(1,2, 'Padding','compact', 'TileSpacing','compact');

    nexttile;
    plot3(traj_stage02.lon_deg, traj_stage02.lat_deg, traj_stage02.h_km, 'b-', 'LineWidth', 1.2);
    grid on; axis square; view(225,25);
    xlabel('Longitude (deg)');
    ylabel('Latitude (deg)');
    zlabel('Height (km)');
    title('Stage02 plotted in lon-lat-h');

    nexttile;
    plot3(traj_stage02.xy_km(:,1), traj_stage02.xy_km(:,2), traj_stage02.h_km, 'r-', 'LineWidth', 1.2);
    grid on; axis equal; view(225,25);
    xlabel('East (km)');
    ylabel('North (km)');
    zlabel('Height (km)');
    title('Stage02 plotted in anchor-local ENU');

    f5 = fullfile(out_dir, 'stage02_two_plotting_dialects.png');
    exportgraphics(fig5, f5, 'Resolution', 220);
    close(fig5);

    % ----------------------------
    % Console summary
    % ----------------------------
    fprintf('\n');
    fprintf('========== manual_compare_stage02_vs_rgv_n01 ==========\n');
    fprintf('Stage01 cache : %s\n', stage01_file);
    fprintf('Case ID       : %s\n', local_safe_get(case_i, 'case_id', ''));
    fprintf('Family        : %s\n', local_safe_get(case_i, 'family', ''));
    fprintf('Subfamily     : %s\n', local_safe_get(case_i, 'subfamily', ''));
    fprintf('Heading deg   : %.6f\n', local_safe_get(case_i, 'heading_deg', NaN));
    fprintf('sigma0 deg    : %.6f\n', rad2deg(hgv_cfg.sigma0));
    fprintf('alpha deg     : %.6f\n', hgv_cfg.ctrl_profile.alpha_deg);
    fprintf('bank deg      : %.6f\n', hgv_cfg.ctrl_profile.bank_deg);
    fprintf('\n');
    fprintf('max|dX|       : [%g  %g  %g  %g  %g  %g]\n', metrics.max_abs_state);
    fprintf('max|dlat|     : %g deg\n', metrics.max_abs_lat_deg);
    fprintf('max|dlon|     : %g deg\n', metrics.max_abs_lon_deg);
    fprintf('max|dh|       : %g km\n', metrics.max_abs_h_km);
    fprintf('max|dENU|     : [%g  %g  %g] km\n', metrics.max_abs_enu_km);
    fprintf('\n');
    fprintf('metrics txt   : %s\n', metrics_txt);
    fprintf('plot 1        : %s\n', f1);
    fprintf('plot 2        : %s\n', f2);
    fprintf('plot 3        : %s\n', f3);
    fprintf('plot 4        : %s\n', f4);
    fprintf('plot 5        : %s\n', f5);
    fprintf('=======================================================\n');

    out = struct();
    out.case_i = case_i;
    out.hgv_cfg = hgv_cfg;
    out.stage02_traj = traj_stage02;
    out.rgv_ref = ref;
    out.metrics = metrics;
    out.files = struct( ...
        'metrics_txt', metrics_txt, ...
        'compare_lon_lat_h', f1, ...
        'compare_enu_xyz', f2, ...
        'compare_state_diffs', f3, ...
        'compare_output_diffs', f4, ...
        'stage02_two_plotting_dialects', f5);
end

% =========================================================================
% Helpers
% =========================================================================
function stage01_file = local_ensure_stage01_cache(cfg)
    d = find_stage_cache_files(cfg.paths.cache, 'stage01_scenario_disk_*.mat');
    if isempty(d)
        fprintf('[manual_compare] No Stage01 cache found. Running Stage01 once...\n');
        out1 = stage01_scenario_disk(cfg, struct('mode', 'full'));
        assert(isfield(out1, 'cache_file') && exist(out1.cache_file, 'file') == 2, ...
            'Stage01 run did not produce a valid cache file.');
        stage01_file = out1.cache_file;
        return;
    end

    [~, idx_latest] = max([d.datenum]);
    stage01_file = fullfile(d(idx_latest).folder, d(idx_latest).name);
end

function case_i = local_find_case_by_id(casebank, case_id)
    case_i = [];

    families = {'nominal', 'heading', 'critical'};
    for i = 1:numel(families)
        name = families{i};
        if ~isfield(casebank, name)
            continue;
        end
        arr = casebank.(name);
        if isempty(arr)
            continue;
        end
        idx = find(arrayfun(@(s) isfield(s, 'case_id') && strcmp(string(s.case_id), string(case_id)), arr), 1, 'first');
        if ~isempty(idx)
            case_i = arr(idx);
            return;
        end
    end
end

function ref = local_propagate_rgv_reference_on_n01(cfg, hgv_cfg)
    p = local_hgv_params_ref();

    X0 = [ ...
        hgv_cfg.v0; ...
        hgv_cfg.theta0; ...
        hgv_cfg.sigma0; ...
        hgv_cfg.phi0; ...
        hgv_cfg.lambda0; ...
        p.Re + hgv_cfg.h0 ];

    ctrl.alpha = @(t) hgv_cfg.ctrl_profile.alpha_deg;
    ctrl.gamma = @(t) hgv_cfg.ctrl_profile.bank_deg;

    t0 = cfg.stage02.t0_s;
    tf = cfg.stage02.Tmax_s;

    opts = odeset('RelTol',1e-6, 'AbsTol',1e-6, ...
        'Events', @(t,y) local_events_landing_ref(t,y,p));

    [T_raw, X_raw] = ode45(@(t,y) local_dynamics_cavh_ref(t,y,ctrl,p), [t0 tf], X0, opts);

    lat_deg_raw = rad2deg(X_raw(:,4));
    lon_deg_raw = rad2deg(X_raw(:,5));
    h_km_raw    = (X_raw(:,6) - p.Re) / 1000;

    ref = struct();
    ref.T_raw = T_raw;
    ref.X_raw = X_raw;
    ref.lat_deg_raw = lat_deg_raw;
    ref.lon_deg_raw = lon_deg_raw;
    ref.h_km_raw = h_km_raw;
    ref.ctrl = ctrl;
end

function p = local_hgv_params_ref()
    p = struct();
    p.Re = 6378137;
    p.mu = 3.986e14;
    p.g0 = 9.80665;
    p.m = 907.2;
    p.S = 0.4839;
    p.coef_L = [0.0301, 2.2992, 1.2287, -1.3001e-4, 0.2047, -6.1460e-2];
    p.coef_D = [0.0100, -0.1748, 2.7247, 4.5781e-4, 0.3591, -6.9440e-2];
end

function dydt = local_dynamics_cavh_ref(t, y, ctrl, p)
    v = y(1);
    th = y(2);
    si = y(3);
    ph = y(4);
    r = y(6);

    h = r - p.Re;
    if h <= 0
        dydt = zeros(6,1);
        return;
    end

    [rho, a_s] = local_atmosphere_us76_manual_ref(h);
    Ma = v / a_s;
    alpha = deg2rad(ctrl.alpha(t));
    gamma = deg2rad(ctrl.gamma(t));

    CL = p.coef_L(1) + p.coef_L(2)*alpha + p.coef_L(3)*alpha^2 + p.coef_L(4)*Ma + p.coef_L(5)*exp(p.coef_L(6)*Ma);
    CD = p.coef_D(1) + p.coef_D(2)*alpha + p.coef_D(3)*alpha^2 + p.coef_D(4)*Ma + p.coef_D(5)*exp(p.coef_D(6)*Ma);

    Q = 0.5 * rho * v^2 * p.S;
    L = Q * CL;
    D = Q * CD;

    dv  = -D/p.m - p.mu/r^2 * sin(th);
    dth = (L*cos(gamma) - p.m*p.g0*cos(th) + p.m*v^2/r*cos(th)) / (p.m*v);
    dsi = -(L*sin(gamma)) / (p.m*v*cos(th)) + (v/r)*cos(th)*sin(si)*tan(ph);
    dph = v*cos(th)*cos(si) / r;
    dla = -v*cos(th)*sin(si) / (r*cos(ph));
    dr  = v*sin(th);

    dydt = [dv; dth; dsi; dph; dla; dr];
end

function [rho, a] = local_atmosphere_us76_manual_ref(h)
    h_km = h / 1000;
    if h_km < 11
        T = 288.15 - 6.5*h_km;
        P = 101325 * (T/288.15)^5.256;
    elseif h_km < 20
        T = 216.65;
        P = 22632 * exp(-0.1577*(h_km-11));
    elseif h_km < 32
        T = 216.65 + (h_km-20);
        P = 5474.9 * (216.65/T)^34.163;
    elseif h_km < 47
        T = 228.65 + 2.8*(h_km-32);
        P = 868.02 * (228.65/T)^12.201;
    elseif h_km < 51
        T = 270.65;
        P = 110.91 * exp(-0.1262*(h_km-47));
    elseif h_km < 71
        T = 270.65 - 2.8*(h_km-51);
        P = 66.939 * (T/270.65)^12.201;
    else
        T = 214.65 - 2.0*(h_km-71);
        P = 3.9564 * (T/214.65)^17.082;
    end

    rho = P / (287.05 * T);
    a = sqrt(1.4 * 287.05 * T);
end

function [value, isterminal, direction] = local_events_landing_ref(~, y, p)
    value = y(6) - p.Re;
    isterminal = 1;
    direction = -1;
end

function local_write_metrics(filepath, metrics, case_i, hgv_cfg, stage01_file)
    fid = fopen(filepath, 'w');
    assert(fid > 0, 'Failed to open metrics file: %s', filepath);
    c = onCleanup(@() fclose(fid)); %#ok<NASGU>

    fprintf(fid, 'manual_compare_stage02_vs_rgv_n01\n');
    fprintf(fid, 'stage01_cache = %s\n', stage01_file);
    fprintf(fid, 'case_id       = %s\n', local_safe_get(case_i, 'case_id', ''));
    fprintf(fid, 'family        = %s\n', local_safe_get(case_i, 'family', ''));
    fprintf(fid, 'subfamily     = %s\n', local_safe_get(case_i, 'subfamily', ''));
    fprintf(fid, 'heading_deg   = %.12g\n', local_safe_get(case_i, 'heading_deg', NaN));
    fprintf(fid, 'sigma0_deg    = %.12g\n', rad2deg(hgv_cfg.sigma0));
    fprintf(fid, 'alpha_deg     = %.12g\n', hgv_cfg.ctrl_profile.alpha_deg);
    fprintf(fid, 'bank_deg      = %.12g\n', hgv_cfg.ctrl_profile.bank_deg);
    fprintf(fid, '\n');

    fprintf(fid, 'max_abs_state = [% .12e  % .12e  % .12e  % .12e  % .12e  % .12e]\n', metrics.max_abs_state);
    fprintf(fid, 'rms_state     = [% .12e  % .12e  % .12e  % .12e  % .12e  % .12e]\n', metrics.rms_state);
    fprintf(fid, '\n');

    fprintf(fid, 'max_abs_lat_deg = %.12e\n', metrics.max_abs_lat_deg);
    fprintf(fid, 'max_abs_lon_deg = %.12e\n', metrics.max_abs_lon_deg);
    fprintf(fid, 'max_abs_h_km    = %.12e\n', metrics.max_abs_h_km);
    fprintf(fid, 'rms_lat_deg     = %.12e\n', metrics.rms_lat_deg);
    fprintf(fid, 'rms_lon_deg     = %.12e\n', metrics.rms_lon_deg);
    fprintf(fid, 'rms_h_km        = %.12e\n', metrics.rms_h_km);
    fprintf(fid, '\n');

    fprintf(fid, 'max_abs_enu_km = [% .12e  % .12e  % .12e]\n', metrics.max_abs_enu_km);
    fprintf(fid, 'rms_enu_km     = [% .12e  % .12e  % .12e]\n', metrics.rms_enu_km);
    fprintf(fid, '\n');

    fprintf(fid, 'final_stage02_lat_lon_h = [% .12e  % .12e  % .12e]\n', metrics.final_stage02_lat_lon_h);
    fprintf(fid, 'final_ref_lat_lon_h     = [% .12e  % .12e  % .12e]\n', metrics.final_ref_lat_lon_h);
end

function v = local_safe_get(s, field_name, defaultv)
    if isstruct(s) && isfield(s, field_name)
        v = s.(field_name);
    else
        v = defaultv;
    end
end