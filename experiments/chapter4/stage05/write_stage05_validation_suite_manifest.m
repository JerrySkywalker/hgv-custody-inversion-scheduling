function manifest = write_stage05_validation_suite_manifest(out)
%WRITE_STAGE05_VALIDATION_SUITE_MANIFEST Write manifest files for Stage05 validation suite.

artifact_root = out.suite_spec.artifact_root;
manifest_dir = fullfile(artifact_root, 'manifest');
if exist(manifest_dir, 'dir') ~= 7
    mkdir(manifest_dir);
end

manifest = struct();
manifest.generated_at = string(datetime('now'));
manifest.started_at = out.started_at;
manifest.finished_at = out.finished_at;

manifest.suite_spec = out.suite_spec;

manifest.reproduction_grid_size = size(out.reproduction.grid_table);
manifest.best_pass_compare_height = height(out.compare.best_pass_compare);
manifest.heatmap_compare_height = height(out.compare.heatmap_compare);

manifest.best_pass_max_abs_diff = max(out.compare.best_pass_compare.pass_abs_diff, [], 'omitnan');
manifest.heatmap_max_abs_diff = max(out.compare.heatmap_compare.abs_diff, [], 'omitnan');

manifest.reproduction_artifact_root = string(out.suite_spec.reproduction_artifact_root);
manifest.validation_artifact_root = string(out.suite_spec.validation_artifact_root);

manifest_mat = fullfile(manifest_dir, 'validation_manifest.mat');
save(manifest_mat, 'manifest');

manifest_txt = fullfile(manifest_dir, 'validation_manifest.txt');
fid = fopen(manifest_txt, 'w');
if fid ~= -1
    fprintf(fid, 'Stage05 validation suite manifest\n');
    fprintf(fid, 'generated_at: %s\n', manifest.generated_at);
    fprintf(fid, 'started_at:   %s\n', manifest.started_at);
    fprintf(fid, 'finished_at:  %s\n', manifest.finished_at);
    fprintf(fid, '\n');

    fprintf(fid, 'reproduction_grid_size: [%d %d]\n', ...
        manifest.reproduction_grid_size(1), manifest.reproduction_grid_size(2));
    fprintf(fid, 'best_pass_compare_height: %d\n', manifest.best_pass_compare_height);
    fprintf(fid, 'heatmap_compare_height:   %d\n', manifest.heatmap_compare_height);
    fprintf(fid, 'best_pass_max_abs_diff:   %.16g\n', manifest.best_pass_max_abs_diff);
    fprintf(fid, 'heatmap_max_abs_diff:     %.16g\n', manifest.heatmap_max_abs_diff);
    fprintf(fid, '\n');

    fprintf(fid, 'reproduction_artifact_root: %s\n', manifest.reproduction_artifact_root);
    fprintf(fid, 'validation_artifact_root:   %s\n', manifest.validation_artifact_root);
    fclose(fid);
end

manifest.manifest_mat = string(manifest_mat);
manifest.manifest_txt = string(manifest_txt);
end
