function stage15_write_validation_summary(pathStr, result)
%STAGE15_WRITE_VALIDATION_SUMMARY  Write Stage15-D validation summary.

fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open file: %s', pathStr);
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== Stage15-D Template Validation Summary ===\n');
fprintf(fid, 'num_samples = %d\n', result.num_samples);
fprintf(fid, 'num_correct = %d\n', result.num_correct);
fprintf(fid, 'accuracy = %.6f\n', result.accuracy);

fprintf(fid, '\n--- matches ---\n');
fprintf(fid, 'sample_id,true_label,matched_template_id,matched_label,distance,is_correct\n');

for i = 1:numel(result.matches)
    m = result.matches(i);
    fprintf(fid, '%s,%s,%s,%s,%.6f,%d\n', ...
        m.sample_id, ...
        m.true_label, ...
        m.matched_template_id, ...
        m.matched_label, ...
        m.distance, ...
        m.is_correct);
end
end
