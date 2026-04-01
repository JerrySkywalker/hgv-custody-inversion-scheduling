function out = run_stage15h0_coupled_calibration_dataset_smoke()
out = stage15h0_make_coupled_calibration_dataset();

disp('=== Stage15-H0 Coupled Calibration Dataset Smoke ===');
disp(['[stage15h0] text : ', out.summary_file]);
disp(['[stage15h0] mat  : ', out.mat_file]);
end
