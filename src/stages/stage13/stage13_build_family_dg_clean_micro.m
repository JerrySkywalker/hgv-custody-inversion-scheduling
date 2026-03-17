function micro_plan = stage13_build_family_dg_clean_micro(cfg, refine_evals, seed_tag)
%STAGE13_BUILD_FAMILY_DG_CLEAN_MICRO Build a very local DG-cleanliness micro plan.

cfg = stage13_default_config(cfg);
seed_eval = local_find_eval_by_tag(refine_evals, seed_tag);
seed_case = seed_eval.scan_out.case_selection.case_struct;

theta_offsets = cfg.stage13.dg_refine.micro.entry_theta_offsets_deg;
heading_offsets = cfg.stage13.dg_refine.micro.heading_offset_offsets_deg;
n = numel(theta_offsets) * numel(heading_offsets);

candidates = repmat(struct( ...
    'candidate_tag', "", ...
    'family', "dg_refined_micro", ...
    'h_km', cfg.stage13.baseline.theta.h_km, ...
    'i_deg', cfg.stage13.baseline.theta.i_deg, ...
    'P', cfg.stage13.baseline.theta.P, ...
    'T', cfg.stage13.baseline.theta.T, ...
    'F', cfg.stage13.baseline.theta.F, ...
    'Tw_s', cfg.stage13.baseline.Tw_s, ...
    'case_mode', "custom", ...
    'case_id', "", ...
    'seed_case_tag', string(seed_tag), ...
    'entry_theta_deg', 0, ...
    'heading_offset_deg', 0, ...
    'case_struct', struct()), n, 1);

idx = 0;
for i = 1:numel(theta_offsets)
    for j = 1:numel(heading_offsets)
        idx = idx + 1;
        entry_theta_deg = seed_case.entry_theta_deg + theta_offsets(i);
        heading_offset_deg = seed_case.heading_offset_deg + heading_offsets(j);
        candidate_tag = sprintf('dg_micro_%02d', idx);
        custom_case = local_build_custom_case(seed_case, cfg, entry_theta_deg, heading_offset_deg, candidate_tag);

        candidates(idx).candidate_tag = string(candidate_tag);
        candidates(idx).case_id = string(custom_case.case_id);
        candidates(idx).seed_case_tag = string(seed_tag);
        candidates(idx).entry_theta_deg = entry_theta_deg;
        candidates(idx).heading_offset_deg = heading_offset_deg;
        candidates(idx).case_struct = custom_case;
    end
end

micro_plan = struct();
micro_plan.seed_tag = string(seed_tag);
micro_plan.seed_case_id = string(seed_case.case_id);
micro_plan.candidates = candidates;
end

function seed_eval = local_find_eval_by_tag(evaluations, case_tag)
seed_eval = struct();
for k = 1:numel(evaluations)
    if strcmp(string(evaluations(k).signature.case_tag), string(case_tag))
        seed_eval = evaluations(k);
        return;
    end
end
error('Stage13 micro plan cannot find seed case: %s', case_tag);
end

function case_i = local_build_custom_case(seed_case, cfg, entry_theta_deg, heading_offset_deg, candidate_tag)
case_i = seed_case;
heading_deg = mod(entry_theta_deg + 180 + heading_offset_deg, 360);
entry_xy_km = cfg.stage01.R_in_km .* [cosd(entry_theta_deg), sind(entry_theta_deg)];
heading_xy = [cosd(heading_deg), sind(heading_deg)];

case_i.case_id = sprintf('%s_%+03.0f_%+03.0f', candidate_tag, entry_theta_deg, heading_offset_deg);
case_i.subfamily = 'heading_micro';
case_i.entry_theta_deg = entry_theta_deg;
case_i.heading_deg = heading_deg;
case_i.heading_offset_deg = heading_offset_deg;
case_i.entry_point_xy_km = entry_xy_km;
case_i.entry_point_enu_km = [entry_xy_km(1); entry_xy_km(2); 0];
case_i.entry_point_enu_m = case_i.entry_point_enu_km * 1000;
case_i.heading_unit_xy = heading_xy;
case_i.heading_unit_enu = [heading_xy(1); heading_xy(2); 0];
case_i.entry_surface_dist_km = cfg.stage01.R_in_km;

case_i.entry_point_ecef_m = local_enu_to_ecef(case_i.entry_point_enu_m, cfg.geo.lat0_deg, cfg.geo.lon0_deg, cfg.geo.h0_m, cfg);
case_i.entry_point_ecef_km = case_i.entry_point_ecef_m / 1000;
case_i.entry_point_eci_m_t0 = ecef_to_eci(case_i.entry_point_ecef_m, cfg.time.epoch_utc, 0);
case_i.entry_point_eci_km_t0 = case_i.entry_point_eci_m_t0 / 1000;

[R_enu_to_ecef, ~] = enu_basis_from_geodetic(cfg.geo.lat0_deg, cfg.geo.lon0_deg);
case_i.heading_unit_ecef_t0 = R_enu_to_ecef * case_i.heading_unit_enu;
case_i.heading_unit_eci_t0 = ecef_to_eci(case_i.heading_unit_ecef_t0, cfg.time.epoch_utc, 0);

[lat_deg, lon_deg, h_m] = ecef_to_geodetic(case_i.entry_point_ecef_m, cfg);
case_i.entry_lat_deg = lat_deg;
case_i.entry_lon_deg = lon_deg;
case_i.anchor_lat_deg = cfg.geo.lat0_deg;
case_i.anchor_lon_deg = cfg.geo.lon0_deg;
case_i.anchor_h_m = cfg.geo.h0_m;
case_i.epoch_utc = cfg.time.epoch_utc;
case_i.scene_mode = 'geodetic';
if ~isempty(h_m)
    case_i.entry_h_m = h_m;
end
end
