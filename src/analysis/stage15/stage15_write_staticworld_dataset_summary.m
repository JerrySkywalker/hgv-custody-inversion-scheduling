function stage15_write_staticworld_dataset_summary(pathStr, dataset)
%STAGE15_WRITE_STATICWORLD_DATASET_SUMMARY

fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== Stage15-F3 Staticworld Dataset Summary ===\n');
fprintf(fid, 'num_samples = %d\n', numel(dataset));

labels = string({dataset.risk_label});
u = unique(labels, 'stable');

fprintf(fid, '\n--- label histogram ---\n');
for i = 1:numel(u)
    fprintf(fid, '%s = %d\n', u(i), sum(labels == u(i)));
end

gcls = string({dataset.geometry_class});
ug = unique(gcls, 'stable');
fprintf(fid, '\n--- geometry histogram ---\n');
for i = 1:numel(ug)
    fprintf(fid, '%s = %d\n', ug(i), sum(gcls == ug(i)));
end

lcls = string({dataset.layout_class});
ul = unique(lcls, 'stable');
fprintf(fid, '\n--- layout histogram ---\n');
for i = 1:numel(ul)
    fprintf(fid, '%s = %d\n', ul(i), sum(lcls == ul(i)));
end

fprintf(fid, '\n--- first 20 samples ---\n');
fprintf(fid, 'sample_id,target_id,pair_id,geometry_class,layout_class,crossing_angle_deg,lambda_min_geom,risk_label\n');

nshow = min(20, numel(dataset));
for i = 1:nshow
    d = dataset(i);
    fprintf(fid, '%s,%s,%s,%s,%s,%.6f,%.6f,%s\n', ...
        d.sample_id, ...
        d.target_id, ...
        d.pair_id, ...
        d.geometry_class, ...
        d.layout_class, ...
        d.kappa2.crossing_angle_deg, ...
        d.kappa2.lambda_min_geom, ...
        d.risk_label);
end
end
