function casebank = legacy_build_casebank_stage01_impl(cfg, opts)
%LEGACY_BUILD_CASEBANK_STAGE01_IMPL Copied Stage01 casebank builder.

if nargin < 2
    opts = struct();
end
opts = local_normalize_opts(cfg, opts);

R_in_km = cfg.stage01.R_in_km;

if isfield(cfg.stage01, 'nominal_entry_theta_deg')
    nominal_theta_deg = cfg.stage01.nominal_entry_theta_deg(:).';
else
    nominal_theta_deg = 0:30:330;
end

if isfield(cfg.stage01, 'heading_offsets_deg')
    heading_offsets_deg = cfg.stage01.heading_offsets_deg(:).';
else
    heading_offsets_deg = [0, -30, 30, -60, 60];
end

if isfield(cfg.stage01, 'critical_cases') && ~isempty(cfg.stage01.critical_cases)
    critical_cases = cfg.stage01.critical_cases;
else
    critical_cases = [
        struct('case_id', 'C1_track_plane_aligned', 'entry_theta_deg', 180, 'heading_deg', 0, 'family', 'critical', 'subfamily', 'track_plane_aligned')
        struct('case_id', 'C2_small_crossing_angle', 'entry_theta_deg', 210, 'heading_deg', 20, 'family', 'critical', 'subfamily', 'small_crossing_angle')
    ];
end

meta = struct();
meta.R_D_km = cfg.stage01.R_D_km;
meta.R_in_km = cfg.stage01.R_in_km;
meta.nominal_theta_deg = nominal_theta_deg;
meta.heading_offsets_deg = heading_offsets_deg;
meta.scene_mode = local_get_scene_mode(cfg);

if isfield(cfg, 'geo')
    meta.anchor_lat_deg = cfg.geo.lat0_deg;
    meta.anchor_lon_deg = cfg.geo.lon0_deg;
    meta.anchor_h_m = cfg.geo.h0_m;
end
if isfield(cfg, 'time')
    meta.epoch_utc = cfg.time.epoch_utc;
end

nominal = repmat(local_empty_case_struct(), numel(nominal_theta_deg), 1);
if opts.use_parallel
    parfor k = 1:numel(nominal_theta_deg)
        theta_deg = nominal_theta_deg(k);
        p_enu_km_plot = R_in_km * [cosd(theta_deg); sind(theta_deg); 0];
        heading_deg = wrapTo180(theta_deg + 180);
        nominal(k) = local_make_case( ...
            sprintf('N%02d', k), ...
            'nominal', ...
            'nominal', ...
            theta_deg, ...
            heading_deg, ...
            0, ...
            p_enu_km_plot, ...
            cfg);
    end
else
    for k = 1:numel(nominal_theta_deg)
        theta_deg = nominal_theta_deg(k);
        p_enu_km_plot = R_in_km * [cosd(theta_deg); sind(theta_deg); 0];
        heading_deg = wrapTo180(theta_deg + 180);
        nominal(k) = local_make_case( ...
            sprintf('N%02d', k), ...
            'nominal', ...
            'nominal', ...
            theta_deg, ...
            heading_deg, ...
            0, ...
            p_enu_km_plot, ...
            cfg);
    end
end

n_heading = numel(nominal_theta_deg) * numel(heading_offsets_deg);
heading = repmat(local_empty_case_struct(), n_heading, 1);

if opts.use_parallel
    parfor idx = 1:n_heading
        k = ceil(idx / numel(heading_offsets_deg));
        j = idx - (k - 1) * numel(heading_offsets_deg);
        base_theta_deg = nominal_theta_deg(k);
        p_enu_km_plot = R_in_km * [cosd(base_theta_deg); sind(base_theta_deg); 0];
        base_heading_deg = wrapTo180(base_theta_deg + 180);
        off_deg = heading_offsets_deg(j);
        heading_deg = wrapTo180(base_heading_deg + off_deg);
        heading(idx) = local_make_case( ...
            sprintf('H%02d_%+03d', k, off_deg), ...
            'heading', ...
            'heading', ...
            base_theta_deg, ...
            heading_deg, ...
            off_deg, ...
            p_enu_km_plot, ...
            cfg);
    end
