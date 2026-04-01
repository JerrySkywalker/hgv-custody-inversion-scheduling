function out = run_stage15f_schema3d_smoke()
%RUN_STAGE15F_SCHEMA3D_SMOKE
% Minimal 3D schema/object smoke for Stage15-F.

out_root = fullfile(pwd, 'outputs', 'stage', 'stage15', 'schema3d');
if ~exist(out_root, 'dir'); mkdir(out_root); end

box = stage15_default_local_box_3d();

target_state = [200, 300, 40, 4200, 1800, -50];   % [x,y,z,vx,vy,vz]
sat1_state   = [-600, -200, 850, 0, 0, 0];
sat2_state   = [700, -150, 820, 0, 0, 0];

xi = stage15_compute_target_local_state_3d(target_state, box);
eta = stage15_compute_target_local_summary_eta(target_state, box);
kappa2 = stage15_compute_pair_kernel_3d(target_state, sat1_state, sat2_state, box);
rec2 = stage15_package_kernel_record_3d(box, xi, eta, 'pair3d', kappa2);

txt_path = fullfile(out_root, 'stage15f_schema3d_summary.txt');
mat_path = fullfile(out_root, 'stage15f_schema3d_smoke.mat');

stage15_write_schema3d_summary(txt_path, box, xi, eta, rec2);
save(mat_path, 'box', 'target_state', 'sat1_state', 'sat2_state', 'xi', 'eta', 'rec2');

disp('=== Stage15-F Schema3D Smoke ===')
disp(box)
disp(xi)
disp(eta)
disp(rec2.kernel)
disp(['[stage15f] text : ', txt_path]);
disp(['[stage15f] mat  : ', mat_path]);

out = struct();
out.output_root = out_root;
out.text_file = txt_path;
out.mat_file = mat_path;
end
