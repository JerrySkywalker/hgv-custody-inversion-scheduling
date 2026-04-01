function stage15_write_holdout_split_summary(pathStr, split, result)
%STAGE15_WRITE_HOLDOUT_SPLIT_SUMMARY

fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== Stage15-G Holdout Validation Summary ===\n');
fprintf(fid, 'num_train_targets = %d\n', numel(split.train_targets));
fprintf(fid, 'num_test_targets = %d\n', numel(split.test_targets));
fprintf(fid, 'num_train_samples = %d\n', numel(split.train_dataset));
fprintf(fid, 'num_test_samples = %d\n', numel(split.test_dataset));

fprintf(fid, '\n--- train targets ---\n');
fprintf(fid, '%s\n', strjoin(split.train_targets, ','));

fprintf(fid, '\n--- test targets ---\n');
fprintf(fid, '%s\n', strjoin(split.test_targets, ','));

fprintf(fid, '\n--- test validation ---\n');
fprintf(fid, 'num_samples = %d\n', result.num_samples);
fprintf(fid, 'num_correct = %d\n', result.num_correct);
fprintf(fid, 'accuracy = %.6f\n', result.accuracy);

fprintf(fid, '\n--- matches (all test samples) ---\n');
fprintf(fid, 'sample_id,true_geometry,true_layout,true_label,matched_template_id,matched_geometry,matched_layout,matched_label,distance,is_correct\n');

for i = 1:numel(result.matches)
    m = result.matches(i);
    fprintf(fid, '%s,%s,%s,%s,%s,%s,%s,%s,%.6f,%d\n', ...
        m.sample_id, ...
        m.true_geometry_class, ...
        m.true_layout_class, ...
        m.true_label, ...
        m.matched_template_id, ...
        m.matched_geometry_class, ...
        m.matched_layout_class, ...
        m.matched_label, ...
        m.distance, ...
        m.is_correct);
end
end