else
    idx = 0;
    for k = 1:numel(nominal_theta_deg)
        base_theta_deg = nominal_theta_deg(k);
        p_enu_km_plot = R_in_km * [cosd(base_theta_deg); sind(base_theta_deg); 0];
        base_heading_deg = wrapTo180(base_theta_deg + 180);

        for j = 1:numel(heading_offsets_deg)
            idx = idx + 1;
            off_deg = heading_offsets_deg(j);
            heading_deg = wrapTo180(base_heading_deg + off_deg);

            heading(idx) = local_make_case( ...
                sprintf('H%02d_%+03d', k, off_deg), ...
                'heading', ...
                'heading', ...
                base_theta_deg, ...
                heading_deg, ...
                off_deg, ...
                p_enu_km_plot, ...
                cfg);
        end
    end
end

critical = repmat(local_empty_case_struct(), numel(critical_cases), 1);

if opts.use_parallel
    parfor k = 1:numel(critical_cases)
        c = critical_cases(k);
        p_enu_km_plot = R_in_km * [cosd(c.entry_theta_deg); sind(c.entry_theta_deg); 0];
        critical(k) = local_make_case( ...
            c.case_id, ...
            c.family, ...
            c.subfamily, ...
            c.entry_theta_deg, ...
            c.heading_deg, ...
            NaN, ...
            p_enu_km_plot, ...
            cfg);
    end
else
    for k = 1:numel(critical_cases)
        c = critical_cases(k);
        p_enu_km_plot = R_in_km * [cosd(c.entry_theta_deg); sind(c.entry_theta_deg); 0];
        critical(k) = local_make_case( ...
            c.case_id, ...
            c.family, ...
            c.subfamily, ...
            c.entry_theta_deg, ...
            c.heading_deg, ...
            NaN, ...
            p_enu_km_plot, ...
            cfg);
    end
end

casebank = struct();
casebank.meta = meta;
casebank.nominal = nominal;
casebank.heading = heading;
casebank.critical = critical;
end

function c = local_empty_case_struct()
c = struct();
c.case_id = '';
c.family = '';
c.subfamily = '';
c.entry_theta_deg = NaN;
c.heading_deg = NaN;
c.heading_offset_deg = NaN;
c.entry_point_xy_km = nan(1, 2);
c.entry_point_enu_km = nan(3, 1);
c.entry_point_enu_m = nan(3, 1);
c.heading_unit_xy = nan(1, 2);
c.heading_unit_enu = nan(3, 1);
c.entry_lat_deg = NaN;
c.entry_lon_deg = NaN;
c.entry_surface_dist_km = NaN;
c.entry_point_ecef_m = nan(3, 1);
c.entry_point_ecef_km = nan(3, 1);
c.entry_point_eci_m_t0 = nan(3, 1);
c.entry_point_eci_km_t0 = nan(3, 1);
c.heading_unit_ecef_t0 = nan(3, 1);
c.heading_unit_eci_t0 = nan(3, 1);
c.anchor_lat_deg = NaN;
c.anchor_lon_deg = NaN;
c.anchor_h_m = NaN;
c.epoch_utc = '';
c.scene_mode = '';
end

function c = local_make_case(case_id, family, subfamily, entry_theta_deg, heading_deg, heading_offset_deg, p_enu_km_plot, cfg)
c = local_empty_case_struct();

c.case_id = case_id;
c.family = family;
c.subfamily = subfamily;

c.entry_theta_deg = entry_theta_deg;
c.heading_deg = heading_deg;
c.heading_offset_deg = heading_offset_deg;
c.scene_mode = local_get_scene_mode(cfg);

if isfield(cfg, 'geo')
    c.anchor_lat_deg = cfg.geo.lat0_deg;
    c.anchor_lon_deg = cfg.geo.lon0_deg;
    c.anchor_h_m = cfg.geo.h0_m;
end
if isfield(cfg, 'time')
    c.epoch_utc = cfg.time.epoch_utc;
end

u_enu = [cosd(heading_deg); sind(heading_deg); 0];
u_enu = u_enu / norm(u_enu);

c.heading_unit_xy = u_enu(1:2).';
c.heading_unit_enu = u_enu;

