function stage15_write_schema3d_summary(pathStr, box, xi, eta, rec2)
%STAGE15_WRITE_SCHEMA3D_SUMMARY  Write stage15f 3d schema smoke summary.

fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== Stage15-F Schema3D Summary ===\n');
fprintf(fid, 'box_name = %s\n', box.box_name);
fprintf(fid, 'half_span_km = %.3f\n', box.half_span_km);
fprintf(fid, 'height_ref_km = %.3f\n', box.height_ref_km);
fprintf(fid, 'velocity_ref_mps = %.3f\n', box.velocity_ref_mps);

fprintf(fid, '\n--- target local state xi ---\n');
fprintf(fid, 'r_norm_xy = %.6f\n', xi.r_norm_xy);
fprintf(fid, 'z_norm = %.6f\n', xi.z_norm);
fprintf(fid, 'bearing_rad = %.6f\n', xi.bearing_rad);
fprintf(fid, 'heading_xy_rad = %.6f\n', xi.heading_xy_rad);
fprintf(fid, 'speed_norm = %.6f\n', xi.speed_norm);

fprintf(fid, '\n--- short-horizon summary eta ---\n');
fprintf(fid, 'radial_rate_norm = %.6f\n', eta.radial_rate_norm);
fprintf(fid, 'vertical_rate_norm = %.6f\n', eta.vertical_rate_norm);
fprintf(fid, 'turn_proxy = %.6f\n', eta.turn_proxy);

fprintf(fid, '\n--- pair kernel 3d ---\n');
fprintf(fid, 'rho1_norm = %.6f\n', rec2.kernel.rho1_norm);
fprintf(fid, 'rho2_norm = %.6f\n', rec2.kernel.rho2_norm);
fprintf(fid, 'delta_h1_norm = %.6f\n', rec2.kernel.delta_h1_norm);
fprintf(fid, 'delta_h2_norm = %.6f\n', rec2.kernel.delta_h2_norm);
fprintf(fid, 'crossing_angle_deg = %.6f\n', rec2.kernel.crossing_angle_deg);
fprintf(fid, 'lambda_min_geom = %.6f\n', rec2.kernel.lambda_min_geom);
end
