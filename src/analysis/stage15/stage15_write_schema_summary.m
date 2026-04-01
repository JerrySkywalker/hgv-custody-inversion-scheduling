function stage15_write_schema_summary(pathStr, box, xi, rec2, rec3)
%STAGE15_WRITE_SCHEMA_SUMMARY  Write stage15a smoke summary.

fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== Stage15-A Schema Summary ===\n');
fprintf(fid, 'box_name = %s\n', box.box_name);
fprintf(fid, 'half_span_km = %.3f\n', box.half_span_km);
fprintf(fid, 'velocity_ref_mps = %.3f\n', box.velocity_ref_mps);

fprintf(fid, '\n--- target local state xi ---\n');
fprintf(fid, 'r_norm = %.6f\n', xi.r_norm);
fprintf(fid, 'bearing_rad = %.6f\n', xi.bearing_rad);
fprintf(fid, 'heading_rad = %.6f\n', xi.heading_rad);
fprintf(fid, 'speed_norm = %.6f\n', xi.speed_norm);

fprintf(fid, '\n--- pair kernel ---\n');
fprintf(fid, 'rho1_norm = %.6f\n', rec2.kernel.rho1_norm);
fprintf(fid, 'rho2_norm = %.6f\n', rec2.kernel.rho2_norm);
fprintf(fid, 'crossing_angle_deg = %.6f\n', rec2.kernel.crossing_angle_deg);
fprintf(fid, 'lambda_min_geom = %.6f\n', rec2.kernel.lambda_min_geom);

fprintf(fid, '\n--- triplet kernel ---\n');
fprintf(fid, 'rho1_norm = %.6f\n', rec3.kernel.rho1_norm);
fprintf(fid, 'rho2_norm = %.6f\n', rec3.kernel.rho2_norm);
fprintf(fid, 'rho3_norm = %.6f\n', rec3.kernel.rho3_norm);
fprintf(fid, 'theta12_deg = %.6f\n', rec3.kernel.theta12_deg);
fprintf(fid, 'theta13_deg = %.6f\n', rec3.kernel.theta13_deg);
fprintf(fid, 'theta23_deg = %.6f\n', rec3.kernel.theta23_deg);
fprintf(fid, 'lambda_min_geom = %.6f\n', rec3.kernel.lambda_min_geom);
end
