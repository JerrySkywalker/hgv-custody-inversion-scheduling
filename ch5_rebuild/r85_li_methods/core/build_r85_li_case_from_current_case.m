function li_case = build_r85_li_case_from_current_case(cfg)
%BUILD_R85_LI_CASE_FROM_CURRENT_CASE
% Build R8.5a working case from the current ch5r real case.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params(true);
    cfg = default_ch5r_r85_li_methods_params(cfg);
end

base_case = build_ch5r_case(cfg);
registry = build_r85_li_method_registry(cfg);

li_case = struct();
li_case.source = 'current_ch5r_case';
li_case.base_case = base_case;
li_case.registry = registry;
li_case.cfg = cfg;

li_case.meta = struct();
li_case.meta.case_id = base_case.target_case.case_id;
li_case.meta.family = base_case.target_case.family;
li_case.meta.dt = base_case.dt;
li_case.meta.n_steps = numel(base_case.t_s);
li_case.meta.window_length_s = base_case.window.length_s;
li_case.meta.window_length_steps = base_case.window.length_steps;
li_case.meta.gamma_req = base_case.gamma_req;

li_case.sensor = struct();
li_case.sensor.source = 'cfg.ch5r.sensor_profile';
li_case.sensor.name = '';
li_case.sensor.sigma_angle_deg = NaN;
li_case.sensor.sigma_angle_rad = NaN;
li_case.sensor.max_range_km = NaN;
li_case.sensor.fov_deg = NaN;
li_case.sensor.off_nadir_deg = NaN;

if isfield(cfg, 'ch5r') && isfield(cfg.ch5r, 'sensor_profile')
    sp = cfg.ch5r.sensor_profile;
    if isfield(sp, 'name'), li_case.sensor.name = sp.name; end
    if isfield(sp, 'sigma_angle_deg'), li_case.sensor.sigma_angle_deg = sp.sigma_angle_deg; end
    if isfield(sp, 'sigma_angle_rad'), li_case.sensor.sigma_angle_rad = sp.sigma_angle_rad; end
    if isfield(sp, 'max_range_km'), li_case.sensor.max_range_km = sp.max_range_km; end
    if isfield(sp, 'fov_deg'), li_case.sensor.fov_deg = sp.fov_deg; end
    if isfield(sp, 'off_nadir_deg'), li_case.sensor.off_nadir_deg = sp.off_nadir_deg; end
end

li_case.resource = registry.resource;
li_case.resource.interval_steps = max(1, round(li_case.resource.interval_s / li_case.meta.dt));

end
