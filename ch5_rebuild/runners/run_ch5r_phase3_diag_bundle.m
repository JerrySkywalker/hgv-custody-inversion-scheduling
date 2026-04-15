function out = run_ch5r_phase3_diag_bundle()
%RUN_CH5R_PHASE3_DIAG_BUNDLE
% R3 diagnostic bundle:
% - run static-hold baseline
% - run Koopman diagnostic replay on fixed selection trace
% - build Chapter2-aligned posthoc diagnostic bundle
% - output the same 3 figures as R5/R9/R10

addpath(fullfile(pwd, 'ch5_rebuild', 'diagnostics'));
addpath(fullfile(pwd, 'ch5_rebuild', 'plots'));

disp('[diag][R3] phase runner: start')
disp('[diag][R3] phase runner: run Phase R3 static baseline')

out3 = run_ch5r_phase3_static_bubble_demo();

disp('[diag][R3] phase runner: run R3 Koopman diagnostic replay')
replay = ch5r_run_selection_replay_koopman('R3', out3, true, true);

out3.paths.mat_file = replay.paths.mat_file;

disp('[diag][R3] phase runner: build diagnostic bundle')
diag_out = ch5r_build_custody_diag_bundle('R3', out3);

out_dir = fullfile(out3.cfg.ch5r.output_root, 'phaseR3_diag_bundle');
disp(['[diag][R3] phase runner: plot to ' out_dir])
artifact_tag = local_diag_tag('R3', out3.case);
files = plot_ch5r_custody_diag_bundle(diag_out, out_dir, 'off', artifact_tag);

disp('=== [ch5r:R3-diag] summary ===')
disp(diag_out.fsm.summary)
disp(files)

out = struct();
out.phase = out3;
out.replay = replay;
out.diag = diag_out;
out.files = files;
out.ok = true;

disp('[diag][R3] phase runner: done')
end

function tag = local_diag_tag(phase_name, ch5case)
stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
tag = [lower(phase_name) '_' ch5r_make_artifact_tag(ch5case, stamp, {'diag-bundle'})];
end
