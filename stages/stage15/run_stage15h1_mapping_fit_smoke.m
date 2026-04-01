function out = run_stage15h1_mapping_fit_smoke()
out = stage15h1_fit_mapping_models();

disp('=== Stage15-H1 Mapping Fit Smoke ===');
disp(['[stage15h1] text : ', out.summary_file]);
disp(['[stage15h1] mat  : ', out.mat_file]);
end
