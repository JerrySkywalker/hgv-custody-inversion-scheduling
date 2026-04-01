function stage15_write_conditioned_template_family_summary_3d(pathStr, template_library)
%STAGE15_WRITE_CONDITIONED_TEMPLATE_FAMILY_SUMMARY_3D

fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== Stage15-G Conditioned Template Family Summary ===\n');
fprintf(fid, 'num_templates = %d\n', numel(template_library));

for i = 1:numel(template_library)
    t = template_library(i);

    fprintf(fid, '\n--- template %d ---\n', i);
    fprintf(fid, 'template_id = %s\n', t.template_id);
    fprintf(fid, 'geometry_class = %s\n', t.geometry_class);
    fprintf(fid, 'layout_class = %s\n', t.layout_class);
    fprintf(fid, 'risk_label = %s\n', t.risk_label);
    fprintf(fid, 'num_members = %d\n', t.num_members);
    fprintf(fid, 'member_ids = %s\n', strjoin(t.member_ids, ','));

    fprintf(fid, 'xi_proto.r_norm_xy = %.6f\n', t.xi_proto.r_norm_xy);
    fprintf(fid, 'xi_proto.z_norm = %.6f\n', t.xi_proto.z_norm);
    fprintf(fid, 'xi_proto.bearing_rad = %.6f\n', t.xi_proto.bearing_rad);
    fprintf(fid, 'xi_proto.heading_xy_rad = %.6f\n', t.xi_proto.heading_xy_rad);
    fprintf(fid, 'xi_proto.speed_norm = %.6f\n', t.xi_proto.speed_norm);

    fprintf(fid, 'eta_proto.radial_rate_norm = %.6f\n', t.eta_proto.radial_rate_norm);
    fprintf(fid, 'eta_proto.vertical_rate_norm = %.6f\n', t.eta_proto.vertical_rate_norm);
    fprintf(fid, 'eta_proto.turn_proxy = %.6f\n', t.eta_proto.turn_proxy);

    fprintf(fid, 'kappa2_proto.rho1_norm = %.6f\n', t.kappa2_proto.rho1_norm);
    fprintf(fid, 'kappa2_proto.rho2_norm = %.6f\n', t.kappa2_proto.rho2_norm);
    fprintf(fid, 'kappa2_proto.delta_h1_norm = %.6f\n', t.kappa2_proto.delta_h1_norm);
    fprintf(fid, 'kappa2_proto.delta_h2_norm = %.6f\n', t.kappa2_proto.delta_h2_norm);
    fprintf(fid, 'kappa2_proto.crossing_angle_deg = %.6f\n', t.kappa2_proto.crossing_angle_deg);
    fprintf(fid, 'kappa2_proto.lambda_min_geom = %.6f\n', t.kappa2_proto.lambda_min_geom);
end
end
