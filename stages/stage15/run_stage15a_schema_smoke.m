function out = run_stage15a_schema_smoke()
%RUN_STAGE15A_SCHEMA_SMOKE
% Minimal schema smoke for Stage15-A.

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'schema');
if ~exist(out_root, 'dir'); mkdir(out_root); end

box = stage15_default_local_box();

target_state = [200, 300, 4200, 1800]; % [x_km, y_km, vx_mps, vy_mps]
target_xy_km = target_state(1:2);

sat1_xy_km = [-600, -200];
sat2_xy_km = [700, -150];
sat3_xy_km = [-100, 800];

xi = stage15_compute_target_local_state(target_state, box);
kappa2 = stage15_compute_pair_kernel(target_xy_km, sat1_xy_km, sat2_xy_km, box);
kappa3 = stage15_compute_triplet_kernel(target_xy_km, sat1_xy_km, sat2_xy_km, sat3_xy_km, box);

rec2 = stage15_package_kernel_record(box, xi, 'pair', kappa2);
rec3 = stage15_package_kernel_record(box, xi, 'triplet', kappa3);

txt_path = fullfile(out_root, 'stage15a_schema_summary.txt');
mat_path = fullfile(out_root, 'stage15a_schema_smoke.mat');

stage15_write_schema_summary(txt_path, box, xi, rec2, rec3);
save(mat_path, 'box', 'xi', 'rec2', 'rec3');

disp('=== Stage15-A Schema Smoke ===')
disp(box)
disp(xi)
disp(rec2.kernel)
disp(rec3.kernel)
disp(['[stage15a] text : ', txt_path]);
disp(['[stage15a] mat  : ', mat_path]);

out = struct();
out.output_root = out_root;
out.text_file = txt_path;
out.mat_file = mat_path;
end
