function out = run_stage15h25_sanity_check_smoke()
out = stage15h25_run_sanity_check();

disp('=== Stage15-H2.5 Sanity Check Smoke ===');
disp(['[stage15h25] text : ', out.summary_file]);
disp(['[stage15h25] mat  : ', out.mat_file]);
end