if isfield(cfg, 'geo') && isfield(cfg.geo, 'enable_geodetic_anchor') && cfg.geo.enable_geodetic_anchor
    s_m = cfg.stage01.R_in_km * 1000;
    az_deg = mod(90 - entry_theta_deg, 360);
    R_m = cfg.geo.a_m;

    [lat_entry_deg, lon_entry_deg] = direct_geodesic_sphere( ...
        cfg.geo.lat0_deg, cfg.geo.lon0_deg, az_deg, s_m, R_m);

    c.entry_lat_deg = lat_entry_deg;
    c.entry_lon_deg = lon_entry_deg;
    c.entry_surface_dist_km = cfg.stage01.R_in_km;

    r_ecef_m = geodetic_to_ecef(lat_entry_deg, lon_entry_deg, cfg.geo.h0_m, cfg);
    r_eci_m = ecef_to_eci(r_ecef_m, cfg.time.epoch_utc, 0);

    c.entry_point_ecef_m = r_ecef_m;
    c.entry_point_ecef_km = r_ecef_m / 1000;
    c.entry_point_eci_m_t0 = r_eci_m;
    c.entry_point_eci_km_t0 = r_eci_m / 1000;

    r_enu_m = ecef_to_local_enu(r_ecef_m, cfg.geo.lat0_deg, cfg.geo.lon0_deg, cfg.geo.h0_m, cfg);

    c.entry_point_enu_m = r_enu_m;
    c.entry_point_enu_km = r_enu_m / 1000;
    c.entry_point_xy_km = c.entry_point_enu_km(1:2).';

    [R_enu_to_ecef, ~] = enu_basis_from_geodetic(cfg.geo.lat0_deg, cfg.geo.lon0_deg);
    u_ecef = R_enu_to_ecef * u_enu;
    u_ecef = u_ecef / norm(u_ecef);

    u_eci = local_rotate_ecef_vector_to_eci(u_ecef, cfg.time.epoch_utc, 0);
    u_eci = u_eci / norm(u_eci);

    c.heading_unit_ecef_t0 = u_ecef;
    c.heading_unit_eci_t0 = u_eci;
else
    c.entry_point_xy_km = p_enu_km_plot(1:2).';
    c.entry_point_enu_km = p_enu_km_plot(:);
    c.entry_point_enu_m = 1000 * p_enu_km_plot(:);

    c.entry_lat_deg = NaN;
    c.entry_lon_deg = NaN;
    c.entry_surface_dist_km = cfg.stage01.R_in_km;

    c.entry_point_ecef_m = nan(3, 1);
    c.entry_point_ecef_km = nan(3, 1);
    c.entry_point_eci_m_t0 = nan(3, 1);
    c.entry_point_eci_km_t0 = nan(3, 1);
    c.heading_unit_ecef_t0 = nan(3, 1);
    c.heading_unit_eci_t0 = nan(3, 1);
end
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

function u_eci = local_rotate_ecef_vector_to_eci(u_ecef, epoch_utc, dt_s)
gmst0 = gmst_from_utc(epoch_utc);
omega = 7.2921150e-5;
theta = gmst0 + omega * dt_s;
R3 = [cos(theta), -sin(theta), 0; ...
      sin(theta),  cos(theta), 0; ...
      0,           0,          1];
u_eci = R3 * u_ecef;
end

function opts = local_normalize_opts(cfg, opts)
if ~isfield(opts, 'mode') || isempty(opts.mode)
    opts.mode = 'serial';
end
opts.mode = char(lower(string(opts.mode)));

opts.use_parallel = strcmp(opts.mode, 'parallel');
if ~isfield(opts, 'parallel_config') || isempty(opts.parallel_config)
    opts.parallel_config = struct();
end
if ~isfield(opts.parallel_config, 'enabled') || isempty(opts.parallel_config.enabled)
    opts.parallel_config.enabled = opts.use_parallel;
end
if ~isfield(opts.parallel_config, 'profile_name') || isempty(opts.parallel_config.profile_name)
    opts.parallel_config.profile_name = cfg.stage01.parallel_pool_profile;
end
if ~isfield(opts.parallel_config, 'num_workers')
    opts.parallel_config.num_workers = cfg.stage01.parallel_num_workers;
end
if ~isfield(opts.parallel_config, 'auto_start_pool') || isempty(opts.parallel_config.auto_start_pool)
    opts.parallel_config.auto_start_pool = cfg.stage01.auto_start_pool;
end

if opts.use_parallel && opts.parallel_config.enabled
    pool = gcp('nocreate');
    if isempty(pool) && opts.parallel_config.auto_start_pool
        pool = ensure_parallel_pool(opts.parallel_config.profile_name, opts.parallel_config.num_workers);
    end
    opts.use_parallel = ~isempty(pool);
else
    opts.use_parallel = false;
end
end
