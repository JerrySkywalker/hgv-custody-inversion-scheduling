function rec = stage15_make_sample_record(sample_id, box, target_state, sat1_xy_km, sat2_xy_km)
%STAGE15_MAKE_SAMPLE_RECORD  Build one pair-kernel sample record.

target_xy_km = target_state(1:2);

xi = stage15_compute_target_local_state(target_state, box);
kappa2 = stage15_compute_pair_kernel(target_xy_km, sat1_xy_km, sat2_xy_km, box);

if (kappa2.crossing_angle_deg < 35) || (kappa2.lambda_min_geom < 0.20)
    risk_label = 'geometry_fragile';
elseif (kappa2.crossing_angle_deg > 80) && (kappa2.lambda_min_geom > 0.60)
    risk_label = 'wide_safe';
else
    risk_label = 'safe';
end

rec = struct();
rec.sample_id = sample_id;
rec.box = box;
rec.target_state = target_state;
rec.sat1_xy_km = sat1_xy_km;
rec.sat2_xy_km = sat2_xy_km;
rec.xi = xi;
rec.kappa2 = kappa2;
rec.risk_label = risk_label;
end
