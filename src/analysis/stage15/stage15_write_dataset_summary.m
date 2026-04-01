function stage15_write_dataset_summary(pathStr, dataset)
%STAGE15_WRITE_DATASET_SUMMARY  Write minimal dataset summary.

fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== Stage15-B Dataset Summary ===\n');
fprintf(fid, 'num_samples = %d\n', numel(dataset));

labels = string({dataset.risk_label});
u = unique(labels, 'stable');

fprintf(fid, '\n--- label histogram ---\n');
for i = 1:numel(u)
    fprintf(fid, '%s = %d\n', u(i), sum(labels == u(i)));
end

fprintf(fid, '\n--- samples ---\n');
fprintf(fid, 'sample_id,r_norm,bearing_rad,heading_rad,speed_norm,rho1_norm,rho2_norm,crossing_angle_deg,lambda_min_geom,risk_label\n');

for i = 1:numel(dataset)
    d = dataset(i);
    fprintf(fid, '%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%s\n', ...
        d.sample_id, ...
        d.xi.r_norm, ...
        d.xi.bearing_rad, ...
        d.xi.heading_rad, ...
        d.xi.speed_norm, ...
        d.kappa2.rho1_norm, ...
        d.kappa2.rho2_norm, ...
        d.kappa2.crossing_angle_deg, ...
        d.kappa2.lambda_min_geom, ...
        d.risk_label);
end
end
