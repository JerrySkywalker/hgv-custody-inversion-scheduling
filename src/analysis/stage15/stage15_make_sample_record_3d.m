function rec = stage15_make_sample_record_3d(sample_id, box, target_state, sat1_state, sat2_state)
%STAGE15_MAKE_SAMPLE_RECORD_3D  Build one 3D pair-kernel sample record.

xi = stage15_compute_target_local_state_3d(target_state, box);
eta = stage15_compute_target_local_summary_eta(target_state, box);
kappa2 = stage15_compute_pair_kernel_3d(target_state, sat1_state, sat2_state, box);

if (kappa2.crossing_angle_deg < 35) || (kappa2.lambda_min_geom < 0.20)
    risk_label = 'geometry_fragile';
elseif (kappa2.crossing_angle_deg > 70) && (kappa2.lambda_min_geom > 0.55)
    risk_label = 'wide_safe';
else
    risk_label = 'safe';
end

rec = struct();
rec.sample_id = sample_id;
rec.box = box;
rec.target_state = target_state;
rec.sat1_state = sat1_state;
rec.sat2_state = sat2_state;
rec.xi = xi;
rec.eta = eta;
rec.kappa2 = kappa2;
rec.risk_label = risk_label;
end
