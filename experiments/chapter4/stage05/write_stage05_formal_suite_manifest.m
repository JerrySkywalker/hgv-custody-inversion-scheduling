function manifest = write_stage05_formal_suite_manifest(out)
%WRITE_STAGE05_FORMAL_SUITE_MANIFEST Write manifest files for Stage05 formal suite.

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

manifest.legacy_grid_size = size(out.legacy_reproduction.grid_table);
manifest.opend_grid_size = size(out.opend_manual_raan.grid_table);
manifest.closedd_grid_size = size(out.closedd_manual_raan.grid_table);

manifest.legacy_artifact_root = string(out.suite_spec.legacy_artifact_root);
manifest.opend_artifact_root = string(out.suite_spec.opend_artifact_root);
manifest.closedd_artifact_root = string(out.suite_spec.closedd_artifact_root);

manifest_mat = fullfile(manifest_dir, 'manifest.mat');
save(manifest_mat, 'manifest');

manifest_txt = fullfile(manifest_dir, 'manifest.txt');
fid = fopen(manifest_txt, 'w');
if fid ~= -1
    fprintf(fid, 'Stage05 formal suite manifest\n');
    fprintf(fid, 'generated_at: %s\n', manifest.generated_at);
    fprintf(fid, 'started_at:   %s\n', manifest.started_at);
    fprintf(fid, 'finished_at:  %s\n', manifest.finished_at);
    fprintf(fid, '\n');
    fprintf(fid, 'legacy_grid_size:  [%d %d]\n', manifest.legacy_grid_size(1), manifest.legacy_grid_size(2));
    fprintf(fid, 'opend_grid_size:   [%d %d]\n', manifest.opend_grid_size(1), manifest.opend_grid_size(2));
    fprintf(fid, 'closedd_grid_size: [%d %d]\n', manifest.closedd_grid_size(1), manifest.closedd_grid_size(2));
    fprintf(fid, '\n');
    fprintf(fid, 'legacy_artifact_root:  %s\n', manifest.legacy_artifact_root);
    fprintf(fid, 'opend_artifact_root:   %s\n', manifest.opend_artifact_root);
    fprintf(fid, 'closedd_artifact_root: %s\n', manifest.closedd_artifact_root);
    fclose(fid);
end

manifest.manifest_mat = string(manifest_mat);
manifest.manifest_txt = string(manifest_txt);
end
